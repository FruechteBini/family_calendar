from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Google account linkage (optional)
    google_id: Mapped[str | None] = mapped_column(String(255), unique=True, index=True, nullable=True)
    google_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    google_access_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    google_refresh_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    google_token_expiry: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Per-feature sync toggles (optional)
    sync_calendar_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sync_todos_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    # The default Google calendar/task list can be customized later.
    google_calendar_id: Mapped[str] = mapped_column(String(255), nullable=False, default="primary")
    google_tasklist_id: Mapped[str] = mapped_column(String(255), nullable=False, default="@@default@@")
    family_id: Mapped[int | None] = mapped_column(
        ForeignKey("families.id", ondelete="SET NULL"), default=None, index=True
    )
    member_id: Mapped[int | None] = mapped_column(
        ForeignKey("family_members.id", ondelete="SET NULL"), default=None
    )
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    family = relationship("Family", lazy="selectin")
    member = relationship("FamilyMember", lazy="selectin")
