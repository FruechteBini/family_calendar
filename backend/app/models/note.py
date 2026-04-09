from datetime import datetime

from sqlalchemy import Column, ForeignKey, String, Table, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow

note_tag_assignments = Table(
    "note_tag_assignments",
    Base.metadata,
    Column("note_id", ForeignKey("notes.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", ForeignKey("note_tags.id", ondelete="CASCADE"), primary_key=True),
)


class Note(Base):
    __tablename__ = "notes"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    created_by_member_id: Mapped[int | None] = mapped_column(
        ForeignKey("family_members.id", ondelete="SET NULL"), default=None, index=True
    )
    is_personal: Mapped[bool] = mapped_column(default=False)
    type: Mapped[str] = mapped_column(String(20), default="text")  # text, link, checklist
    title: Mapped[str] = mapped_column(String(200), default="")
    content: Mapped[str | None] = mapped_column(Text, default=None)
    url: Mapped[str | None] = mapped_column(String(2000), default=None)
    link_title: Mapped[str | None] = mapped_column(String(500), default=None)
    link_description: Mapped[str | None] = mapped_column(Text, default=None)
    link_thumbnail_url: Mapped[str | None] = mapped_column(String(2000), default=None)
    link_domain: Mapped[str | None] = mapped_column(String(200), default=None)
    checklist_json: Mapped[str | None] = mapped_column(Text, default=None)
    is_pinned: Mapped[bool] = mapped_column(default=False)
    is_archived: Mapped[bool] = mapped_column(default=False)
    color: Mapped[str | None] = mapped_column(String(7), default=None)
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("note_categories.id", ondelete="SET NULL"), default=None
    )
    reminder_at: Mapped[datetime | None] = mapped_column(default=None)
    position: Mapped[int] = mapped_column(default=0, index=True)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    category = relationship("NoteCategory", lazy="selectin")
    created_by = relationship(
        "FamilyMember",
        foreign_keys=[created_by_member_id],
        lazy="selectin",
    )
    tags = relationship("NoteTag", secondary=note_tag_assignments, lazy="selectin")
    comments = relationship(
        "NoteComment",
        lazy="selectin",
        order_by="NoteComment.created_at",
        cascade="all, delete-orphan",
    )
    attachments = relationship(
        "NoteAttachment",
        lazy="selectin",
        cascade="all, delete-orphan",
    )
