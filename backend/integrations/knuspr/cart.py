"""Cart management for Knuspr: shopping list preview, send, and product mappings."""

from __future__ import annotations

import logging
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import utcnow
from app.models.knuspr_mapping import KnusprProductMapping
from app.models.shopping_list import ShoppingItem, ShoppingList
from app.utils import normalize_ingredient_name

from . import client as knuspr_client

logger = logging.getLogger("kalender.knuspr")


def shopping_item_quantity(item: ShoppingItem) -> int:
    """Heuristic: integer pack count from amount string, else 1."""
    s = (item.amount or "").strip()
    if s.isdigit():
        v = int(s)
        if 1 <= v <= 99:
            return v
    return 1


async def _get_mapping(
    db: AsyncSession, family_id: int, normalized_name: str,
) -> KnusprProductMapping | None:
    r = await db.execute(
        select(KnusprProductMapping).where(
            KnusprProductMapping.family_id == family_id,
            KnusprProductMapping.item_name_normalized == normalized_name,
        )
    )
    return r.scalar_one_or_none()


async def _record_mapping(
    db: AsyncSession,
    family_id: int,
    item_name: str,
    product_id: str,
    product_name: str,
) -> None:
    norm = normalize_ingredient_name(item_name)
    row = await _get_mapping(db, family_id, norm)
    now = utcnow()
    if row:
        row.knuspr_product_id = product_id
        row.knuspr_product_name = product_name or row.knuspr_product_name
        row.use_count = (row.use_count or 0) + 1
        row.last_used_at = now
    else:
        db.add(
            KnusprProductMapping(
                family_id=family_id,
                item_name_normalized=norm,
                knuspr_product_id=product_id,
                knuspr_product_name=product_name or "",
                use_count=1,
                last_used_at=now,
            )
        )


def _match_from_dict(d: dict[str, Any]) -> dict[str, Any]:
    return {
        "product_id": d["id"],
        "name": d["name"],
        "price": d.get("price"),
        "unit": d.get("unit"),
        "available": d.get("available", True),
    }


async def preview_shopping_list(
    shopping_list_id: int, db: AsyncSession, family_id: int,
) -> dict[str, Any] | None:
    stmt = (
        select(ShoppingList)
        .options(selectinload(ShoppingList.items))
        .where(
            ShoppingList.id == shopping_list_id,
            ShoppingList.family_id == family_id,
        )
    )
    result = await db.execute(stmt)
    sl = result.scalar_one_or_none()
    if not sl:
        return None

    lines: list[dict[str, Any]] = []
    for item in sl.items:
        if item.checked:
            continue
        qty = shopping_item_quantity(item)
        norm = normalize_ingredient_name(item.name)
        matches: list[dict[str, Any]] = []
        mapped = await _get_mapping(db, family_id, norm)
        seen_ids: set[str] = set()
        if mapped:
            fake = {
                "id": mapped.knuspr_product_id,
                "name": mapped.knuspr_product_name or item.name,
                "price": None,
                "unit": None,
                "available": True,
            }
            matches.append(_match_from_dict(fake))
            seen_ids.add(mapped.knuspr_product_id)
        found = await knuspr_client.search_products(item.name, limit=5)
        for p in found:
            pid = p["id"]
            if pid in seen_ids:
                continue
            matches.append(_match_from_dict(p))
            seen_ids.add(pid)
            if len(matches) >= 3:
                break
        lines.append(
            {
                "shopping_item_id": item.id,
                "item_name": item.name,
                "quantity": qty,
                "matches": matches,
            }
        )

    return {"shopping_list_id": sl.id, "lines": lines}


async def apply_selections_to_cart(
    shopping_list_id: int,
    family_id: int,
    selections: list[dict[str, Any]],
    db: AsyncSession,
) -> dict[str, Any]:
    stmt = select(ShoppingList).where(
        ShoppingList.id == shopping_list_id,
        ShoppingList.family_id == family_id,
    )
    r = await db.execute(stmt)
    if not r.scalar_one_or_none():
        return {"success": False, "error": "Einkaufsliste nicht gefunden"}

    added = []
    failed = []
    for sel in selections:
        name = sel.get("item_name") or ""
        pid = str(sel.get("product_id", ""))
        qty = int(sel.get("quantity") or 1)
        pname = str(sel.get("product_name") or name)
        if not pid:
            failed.append({"item": name, "reason": "Keine Produkt-ID"})
            continue
        try:
            await knuspr_client.add_to_cart(pid, quantity=qty)
            added.append({"item": name, "product": pname or pid})
            await _record_mapping(db, family_id, name, pid, pname)
        except Exception as e:
            failed.append({"item": name, "reason": str(e)})

    return {
        "success": True,
        "added": added,
        "failed": failed,
        "total_added": len(added),
        "total_failed": len(failed),
    }


async def send_list_to_cart(
    shopping_list_id: int, db: AsyncSession, family_id: int | None = None,
) -> dict[str, Any]:
    """Search each unchecked item on Knuspr and add best match to cart."""
    stmt = (
        select(ShoppingList)
        .options(selectinload(ShoppingList.items))
        .where(ShoppingList.id == shopping_list_id)
    )
    if family_id is not None:
        stmt = stmt.where(ShoppingList.family_id == family_id)
    result = await db.execute(stmt)
    sl = result.scalar_one_or_none()
    if not sl:
        return {"success": False, "error": "Einkaufsliste nicht gefunden"}

    fid = sl.family_id
    added = []
    failed = []

    for item in sl.items:
        if item.checked:
            continue
        qty = shopping_item_quantity(item)
        norm = normalize_ingredient_name(item.name)
        try:
            mapped = await _get_mapping(db, fid, norm)
            if mapped:
                await knuspr_client.add_to_cart(mapped.knuspr_product_id, quantity=qty)
                pname = mapped.knuspr_product_name or item.name
                added.append({"item": item.name, "product": pname})
                await _record_mapping(
                    db, fid, item.name, mapped.knuspr_product_id, pname,
                )
                continue
            products = await knuspr_client.search_products(item.name, limit=1)
            product = products[0] if products else None
            if product and product.get("available", True):
                await knuspr_client.add_to_cart(product["id"], quantity=qty)
                pname = str(product.get("name", ""))
                added.append({"item": item.name, "product": pname})
                await _record_mapping(db, fid, item.name, str(product["id"]), pname)
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
