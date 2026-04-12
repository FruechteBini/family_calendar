"""Wrapper around knuspr (knuspr-api) for product search and cart management.

Uses the synchronous ``knuspr.KnusprClient`` inside ``asyncio.to_thread`` so FastAPI
stays non-blocking. Credentials: ``KNUSPR_EMAIL`` / ``KNUSPR_PASSWORD`` from app settings
(mapped to username/password for Knuspr).
"""

from __future__ import annotations

import asyncio
import logging
from functools import lru_cache
from typing import Any, Callable, TypeVar

from pydantic_settings import SettingsConfigDict

logger = logging.getLogger("kalender.knuspr")


@lru_cache(maxsize=1)
def _isolated_knuspr_config_model():
    """Knuspr BaseSettings subclass that does not read the app's .env (avoids extra_forbidden)."""
    from knuspr.config import KnusprConfig

    class _KnusprConfigNoAppEnv(KnusprConfig):
        model_config = SettingsConfigDict(
            env_prefix="KNUSPR_",
            env_file=None,
            env_file_encoding="utf-8",
        )

    return _KnusprConfigNoAppEnv


_knuspr_auth_patched = False


def _patch_knuspr_auth_null_safe() -> None:
    """knuspr-api 0.3.0 crashes if login JSON has user/address set to null."""
    global _knuspr_auth_patched
    if _knuspr_auth_patched:
        return
    try:
        import httpx
        from knuspr import endpoints
        from knuspr.auth import AuthHandler
        from knuspr.exceptions import APIError, AuthenticationError, NetworkError
    except ImportError:
        return

    def login(self: Any, http_client: httpx.Client) -> dict:
        try:
            response = http_client.post(
                self._config.base_url + endpoints.LOGIN,
                json={
                    "email": self._config.username,
                    "password": self._config.password,
                    "name": "",
                },
            )
        except httpx.RequestError as e:
            raise NetworkError(f"Login request failed: {e}") from e

        if response.status_code in (401, 403):
            raise AuthenticationError("Invalid credentials")

        data = response.json()
        inner_status = data.get("status")
        if inner_status and inner_status in (401, 403):
            raise AuthenticationError("Invalid credentials")

        if inner_status and inner_status not in (200, 202):
            messages = data.get("messages") or []
            first = messages[0] if messages else None
            msg = (
                first.get("content", "Login failed")
                if isinstance(first, dict)
                else "Login failed"
            )
            raise APIError(msg, status_code=inner_status)

        user_data = data.get("data") or {}
        user_obj = user_data.get("user")
        if not isinstance(user_obj, dict):
            user_obj = {}
        addr_obj = user_data.get("address")
        if not isinstance(addr_obj, dict):
            addr_obj = {}
        self.user_id = user_obj.get("id")
        self.address_id = addr_obj.get("id")
        self._authenticated = True
        return data

    AuthHandler.login = login  # type: ignore[method-assign]
    _knuspr_auth_patched = True


_client: Any = None
_client_lock = asyncio.Lock()

T = TypeVar("T")


def _import_knuspr_client():
    try:
        from knuspr import KnusprClient
        from knuspr.exceptions import AuthenticationError, KnusprError

        return KnusprClient, AuthenticationError, KnusprError
    except ImportError:
        return None, None, None


async def reset_client() -> None:
    """Close and drop cached client (e.g. after auth failure)."""
    global _client
    async with _client_lock:
        old = _client
        _client = None
        if old is not None:

            def _close():
                try:
                    old.__exit__(None, None, None)
                except Exception:
                    pass

            await asyncio.to_thread(_close)


async def _ensure_client():
    """Return logged-in KnusprClient (context-entered, not exited)."""
    global _client
    KnusprClient, AuthenticationError, KnusprError = _import_knuspr_client()
    if KnusprClient is None:
        return None

    async with _client_lock:
        if _client is not None:
            return _client

        from app.config import settings

        username = (settings.KNUSPR_EMAIL or "").strip()
        password = (settings.KNUSPR_PASSWORD or "").strip()
        if not username or not password:
            logger.info("Knuspr credentials not configured, bridge disabled")
            return None

        _patch_knuspr_auth_null_safe()

        def _open():
            cfg = _isolated_knuspr_config_model()(username=username, password=password)
            cli = KnusprClient(config=cfg)
            cli.__enter__()
            return cli

        try:
            _client = await asyncio.to_thread(_open)
            logger.info("Knuspr client authenticated")
            return _client
        except Exception as e:
            logger.error("Knuspr login failed: %s", e)
            _client = None
            return None


async def run_with_client(fn: Callable[[Any], T], *, retry_on_auth: bool = True) -> T:
    """Run sync function ``fn(client)`` with auto re-login on auth errors once."""
    from knuspr.exceptions import AuthenticationError

    client = await _ensure_client()
    if not client:
        raise RuntimeError("Knuspr nicht konfiguriert")

    try:
        return await asyncio.to_thread(fn, client)
    except AuthenticationError:
        if not retry_on_auth:
            raise
        logger.warning("Knuspr session expired, re-authenticating")
        await reset_client()
        client = await _ensure_client()
        if not client:
            raise RuntimeError("Knuspr nicht konfiguriert")
        return await asyncio.to_thread(fn, client)


def _raw_product_to_dict(p: dict[str, Any]) -> dict[str, Any]:
    """Normalize raw Knuspr API product JSON to our API shape.

    Works directly on the dict from the JSON response – avoids knuspr-api 0.3.0
    bugs where brand/other fields can be None but the Pydantic model requires str.
    """
    raw_price = p.get("price")
    price_val: float | None = None
    if isinstance(raw_price, dict):
        try:
            price_val = float(raw_price.get("full") or 0) or None
        except (TypeError, ValueError):
            pass
    elif raw_price is not None:
        try:
            price_val = float(raw_price)
        except (TypeError, ValueError):
            pass

    img = p.get("imgPath") or p.get("image_path") or p.get("image_url")
    image_url: str | None = None
    if img:
        s = str(img)
        image_url = s if s.startswith("http") else f"https://www.knuspr.de{s}" if s.startswith("/") else s

    return {
        "id": str(p.get("productId", "")),
        "name": str(p.get("productName") or ""),
        "price": price_val,
        "unit": str(p.get("textualAmount") or "") or None,
        "available": bool(p.get("inStock", True)),
        # Knuspr/Rohlik search payloads mark account favourites on each hit (no separate favourites API).
        "favourite": bool(p.get("favourite") or p.get("favorite")),
        "image_url": image_url,
        "category": str(p.get("primaryCategoryName") or "") or None,
    }


def _product_to_dict(p: Any) -> dict[str, Any]:
    """Normalize SearchResult (or duck-typed) to API shape – legacy, kept for compatibility."""
    if isinstance(p, dict):
        return _raw_product_to_dict(p)

    pid = str(getattr(p, "id", p))
    name = str(getattr(p, "name", ""))
    try:
        price_val: float | None = float(p.price_value)  # SearchResult property
    except Exception:
        raw = getattr(p, "price", None)
        if isinstance(raw, dict):
            price_val = float(raw.get("full") or 0) or None
        elif raw is not None:
            try:
                price_val = float(raw)
            except (TypeError, ValueError):
                price_val = None
        else:
            price_val = None

    unit = getattr(p, "amount", None) or getattr(p, "unit", None)
    if unit is not None:
        unit = str(unit)
    available = getattr(p, "in_stock", getattr(p, "available", True))
    img = getattr(p, "image_path", None) or getattr(p, "image_url", None)
    image_url = None
    if img:
        s = str(img)
        image_url = s if s.startswith("http") else f"https://www.knuspr.de{s}" if s.startswith("/") else s

    return {
        "id": pid,
        "name": name,
        "price": price_val,
        "unit": unit,
        "available": bool(available),
        "favourite": bool(getattr(p, "favourite", False)),
        "image_url": image_url,
        "category": getattr(p, "primary_category_name", None) or getattr(p, "category", None),
    }


async def get_client():
    """Return cached Knuspr client or None (for legacy callers)."""
    return await _ensure_client()


async def search_products(query: str, limit: int = 20) -> list[dict[str, Any]]:
    """Search Knuspr products via direct HTTP to avoid knuspr-api 0.3.0 model bugs (brand=None crash)."""
    if _import_knuspr_client()[0] is None:
        return []

    import json as _json

    from knuspr import endpoints as _ep

    def _search(c):
        params = {
            "search": query,
            "offset": "0",
            "limit": str(limit),
            "companyId": "1",
            "filterData": _json.dumps({"filters": []}),
            "canCorrect": "true",
        }
        raw = c._get(_ep.SEARCH, params=params)
        products = raw.get("productList", [])
        out = []
        for p in products:
            badge = p.get("badge")
            if isinstance(badge, list) and any(
                b.get("slug") == "promoted" for b in badge if isinstance(b, dict)
            ):
                continue
            out.append(_raw_product_to_dict(p))
        return out

    try:
        return await run_with_client(_search)
    except Exception as e:
        logger.error("Knuspr search error for %r: %s", query, e)
        return []


def pick_search_hit_for_cart(products: list[dict[str, Any]]) -> dict[str, Any] | None:
    """Prefer Knuspr account favourite among in-stock hits, else first in-stock, else first hit."""
    if not products:
        return None
    avail = [p for p in products if p.get("available", True)]
    fav_avail = [p for p in avail if p.get("favourite")]
    if fav_avail:
        return fav_avail[0]
    if avail:
        return avail[0]
    return products[0]


async def get_delivery_slots() -> list[dict[str, Any]]:
    def _slots(c):
        slots = c.get_delivery_slots()
        out = []
        for s in slots or []:
            sid = getattr(s, "id", "")
            start = getattr(s, "start", None)
            end = getattr(s, "end", None)
            start_s = str(start) if start is not None else None
            end_s = str(end) if end is not None else None
            date_part = None
            time_range = None
            if start_s and end_s:
                if "T" in start_s:
                    date_part = start_s.split("T", 1)[0]
                elif len(start_s) >= 10 and start_s[4] == "-":
                    date_part = start_s[:10]
                time_range = f"{start_s} – {end_s}"
            out.append(
                {
                    "id": str(sid),
                    "start": start_s,
                    "end": end_s,
                    "date": date_part or "",
                    "time_range": time_range or (start_s or str(sid)),
                    "available": bool(getattr(s, "is_available", True)),
                    "fee": getattr(s, "price", None),
                }
            )
        return out

    try:
        return await run_with_client(_slots)
    except Exception as e:
        logger.error("Knuspr delivery slots error: %s", e)
        return []


async def add_to_cart(product_id: str, quantity: int = 1) -> None:
    pid = int(product_id)

    def _add(c):
        c.add_to_cart(pid, quantity=quantity)

    await run_with_client(_add)


async def clear_cart() -> None:
    def _clear(c):
        cart = c.get_cart()
        for line in cart.items:
            c.remove_from_cart(line.order_field_id)

    await run_with_client(_clear)


async def get_cart_payload() -> dict[str, Any]:
    def _get(c):
        cart = c.get_cart()
        items = []
        for it in cart.items:
            items.append(
                {
                    "order_field_id": it.order_field_id,
                    "product_id": str(it.product_id),
                    "name": it.product_name,
                    "quantity": it.quantity,
                    "price": float(it.price or 0),
                }
            )
        return {
            "items": items,
            "total_price": float(cart.total_price or 0),
            "total_items": int(cart.total_items or len(items)),
            "can_make_order": bool(cart.can_make_order),
        }

    return await run_with_client(_get)


async def remove_cart_line(order_field_id: str) -> None:
    oid = str(order_field_id)

    def _rm(c):
        c.remove_from_cart(oid)

    await run_with_client(_rm)


async def knuspr_status_probe() -> tuple[bool, str | None]:
    """Return (ok, error_message)."""
    KnusprClient, _, _ = _import_knuspr_client()
    if KnusprClient is None:
        return False, "knuspr-api nicht installiert"
    from app.config import settings

    if not (settings.KNUSPR_EMAIL and settings.KNUSPR_PASSWORD):
        return False, "Zugangsdaten fehlen"

    try:

        def _ping(c):
            c.search_products("milch", limit=1)

        await run_with_client(_ping, retry_on_auth=True)
        return True, None
    except Exception as e:
        return False, str(e)


async def book_delivery_slot(slot_id: str) -> tuple[bool, str]:
    """Reserve a delivery slot (best-effort; API undocumented in knuspr 0.3.0)."""

    def _book(c):
        last_err = ""
        for path, payload in (
            ("/services/frontend-service/timeslots-api/0/select", {"slotId": slot_id}),
            ("/services/frontend-service/timeslots-api/0/select", {"id": slot_id}),
            ("/services/frontend-service/timeslots-api/0", {"action": "select", "slotId": slot_id}),
        ):
            try:
                c._post(path, json=payload)
                return True, ""
            except Exception as e:
                last_err = str(e)
        return False, last_err or "Slot konnte nicht gebucht werden"

    try:
        return await run_with_client(_book)
    except Exception as e:
        return False, str(e)
