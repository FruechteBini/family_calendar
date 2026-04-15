from sqlalchemy import CheckConstraint, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class NoteCategory(Base):
    __tablename__ = "note_categories"
    __table_args__ = (
        CheckConstraint(
            "(is_personal = true AND user_id IS NOT NULL) "
            "OR (is_personal = false AND user_id IS NULL)",
            name="ck_note_category_scope_user",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=True
    )
    is_personal: Mapped[bool] = mapped_column(default=True, index=True)
    position: Mapped[int] = mapped_column(default=0, index=True)
    name: Mapped[str] = mapped_column(String(50))
    color: Mapped[str] = mapped_column(String(7), default="#0052CC")
    icon: Mapped[str] = mapped_column(String(10), default="📝")
