from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Self

from pydantic import BaseModel, Field, model_validator

from .recipe_category import RecipeCategoryResponse
from .recipe_tag import RecipeTagResponse


class RecipeSource(str, Enum):
    cookidoo = "cookidoo"
    manual = "manual"
    web = "web"


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
    instructions: str | None = None
    notes: str | None = None
    image_url: str | None = None
    ai_accessible: bool = True
    recipe_category_id: int | None = None
    tag_ids: list[int] = []
    ingredients: list[IngredientCreate] = []


class RecipeUpdate(BaseModel):
    title: str | None = None
    servings: int | None = None
    prep_time_active_minutes: int | None = None
    prep_time_passive_minutes: int | None = None
    difficulty: Difficulty | None = None
    instructions: str | None = None
    notes: str | None = None
    image_url: str | None = None
    ai_accessible: bool | None = None
    recipe_category_id: int | None = None
    tag_ids: list[int] | None = None
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
    instructions: str | None
    notes: str | None
    image_url: str | None
    cover_image_path: str | None = Field(default=None, exclude=True)
    ai_accessible: bool
    recipe_category_id: int | None
    category: RecipeCategoryResponse | None
    tags: list[RecipeTagResponse]
    ingredients: list[IngredientResponse]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @model_validator(mode="after")
    def _apply_cover_image_url(self) -> Self:
        if self.cover_image_path:
            return self.model_copy(update={"image_url": f"/api/recipes/{self.id}/cover"})
        return self


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
    image_url: str | None = None
    last_cooked_at: datetime | None
    cook_count: int
    days_since_cooked: int | None

    model_config = {"from_attributes": True}


class UrlImportRequest(BaseModel):
    url: str


class UrlImportPreview(BaseModel):
    title: str
    servings: int = 4
    prep_time_active_minutes: int | None = None
    prep_time_passive_minutes: int | None = None
    difficulty: str = "medium"
    instructions: str | None = None
    image_url: str | None = None
    source_url: str | None = None
    ingredients: list[IngredientCreate] = []
