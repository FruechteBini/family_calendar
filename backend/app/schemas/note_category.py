from pydantic import BaseModel


class NoteCategoryCreate(BaseModel):
    name: str
    color: str = "#0052CC"
    icon: str = "📝"


class NoteCategoryUpdate(BaseModel):
    name: str | None = None
    color: str | None = None
    icon: str | None = None
    position: int | None = None


class NoteCategoryResponse(BaseModel):
    id: int
    position: int
    name: str
    color: str
    icon: str

    model_config = {"from_attributes": True}
