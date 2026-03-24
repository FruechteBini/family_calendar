import secrets
from datetime import datetime

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base, utcnow


def _generate_invite_code() -> str:
    return secrets.token_urlsafe(12)


class Family(Base):
    __tablename__ = "families"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    invite_code: Mapped[str] = mapped_column(
        String(20), unique=True, index=True, default=_generate_invite_code
    )
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
