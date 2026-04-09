from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from sqlalchemy.ext.asyncio import AsyncSession as _AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db, utcnow
from ..models.cooking_history import CookingHistory
from ..models.meal_plan import MealPlan
from ..models.pantry_item import PantryItem
from ..models.recipe import Recipe
from ..schemas.meal_plan import (
    CookingHistoryEntry,
    DayPlan,
    MarkCookedRequest,
    MarkCookedResponse,
    MealSlotResponse,
    MealSlotUpdate,
    PantryDeductionItem,
    WeekPlanResponse,
)
from ..utils import monday_of, normalize_ingredient_name

router = APIRouter(
    prefix="/api/meals",
    tags=["meals"],
    dependencies=[Depends(get_current_user)],
)

WEEKDAY_NAMES = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]


@router.get("/plan", response_model=WeekPlanResponse)
async def get_week_plan(
    week: date = Query(default=None),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if week is None:
        week = utcnow().date()
    monday = monday_of(week)
    sunday = monday + timedelta(days=6)

    stmt = (
        select(MealPlan)
        .options(selectinload(MealPlan.recipe).selectinload(Recipe.ingredients))
        .where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date >= monday,
            MealPlan.plan_date <= sunday,
        ))
        .order_by(MealPlan.plan_date, MealPlan.slot)
    )
    result = await db.execute(stmt)
    slots = result.scalars().unique().all()

    slot_map: dict[str, MealPlan] = {}
    for s in slots:
        slot_map[f"{s.plan_date}_{s.slot}"] = s

    days = []
    for i in range(7):
        d = monday + timedelta(days=i)
        lunch_key = f"{d}_lunch"
        dinner_key = f"{d}_dinner"
        days.append(DayPlan(
            date=d,
            weekday=WEEKDAY_NAMES[i],
            lunch=slot_map.get(lunch_key),
            dinner=slot_map.get(dinner_key),
        ))

    return WeekPlanResponse(week_start=monday, days=days)


@router.get("/history", response_model=list[CookingHistoryEntry])
async def get_cooking_history(
    limit: int = Query(default=10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(CookingHistory)
        .join(Recipe)
        .where(Recipe.family_id == family_id)
        .options(selectinload(CookingHistory.recipe))
        .order_by(CookingHistory.cooked_at.desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    entries = result.scalars().unique().all()
    return [
        CookingHistoryEntry(
            id=e.id,
            recipe_id=e.recipe_id,
            recipe_title=e.recipe.title,
            recipe_difficulty=e.recipe.difficulty,
            recipe_image_url=e.recipe.image_url,
            cooked_at=e.cooked_at,
            servings_cooked=e.servings_cooked,
            rating=e.rating,
        )
        for e in entries
    ]


@router.put("/plan/{plan_date}/{slot}", response_model=MealSlotResponse)
async def set_meal_slot(
    plan_date: date,
    slot: str,
    data: MealSlotUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if slot not in ("lunch", "dinner"):
        raise HTTPException(status_code=400, detail="Slot muss 'lunch' oder 'dinner' sein")

    recipe = await db.get(Recipe, data.recipe_id)
    if not recipe or recipe.family_id != family_id:
        raise HTTPException(status_code=404, detail="Rezept nicht gefunden")

    stmt = select(MealPlan).where(and_(
        MealPlan.family_id == family_id,
        MealPlan.plan_date == plan_date,
        MealPlan.slot == slot,
    ))
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()

    if existing:
        existing.recipe_id = data.recipe_id
        existing.servings_planned = data.servings_planned
        meal_id = existing.id
    else:
        meal = MealPlan(
            family_id=family_id,
            plan_date=plan_date,
            slot=slot,
            recipe_id=data.recipe_id,
            servings_planned=data.servings_planned,
        )
        db.add(meal)
        await db.flush()
        meal_id = meal.id

    load_stmt = (
        select(MealPlan)
        .options(selectinload(MealPlan.recipe).selectinload(Recipe.ingredients))
        .where(MealPlan.id == meal_id)
    )
    load_result = await db.execute(load_stmt)
    return load_result.scalar_one()


@router.delete("/plan/{plan_date}/{slot}", status_code=status.HTTP_204_NO_CONTENT)
async def clear_meal_slot(
    plan_date: date,
    slot: str,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if slot not in ("lunch", "dinner"):
        raise HTTPException(status_code=400, detail="Slot muss 'lunch' oder 'dinner' sein")
    stmt = select(MealPlan).where(and_(
        MealPlan.family_id == family_id,
        MealPlan.plan_date == plan_date,
        MealPlan.slot == slot,
    ))
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()
    if existing:
        await db.delete(existing)


async def _deduct_from_pantry(
    db: _AsyncSession, family_id: int, ingredients, ratio: float,
) -> list[PantryDeductionItem]:
    """Deduct recipe ingredient amounts from pantry. Returns deduction report."""
    pantry_stmt = select(PantryItem).where(PantryItem.family_id == family_id)
    pantry_result = await db.execute(pantry_stmt)
    pantry_items = pantry_result.scalars().all()

    pantry_lookup: dict[str, PantryItem] = {}
    pantry_by_name: dict[str, PantryItem] = {}
    for pi in pantry_items:
        key = f"{pi.name_normalized}_{pi.unit or ''}"
        pantry_lookup[key] = pi
        pantry_by_name[pi.name_normalized] = pi

    deductions: list[PantryDeductionItem] = []
    for ing in ingredients:
        norm_name = normalize_ingredient_name(ing.name)
        norm_key = f"{norm_name}_{ing.unit or ''}"
        match = pantry_lookup.get(norm_key) or pantry_by_name.get(norm_name)
        if not match or match.amount is None:
            continue

        scaled = (ing.amount * ratio) if ing.amount else 0
        if scaled <= 0:
            continue

        old_amount = match.amount
        new_amount = max(0, round(old_amount - scaled, 2))
        match.amount = new_amount

        deductions.append(PantryDeductionItem(
            name=match.name,
            old_amount=old_amount,
            new_amount=new_amount,
            depleted=new_amount <= 0,
        ))

    return deductions


@router.patch("/plan/{plan_date}/{slot}/done", response_model=MarkCookedResponse)
async def mark_as_cooked(
    plan_date: date,
    slot: str,
    body: MarkCookedRequest | None = None,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if slot not in ("lunch", "dinner"):
        raise HTTPException(status_code=400, detail="Slot muss 'lunch' oder 'dinner' sein")

    stmt = (
        select(MealPlan)
        .options(selectinload(MealPlan.recipe).selectinload(Recipe.ingredients))
        .where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date == plan_date,
            MealPlan.slot == slot,
        ))
    )
    result = await db.execute(stmt)
    meal = result.scalar_one_or_none()
    if not meal:
        raise HTTPException(status_code=404, detail="Kein Eintrag für diesen Slot")

    now = utcnow()
    servings = body.servings_cooked if body and body.servings_cooked else meal.servings_planned
    rating = body.rating if body else None
    notes = body.notes if body else None

    history_entry = CookingHistory(
        recipe_id=meal.recipe_id,
        cooked_at=now,
        servings_cooked=servings,
        rating=rating,
        notes=notes,
    )
    db.add(history_entry)

    recipe = await db.get(Recipe, meal.recipe_id)
    if recipe:
        recipe.last_cooked_at = now
        recipe.cook_count = (recipe.cook_count or 0) + 1

    # Deduct from pantry
    pantry_deductions: list[PantryDeductionItem] = []
    if meal.recipe and meal.recipe.ingredients:
        ratio = servings / meal.recipe.servings if meal.recipe.servings else 1
        pantry_deductions = await _deduct_from_pantry(db, family_id, meal.recipe.ingredients, ratio)

    await db.flush()

    return MarkCookedResponse(
        id=meal.id,
        plan_date=meal.plan_date,
        slot=meal.slot,
        recipe_id=meal.recipe_id,
        servings_planned=meal.servings_planned,
        recipe=meal.recipe,
        created_at=meal.created_at,
        updated_at=meal.updated_at,
        pantry_deductions=pantry_deductions,
    )
