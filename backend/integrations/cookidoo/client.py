"""Async wrapper around cookidoo-api for recipe browsing & import."""

import logging
from datetime import date
from typing import Any

import aiohttp

logger = logging.getLogger("kalender.cookidoo")

_session: aiohttp.ClientSession | None = None
_client = None


async def get_client():
    """Lazily initialize and return Cookidoo client. Returns None if not configured."""
    global _session, _client

    if _client is not None:
        return _client

    try:
        from cookidoo_api import Cookidoo, CookidooConfig, CookidooLocalizationConfig
        from app.config import settings

        email = settings.COOKIDOO_EMAIL
        password = settings.COOKIDOO_PASSWORD
        if not email or not password:
            logger.info("Cookidoo credentials not configured, bridge disabled")
            return None

        loc = CookidooLocalizationConfig(
            country_code="de",
            language="de-DE",
            url="https://cookidoo.de/foundation/de-DE",
        )
        cfg = CookidooConfig(localization=loc, email=email, password=password)

        _session = aiohttp.ClientSession()
        _client = Cookidoo(_session, cfg)
        await _client.login()
        logger.info("Cookidoo client authenticated")
        return _client

    except ImportError:
        logger.warning("cookidoo-api not installed, bridge disabled")
        return None
    except Exception as e:
        logger.error("Cookidoo login failed: %s", e)
        if _session and not _session.closed:
            await _session.close()
        _session = None
        _client = None
        return None


async def _ensure_auth():
    """Re-login if token is expired."""
    global _client, _session
    client = await get_client()
    if client is None:
        return None
    try:
        if client.expires_in < 60:
            await client.login()
    except Exception:
        logger.warning("Cookidoo re-login failed, resetting client", exc_info=True)
        if _session and not _session.closed:
            await _session.close()
        _session = None
        _client = None
        return None
    return client


def _serialize_ingredient(ing) -> dict[str, Any]:
    return {
        "id": getattr(ing, "id", ""),
        "name": getattr(ing, "name", str(ing)),
        "description": getattr(ing, "description", ""),
    }


def _serialize_recipe_brief(r) -> dict[str, Any]:
    thumb = (
        getattr(r, "thumbnail", None)
        or getattr(r, "image_url", None)
        or getattr(r, "image", None)
    )
    return {
        "cookidoo_id": r.id,
        "name": getattr(r, "name", ""),
        "total_time": getattr(r, "total_time", None),
        "thumbnail": thumb,
        "url": getattr(r, "url", None),
        "ingredients": [_serialize_ingredient(i) for i in getattr(r, "ingredients", [])],
    }


async def get_collections() -> list[dict[str, Any]]:
    client = await _ensure_auth()
    if not client:
        return []
    try:
        # cookidoo-api has changed naming/behavior across versions.
        # Some accounts have collections that are not returned by "managed collections".
        # Try a small set of known methods, first successful result wins.
        collections = None
        for method_name in (
            "get_managed_collections",
            "get_collections",
            "get_recipe_collections",
            "get_my_collections",
        ):
            method = getattr(client, method_name, None)
            if method is None:
                continue
            try:
                collections = await method()
                logger.info("Cookidoo collections loaded via %s: %s", method_name, len(collections or []))
                break
            except Exception:
                logger.warning("Cookidoo collections method failed: %s", method_name, exc_info=True)
                continue

        if collections is None:
            logger.warning("Cookidoo client has no supported collections method")
            return []
        result = []
        for col in collections:
            chapters = []
            for ch in getattr(col, "chapters", []):
                recipes = []
                for rec in getattr(ch, "recipes", []):
                    thumb = (
                        getattr(rec, "thumbnail", None)
                        or getattr(rec, "image_url", None)
                        or getattr(rec, "image", None)
                    )
                    recipes.append({
                        "cookidoo_id": rec.id,
                        "name": getattr(rec, "name", ""),
                        "total_time": getattr(rec, "total_time", None),
                        "thumbnail": thumb,
                        "url": getattr(rec, "url", None),
                        "ingredients": [],
                    })
                chapters.append({
                    "name": getattr(ch, "name", ""),
                    "recipes": recipes,
                })
            result.append({
                "id": col.id,
                "name": getattr(col, "name", ""),
                "description": getattr(col, "description", ""),
                "chapters": chapters,
            })
        return result
    except Exception as e:
        logger.error("Cookidoo get_collections error: %s", e, exc_info=True)
        return []


async def get_shopping_list() -> list[dict[str, Any]]:
    client = await _ensure_auth()
    if not client:
        return []
    try:
        recipes = await client.get_shopping_list_recipes()
        return [_serialize_recipe_brief(r) for r in recipes]
    except Exception as e:
        logger.error("Cookidoo shopping list error: %s", e)
        return []


async def get_recipe_detail(cookidoo_id: str) -> dict[str, Any] | None:
    client = await _ensure_auth()
    if not client:
        return None
    try:
        r = await client.get_recipe_details(cookidoo_id)
        ingredients = [_serialize_ingredient(i) for i in getattr(r, "ingredients", [])]
        # Extract instructions from notes or instructions field
        instructions_list = getattr(r, "instructions", None) or getattr(r, "notes", None) or []
        instructions_text = None
        if instructions_list and isinstance(instructions_list, list):
            steps = [s for s in instructions_list if s and s.strip()]
            if steps:
                instructions_text = "\n".join(f"{i+1}. {step}" for i, step in enumerate(steps))

        # Some cookidoo-api versions expose a textual description/summary separately.
        description = (
            getattr(r, "description", None)
            or getattr(r, "summary", None)
            or getattr(r, "subtitle", None)
        )
        if isinstance(description, list):
            description = "\n".join([str(s) for s in description if s])
        if description is not None:
            description = str(description).strip() or None

        return {
            "cookidoo_id": r.id,
            "name": getattr(r, "name", ""),
            "serving_size": getattr(r, "serving_size", 4),
            "total_time": getattr(r, "total_time", None),
            "active_time": getattr(r, "active_time", None),
            "difficulty": getattr(r, "difficulty", None),
            "image": getattr(r, "image", None),
            "url": getattr(r, "url", None),
            "ingredients": ingredients,
            "description": description,
            "instructions": instructions_text,
            "categories": [getattr(c, "name", str(c)) for c in getattr(r, "categories", [])],
        }
    except Exception as e:
        logger.error("Cookidoo recipe detail error: %s", e)
        return None


async def get_calendar_week(day: date) -> list[dict[str, Any]]:
    client = await _ensure_auth()
    if not client:
        return []
    try:
        days = await client.get_recipes_in_calendar_week(day)
        result = []
        for d in days:
            result.append({
                "date": str(getattr(d, "date", "")),
                "recipes": [
                    {"cookidoo_id": rec.id, "name": getattr(rec, "name", "")}
                    for rec in getattr(d, "recipes", [])
                ],
            })
        return result
    except Exception as e:
        logger.error("Cookidoo calendar error: %s", e)
        return []


def _map_difficulty(val) -> str:
    if val is None:
        return "medium"
    val_lower = str(val).lower()
    if "easy" in val_lower or "einfach" in val_lower or "leicht" in val_lower:
        return "easy"
    if "hard" in val_lower or "schwer" in val_lower or "aufwendig" in val_lower:
        return "hard"
    return "medium"
