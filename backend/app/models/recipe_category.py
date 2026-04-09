from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class RecipeCategory(Base):
    __tablename__ = "recipe_categories"
    __table_args__ = (
        UniqueConstraint("family_id", "name", name="uq_recipe_category_family_name"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    position: Mapped[int] = mapped_column(default=0, index=True)
    name: Mapped[str] = mapped_column(String(50))
    color: Mapped[str] = mapped_column(String(7), default="#0052CC")
    icon: Mapped[str] = mapped_column(String(10), default="🍽")
