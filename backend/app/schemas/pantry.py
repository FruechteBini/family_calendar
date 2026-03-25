from datetime import date, datetime

from pydantic import BaseModel

from .recipe import IngredientCategory


class PantryItemCreate(BaseModel):
    name: str
    amount: float | None = None
    unit: str | None = None
    category: IngredientCategory = IngredientCategory.sonstiges
    expiry_date: date | None = None
    min_stock: float | None = None


class PantryItemUpdate(BaseModel):
    name: str | None = None
    amount: float | None = None
    unit: str | None = None
    category: IngredientCategory | None = None
    expiry_date: date | None = None
    min_stock: float | None = None


class PantryItemResponse(BaseModel):
    id: int
    name: str
    amount: float | None
    unit: str | None
    category: str
    expiry_date: date | None
    min_stock: float | None
    is_low_stock: bool = False
    is_expiring_soon: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class PantryBulkAddRequest(BaseModel):
    items: list[PantryItemCreate]


class PantryAlertItem(BaseModel):
    id: int
    name: str
    amount: float | None
    unit: str | None
    reason: str
    expiry_date: date | None


class PantryDeduction(BaseModel):
    name: str
    old_amount: float
    new_amount: float
    depleted: bool
