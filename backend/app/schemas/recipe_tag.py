from pydantic import BaseModel


class RecipeTagCreate(BaseModel):
    name: str
    color: str = "#6B7280"


class RecipeTagUpdate(BaseModel):
    name: str | None = None
    color: str | None = None


class RecipeTagResponse(BaseModel):
    id: int
    name: str
    color: str

    model_config = {"from_attributes": True}
