from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..database import get_db, utcnow
from ..models.cooking_history import CookingHistory
from ..models.meal_plan import MealPlan
from ..models.recipe import Recipe
from ..schemas.meal_plan import (
    DayPlan,
    MarkCookedRequest,
    MealSlotResponse,
    MealSlotUpdate,
    WeekPlanResponse,
)
from ..utils import monday_of

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


@router.patch("/plan/{plan_date}/{slot}/done", response_model=MealSlotResponse)
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
        raise HTTPException(status_code=404, detail="Kein Eintrag fuer diesen Slot")

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

    await db.flush()
    return meal
