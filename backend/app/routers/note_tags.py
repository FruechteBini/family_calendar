from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.note_tag import NoteTag
from ..schemas.note_tag import NoteTagCreate, NoteTagResponse, NoteTagUpdate

router = APIRouter(
    prefix="/api/note-tags",
    tags=["note-tags"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/", response_model=list[NoteTagResponse])
async def list_note_tags(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(NoteTag)
        .where(NoteTag.family_id == family_id)
        .order_by(NoteTag.name.asc())
    )
    return result.scalars().all()


@router.post("/", response_model=NoteTagResponse, status_code=status.HTTP_201_CREATED)
async def create_note_tag(
    data: NoteTagCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    existing = await db.execute(
        select(NoteTag).where(
            NoteTag.name == data.name,
            NoteTag.family_id == family_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Notiz-Tag existiert bereits")
    tag = NoteTag(family_id=family_id, **data.model_dump())
    db.add(tag)
    await db.flush()
    await db.refresh(tag)
    return tag


@router.put("/{tag_id}", response_model=NoteTagResponse)
async def update_note_tag(
    tag_id: int,
    data: NoteTagUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(NoteTag).where(
            NoteTag.id == tag_id,
            NoteTag.family_id == family_id,
        )
    )
    tag = result.scalar_one_or_none()
    if not tag:
        raise HTTPException(status_code=404, detail="Notiz-Tag nicht gefunden")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(tag, key, value)
    await db.flush()
    await db.refresh(tag)
    return tag


@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_note_tag(
    tag_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(NoteTag).where(
            NoteTag.id == tag_id,
            NoteTag.family_id == family_id,
        )
    )
    tag = result.scalar_one_or_none()
    if not tag:
        raise HTTPException(status_code=404, detail="Notiz-Tag nicht gefunden")
    await db.delete(tag)
