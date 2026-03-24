import datetime as dt

from sqlalchemy import Date, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow


class MealPlan(Base):
    __tablename__ = "meal_plan"
    __table_args__ = (UniqueConstraint("family_id", "plan_date", "slot", name="uq_meal_family_date_slot"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    plan_date: Mapped[dt.date] = mapped_column(Date)
    slot: Mapped[str] = mapped_column(String(10))
    recipe_id: Mapped[int] = mapped_column(
        ForeignKey("recipes.id", ondelete="CASCADE")
    )
    servings_planned: Mapped[int] = mapped_column(default=4)
    created_at: Mapped[dt.datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[dt.datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    recipe = relationship("Recipe", lazy="selectin")
