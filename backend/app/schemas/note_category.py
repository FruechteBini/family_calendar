from pydantic import BaseModel


class NoteCategoryCreate(BaseModel):
    name: str
    color: str = "#0052CC"
    icon: str = "\U0001f4dd"
    is_personal: bool = True


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
    is_personal: bool

    model_config = {"from_attributes": True}
