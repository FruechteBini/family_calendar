from datetime import date, datetime

from pydantic import BaseModel

from .recipe import IngredientCategory


class ShoppingItemCreate(BaseModel):
    name: str
    amount: str | None = None
    unit: str | None = None
    category: IngredientCategory = IngredientCategory.sonstiges


class ShoppingItemResponse(BaseModel):
    id: int
    shopping_list_id: int
    name: str
    amount: str | None
    unit: str | None
    category: str
    checked: bool
    source: str
    recipe_id: int | None
    ai_accessible: bool
    sort_order: int | None = None
    store_section: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ShoppingListResponse(BaseModel):
    id: int
    week_start_date: date
    status: str
    sorted_by_store: str | None = None
    items: list[ShoppingItemResponse]
    created_at: datetime

    model_config = {"from_attributes": True}


class GenerateRequest(BaseModel):
    week_start: date


