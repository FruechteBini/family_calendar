"""Async wrapper around cookidoo-api for recipe browsing & import."""

import logging
from datetime import date
from typing import Any, cast

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


def _instructions_from_recipe_step_groups(raw: dict[str, Any]) -> str | None:
    """Build numbered instruction text from Cookidoo API ``recipeStepGroups``."""
    groups = raw.get("recipeStepGroups")
    if not isinstance(groups, list) or not groups:
        return None
    lines: list[str] = []
    step_no = 1
    for group in groups:
        if not isinstance(group, dict):
            continue
        title = str(group.get("title") or "").strip()
        steps = group.get("recipeSteps")
        if title and isinstance(steps, list) and steps:
            lines.append(title)
        if not isinstance(steps, list):
            continue
        for step in steps:
            if not isinstance(step, dict):
                continue
            formatted = str(step.get("formattedText") or "").strip()
            step_title = str(step.get("title") or "").strip()
            body = formatted or step_title
            if body:
                lines.append(f"{step_no}. {body}")
                step_no += 1
    text = "\n".join(lines).strip()
    return text or None


async def get_recipe_detail(cookidoo_id: str) -> dict[str, Any] | None:
    client = await _ensure_auth()
    if not client:
        return None
    try:
        # One HTTP GET: cookidoo-api's ``get_recipe_details`` omits step groups from the model;
        # parse raw JSON for Zubereitungsschritte.
        from cookidoo_api.const import RECIPE_PATH
        from cookidoo_api.helpers import cookidoo_recipe_details_from_json
        from cookidoo_api.raw_types import RecipeDetailsJSON

        url = client.api_endpoint / RECIPE_PATH.format(
            **client._cfg.localization.__dict__, id=cookidoo_id
        )
        async with client._session.get(url, headers=client._api_headers) as resp:
            if resp.status == 401:
                logger.warning("Cookidoo recipe detail HTTP 401 for id=%s", cookidoo_id)
                return None
            resp.raise_for_status()
            raw = cast(dict[str, Any], await resp.json())

        r = cookidoo_recipe_details_from_json(
            cast(RecipeDetailsJSON, raw), client._cfg.localization
        )
        ingredients = [_serialize_ingredient(i) for i in getattr(r, "ingredients", [])]

        instructions_text = _instructions_from_recipe_step_groups(raw)
        if not instructions_text:
            instr_attr = getattr(r, "instructions", None)
            if isinstance(instr_attr, list):
                steps = [str(s).strip() for s in instr_attr if s and str(s).strip()]
                if steps:
                    instructions_text = "\n".join(
                        f"{i + 1}. {step}" for i, step in enumerate(steps)
                    )
            elif isinstance(instr_attr, str) and instr_attr.strip():
                instructions_text = instr_attr.strip()

        description = (
            getattr(r, "description", None)
            or getattr(r, "summary", None)
            or getattr(r, "subtitle", None)
        )
        if isinstance(description, list):
            description = "\n".join([str(s) for s in description if s])
        if description is not None:
            description = str(description).strip() or None

        if not description and hasattr(r, "notes"):
            hint_lines = [
                str(n).strip()
                for n in (getattr(r, "notes", None) or [])
                if n and str(n).strip()
            ]
            if hint_lines:
                description = "\n".join(hint_lines)

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


async def add_recipes_to_planning_day(
    cookidoo_ids: list[str],
    day: date | None = None,
) -> dict[str, Any] | None:
    """Trägt Rezepte in Cookidoo „Mein Tag“ ein (sync zum Thermomix / Cookidoo-App)."""
    client = await _ensure_auth()
    if not client:
        return None
    seen: set[str] = set()
    ids: list[str] = []
    for raw in cookidoo_ids:
        cid = str(raw).strip() if raw else ""
        if not cid or cid in seen:
            continue
        seen.add(cid)
        ids.append(cid)
    if not ids:
        return None
    target_day = day or date.today()
    try:
        cal_day = await client.add_recipes_to_calendar(target_day, ids)
        return {
            "day": target_day.isoformat(),
            "recipes": [
                {"cookidoo_id": r.id, "name": getattr(r, "name", "")}
                for r in getattr(cal_day, "recipes", []) or []
            ],
        }
    except Exception as e:
        logger.error(
            "Cookidoo add_recipes_to_calendar day=%s ids=%s: %s",
            target_day.isoformat(),
            ids,
            e,
            exc_info=True,
        )
        raise


def _map_difficulty(val) -> str:
    if val is None:
        return "medium"
    val_lower = str(val).lower()
    if "easy" in val_lower or "einfach" in val_lower or "leicht" in val_lower:
        return "easy"
    if "hard" in val_lower or "schwer" in val_lower or "aufwendig" in val_lower:
        return "hard"
    return "medium"
