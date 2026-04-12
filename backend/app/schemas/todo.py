from __future__ import annotations

from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, Field, computed_field, field_validator

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
    notification_level_id: int | None = None

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
    notification_level_id: int | None = None


class LinkEventRequest(BaseModel):
    event_id: int | None


class TodoAttachmentResponse(BaseModel):
    id: int
    todo_id: int
    filename: str
    content_type: str
    file_size: int
    created_at: datetime

    model_config = {"from_attributes": True}

    @computed_field  # type: ignore[prop-decorator]
    @property
    def download_url(self) -> str:
        return f"/api/todos/{self.todo_id}/attachments/{self.id}/download"


class SubtodoResponse(BaseModel):
    id: int
    parent_id: int | None = None
    is_personal: bool = False
    created_by_member_id: int | None = None
    title: str
    description: str | None = None
    priority: str = "low"
    due_date: date | None = None
    completed: bool
    completed_at: datetime | None
    created_at: datetime
    sort_order: int = 0
    members: list[FamilyMemberResponse] = Field(default_factory=list)
    attachments: list[TodoAttachmentResponse] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class ReorderSubtodosRequest(BaseModel):
    subtodo_ids: list[int]


class TodoLinkedEventResponse(BaseModel):
    """Minimal event payload for todos linked to a calendar entry."""

    id: int
    title: str
    start: datetime
    end: datetime
    all_day: bool

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
    event: TodoLinkedEventResponse | None = None
    parent_id: int | None
    requires_multiple: bool
    notification_level_id: int | None = None
    members: list[FamilyMemberResponse]
    subtodos: list[SubtodoResponse]
    attachments: list[TodoAttachmentResponse] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime
    # Set only on PATCH /complete when a sub-todo completion auto-completed the parent
    parent_auto_completed: bool = False

    model_config = {"from_attributes": True}
