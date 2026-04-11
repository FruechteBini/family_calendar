from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, field_validator


class NotificationType(str, Enum):
    event_reminder = "event_reminder"
    todo_reminder = "todo_reminder"
    note_reminder = "note_reminder"
    event_assigned = "event_assigned"
    todo_assigned = "todo_assigned"
    proposal_new = "proposal_new"
    proposal_response = "proposal_response"
    event_updated = "event_updated"
    event_deleted = "event_deleted"
    todo_completed = "todo_completed"
    shopping_list_changed = "shopping_list_changed"
    meal_plan_changed = "meal_plan_changed"
    note_comment = "note_comment"


class DeviceTokenUpsert(BaseModel):
    token: str
    platform: str = "unknown"


class DeviceTokenResponse(BaseModel):
    token: str
    platform: str
    updated_at: datetime

    model_config = {"from_attributes": True}


class NotificationLevelCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    position: int = 0
    reminders_minutes: list[int] = []
    is_default: bool = False

    @field_validator("reminders_minutes")
    @classmethod
    def _normalize_reminders(cls, v: list[int]) -> list[int]:
        out = sorted({int(m) for m in v if int(m) >= 0}, reverse=True)
        return out


class NotificationLevelUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    position: int | None = None
    reminders_minutes: list[int] | None = None
    is_default: bool | None = None

    @field_validator("reminders_minutes")
    @classmethod
    def _normalize_reminders(cls, v: list[int] | None) -> list[int] | None:
        if v is None:
            return None
        return sorted({int(m) for m in v if int(m) >= 0}, reverse=True)


class NotificationLevelResponse(BaseModel):
    id: int
    name: str
    position: int
    reminders_minutes: list[int]
    is_default: bool
    created_at: datetime
    updated_at: datetime


class NotificationLevelReorderItem(BaseModel):
    id: int
    position: int


class NotificationLevelReorderRequest(BaseModel):
    items: list[NotificationLevelReorderItem]


class NotificationPreferenceItem(BaseModel):
    notification_type: NotificationType
    enabled: bool


class NotificationPreferencesUpdate(BaseModel):
    items: list[NotificationPreferenceItem]


class NotificationPreferencesResponse(BaseModel):
    items: list[NotificationPreferenceItem]
