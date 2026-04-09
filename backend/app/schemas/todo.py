from __future__ import annotations

from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel
from pydantic import field_validator

from .category import CategoryResponse
from .family_member import FamilyMemberResponse


class Priority(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class TodoCreate(BaseModel):
    title: str
    description: str | None = None
    # If omitted, default to low (user requested). Also accept null/empty from clients.
    priority: Priority = Priority.low
    due_date: date | None = None
    category_id: int | None = None
    event_id: int | None = None
    parent_id: int | None = None
    requires_multiple: bool = False
    is_personal: bool = False
    member_ids: list[int] = []

    @field_validator("priority", mode="before")
    @classmethod
    def _normalize_priority(cls, v):
        if v is None:
            return Priority.low
        if isinstance(v, str):
            s = v.strip().lower()
            if s in ("", "none", "null"):
                return Priority.low
            return s
        return v


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
    is_personal: bool
    created_by_member_id: int | None
    created_by: FamilyMemberResponse | None
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
