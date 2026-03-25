import logging
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db, utcnow
from ..models.pantry_item import PantryItem
from ..models.shopping_list import ShoppingItem, ShoppingList
from ..schemas.pantry import (
    PantryAlertItem,
    PantryBulkAddRequest,
    PantryItemCreate,
    PantryItemResponse,
    PantryItemUpdate,
)
from ..utils import normalize_ingredient_name

logger = logging.getLogger("kalender.pantry")

router = APIRouter(
    prefix="/api/pantry",
    tags=["pantry"],
    dependencies=[Depends(get_current_user)],
)

LOW_STOCK_DEFAULT = 2
EXPIRY_WARN_DAYS = 7


def _to_response(item: PantryItem) -> dict:
    """Convert PantryItem to response dict with computed alert fields."""
    today = utcnow().date()
    is_low = False
    if item.amount is not None:
        threshold = item.min_stock if item.min_stock is not None else LOW_STOCK_DEFAULT
        is_low = item.amount <= threshold

    is_expiring = False
    if item.expiry_date is not None:
        is_expiring = item.expiry_date <= today + timedelta(days=EXPIRY_WARN_DAYS)

    return PantryItemResponse(
        id=item.id,
        name=item.name,
        amount=item.amount,
        unit=item.unit,
        category=item.category,
        expiry_date=item.expiry_date,
        min_stock=item.min_stock,
        is_low_stock=is_low,
        is_expiring_soon=is_expiring,
        created_at=item.created_at,
        updated_at=item.updated_at,
    )


@router.get("/", response_model=list[PantryItemResponse])
async def list_pantry(
    category: str | None = Query(default=None),
    search: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = select(PantryItem).where(PantryItem.family_id == family_id)
    if category:
        stmt = stmt.where(PantryItem.category == category)
    if search:
        stmt = stmt.where(PantryItem.name.ilike(f"%{search}%"))
    stmt = stmt.order_by(PantryItem.category, PantryItem.name)
    result = await db.execute(stmt)
    items = result.scalars().all()
    return [_to_response(i) for i in items]


async def _find_existing(
    db: AsyncSession, family_id: int, name: str, unit: str | None,
) -> PantryItem | None:
    norm = normalize_ingredient_name(name)
    stmt = select(PantryItem).where(
        PantryItem.family_id == family_id,
        PantryItem.name_normalized == norm,
    )
    if unit:
        stmt = stmt.where(PantryItem.unit == unit)
    else:
        stmt = stmt.where(PantryItem.unit.is_(None))
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def _add_or_merge(
    db: AsyncSession, family_id: int, data: PantryItemCreate,
) -> PantryItem:
    existing = await _find_existing(db, family_id, data.name, data.unit)
    if existing:
        if data.amount is not None and existing.amount is not None:
            existing.amount = round(existing.amount + data.amount, 2)
        elif data.amount is not None:
            existing.amount = data.amount
        if data.expiry_date is not None:
            existing.expiry_date = data.expiry_date
        if data.min_stock is not None:
            existing.min_stock = data.min_stock
        await db.flush()
        await db.refresh(existing)
        return existing

    item = PantryItem(
        family_id=family_id,
        name=data.name,
        name_normalized=normalize_ingredient_name(data.name),
        amount=data.amount,
        unit=data.unit,
        category=data.category.value if hasattr(data.category, "value") else data.category,
        expiry_date=data.expiry_date,
        min_stock=data.min_stock,
    )
    db.add(item)
    await db.flush()
    await db.refresh(item)
    return item


@router.post("/", response_model=PantryItemResponse, status_code=status.HTTP_201_CREATED)
async def add_pantry_item(
    data: PantryItemCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    item = await _add_or_merge(db, family_id, data)
    return _to_response(item)


@router.post("/bulk", response_model=list[PantryItemResponse], status_code=status.HTTP_201_CREATED)
async def bulk_add_pantry_items(
    data: PantryBulkAddRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    results = []
    for item_data in data.items:
        item = await _add_or_merge(db, family_id, item_data)
        results.append(_to_response(item))
    return results


@router.patch("/{item_id}", response_model=PantryItemResponse)
async def update_pantry_item(
    item_id: int,
    data: PantryItemUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    item = await db.get(PantryItem, item_id)
    if not item or item.family_id != family_id:
        raise HTTPException(status_code=404, detail="Artikel nicht gefunden")

    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "category" and hasattr(value, "value"):
            value = value.value
        setattr(item, field, value)
    if "name" in update_data:
        item.name_normalized = normalize_ingredient_name(item.name)

    await db.flush()
    await db.refresh(item)
    return _to_response(item)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pantry_item(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    item = await db.get(PantryItem, item_id)
    if not item or item.family_id != family_id:
        raise HTTPException(status_code=404, detail="Artikel nicht gefunden")
    await db.delete(item)


@router.get("/alerts", response_model=list[PantryAlertItem])
async def get_alerts(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    today = utcnow().date()
    stmt = select(PantryItem).where(PantryItem.family_id == family_id)
    result = await db.execute(stmt)
    items = result.scalars().all()

    alerts: list[PantryAlertItem] = []
    for item in items:
        if item.amount is not None:
            threshold = item.min_stock if item.min_stock is not None else LOW_STOCK_DEFAULT
            if item.amount <= threshold:
                alerts.append(PantryAlertItem(
                    id=item.id, name=item.name, amount=item.amount,
                    unit=item.unit, reason="low_stock", expiry_date=item.expiry_date,
                ))
                continue
        if item.expiry_date is not None and item.expiry_date <= today + timedelta(days=EXPIRY_WARN_DAYS):
            alerts.append(PantryAlertItem(
                id=item.id, name=item.name, amount=item.amount,
                unit=item.unit, reason="expiring_soon", expiry_date=item.expiry_date,
            ))
    return alerts


@router.post("/alerts/{item_id}/add-to-shopping")
async def add_alert_to_shopping(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    item = await db.get(PantryItem, item_id)
    if not item or item.family_id != family_id:
        raise HTTPException(status_code=404, detail="Artikel nicht gefunden")

    sl_stmt = (
        select(ShoppingList)
        .where(ShoppingList.status == "active", ShoppingList.family_id == family_id)
        .order_by(ShoppingList.created_at.desc())
        .limit(1)
    )
    result = await db.execute(sl_stmt)
    sl = result.scalar_one_or_none()
    if not sl:
        sl = ShoppingList(family_id=family_id, week_start_date=utcnow().date(), status="active")
        db.add(sl)
        await db.flush()

    shopping_item = ShoppingItem(
        shopping_list_id=sl.id,
        name=item.name,
        amount=str(item.amount) if item.amount is not None else None,
        unit=item.unit,
        category=item.category,
        source="manual",
    )
    db.add(shopping_item)

    # Clear alert conditions so warning disappears
    item.amount = None
    item.expiry_date = None
    await db.flush()
    return {"message": f"{item.name} zur Einkaufsliste hinzugefuegt"}


@router.post("/alerts/{item_id}/dismiss")
async def dismiss_alert(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    item = await db.get(PantryItem, item_id)
    if not item or item.family_id != family_id:
        raise HTTPException(status_code=404, detail="Artikel nicht gefunden")
    item.amount = None
    item.expiry_date = None
    await db.flush()
    return {"message": f"Warnung fuer {item.name} verworfen"}
