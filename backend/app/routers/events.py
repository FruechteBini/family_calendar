import json
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from sqlalchemy import and_, func, not_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..config import settings
from ..database import get_db
from ..database import async_session
from ..event_recurrence import occurrence_starts_for_event
from ..google_sync_service import GoogleSyncService
from ..models.event import Event
from ..models.family_member import FamilyMember
from ..models.todo import Todo
from ..models.user import User
from ..notification_service import notification_service
from ..todo_event_binding import apply_event_binding_to_todo, reschedule_todo_reminders
from ..schemas.event import EventCreate, EventResponse, EventUpdate, RecurrenceRule
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

_REMINDER_HORIZON_DAYS = 400
_MAX_SCHEDULED_OCCURRENCES = 64


def _recurrence_rules_json_from_payload(rules: list[RecurrenceRule] | None) -> str | None:
    if not rules:
        return None
    return json.dumps([r.model_dump(mode="json", exclude_none=True) for r in rules], ensure_ascii=False)


def _recurrence_rules_list(raw: str | None) -> list[dict]:
    if not raw or not raw.strip():
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


def _event_response(
    event: Event,
    *,
    start: datetime | None = None,
    end: datetime | None = None,
    occurrence_start: datetime | None = None,
) -> EventResponse:
    s = start if start is not None else event.start
    e = end if end is not None else event.end
    base = EventResponse.model_validate(event)
    has_rec = bool(event.recurrence_rules and event.recurrence_rules.strip())
    anchor_s = occurrence_start if occurrence_start is not None else event.start
    anchor_e = occurrence_start + (event.end - event.start) if occurrence_start is not None else event.end
    return base.model_copy(
        update={
            "start": s,
            "end": e,
            "recurrence_rules": _recurrence_rules_list(event.recurrence_rules),
            "occurrence_start": occurrence_start,
            "recurrence_anchor_start": anchor_s if has_rec else None,
            "recurrence_anchor_end": anchor_e if has_rec else None,
        }
    )


def _expand_event_for_range(
    event: Event,
    date_from: datetime | None,
    date_to: datetime | None,
) -> list[EventResponse]:
    raw = event.recurrence_rules
    if not raw or not raw.strip():
        if date_from and event.end < date_from:
            return []
        if date_to and event.start > date_to:
            return []
        return [_event_response(event)]

    now = datetime.now(timezone.utc)
    eff_from = date_from
    eff_to = date_to
    if eff_from is None:
        eff_from = now - timedelta(days=30)
    if eff_to is None:
        eff_to = now + timedelta(days=400)

    pairs = occurrence_starts_for_event(
        event.start, event.end, raw, eff_from, eff_to
    )
    out: list[EventResponse] = []
    for occ_s, occ_e in pairs:
        out.append(
            _event_response(
                event,
                start=occ_s,
                end=occ_e,
                occurrence_start=occ_s,
            )
        )
    return out


async def _schedule_event_reminders(
    db: AsyncSession,
    family_id: int,
    event: Event,
    target_user_ids: list[int],
    actor_user_id: int,
) -> None:
    await notification_service.cancel_schedules(
        db=db,
        family_id=family_id,
        entity_type="event",
        entity_id=event.id,
        notification_type="event_reminder",
    )
    await notification_service.cancel_schedules(
        db=db,
        family_id=family_id,
        entity_type="event_recurrence",
        entity_id=event.id,
        notification_type="event_reminder",
    )

    recipients = target_user_ids if target_user_ids else [actor_user_id]
    if event.notification_level_id is None:
        return

    now = datetime.now(timezone.utc)
    horizon_end = now + timedelta(days=_REMINDER_HORIZON_DAYS)

    if not event.recurrence_rules or not event.recurrence_rules.strip():
        await notification_service.schedule_from_level(
            db=db,
            family_id=family_id,
            entity_type="event",
            entity_id=event.id,
            notification_type="event_reminder",
            anchor_time=event.start,
            level_id=event.notification_level_id,
            target_user_ids=recipients,
            title="Termin-Erinnerung",
            body=f'"{event.title}" startet bald',
            data={
                "route": "/calendar",
                "event_id": str(event.id),
            },
        )
        return

    pairs = occurrence_starts_for_event(
        event.start, event.end, event.recurrence_rules, now, horizon_end
    )
    for occ_s, _ in pairs[:_MAX_SCHEDULED_OCCURRENCES]:
        await notification_service.schedule_from_level(
            db=db,
            family_id=family_id,
            entity_type="event_recurrence",
            entity_id=event.id,
            notification_type="event_reminder",
            anchor_time=occ_s,
            level_id=event.notification_level_id,
            target_user_ids=recipients,
            title="Termin-Erinnerung",
            body=f'"{event.title}" startet bald',
            data={
                "route": "/calendar",
                "event_id": str(event.id),
                "occurrence_start": occ_s.isoformat(),
            },
        )


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
    if date_from and date_to:
        rec_empty = or_(
            Event.recurrence_rules.is_(None),
            func.trim(func.coalesce(Event.recurrence_rules, "")) == "",
            func.trim(func.coalesce(Event.recurrence_rules, "")) == "[]",
        )
        stmt = stmt.where(
            or_(
                and_(
                    rec_empty,
                    Event.end >= date_from,
                    Event.start <= date_to,
                ),
                and_(not_(rec_empty), Event.start <= date_to),
            )
        )
    elif date_from:
        rec_empty = or_(
            Event.recurrence_rules.is_(None),
            func.trim(func.coalesce(Event.recurrence_rules, "")) == "",
            func.trim(func.coalesce(Event.recurrence_rules, "")) == "[]",
        )
        stmt = stmt.where(
            or_(and_(rec_empty, Event.end >= date_from), not_(rec_empty))
        )
    elif date_to:
        rec_empty = or_(
            Event.recurrence_rules.is_(None),
            func.trim(func.coalesce(Event.recurrence_rules, "")) == "",
            func.trim(func.coalesce(Event.recurrence_rules, "")) == "[]",
        )
        stmt = stmt.where(
            or_(and_(rec_empty, Event.start <= date_to), not_(rec_empty))
        )
    if category_id:
        stmt = stmt.where(Event.category_id == category_id)
    if member_id:
        stmt = stmt.where(Event.members.any(FamilyMember.id == member_id))
    stmt = stmt.order_by(Event.start)
    result = await db.execute(stmt)
    rows = result.scalars().unique().all()

    expanded: list[EventResponse] = []
    for event in rows:
        expanded.extend(_expand_event_for_range(event, date_from, date_to))
    expanded.sort(key=lambda r: r.start)
    return expanded


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(
    event_id: int,
    occurrence_start: datetime | None = Query(
        None,
        description="Startzeit einer Serie (UTC/Offset); für wiederkehrende Termine",
    ),
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

    if occurrence_start is None or not event.recurrence_rules:
        return _event_response(event)

    occ = occurrence_start
    if occ.tzinfo is None:
        occ = occ.replace(tzinfo=timezone.utc)
    else:
        occ = occ.astimezone(timezone.utc)

    win_start = occ - timedelta(days=1)
    win_end = occ + timedelta(days=1)
    pairs = occurrence_starts_for_event(
        event.start, event.end, event.recurrence_rules, win_start, win_end
    )
    for occ_s, occ_e in pairs:
        if occ_s == occ:
            return _event_response(
                event, start=occ_s, end=occ_e, occurrence_start=occ_s
            )
    raise HTTPException(
        status_code=400,
        detail="Ungültige occurrence_start für diesen Termin",
    )


@router.post("/", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
async def create_event(
    data: EventCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    user: User = Depends(get_current_user),
):
    members = await resolve_members(db, data.member_ids, family_id)
    recurrence_json = _recurrence_rules_json_from_payload(data.recurrence_rules)
    event = Event(
        family_id=family_id,
        title=data.title,
        description=data.description,
        start=data.start,
        end=data.end,
        all_day=data.all_day,
        category_id=data.category_id,
        notification_level_id=data.notification_level_id,
        recurrence_rules=recurrence_json,
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
    member_ids = [m.id for m in members]
    target_user_ids: list[int] = []
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
    await _schedule_event_reminders(
        db, family_id, event, target_user_ids, user.id
    )
    reloaded = await _reload_event(db, event.id)
    return _event_response(reloaded)


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
    recurrence_rules = update_data.pop("recurrence_rules", None)
    anchor_raw = update_data.pop("recurrence_anchor_start", None)
    if recurrence_rules is not None:
        event.recurrence_rules = _recurrence_rules_json_from_payload(recurrence_rules)

    if (
        anchor_raw is not None
        and event.recurrence_rules
        and event.recurrence_rules.strip()
        and ("start" in update_data or "end" in update_data)
    ):
        anchor = anchor_raw
        if anchor.tzinfo is None:
            anchor = anchor.replace(tzinfo=timezone.utc)
        else:
            anchor = anchor.astimezone(timezone.utc)
        if "start" not in update_data:
            raise HTTPException(
                status_code=400,
                detail="Bei Serien mit recurrence_anchor_start muss auch start gesetzt werden",
            )
        new_start = update_data.pop("start")
        new_end = update_data.pop("end", None)
        win_start = anchor - timedelta(days=1)
        win_end = anchor + timedelta(days=1)
        pairs = occurrence_starts_for_event(
            event.start, event.end, event.recurrence_rules, win_start, win_end
        )
        occ_match: tuple[datetime, datetime] | None = None
        for occ_s, occ_e in pairs:
            if occ_s == anchor:
                occ_match = (occ_s, occ_e)
                break
        if occ_match is None:
            raise HTTPException(
                status_code=400,
                detail="recurrence_anchor_start passt nicht zu dieser Serie",
            )
        occ_s, occ_e = occ_match
        if new_end is None:
            new_end = new_start + (occ_e - occ_s)
        delta = new_start - occ_s
        event.start = event.start + delta
        event.end = event.end + delta

    for key, value in update_data.items():
        setattr(event, key, value)

    if member_ids is not None:
        event.members = await resolve_members(db, member_ids, family_id)

    await db.flush()

    r_linked = await db.execute(
        select(Todo).where(Todo.event_id == event.id, Todo.family_id == family_id)
    )
    linked_todos = list(r_linked.scalars().unique().all())
    for t in linked_todos:
        apply_event_binding_to_todo(t, event)
        await reschedule_todo_reminders(db, family_id, t, user.id)
    if linked_todos:
        await db.flush()

    res_users = await db.execute(
        select(User.id).where(
            User.family_id == family_id,
            User.member_id.in_([m.id for m in event.members]),
        )
    )
    target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
    await _schedule_event_reminders(
        db, family_id, event, target_user_ids, user.id
    )
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
    reloaded = await _reload_event(db, event_id)
    return _event_response(reloaded)


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
    await notification_service.cancel_schedules(
        db=db,
        family_id=family_id,
        entity_type="event_recurrence",
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
