import json
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator

from .category import CategoryResponse
from .family_member import FamilyMemberResponse


def _parse_recurrence_rules_from_db(raw: str | list | None) -> list[dict[str, Any]]:
    if raw is None:
        return []
    if isinstance(raw, list):
        return [x for x in raw if isinstance(x, dict)]
    if not str(raw).strip():
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []

RecurrenceFrequency = Literal["daily", "weekly", "monthly", "yearly"]


class RecurrenceRule(BaseModel):
    """One recurrence rule; multiple rules may be combined (OR)."""

    frequency: RecurrenceFrequency
    interval: int = Field(default=1, ge=1, description="Every N days/weeks/months/years")
    by_weekday: list[int] | None = Field(
        default=None,
        description="ISO weekdays 1=Mo … 7=Su; for weekly; omit = weekday of start date",
    )
    until: datetime | None = Field(default=None, description="Last allowed start (inclusive day)")
    count: int | None = Field(default=None, ge=1, description="Max number of occurrences")


class EventCreate(BaseModel):
    title: str
    description: str | None = None
    start: datetime
    end: datetime
    all_day: bool = False
    category_id: int | None = None
    member_ids: list[int] = []
    notification_level_id: int | None = None
    recurrence_rules: list[RecurrenceRule] | None = None


class EventUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    start: datetime | None = None
    end: datetime | None = None
    all_day: bool | None = None
    category_id: int | None = None
    member_ids: list[int] | None = None
    notification_level_id: int | None = None
    recurrence_rules: list[RecurrenceRule] | None = None
    recurrence_anchor_start: datetime | None = Field(
        default=None,
        description="Bei Serien: bisheriger Start dieser Instanz (von der API), wenn start/end verschoben werden",
    )


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
    notification_level_id: int | None = None
    recurrence_rules: list[dict[str, Any]] = []
    occurrence_start: datetime | None = None
    recurrence_anchor_start: datetime | None = None
    recurrence_anchor_end: datetime | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @field_validator("recurrence_rules", mode="before")
    @classmethod
    def _coerce_recurrence_rules(cls, v: Any) -> list[dict[str, Any]]:
        return _parse_recurrence_rules_from_db(v)
