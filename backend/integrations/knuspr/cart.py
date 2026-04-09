"""Cart management for Knuspr: send shopping list items to Knuspr cart."""

import logging
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlalchemy import select

from app.models.shopping_list import ShoppingItem, ShoppingList
from . import client as knuspr_client

logger = logging.getLogger("kalender.knuspr")


async def send_list_to_cart(shopping_list_id: int, db: AsyncSession) -> dict[str, Any]:
    """Search each unchecked item on Knuspr and add best match to cart."""
    kn = await knuspr_client.get_client()
    if not kn:
        return {"success": False, "error": "Knuspr nicht konfiguriert"}

    stmt = (
        select(ShoppingList)
        .options(selectinload(ShoppingList.items))
        .where(ShoppingList.id == shopping_list_id)
    )
    result = await db.execute(stmt)
    sl = result.scalar_one_or_none()
    if not sl:
        return {"success": False, "error": "Einkaufsliste nicht gefunden"}

    unchecked = [i for i in sl.items if not i.checked]
    added = []
    failed = []

    for item in unchecked:
        try:
            products = await knuspr_client.search_products(item.name, limit=1)
            if products and products[0].get("available", True):
                product = products[0]
                await kn.add_to_cart(product["product_id"], quantity=1)
                added.append({"item": item.name, "product": product["name"]})
            else:
                failed.append({"item": item.name, "reason": "Nicht gefunden oder nicht verfügbar"})
        except Exception as e:
            failed.append({"item": item.name, "reason": str(e)})

    return {
        "success": True,
        "added": added,
        "failed": failed,
        "total_added": len(added),
        "total_failed": len(failed),
    }
