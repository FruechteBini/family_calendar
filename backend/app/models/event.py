from datetime import datetime

from sqlalchemy import Column, ForeignKey, String, Table, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow

event_members = Table(
    "event_members",
    Base.metadata,
    Column("event_id", ForeignKey("events.id", ondelete="CASCADE"), primary_key=True),
    Column("member_id", ForeignKey("family_members.id", ondelete="CASCADE"), primary_key=True),
)


class Event(Base):
    __tablename__ = "events"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(Text, default=None)
    start: Mapped[datetime] = mapped_column()
    end: Mapped[datetime] = mapped_column()
    all_day: Mapped[bool] = mapped_column(default=False)
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), default=None
    )
    notification_level_id: Mapped[int | None] = mapped_column(
        ForeignKey("notification_levels.id", ondelete="SET NULL"), default=None
    )
    recurrence_rules: Mapped[str | None] = mapped_column(Text, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    category = relationship("Category", lazy="selectin")
    members = relationship("FamilyMember", secondary=event_members, lazy="selectin")
    todos = relationship("Todo", back_populates="event", lazy="selectin")
    notification_level = relationship("NotificationLevel", lazy="selectin")
