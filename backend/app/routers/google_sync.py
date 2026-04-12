import logging

from fastapi import APIRouter, Depends, HTTPException
from googleapiclient.errors import HttpError
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user
from ..config import settings
from ..database import get_db
from ..google_sync_service import GoogleSyncService
from ..models.user import User
from ..schemas.auth import UserResponse
from ..schemas.common import MessageResponse
from pydantic import BaseModel

logger = logging.getLogger("kalender")

router = APIRouter(prefix="/api/google-sync", tags=["google-sync"])


class GoogleSyncStatusResponse(BaseModel):
    google_email: str | None = None
    sync_calendar_enabled: bool
    sync_todos_enabled: bool


class GoogleSyncSettingsRequest(BaseModel):
    sync_calendar_enabled: bool | None = None
    sync_todos_enabled: bool | None = None


_service = GoogleSyncService()


@router.get("/status", response_model=GoogleSyncStatusResponse)
async def status(user: User = Depends(get_current_user)):
    return GoogleSyncStatusResponse(
        google_email=user.google_email,
        sync_calendar_enabled=bool(user.sync_calendar_enabled),
        sync_todos_enabled=bool(user.sync_todos_enabled),
    )


@router.put("/settings", response_model=UserResponse)
async def update_settings(
    data: GoogleSyncSettingsRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.sync_calendar_enabled is not None:
        if data.sync_calendar_enabled and not user.google_refresh_token:
            raise HTTPException(status_code=400, detail="Google Sync benötigt ein verbundenes Google-Konto.")
        user.sync_calendar_enabled = data.sync_calendar_enabled
    if data.sync_todos_enabled is not None:
        if data.sync_todos_enabled and not user.google_refresh_token:
            raise HTTPException(status_code=400, detail="Google Sync benötigt ein verbundenes Google-Konto.")
        user.sync_todos_enabled = data.sync_todos_enabled
    await db.flush()
    await db.refresh(user)
    return user


@router.post("/trigger", response_model=MessageResponse)
async def trigger(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        raise HTTPException(status_code=503, detail="Google Sync ist nicht konfiguriert.")
    if not user.google_refresh_token:
        raise HTTPException(status_code=400, detail="Kein Google-Konto verbunden.")
    try:
        await _service.sync_calendar(
            user=user,
            db=db,
            client_id=settings.GOOGLE_CLIENT_ID,
            client_secret=settings.GOOGLE_CLIENT_SECRET,
        )
        await _service.sync_tasks(
            user=user,
            db=db,
            client_id=settings.GOOGLE_CLIENT_ID,
            client_secret=settings.GOOGLE_CLIENT_SECRET,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HttpError as e:
        status = e.resp.status if e.resp else 502
        reason = getattr(e, "reason", None) or str(e)
        logger.warning("Google Sync API-Fehler: %s %s", status, reason)
        raise HTTPException(
            status_code=502,
            detail=f"Google API-Fehler ({status}): {reason}",
        )
    except IntegrityError:
        logger.exception("Google Sync: Datenbank-Konflikt")
        raise HTTPException(
            status_code=409,
            detail="Sync-Konflikt in der Datenbank. Bitte erneut versuchen oder Support kontaktieren.",
        )
    return MessageResponse(message="Sync gestartet")

