import re
from datetime import date, datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .models.family_member import FamilyMember


def ensure_aware(dt: datetime) -> datetime:
    """Ensure a datetime is timezone-aware (assumes UTC for naive datetimes)."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def monday_of(d: date) -> date:
    """Return the Monday of the week containing the given date."""
    return d - timedelta(days=d.weekday())


def normalize_ingredient_name(name: str) -> str:
    """Normalize an ingredient name for fuzzy matching.

    "Tomaten, gehackt" -> "gehackt tomaten"
    "gehackte Tomaten" -> "gehackt tomaten"
    "Salz" -> "salz"
    """
    name = name.lower().strip()
    name = re.sub(r"[,;.\-/()]", " ", name)
    name = re.sub(r"\s+", " ", name).strip()
    tokens = sorted(name.split())
    normalized = []
    for t in tokens:
        for suffix in ("te", "ter", "tes", "ten", "em"):
            if len(t) > len(suffix) + 3 and t.endswith(suffix):
                t = t[: -len(suffix)]
                break
        normalized.append(t)
    return " ".join(normalized)


async def resolve_members(
    db: AsyncSession, member_ids: list[int], family_id: int,
) -> list[FamilyMember]:
    """Fetch family members by IDs within a family, raising 400 if any ID is invalid."""
    if not member_ids:
        return []
    result = await db.execute(
        select(FamilyMember).where(
            FamilyMember.id.in_(member_ids),
            FamilyMember.family_id == family_id,
        )
    )
    members = result.scalars().all()
    if len(members) != len(member_ids):
        raise HTTPException(status_code=400, detail="Ein oder mehrere Familienmitglieder nicht gefunden")
    return list(members)
