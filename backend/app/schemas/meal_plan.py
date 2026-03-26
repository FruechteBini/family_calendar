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


class PantryDeductionItem(BaseModel):
    name: str
    old_amount: float
    new_amount: float
    depleted: bool


class MarkCookedResponse(BaseModel):
    id: int
    plan_date: date
    slot: str
    recipe_id: int
    servings_planned: int
    recipe: RecipeResponse
    created_at: datetime
    updated_at: datetime
    pantry_deductions: list[PantryDeductionItem] = []

    model_config = {"from_attributes": True}


class WeekPlanResponse(BaseModel):
    week_start: date
    days: list[DayPlan]


class CookingHistoryEntry(BaseModel):
    id: int
    recipe_id: int
    recipe_title: str
    recipe_difficulty: str | None = None
    recipe_image_url: str | None = None
    cooked_at: datetime
    servings_cooked: int
    rating: int | None = None

    model_config = {"from_attributes": True}
