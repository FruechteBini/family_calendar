import json
import logging
from datetime import date, timedelta

import anthropic
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..config import settings
from ..database import get_db, utcnow
from ..models.meal_plan import MealPlan
from ..models.pantry_item import PantryItem
from ..models.recipe import Recipe
from ..models.shopping_list import ShoppingItem, ShoppingList
from ..schemas.shopping import (
    GenerateRequest,
    ShoppingItemCreate,
    ShoppingItemResponse,
    ShoppingListResponse,
)
from ..utils import normalize_ingredient_name

logger = logging.getLogger("kalender.shopping")

router = APIRouter(
    prefix="/api/shopping",
    tags=["shopping"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/list", response_model=ShoppingListResponse | None)
async def get_active_list(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(ShoppingList)
        .options(selectinload(ShoppingList.items))
        .where(ShoppingList.status == "active", ShoppingList.family_id == family_id)
        .order_by(ShoppingList.created_at.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    sl = result.scalar_one_or_none()
    return sl


async def _generate_shopping_list(monday: date, family_id: int, db: AsyncSession) -> ShoppingList:
    """Core logic to generate a shopping list from the week plan. Reused by AI router."""
    sunday = monday + timedelta(days=6)

    stmt = (
        select(MealPlan)
        .options(selectinload(MealPlan.recipe).selectinload(Recipe.ingredients))
        .where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date >= monday,
            MealPlan.plan_date <= sunday,
        ))
    )
    result = await db.execute(stmt)
    meals = result.scalars().unique().all()

    if not meals:
        raise HTTPException(status_code=400, detail="Keine Mahlzeiten im Wochenplan für diese Woche")

    old_stmt = select(ShoppingList).where(
        ShoppingList.status == "active", ShoppingList.family_id == family_id
    )
    old_result = await db.execute(old_stmt)
    for old in old_result.scalars().all():
        old.status = "archived"

    consolidated: dict[str, dict] = {}
    for meal in meals:
        ratio = meal.servings_planned / meal.recipe.servings if meal.recipe.servings else 1
        for ing in meal.recipe.ingredients:
            key = f"{ing.name.lower().strip()}_{ing.unit or ''}"
            scaled_amount = round(ing.amount * ratio, 2) if ing.amount else None
            if key in consolidated:
                if scaled_amount is not None and consolidated[key]["amount"] is not None:
                    consolidated[key]["amount"] = round(
                        consolidated[key]["amount"] + scaled_amount, 2
                    )
                elif scaled_amount is not None:
                    consolidated[key]["amount"] = scaled_amount
            else:
                consolidated[key] = {
                    "name": ing.name,
                    "amount": scaled_amount,
                    "unit": ing.unit,
                    "category": ing.category,
                    "recipe_id": meal.recipe_id,
                }

    # Deduct pantry quantities
    pantry_stmt = select(PantryItem).where(PantryItem.family_id == family_id)
    pantry_result = await db.execute(pantry_stmt)
    pantry_items = pantry_result.scalars().all()
    # Two lookups: exact (name+unit) and name-only (fallback for unit mismatch)
    pantry_lookup: dict[str, PantryItem] = {}
    pantry_by_name: dict[str, PantryItem] = {}
    for pi in pantry_items:
        key = f"{pi.name_normalized}_{pi.unit or ''}"
        pantry_lookup[key] = pi
        pantry_by_name[pi.name_normalized] = pi

    items_to_add: list[dict] = []
    for item_data in consolidated.values():
        norm_name = normalize_ingredient_name(item_data["name"])
        norm_key = f"{norm_name}_{item_data['unit'] or ''}"
        # Try exact match (name+unit) first, then fall back to name-only
        pantry_match = pantry_lookup.get(norm_key) or pantry_by_name.get(norm_name)

        if pantry_match:
            if pantry_match.amount is None:
                # Unknown quantity in pantry — assume sufficient, skip
                continue
            if item_data["amount"] is not None:
                # Only deduct if units match; otherwise skip (assume available)
                if pantry_match.unit and item_data["unit"] and pantry_match.unit != item_data["unit"]:
                    continue
                remaining = item_data["amount"] - pantry_match.amount
                if remaining <= 0:
                    continue  # Pantry covers entirely
                item_data["amount"] = round(remaining, 2)
            else:
                # Recipe has no amount but pantry has it — skip
                continue

        items_to_add.append(item_data)

    shopping_list = ShoppingList(family_id=family_id, week_start_date=monday, status="active")
    for item_data in items_to_add:
        shopping_list.items.append(ShoppingItem(
            name=item_data["name"],
            amount=str(item_data["amount"]) if item_data["amount"] is not None else None,
            unit=item_data["unit"],
            category=item_data["category"],
            source="recipe",
            recipe_id=item_data["recipe_id"],
        ))
    db.add(shopping_list)
    await db.flush()
    await db.refresh(shopping_list)
    return shopping_list


@router.post("/generate", response_model=ShoppingListResponse, status_code=status.HTTP_201_CREATED)
async def generate_from_plan(
    data: GenerateRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    return await _generate_shopping_list(data.week_start, family_id, db)


@router.post("/items", response_model=ShoppingItemResponse, status_code=status.HTTP_201_CREATED)
async def add_manual_item(
    data: ShoppingItemCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(ShoppingList)
        .where(ShoppingList.status == "active", ShoppingList.family_id == family_id)
        .order_by(ShoppingList.created_at.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    sl = result.scalar_one_or_none()
    if not sl:
        sl = ShoppingList(family_id=family_id, week_start_date=utcnow().date(), status="active")
        db.add(sl)
        await db.flush()

    item = ShoppingItem(
        shopping_list_id=sl.id,
        name=data.name,
        amount=data.amount,
        unit=data.unit,
        category=data.category.value,
        source="manual",
    )
    db.add(item)
    await db.flush()
    await db.refresh(item)
    return item


@router.post("/clear-all")
async def clear_shopping_list(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = select(ShoppingList).where(
        ShoppingList.status == "active", ShoppingList.family_id == family_id
    )
    result = await db.execute(stmt)
    for sl in result.scalars().all():
        sl.status = "archived"
    return {"message": "Einkaufsliste geleert"}


@router.patch("/items/{item_id}/check", response_model=ShoppingItemResponse)
async def check_item(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(ShoppingItem)
        .join(ShoppingList)
        .where(ShoppingItem.id == item_id, ShoppingList.family_id == family_id)
    )
    result = await db.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Artikel nicht gefunden")
    item.checked = not item.checked
    await db.flush()
    await db.refresh(item)
    return item


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(ShoppingItem)
        .join(ShoppingList)
        .where(ShoppingItem.id == item_id, ShoppingList.family_id == family_id)
    )
    result = await db.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Artikel nicht gefunden")
    await db.delete(item)


def _build_sort_prompt(items: list[ShoppingItem]) -> str:
    items_text = "\n".join(f"- id={it.id}, name=\"{it.name}\"" for it in items)

    return f"""Du bist ein Experte für deutsche Supermarkt-Layouts. Sortiere die folgende Einkaufsliste so, dass Artikel die typischerweise in der gleichen Abteilung eines Supermarkts stehen zusammen gruppiert sind. Ordne sie in der Reihenfolge an, wie man sie bei einem typischen Rundgang durch einen deutschen Supermarkt antrifft (vom Eingang bis zur Kasse).

## Typischer Supermarkt-Rundgang
Obst & Gemüse → Backwaren → Fleisch & Wurst → Käse → Kühlregal/Molkereiprodukte → Tiefkühl → Konserven & Trockenware → Gewürze & Backen → Getränke → Süßigkeiten & Snacks → Drogerie & Haushalt → Kasse

## Einkaufsliste
{items_text}

## Regeln
- Ordne JEDEN Artikel einer Abteilung (section) zu und vergib eine aufsteigende sort_order (1, 2, 3, ...)
- Die sort_order soll der Reihenfolge entsprechen, in der man die Artikel im Laden antrifft
- Artikel der gleichen Abteilung sollen hintereinander stehen
- Verwende kurze, prägnante deutsche Abteilungsnamen (z.B. "Obst & Gemüse", "Kühlregal", "Tiefkühl", "Backwaren", "Trockenware", "Getränke", "Drogerie", "Süßigkeiten")
- Antworte AUSSCHLIESSLICH mit einem JSON-Array, kein Markdown, keine Erklärung

## Antwort-Format
[{{"id": 1, "section": "Obst & Gemüse", "sort_order": 1}}, ...]
"""


@router.post("/sort", response_model=ShoppingListResponse)
async def sort_shopping_list(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):

    stmt = (
        select(ShoppingList)
        .options(selectinload(ShoppingList.items))
        .where(ShoppingList.status == "active", ShoppingList.family_id == family_id)
        .order_by(ShoppingList.created_at.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    sl = result.scalar_one_or_none()
    if not sl or not sl.items:
        raise HTTPException(status_code=404, detail="Keine aktive Einkaufsliste vorhanden")

    unchecked = [it for it in sl.items if not it.checked]
    checked = [it for it in sl.items if it.checked]

    if not unchecked:
        raise HTTPException(status_code=400, detail="Alle Artikel bereits abgehakt")

    prompt = _build_sort_prompt(unchecked)

    try:
        client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        response = await client.messages.create(
            model=settings.ANTHROPIC_MODEL,
            max_tokens=1500,
            messages=[{"role": "user", "content": prompt}],
        )
    except anthropic.AuthenticationError:
        raise HTTPException(status_code=503, detail="Ungültiger ANTHROPIC_API_KEY")
    except anthropic.APIError as e:
        logger.error("Claude API error during shopping sort: %s", e)
        raise HTTPException(status_code=502, detail=f"Claude API Fehler: {e}")

    raw_text = response.content[0].text.strip()
    if raw_text.startswith("```"):
        lines = raw_text.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        raw_text = "\n".join(lines).strip()

    try:
        sort_data = json.loads(raw_text)
    except json.JSONDecodeError:
        logger.error("Claude returned invalid JSON for sort: %s", raw_text[:500])
        raise HTTPException(
            status_code=502,
            detail="KI hat ungültiges Format zurückgegeben. Bitte erneut versuchen.",
        )

    if not isinstance(sort_data, list):
        raise HTTPException(status_code=502, detail="KI hat ungültiges Format zurückgegeben.")

    item_lookup = {it.id: it for it in unchecked}
    for entry in sort_data:
        item_id = entry.get("id")
        if item_id in item_lookup:
            item_lookup[item_id].sort_order = entry.get("sort_order", 999)
            item_lookup[item_id].store_section = entry.get("section", "Sonstiges")

    max_order = max((e.get("sort_order", 0) for e in sort_data), default=0)
    for i, it in enumerate(checked):
        it.sort_order = max_order + 1 + i
        it.store_section = "Erledigt"

    sl.sorted_by_store = "sorted"
    await db.flush()

    await db.refresh(sl)
    stmt2 = (
        select(ShoppingList)
        .options(selectinload(ShoppingList.items))
        .where(ShoppingList.id == sl.id)
    )
    result2 = await db.execute(stmt2)
    return result2.scalar_one()
