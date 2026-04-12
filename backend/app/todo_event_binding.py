"""Helpers for calendar events linked to todos (due date + reminder level)."""

from __future__ import annotations

from datetime import datetime, time, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .models.event import Event
from .models.todo import Todo
from .models.user import User
from .notification_service import notification_service


def apply_event_binding_to_todo(todo: Todo, event: Event) -> None:
    """Copy due date (event start, calendar date) and push/reminder level from the event."""
    todo.due_date = event.start.date()
    todo.notification_level_id = event.notification_level_id


async def reschedule_todo_reminders(
    db: AsyncSession,
    family_id: int,
    todo: Todo,
    acting_user_id: int,
) -> None:
    """Cancel and recreate todo_reminder schedules; mirrors todos router behaviour."""
    if todo.is_personal or not todo.members:
        await notification_service.cancel_schedules(
            db=db,
            family_id=family_id,
            entity_type="todo",
            entity_id=todo.id,
            notification_type="todo_reminder",
        )
        return

    res_users = await db.execute(
        select(User.id).where(
            User.family_id == family_id,
            User.member_id.in_([m.id for m in todo.members]),
        )
    )
    target_user_ids = [r[0] for r in res_users.all() if r[0] != acting_user_id]
    if todo.due_date and todo.notification_level_id is not None:
        anchor = datetime.combine(
            todo.due_date, time(hour=9, minute=0), tzinfo=timezone.utc
        )
        await notification_service.cancel_schedules(
            db=db,
            family_id=family_id,
            entity_type="todo",
            entity_id=todo.id,
            notification_type="todo_reminder",
        )
        await notification_service.schedule_from_level(
            db=db,
            family_id=family_id,
            entity_type="todo",
            entity_id=todo.id,
            notification_type="todo_reminder",
            anchor_time=anchor,
            level_id=todo.notification_level_id,
            target_user_ids=target_user_ids if target_user_ids else [acting_user_id],
            title="Todo-Erinnerung",
            body=f'"{todo.title}" ist fällig',
            data={"route": "/todos", "todo_id": str(todo.id)},
        )
    else:
        await notification_service.cancel_schedules(
            db=db,
            family_id=family_id,
            entity_type="todo",
            entity_id=todo.id,
            notification_type="todo_reminder",
        )
