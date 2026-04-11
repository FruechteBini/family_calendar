from __future__ import annotations

import json
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Table,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow

scheduled_notification_targets = Table(
    "scheduled_notification_targets",
    Base.metadata,
    Column(
        "scheduled_notification_id",
        ForeignKey("scheduled_notifications.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column("user_id", ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)


class ScheduledNotification(Base):
    __tablename__ = "scheduled_notifications"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    notification_type: Mapped[str] = mapped_column(String(50), index=True)
    entity_type: Mapped[str] = mapped_column(String(20), index=True)
    entity_id: Mapped[int] = mapped_column(Integer, index=True)
    title: Mapped[str] = mapped_column(String(200))
    body: Mapped[str] = mapped_column(Text)
    data_json: Mapped[str | None] = mapped_column(Text, default=None)
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    sent: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    targets = relationship(
        "User",
        secondary=scheduled_notification_targets,
        lazy="selectin",
    )

    def get_data(self) -> dict[str, str]:
        if not self.data_json:
            return {}
        try:
            raw = json.loads(self.data_json)
            if not isinstance(raw, dict):
                return {}
            return {str(k): str(v) for k, v in raw.items()}
        except Exception:
            return {}

    def set_data(self, data: dict) -> None:
        self.data_json = json.dumps(data or {}, ensure_ascii=False)
