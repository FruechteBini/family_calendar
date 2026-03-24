from datetime import datetime

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    family_id: Mapped[int | None] = mapped_column(
        ForeignKey("families.id", ondelete="SET NULL"), default=None, index=True
    )
    member_id: Mapped[int | None] = mapped_column(
        ForeignKey("family_members.id", ondelete="SET NULL"), default=None
    )
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    family = relationship("Family", lazy="selectin")
    member = relationship("FamilyMember", lazy="selectin")
