from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.note_category import NoteCategory
from ..schemas.note_category import NoteCategoryCreate, NoteCategoryResponse, NoteCategoryUpdate

router = APIRouter(
    prefix="/api/note-categories",
    tags=["note-categories"],
    dependencies=[Depends(get_current_user)],
)


class NoteCategoryReorderRequest(BaseModel):
    ids: list[int]


@router.get("/", response_model=list[NoteCategoryResponse])
async def list_note_categories(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(NoteCategory)
        .where(NoteCategory.family_id == family_id)
        .order_by(NoteCategory.position.asc(), NoteCategory.name.asc())
    )
    return result.scalars().all()


@router.post("/", response_model=NoteCategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_note_category(
    data: NoteCategoryCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    existing = await db.execute(
        select(NoteCategory).where(
            NoteCategory.name == data.name,
            NoteCategory.family_id == family_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Notiz-Kategorie existiert bereits")
    max_pos = await db.scalar(
        select(func.coalesce(func.max(NoteCategory.position), 0)).where(
            NoteCategory.family_id == family_id
        )
    )
    category = NoteCategory(
        family_id=family_id,
        position=int(max_pos or 0) + 1,
        **data.model_dump(),
    )
    db.add(category)
    await db.flush()
    await db.refresh(category)
    return category


@router.put("/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_note_categories(
    data: NoteCategoryReorderRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if not data.ids:
        return
    result = await db.execute(
        select(NoteCategory).where(
            NoteCategory.family_id == family_id,
            NoteCategory.id.in_(data.ids),
        )
    )
    cats = {c.id: c for c in result.scalars().all()}
    missing = [cid for cid in data.ids if cid not in cats]
    if missing:
        raise HTTPException(status_code=400, detail="Ungültige Notiz-Kategorie-IDs")
    for idx, cid in enumerate(data.ids):
        cats[cid].position = idx
    await db.flush()


@router.put("/{category_id}", response_model=NoteCategoryResponse)
async def update_note_category(
    category_id: int,
    data: NoteCategoryUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(NoteCategory).where(
            NoteCategory.id == category_id,
            NoteCategory.family_id == family_id,
        )
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Notiz-Kategorie nicht gefunden")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(category, key, value)
    await db.flush()
    await db.refresh(category)
    return category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_note_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(NoteCategory).where(
            NoteCategory.id == category_id,
            NoteCategory.family_id == family_id,
        )
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Notiz-Kategorie nicht gefunden")
    await db.delete(category)
