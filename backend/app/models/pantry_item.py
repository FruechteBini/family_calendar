from datetime import date, datetime

from sqlalchemy import Boolean, Date, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base, utcnow


class PantryItem(Base):
    __tablename__ = "pantry_items"

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(200))
    name_normalized: Mapped[str] = mapped_column(String(200), index=True)
    amount: Mapped[float | None] = mapped_column(default=None)
    unit: Mapped[str | None] = mapped_column(String(50), default=None)
    category: Mapped[str] = mapped_column(String(30), default="sonstiges")
    expiry_date: Mapped[date | None] = mapped_column(Date, default=None)
    min_stock: Mapped[float | None] = mapped_column(default=None)
    # True after "Gekocht" reduced amount; restock clears. Low-stock UI only when this is set.
    low_stock_watch_active: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow)
