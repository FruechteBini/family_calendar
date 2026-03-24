from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.family_member import FamilyMember
from ..schemas.family_member import (
    FamilyMemberCreate,
    FamilyMemberResponse,
    FamilyMemberUpdate,
)

router = APIRouter(
    prefix="/api/family-members",
    tags=["family-members"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/", response_model=list[FamilyMemberResponse])
async def list_members(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(FamilyMember)
        .where(FamilyMember.family_id == family_id)
        .order_by(FamilyMember.name)
    )
    return result.scalars().all()


@router.post("/", response_model=FamilyMemberResponse, status_code=status.HTTP_201_CREATED)
async def create_member(
    data: FamilyMemberCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    member = FamilyMember(family_id=family_id, **data.model_dump())
    db.add(member)
    await db.flush()
    await db.refresh(member)
    return member


@router.put("/{member_id}", response_model=FamilyMemberResponse)
async def update_member(
    member_id: int,
    data: FamilyMemberUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(FamilyMember).where(FamilyMember.id == member_id, FamilyMember.family_id == family_id)
    )
    member = result.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=404, detail="Familienmitglied nicht gefunden")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(member, key, value)
    await db.flush()
    await db.refresh(member)
    return member


@router.delete("/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_member(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(FamilyMember).where(FamilyMember.id == member_id, FamilyMember.family_id == family_id)
    )
    member = result.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=404, detail="Familienmitglied nicht gefunden")
    await db.delete(member)
