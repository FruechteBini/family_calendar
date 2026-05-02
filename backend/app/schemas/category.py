from pydantic import BaseModel


class CategoryCreate(BaseModel):
    name: str
    color: str = "#0052CC"
    icon: str = "📁"
    is_personal: bool = False


class CategoryUpdate(BaseModel):
    name: str | None = None
    color: str | None = None
    icon: str | None = None
    position: int | None = None


class CategoryResponse(BaseModel):
    id: int
    position: int
    name: str
    color: str
    icon: str
    is_personal: bool

    model_config = {"from_attributes": True}
