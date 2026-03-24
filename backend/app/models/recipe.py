from datetime import datetime

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow


class Recipe(Base):
    __tablename__ = "recipes"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(200))
    source: Mapped[str] = mapped_column(String(20), default="manual")
    cookidoo_id: Mapped[str | None] = mapped_column(String(100), default=None)
    servings: Mapped[int] = mapped_column(default=4)
    prep_time_active_minutes: Mapped[int | None] = mapped_column(default=None)
    prep_time_passive_minutes: Mapped[int | None] = mapped_column(default=None)
    difficulty: Mapped[str] = mapped_column(String(10), default="medium")
    last_cooked_at: Mapped[datetime | None] = mapped_column(default=None)
    cook_count: Mapped[int] = mapped_column(default=0)
    notes: Mapped[str | None] = mapped_column(Text, default=None)
    image_url: Mapped[str | None] = mapped_column(String(500), default=None)
    ai_accessible: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    ingredients = relationship(
        "Ingredient",
        back_populates="recipe",
        lazy="selectin",
        cascade="all, delete-orphan",
    )
    history = relationship(
        "CookingHistory",
        back_populates="recipe",
        lazy="noload",
        cascade="all, delete-orphan",
        order_by="CookingHistory.cooked_at.desc()",
    )
