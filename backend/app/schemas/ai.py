from datetime import date

from pydantic import BaseModel


class SlotSelection(BaseModel):
    date: str
    slot: str


class GenerateMealPlanRequest(BaseModel):
    week_start: date
    servings: int = 4
    preferences: str = ""
    selected_slots: list[SlotSelection] = []
    include_cookidoo: bool = False


class MealSuggestion(BaseModel):
    date: str
    slot: str
    recipe_id: int | None = None
    cookidoo_id: str | None = None
    recipe_title: str
    servings_planned: int
    source: str
    difficulty: str | None = None
    prep_time: int | None = None


class PreviewMealPlanResponse(BaseModel):
    suggestions: list[MealSuggestion]
    reasoning: str | None = None


class ConfirmMealPlanRequest(BaseModel):
    week_start: date
    items: list[MealSuggestion]


class ConfirmMealPlanResponse(BaseModel):
    message: str
    meals_created: int
    meal_ids: list[int]
    shopping_list_generated: bool


class UndoMealPlanRequest(BaseModel):
    meal_ids: list[int]


# ── Voice Command Schemas ──


class VoiceCommandRequest(BaseModel):
    text: str


class VoiceCommandAction(BaseModel):
    type: str
    ref: str | None = None
    params: dict
    result: dict | None = None


class VoiceCommandResponse(BaseModel):
    summary: str
    actions: list[VoiceCommandAction]
