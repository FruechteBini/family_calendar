from datetime import datetime

from pydantic import BaseModel

from .category import CategoryResponse
from .family_member import FamilyMemberResponse


class EventCreate(BaseModel):
    title: str
    description: str | None = None
    start: datetime
    end: datetime
    all_day: bool = False
    category_id: int | None = None
    member_ids: list[int] = []


class EventUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    start: datetime | None = None
    end: datetime | None = None
    all_day: bool | None = None
    category_id: int | None = None
    member_ids: list[int] | None = None


class EventTodoResponse(BaseModel):
    id: int
    title: str
    completed: bool
    priority: str

    model_config = {"from_attributes": True}


class EventResponse(BaseModel):
    id: int
    title: str
    description: str | None
    start: datetime
    end: datetime
    all_day: bool
    category: CategoryResponse | None
    members: list[FamilyMemberResponse]
    todos: list[EventTodoResponse] = []
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
