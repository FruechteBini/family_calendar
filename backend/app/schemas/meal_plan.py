from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel

from .recipe import RecipeResponse


class MealSlot(str, Enum):
    lunch = "lunch"
    dinner = "dinner"


class MealSlotUpdate(BaseModel):
    recipe_id: int
    servings_planned: int = 4


class MarkCookedRequest(BaseModel):
    servings_cooked: int | None = None
    rating: int | None = None
    notes: str | None = None


class MealSlotResponse(BaseModel):
    id: int
    plan_date: date
    slot: str
    recipe_id: int
    servings_planned: int
    recipe: RecipeResponse
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class DayPlan(BaseModel):
    date: date
    weekday: str
    lunch: MealSlotResponse | None = None
    dinner: MealSlotResponse | None = None


class WeekPlanResponse(BaseModel):
    week_start: date
    days: list[DayPlan]
