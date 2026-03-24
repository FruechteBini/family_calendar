from datetime import date, datetime

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow


class ShoppingList(Base):
    __tablename__ = "shopping_lists"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    week_start_date: Mapped[date] = mapped_column()
    status: Mapped[str] = mapped_column(String(20), default="active")
    sorted_by_store: Mapped[str | None] = mapped_column(String(30), default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    items = relationship(
        "ShoppingItem",
        back_populates="shopping_list",
        lazy="selectin",
        cascade="all, delete-orphan",
    )


class ShoppingItem(Base):
    __tablename__ = "shopping_items"

    id: Mapped[int] = mapped_column(primary_key=True)
    shopping_list_id: Mapped[int] = mapped_column(
        ForeignKey("shopping_lists.id", ondelete="CASCADE")
    )
    name: Mapped[str] = mapped_column(String(200))
    amount: Mapped[str | None] = mapped_column(String(50), default=None)
    unit: Mapped[str | None] = mapped_column(String(50), default=None)
    category: Mapped[str] = mapped_column(String(30), default="sonstiges")
    checked: Mapped[bool] = mapped_column(default=False)
    source: Mapped[str] = mapped_column(String(20), default="manual")
    recipe_id: Mapped[int | None] = mapped_column(
        ForeignKey("recipes.id", ondelete="SET NULL"), default=None
    )
    ai_accessible: Mapped[bool] = mapped_column(default=True)
    sort_order: Mapped[int | None] = mapped_column(default=None)
    store_section: Mapped[str | None] = mapped_column(String(100), default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)

    shopping_list = relationship("ShoppingList", back_populates="items")
