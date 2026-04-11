from datetime import datetime

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..config import settings
from ..database import get_db
from ..database import async_session
from ..google_sync_service import GoogleSyncService
from ..models.event import Event
from ..models.family_member import FamilyMember
from ..models.user import User
from ..models.notification_level import NotificationLevel
from ..notification_service import notification_service
from ..schemas.event import EventCreate, EventResponse, EventUpdate
from ..utils import resolve_members

router = APIRouter(
    prefix="/api/events",
    tags=["events"],
    dependencies=[Depends(get_current_user)],
)

_event_load_options = [
    selectinload(Event.category),
    selectinload(Event.members),
    selectinload(Event.todos),
]

_google_sync = GoogleSyncService()


async def _google_push_event(user_id: int, event_id: int) -> None:
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        return
    async with async_session() as db:
        user = await db.get(User, user_id)
        event = await db.get(Event, event_id)
        if not user or not event:
            return
        try:
            await _google_sync.push_event_to_google(
                user=user,
                event=event,
                db=db,
                client_id=settings.GOOGLE_CLIENT_ID,
                client_secret=settings.GOOGLE_CLIENT_SECRET,
            )
            await db.commit()
        except Exception:
            await db.rollback()


async def _google_delete_event(user_id: int, event_id: int) -> None:
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        return
    async with async_session() as db:
        user = await db.get(User, user_id)
        if not user:
            return
        try:
            await _google_sync.delete_event_from_google(
                user=user,
                event_id=event_id,
                db=db,
                client_id=settings.GOOGLE_CLIENT_ID,
                client_secret=settings.GOOGLE_CLIENT_SECRET,
            )
            await db.commit()
        except Exception:
            await db.rollback()


async def _reload_event(db: AsyncSession, event_id: int) -> Event:
    """Re-query an event with all relationships fully loaded."""
    result = await db.execute(
        select(Event).options(*_event_load_options).where(Event.id == event_id)
    )
    return result.scalar_one()


@router.get("/", response_model=list[EventResponse])
async def list_events(
    date_from: datetime | None = Query(None),
    date_to: datetime | None = Query(None),
    member_id: int | None = Query(None),
    category_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(Event)
        .options(*_event_load_options)
        .where(Event.family_id == family_id)
    )
    if date_from:
        stmt = stmt.where(Event.end >= date_from)
    if date_to:
        stmt = stmt.where(Event.start <= date_to)
    if category_id:
        stmt = stmt.where(Event.category_id == category_id)
    if member_id:
        stmt = stmt.where(Event.members.any(FamilyMember.id == member_id))
    stmt = stmt.order_by(Event.start)
    result = await db.execute(stmt)
    return result.scalars().unique().all()


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(
    event_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(Event)
        .options(*_event_load_options)
        .where(Event.id == event_id, Event.family_id == family_id)
    )
    result = await db.execute(stmt)
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event nicht gefunden")
    return event


@router.post("/", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
async def create_event(
    data: EventCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    user: User = Depends(get_current_user),
):
    members = await resolve_members(db, data.member_ids, family_id)
    event = Event(
        family_id=family_id,
        title=data.title,
        description=data.description,
        start=data.start,
        end=data.end,
        all_day=data.all_day,
        category_id=data.category_id,
        notification_level_id=data.notification_level_id,
        members=members,
    )
    db.add(event)
    await db.flush()
    if (
        background_tasks is not None
        and user.sync_calendar_enabled
        and user.google_refresh_token
        and settings.GOOGLE_CLIENT_ID
        and settings.GOOGLE_CLIENT_SECRET
    ):
        background_tasks.add_task(_google_push_event, user.id, event.id)
    # Immediate push: assigned members (excluding actor where possible)
    member_ids = [m.id for m in members]
    if member_ids:
        res_users = await db.execute(
            select(User.id)
            .where(User.family_id == family_id, User.member_id.in_(member_ids))
        )
        target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
        await notification_service.send_immediate(
            db=db,
            user_ids=target_user_ids,
            notification_type="event_assigned",
            title="Neuer Termin",
            body=f'"{event.title}" wurde dir zugewiesen',
            data={"route": "/calendar", "event_id": str(event.id)},
        )

        # Schedule reminders for assigned users
        await notification_service.cancel_schedules(
            db=db,
            family_id=family_id,
            entity_type="event",
            entity_id=event.id,
            notification_type="event_reminder",
        )
        await notification_service.schedule_from_level(
            db=db,
            family_id=family_id,
            entity_type="event",
            entity_id=event.id,
            notification_type="event_reminder",
            anchor_time=event.start,
            level_id=event.notification_level_id,
            target_user_ids=target_user_ids if target_user_ids else [user.id],
            title="Termin-Erinnerung",
            body=f'"{event.title}" startet bald',
            data={"route": "/calendar", "event_id": str(event.id)},
        )
    return await _reload_event(db, event.id)


@router.put("/{event_id}", response_model=EventResponse)
async def update_event(
    event_id: int,
    data: EventUpdate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    user: User = Depends(get_current_user),
):
    stmt = select(Event).where(Event.id == event_id, Event.family_id == family_id)
    result = await db.execute(stmt)
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event nicht gefunden")

    update_data = data.model_dump(exclude_unset=True)
    member_ids = update_data.pop("member_ids", None)

    for key, value in update_data.items():
        setattr(event, key, value)

    if member_ids is not None:
        event.members = await resolve_members(db, member_ids, family_id)

    await db.flush()
    # Reschedule reminders on any change (time/level/members)
    res_users = await db.execute(
        select(User.id).where(
            User.family_id == family_id,
            User.member_id.in_([m.id for m in event.members]),
        )
    )
    target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
    await notification_service.cancel_schedules(
        db=db,
        family_id=family_id,
        entity_type="event",
        entity_id=event.id,
        notification_type="event_reminder",
    )
    await notification_service.schedule_from_level(
        db=db,
        family_id=family_id,
        entity_type="event",
        entity_id=event.id,
        notification_type="event_reminder",
        anchor_time=event.start,
        level_id=event.notification_level_id,
        target_user_ids=target_user_ids if target_user_ids else [user.id],
        title="Termin-Erinnerung",
        body=f'"{event.title}" startet bald',
        data={"route": "/calendar", "event_id": str(event.id)},
    )
    # Immediate push: updated
    await notification_service.send_immediate(
        db=db,
        user_ids=target_user_ids,
        notification_type="event_updated",
        title="Termin geändert",
        body=f'"{event.title}" wurde aktualisiert',
        data={"route": "/calendar", "event_id": str(event.id)},
    )
    if (
        background_tasks is not None
        and user.sync_calendar_enabled
        and user.google_refresh_token
        and settings.GOOGLE_CLIENT_ID
        and settings.GOOGLE_CLIENT_SECRET
    ):
        background_tasks.add_task(_google_push_event, user.id, event.id)
    return await _reload_event(db, event_id)


@router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_event(
    event_id: int,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    user: User = Depends(get_current_user),
):
    stmt = select(Event).where(Event.id == event_id, Event.family_id == family_id)
    result = await db.execute(stmt)
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event nicht gefunden")
    # cancel schedules and inform assigned users
    res_users = await db.execute(
        select(User.id).where(
            User.family_id == family_id,
            User.member_id.in_([m.id for m in event.members]),
        )
    )
    target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
    await notification_service.cancel_schedules(
        db=db,
        family_id=family_id,
        entity_type="event",
        entity_id=event.id,
    )
    await notification_service.send_immediate(
        db=db,
        user_ids=target_user_ids,
        notification_type="event_deleted",
        title="Termin gelöscht",
        body=f'"{event.title}" wurde gelöscht',
        data={"route": "/calendar"},
    )
    if (
        background_tasks is not None
        and user.sync_calendar_enabled
        and user.google_refresh_token
        and settings.GOOGLE_CLIENT_ID
        and settings.GOOGLE_CLIENT_SECRET
    ):
        background_tasks.add_task(_google_delete_event, user.id, event.id)
    await db.delete(event)
