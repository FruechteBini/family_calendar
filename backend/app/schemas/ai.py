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


# ── Todo Prioritization Schemas ──


class TodoPrioritization(BaseModel):
    todo_id: int
    suggested_priority: str  # low|medium|high
    suggested_category_id: int | None = None
    urgency_score: float  # 0.0 - 1.0
    reasoning: str = ""


class TodoPrioritizeResponse(BaseModel):
    items: list[TodoPrioritization]
    summary: str = ""


class ApplyTodoPrioritiesRequest(BaseModel):
    items: list[TodoPrioritization]


class ApplyTodoPrioritiesResponse(BaseModel):
    updated: int


# ── Recipe categorization (preview + apply) ──


class RecipeNewCategorySpec(BaseModel):
    name: str
    color: str = "#0052CC"


class RecipeNewTagSpec(BaseModel):
    name: str
    color: str = "#6B7280"


class RecipeCategorizationAssignment(BaseModel):
    recipe_id: int
    category_name: str
    suggested_category_id: int | None = None
    tag_names: list[str] = []


class RecipeCategorizationPreview(BaseModel):
    new_categories: list[RecipeNewCategorySpec] = []
    new_tags: list[RecipeNewTagSpec] = []
    assignments: list[RecipeCategorizationAssignment]
    summary: str = ""


class ApplyRecipeCategorizationRequest(BaseModel):
    new_categories: list[RecipeNewCategorySpec] = []
    new_tags: list[RecipeNewTagSpec] = []
    assignments: list[RecipeCategorizationAssignment]


class ApplyRecipeCategorizationResponse(BaseModel):
    updated: int
    categories_created: int
    tags_created: int


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
