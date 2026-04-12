from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base, utcnow


class GoogleCalendarSync(Base):
    __tablename__ = "google_calendar_sync"
    __table_args__ = (
        # Pro Benutzer: dieselbe Familie kann mehrere Google-Konten verbinden.
        UniqueConstraint("family_id", "user_id", "event_id", name="ux_google_calendar_sync_family_user_event"),
        UniqueConstraint("family_id", "google_calendar_id", "google_event_id", name="ux_google_calendar_sync_family_google"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    event_id: Mapped[int] = mapped_column(
        ForeignKey("events.id", ondelete="CASCADE"), index=True
    )

    google_calendar_id: Mapped[str] = mapped_column(String(255), nullable=False, default="primary")
    google_event_id: Mapped[str] = mapped_column(String(255), nullable=False)

    last_synced_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
    )
    last_local_hash: Mapped[str | None] = mapped_column(Text, nullable=True, default=None)
    last_google_hash: Mapped[str | None] = mapped_column(Text, nullable=True, default=None)

    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)


class GoogleTasksSync(Base):
    __tablename__ = "google_tasks_sync"
    __table_args__ = (
        UniqueConstraint("family_id", "user_id", "todo_id", name="ux_google_tasks_sync_family_user_todo"),
        UniqueConstraint("family_id", "google_tasklist_id", "google_task_id", name="ux_google_tasks_sync_family_google"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    todo_id: Mapped[int] = mapped_column(
        ForeignKey("todos.id", ondelete="CASCADE"), index=True
    )

    google_tasklist_id: Mapped[str] = mapped_column(String(255), nullable=False)
    google_task_id: Mapped[str] = mapped_column(String(255), nullable=False)

    last_synced_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
    )
    last_local_hash: Mapped[str | None] = mapped_column(Text, nullable=True, default=None)
    last_google_hash: Mapped[str | None] = mapped_column(Text, nullable=True, default=None)

    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

