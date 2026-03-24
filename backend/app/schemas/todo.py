from __future__ import annotations

from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel

from .category import CategoryResponse
from .family_member import FamilyMemberResponse


class Priority(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class TodoCreate(BaseModel):
    title: str
    description: str | None = None
    priority: Priority = Priority.medium
    due_date: date | None = None
    category_id: int | None = None
    event_id: int | None = None
    parent_id: int | None = None
    requires_multiple: bool = False
    member_ids: list[int] = []


class TodoUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    priority: Priority | None = None
    due_date: date | None = None
    category_id: int | None = None
    event_id: int | None = None
    requires_multiple: bool | None = None
    member_ids: list[int] | None = None


class LinkEventRequest(BaseModel):
    event_id: int | None


class SubtodoResponse(BaseModel):
    id: int
    title: str
    completed: bool
    completed_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class TodoResponse(BaseModel):
    id: int
    title: str
    description: str | None
    priority: str
    due_date: date | None
    completed: bool
    completed_at: datetime | None
    category: CategoryResponse | None
    event_id: int | None
    parent_id: int | None
    requires_multiple: bool
    members: list[FamilyMemberResponse]
    subtodos: list[SubtodoResponse]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
