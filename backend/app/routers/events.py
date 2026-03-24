from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.event import Event
from ..models.family_member import FamilyMember
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
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
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
        members=members,
    )
    db.add(event)
    await db.flush()
    return await _reload_event(db, event.id)


@router.put("/{event_id}", response_model=EventResponse)
async def update_event(
    event_id: int,
    data: EventUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
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
    return await _reload_event(db, event_id)


@router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_event(
    event_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = select(Event).where(Event.id == event_id, Event.family_id == family_id)
    result = await db.execute(stmt)
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event nicht gefunden")
    await db.delete(event)
