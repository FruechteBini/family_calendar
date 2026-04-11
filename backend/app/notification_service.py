from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from .config import settings
from .database import utcnow
from .models.device_token import DeviceToken
from .models.notification_level import NotificationLevel
from .models.notification_preference import NotificationPreference
from .models.scheduled_notification import ScheduledNotification
from .models.user import User

logger = logging.getLogger("kalender")


class FirebaseClient:
    def __init__(self) -> None:
        self._enabled = False
        self._messaging = None
        self._initialized = False

    def enabled(self) -> bool:
        self._ensure_init()
        return self._enabled

    def _ensure_init(self) -> None:
        if self._initialized:
            return
        self._initialized = True

        creds_json = (settings.FIREBASE_CREDENTIALS_JSON or "").strip()
        creds_path = (settings.FIREBASE_CREDENTIALS_PATH or "").strip()
        if not creds_json and not creds_path:
            logger.info("FCM disabled (no credentials configured)")
            self._enabled = False
            return

        try:
            import firebase_admin  # type: ignore
            from firebase_admin import credentials, messaging  # type: ignore

            if not firebase_admin._apps:
                if creds_json:
                    firebase_admin.initialize_app(
                        credentials.Certificate(json.loads(creds_json))
                    )
                else:
                    firebase_admin.initialize_app(credentials.Certificate(creds_path))

            self._messaging = messaging
            self._enabled = True
            logger.info("FCM enabled")
        except Exception as e:
            logger.warning(f"FCM init failed; disabling push. {e}")
            self._enabled = False
            self._messaging = None

    def send_to_tokens(
        self,
        tokens: list[str],
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        self._ensure_init()
        if not self._enabled or not self._messaging or not tokens:
            return {"enabled": False, "sent": 0, "failed": 0, "invalid_tokens": []}

        messaging = self._messaging
        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in (data or {}).items()},
            tokens=tokens,
        )
        resp = messaging.send_each_for_multicast(message)
        invalid: list[str] = []
        for idx, r in enumerate(resp.responses):
            if r.success:
                continue
            # remove unregistered/invalid tokens
            exc = getattr(r, "exception", None)
            if exc is None:
                continue
            name = exc.__class__.__name__
            if name in ("UnregisteredError", "InvalidArgumentError"):
                invalid.append(tokens[idx])
        return {
            "enabled": True,
            "sent": resp.success_count,
            "failed": resp.failure_count,
            "invalid_tokens": invalid,
        }


class NotificationService:
    def __init__(self, firebase: FirebaseClient | None = None) -> None:
        self.firebase = firebase or FirebaseClient()

    async def send_immediate(
        self,
        db: AsyncSession,
        user_ids: list[int],
        notification_type: str,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> None:
        if not user_ids:
            return

        enabled_map = await self._preferences_enabled_map(db, user_ids, notification_type)
        target_ids = [uid for uid in user_ids if enabled_map.get(uid, True)]
        if not target_ids:
            return

        tokens = await self._tokens_for_users(db, target_ids)
        if not tokens:
            return

        result = self.firebase.send_to_tokens(tokens, title=title, body=body, data=data)
        invalid = result.get("invalid_tokens") or []
        if invalid:
            await db.execute(delete(DeviceToken).where(DeviceToken.token.in_(invalid)))

    async def cancel_schedules(
        self,
        db: AsyncSession,
        family_id: int,
        entity_type: str,
        entity_id: int,
        notification_type: str | None = None,
    ) -> None:
        q = delete(ScheduledNotification).where(
            ScheduledNotification.family_id == family_id,
            ScheduledNotification.entity_type == entity_type,
            ScheduledNotification.entity_id == entity_id,
            ScheduledNotification.sent.is_(False),
        )
        if notification_type:
            q = q.where(ScheduledNotification.notification_type == notification_type)
        await db.execute(q)

    async def schedule_from_level(
        self,
        db: AsyncSession,
        family_id: int,
        entity_type: str,
        entity_id: int,
        notification_type: str,
        anchor_time: datetime,
        level_id: int | None,
        target_user_ids: list[int],
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> None:
        if not target_user_ids:
            return
        if level_id is None:
            return

        level = await db.get(NotificationLevel, level_id)
        if not level or level.family_id != family_id:
            return

        minutes_list = level.get_reminders_minutes()
        if not minutes_list:
            return

        now = utcnow()
        for minutes_before in minutes_list:
            scheduled_at = anchor_time - timedelta(minutes=minutes_before)
            if scheduled_at <= now:
                continue
            sn = ScheduledNotification(
                family_id=family_id,
                notification_type=notification_type,
                entity_type=entity_type,
                entity_id=entity_id,
                title=title,
                body=body,
                scheduled_at=scheduled_at,
                sent=False,
                sent_at=None,
            )
            sn.set_data(data or {})
            db.add(sn)
            await db.flush()
            # attach targets
            if target_user_ids:
                res = await db.execute(select(User).where(User.id.in_(target_user_ids)))
                sn.targets = list(res.scalars().all())

    async def process_due(self, db: AsyncSession) -> int:
        now = utcnow()
        res = await db.execute(
            select(ScheduledNotification)
            .where(
                ScheduledNotification.sent.is_(False),
                ScheduledNotification.scheduled_at <= now,
            )
            .order_by(ScheduledNotification.scheduled_at.asc(), ScheduledNotification.id.asc())
            .limit(200)
        )
        due = res.scalars().all()
        if not due:
            return 0

        sent_count = 0
        for sn in due:
            target_ids = [u.id for u in (sn.targets or [])]
            await self.send_immediate(
                db=db,
                user_ids=target_ids,
                notification_type=sn.notification_type,
                title=sn.title,
                body=sn.body,
                data=sn.get_data(),
            )
            await db.execute(
                update(ScheduledNotification)
                .where(ScheduledNotification.id == sn.id)
                .values(sent=True, sent_at=now)
            )
            sent_count += 1
        return sent_count

    async def _tokens_for_users(self, db: AsyncSession, user_ids: list[int]) -> list[str]:
        res = await db.execute(
            select(DeviceToken.token).where(DeviceToken.user_id.in_(user_ids))
        )
        return [r[0] for r in res.all()]

    async def _preferences_enabled_map(
        self, db: AsyncSession, user_ids: list[int], notification_type: str
    ) -> dict[int, bool]:
        res = await db.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id.in_(user_ids),
                NotificationPreference.notification_type == notification_type,
            )
        )
        prefs = res.scalars().all()
        return {p.user_id: bool(p.enabled) for p in prefs}


notification_service = NotificationService()
