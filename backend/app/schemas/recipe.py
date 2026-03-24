from datetime import datetime
from enum import Enum

from pydantic import BaseModel


class RecipeSource(str, Enum):
    cookidoo = "cookidoo"
    manual = "manual"


class Difficulty(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"


class IngredientCategory(str, Enum):
    kuehlregal = "kuehlregal"
    obst_gemuese = "obst_gemuese"
    trockenware = "trockenware"
    drogerie = "drogerie"
    sonstiges = "sonstiges"


class IngredientCreate(BaseModel):
    name: str
    amount: float | None = None
    unit: str | None = None
    category: IngredientCategory = IngredientCategory.sonstiges


class IngredientResponse(BaseModel):
    id: int
    name: str
    amount: float | None
    unit: str | None
    category: str

    model_config = {"from_attributes": True}


class RecipeCreate(BaseModel):
    title: str
    source: RecipeSource = RecipeSource.manual
    cookidoo_id: str | None = None
    servings: int = 4
    prep_time_active_minutes: int | None = None
    prep_time_passive_minutes: int | None = None
    difficulty: Difficulty = Difficulty.medium
    notes: str | None = None
    image_url: str | None = None
    ai_accessible: bool = True
    ingredients: list[IngredientCreate] = []


class RecipeUpdate(BaseModel):
    title: str | None = None
    servings: int | None = None
    prep_time_active_minutes: int | None = None
    prep_time_passive_minutes: int | None = None
    difficulty: Difficulty | None = None
    notes: str | None = None
    image_url: str | None = None
    ai_accessible: bool | None = None
    ingredients: list[IngredientCreate] | None = None


class RecipeResponse(BaseModel):
    id: int
    title: str
    source: str
    cookidoo_id: str | None
    servings: int
    prep_time_active_minutes: int | None
    prep_time_passive_minutes: int | None
    difficulty: str
    last_cooked_at: datetime | None
    cook_count: int
    notes: str | None
    image_url: str | None
    ai_accessible: bool
    ingredients: list[IngredientResponse]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CookingHistoryResponse(BaseModel):
    id: int
    recipe_id: int
    cooked_at: datetime
    servings_cooked: int
    rating: int | None
    notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class RecipeDetailResponse(RecipeResponse):
    history: list[CookingHistoryResponse] = []


class RecipeSuggestion(BaseModel):
    id: int
    title: str
    difficulty: str
    prep_time_active_minutes: int | None
    last_cooked_at: datetime | None
    cook_count: int
    days_since_cooked: int | None

    model_config = {"from_attributes": True}
