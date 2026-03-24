from datetime import datetime

from sqlalchemy import ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow


class CookingHistory(Base):
    __tablename__ = "cooking_history"

    id: Mapped[int] = mapped_column(primary_key=True)
    recipe_id: Mapped[int] = mapped_column(
        ForeignKey("recipes.id", ondelete="CASCADE")
    )
    cooked_at: Mapped[datetime] = mapped_column(default=utcnow)
    servings_cooked: Mapped[int] = mapped_column(default=4)
    rating: Mapped[int | None] = mapped_column(default=None)
    notes: Mapped[str | None] = mapped_column(Text, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    recipe = relationship("Recipe", back_populates="history")
