from __future__ import annotations

import json
from datetime import datetime

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base, utcnow


class NotificationLevel(Base):
    __tablename__ = "notification_levels"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(50))
    position: Mapped[int] = mapped_column(Integer, default=0, index=True)
    reminders_minutes_json: Mapped[str] = mapped_column(Text, default="[]")
    is_default: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    def get_reminders_minutes(self) -> list[int]:
        try:
            raw = json.loads(self.reminders_minutes_json or "[]")
            if not isinstance(raw, list):
                return []
            out: list[int] = []
            for v in raw:
                if isinstance(v, int):
                    out.append(v)
                elif isinstance(v, float) and v.is_integer():
                    out.append(int(v))
                elif isinstance(v, str) and v.strip().isdigit():
                    out.append(int(v.strip()))
            return sorted({m for m in out if m >= 0}, reverse=True)
        except Exception:
            return []

    def set_reminders_minutes(self, minutes: list[int]) -> None:
        normalized = sorted({int(m) for m in minutes if int(m) >= 0}, reverse=True)
        self.reminders_minutes_json = json.dumps(normalized, ensure_ascii=False)
