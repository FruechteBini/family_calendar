from pydantic import BaseModel


class NoteTagCreate(BaseModel):
    name: str
    color: str = "#6B7280"


class NoteTagUpdate(BaseModel):
    name: str | None = None
    color: str | None = None


class NoteTagResponse(BaseModel):
    id: int
    name: str
    color: str

    model_config = {"from_attributes": True}
