from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Ingredient(Base):
    __tablename__ = "ingredients"

    id: Mapped[int] = mapped_column(primary_key=True)
    recipe_id: Mapped[int] = mapped_column(
        ForeignKey("recipes.id", ondelete="CASCADE")
    )
    name: Mapped[str] = mapped_column(String(200))
    amount: Mapped[float | None] = mapped_column(default=None)
    unit: Mapped[str | None] = mapped_column(String(50), default=None)
    category: Mapped[str] = mapped_column(String(30), default="sonstiges")

    recipe = relationship("Recipe", back_populates="ingredients")
