"""Wrapper around knuspr-api for product search and cart management."""

import logging
from typing import Any

logger = logging.getLogger("kalender.knuspr")

_knuspr = None


async def get_client():
    """Lazily initialize and return Knuspr client. Returns None if not configured."""
    global _knuspr
    if _knuspr is not None:
        return _knuspr

    try:
        from knuspr_api import KnusprClient
        from app.config import settings

        email = settings.KNUSPR_EMAIL
        password = settings.KNUSPR_PASSWORD
        if not email or not password:
            logger.info("Knuspr credentials not configured, bridge disabled")
            return None

        _knuspr = KnusprClient(email=email, password=password)
        await _knuspr.login()
        logger.info("Knuspr client authenticated")
        return _knuspr
    except ImportError:
        logger.warning("knuspr-api not installed, bridge disabled")
        return None
    except Exception as e:
        logger.error("Knuspr login failed: %s", e)
        _knuspr = None
        return None


async def search_products(query: str, limit: int = 20) -> list[dict[str, Any]]:
    client = await get_client()
    if not client:
        return []
    try:
        results = await client.search(query)
        return [
            {
                "product_id": getattr(p, "id", str(p)),
                "name": getattr(p, "name", str(p)),
                "price": getattr(p, "price", None),
                "unit": getattr(p, "unit", None),
                "available": getattr(p, "available", True),
            }
            for p in (results[:limit] if results else [])
        ]
    except Exception as e:
        logger.error("Knuspr search error: %s", e)
        return []


async def get_delivery_slots() -> list[dict[str, Any]]:
    client = await get_client()
    if not client:
        return []
    try:
        slots = await client.get_delivery_slots()
        return [
            {
                "slot_id": getattr(s, "id", str(s)),
                "date": str(getattr(s, "date", "")),
                "time_range": getattr(s, "time_range", str(s)),
            }
            for s in (slots or [])
        ]
    except Exception as e:
        logger.error("Knuspr delivery slots error: %s", e)
        return []
