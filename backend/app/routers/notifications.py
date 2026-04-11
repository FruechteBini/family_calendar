from __future__ import annotations

import json
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import delete, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db, utcnow
from ..models.device_token import DeviceToken
from ..models.notification_level import NotificationLevel
from ..models.notification_preference import NotificationPreference
from ..models.user import User
from ..schemas.notification import (
    DeviceTokenResponse,
    DeviceTokenUpsert,
    NotificationLevelCreate,
    NotificationLevelReorderRequest,
    NotificationLevelResponse,
    NotificationLevelUpdate,
    NotificationPreferencesResponse,
    NotificationPreferencesUpdate,
    NotificationPreferenceItem,
    NotificationType,
)

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


DEFAULT_NOTIFICATION_LEVELS: list[dict] = [
    {
        "name": "hoch",
        "position": 0,
        "reminders_minutes": [10080, 2880, 1440, 240, 0],
        "is_default": False,
    },
    {
        "name": "mittel",
        "position": 1,
        "reminders_minutes": [1440, 240, 0],
        "is_default": True,
    },
    {
        "name": "niedrig",
        "position": 2,
        "reminders_minutes": [240, 0],
        "is_default": False,
    },
    {
        "name": "unwichtig",
        "position": 3,
        "reminders_minutes": [],
        "is_default": False,
    },
]


async def ensure_default_levels_for_family(
    family_id: int, db: AsyncSession
) -> None:
    existing = await db.execute(
        select(NotificationLevel).where(NotificationLevel.family_id == family_id)
    )
    if existing.scalars().first():
        return
    for lvl in DEFAULT_NOTIFICATION_LEVELS:
        nl = NotificationLevel(
            family_id=family_id,
            name=lvl["name"],
            position=lvl["position"],
            is_default=lvl["is_default"],
        )
        nl.set_reminders_minutes(lvl["reminders_minutes"])
        db.add(nl)
    await db.flush()


def _level_to_response(level: NotificationLevel) -> NotificationLevelResponse:
    return NotificationLevelResponse(
        id=level.id,
        name=level.name,
        position=level.position,
        reminders_minutes=level.get_reminders_minutes(),
        is_default=level.is_default,
        created_at=level.created_at,
        updated_at=level.updated_at,
    )


@router.post("/device-token", response_model=DeviceTokenResponse)
async def upsert_device_token(
    data: DeviceTokenUpsert,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    token = data.token.strip()
    if not token:
        raise HTTPException(status_code=400, detail="Token fehlt")

    result = await db.execute(select(DeviceToken).where(DeviceToken.token == token))
    existing = result.scalar_one_or_none()
    now = utcnow()
    if existing:
        existing.user_id = user.id
        existing.platform = (data.platform or "unknown").strip()[:20]
        existing.updated_at = now
        await db.flush()
        await db.refresh(existing)
        return existing

    dt = DeviceToken(
        user_id=user.id,
        token=token,
        platform=(data.platform or "unknown").strip()[:20],
        created_at=now,
        updated_at=now,
    )
    db.add(dt)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        # race: token inserted in parallel; update it
        await db.execute(
            update(DeviceToken)
            .where(DeviceToken.token == token)
            .values(user_id=user.id, platform=(data.platform or "unknown")[:20], updated_at=now)
        )
        await db.flush()
        result2 = await db.execute(select(DeviceToken).where(DeviceToken.token == token))
        dt2 = result2.scalar_one()
        await db.refresh(dt2)
        return dt2
    await db.refresh(dt)
    return dt


@router.delete("/device-token")
async def delete_device_token(
    token: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    token = (token or "").strip()
    if not token:
        return {"ok": True}
    await db.execute(
        delete(DeviceToken).where(DeviceToken.user_id == user.id, DeviceToken.token == token)
    )
    return {"ok": True}


@router.get("/levels", response_model=list[NotificationLevelResponse])
async def list_levels(
    family_id: int = Depends(require_family_id),
    db: AsyncSession = Depends(get_db),
):
    await ensure_default_levels_for_family(family_id, db)
    res = await db.execute(
        select(NotificationLevel)
        .where(NotificationLevel.family_id == family_id)
        .order_by(NotificationLevel.position.asc(), NotificationLevel.id.asc())
    )
    return [_level_to_response(l) for l in res.scalars().all()]


@router.post("/levels", response_model=NotificationLevelResponse)
async def create_level(
    data: NotificationLevelCreate,
    family_id: int = Depends(require_family_id),
    db: AsyncSession = Depends(get_db),
):
    await ensure_default_levels_for_family(family_id, db)
    level = NotificationLevel(
        family_id=family_id,
        name=data.name.strip(),
        position=data.position,
        is_default=data.is_default,
    )
    level.set_reminders_minutes(data.reminders_minutes)
    db.add(level)
    await db.flush()
    if level.is_default:
        await db.execute(
            update(NotificationLevel)
            .where(
                NotificationLevel.family_id == family_id,
                NotificationLevel.id != level.id,
            )
            .values(is_default=False)
        )
    await db.refresh(level)
    return _level_to_response(level)


@router.put("/levels/{level_id}", response_model=NotificationLevelResponse)
async def update_level(
    level_id: int,
    data: NotificationLevelUpdate,
    family_id: int = Depends(require_family_id),
    db: AsyncSession = Depends(get_db),
):
    await ensure_default_levels_for_family(family_id, db)
    level = await db.get(NotificationLevel, level_id)
    if not level or level.family_id != family_id:
        raise HTTPException(status_code=404, detail="Stufe nicht gefunden")

    if data.name is not None:
        level.name = data.name.strip()
    if data.position is not None:
        level.position = data.position
    if data.reminders_minutes is not None:
        level.set_reminders_minutes(data.reminders_minutes)
    if data.is_default is not None:
        level.is_default = data.is_default

    await db.flush()
    if level.is_default:
        await db.execute(
            update(NotificationLevel)
            .where(
                NotificationLevel.family_id == family_id,
                NotificationLevel.id != level.id,
            )
            .values(is_default=False)
        )
    await db.refresh(level)
    return _level_to_response(level)


@router.delete("/levels/{level_id}")
async def delete_level(
    level_id: int,
    family_id: int = Depends(require_family_id),
    db: AsyncSession = Depends(get_db),
):
    level = await db.get(NotificationLevel, level_id)
    if not level or level.family_id != family_id:
        raise HTTPException(status_code=404, detail="Stufe nicht gefunden")
    await db.delete(level)
    return {"ok": True}


@router.put("/levels/reorder")
async def reorder_levels(
    data: NotificationLevelReorderRequest,
    family_id: int = Depends(require_family_id),
    db: AsyncSession = Depends(get_db),
):
    await ensure_default_levels_for_family(family_id, db)
    ids = [i.id for i in data.items]
    if len(ids) != len(set(ids)):
        raise HTTPException(status_code=400, detail="Doppelte IDs")
    res = await db.execute(
        select(NotificationLevel.id).where(
            NotificationLevel.family_id == family_id,
            NotificationLevel.id.in_(ids),
        )
    )
    found = {r[0] for r in res.all()}
    missing = [i for i in ids if i not in found]
    if missing:
        raise HTTPException(status_code=404, detail="Stufe nicht gefunden")

    for item in data.items:
        await db.execute(
            update(NotificationLevel)
            .where(
                NotificationLevel.family_id == family_id,
                NotificationLevel.id == item.id,
            )
            .values(position=item.position)
        )
    return {"ok": True}


async def _get_pref_map(db: AsyncSession, user_id: int) -> dict[str, bool]:
    res = await db.execute(
        select(NotificationPreference).where(NotificationPreference.user_id == user_id)
    )
    prefs = res.scalars().all()
    return {p.notification_type: bool(p.enabled) for p in prefs}


@router.get("/preferences", response_model=NotificationPreferencesResponse)
async def get_preferences(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pref_map = await _get_pref_map(db, user.id)
    items: list[NotificationPreferenceItem] = []
    for t in NotificationType:
        enabled = pref_map.get(t.value, True)
        items.append(NotificationPreferenceItem(notification_type=t, enabled=enabled))
    return NotificationPreferencesResponse(items=items)


@router.put("/preferences", response_model=NotificationPreferencesResponse)
async def update_preferences(
    data: NotificationPreferencesUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Upsert each pref
    for item in data.items:
        nt = item.notification_type.value
        res = await db.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == user.id,
                NotificationPreference.notification_type == nt,
            )
        )
        existing = res.scalar_one_or_none()
        if existing:
            existing.enabled = bool(item.enabled)
            existing.updated_at = utcnow()
        else:
            db.add(
                NotificationPreference(
                    user_id=user.id,
                    notification_type=nt,
                    enabled=bool(item.enabled),
                    created_at=utcnow(),
                    updated_at=utcnow(),
                )
            )
    await db.flush()
    return await get_preferences(user=user, db=db)

