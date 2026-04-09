from pydantic import BaseModel


class RecipeCategoryCreate(BaseModel):
    name: str
    color: str = "#0052CC"
    icon: str = "🍽"


class RecipeCategoryUpdate(BaseModel):
    name: str | None = None
    color: str | None = None
    icon: str | None = None
    position: int | None = None


class RecipeCategoryResponse(BaseModel):
    id: int
    position: int
    name: str
    color: str
    icon: str

    model_config = {"from_attributes": True}
