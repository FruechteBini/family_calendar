from datetime import datetime

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base, utcnow


class KnusprProductMapping(Base):
    """Remembers which Knuspr product the family prefers for a shopping-list item name."""

    __tablename__ = "knuspr_product_mappings"
    __table_args__ = (
        UniqueConstraint(
            "family_id",
            "item_name_normalized",
            name="uq_knuspr_map_family_item",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    family_id: Mapped[int] = mapped_column(
        ForeignKey("families.id", ondelete="CASCADE"), index=True
    )
    item_name_normalized: Mapped[str] = mapped_column(String(400))
    knuspr_product_id: Mapped[str] = mapped_column(String(64))
    knuspr_product_name: Mapped[str] = mapped_column(String(500), default="")
    use_count: Mapped[int] = mapped_column(default=0)
    last_used_at: Mapped[datetime] = mapped_column(default=utcnow)
