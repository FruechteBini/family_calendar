from datetime import date, datetime

from sqlalchemy import Column, ForeignKey, String, Table, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow

todo_members = Table(
    "todo_members",
    Base.metadata,
    Column("todo_id", ForeignKey("todos.id", ondelete="CASCADE"), primary_key=True),
    Column("member_id", ForeignKey("family_members.id", ondelete="CASCADE"), primary_key=True),
)


class Todo(Base):
    __tablename__ = "todos"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(Text, default=None)
    priority: Mapped[str] = mapped_column(String(10), default="medium")
    due_date: Mapped[date | None] = mapped_column(default=None)
    completed: Mapped[bool] = mapped_column(default=False)
    completed_at: Mapped[datetime | None] = mapped_column(default=None)
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), default=None
    )
    event_id: Mapped[int | None] = mapped_column(
        ForeignKey("events.id", ondelete="SET NULL"), default=None
    )
    requires_multiple: Mapped[bool] = mapped_column(default=False)
    parent_id: Mapped[int | None] = mapped_column(
        ForeignKey("todos.id", ondelete="CASCADE"), default=None
    )
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    category = relationship("Category", lazy="selectin")
    event = relationship("Event", back_populates="todos", lazy="selectin")
    members = relationship("FamilyMember", secondary=todo_members, lazy="selectin")
    subtodos = relationship(
        "Todo",
        back_populates="parent",
        lazy="selectin",
        cascade="all, delete-orphan",
        order_by="Todo.created_at",
    )
    parent = relationship("Todo", back_populates="subtodos", remote_side=[id], lazy="noload")
