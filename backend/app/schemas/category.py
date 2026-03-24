from pydantic import BaseModel


class CategoryCreate(BaseModel):
    name: str
    color: str = "#0052CC"
    icon: str = "📁"


class CategoryUpdate(BaseModel):
    name: str | None = None
    color: str | None = None
    icon: str | None = None


class CategoryResponse(BaseModel):
    id: int
    name: str
    color: str
    icon: str

    model_config = {"from_attributes": True}
