from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.category import Category
from ..schemas.category import CategoryCreate, CategoryResponse, CategoryUpdate
from pydantic import BaseModel

router = APIRouter(
    prefix="/api/categories",
    tags=["categories"],
    dependencies=[Depends(get_current_user)],
)

class CategoryReorderRequest(BaseModel):
    ids: list[int]


@router.get("/", response_model=list[CategoryResponse])
async def list_categories(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Category)
        .where(Category.family_id == family_id)
        .order_by(Category.position.asc(), Category.name.asc())
    )
    return result.scalars().all()


@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    data: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    existing = await db.execute(
        select(Category).where(Category.name == data.name, Category.family_id == family_id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Kategorie existiert bereits")
    max_pos = await db.scalar(
        select(func.coalesce(func.max(Category.position), 0)).where(Category.family_id == family_id)
    )
    category = Category(family_id=family_id, position=int(max_pos or 0) + 1, **data.model_dump())
    db.add(category)
    await db.flush()
    await db.refresh(category)
    return category


@router.put("/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_categories(
    data: CategoryReorderRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if not data.ids:
        return
    result = await db.execute(
        select(Category).where(Category.family_id == family_id, Category.id.in_(data.ids))
    )
    cats = {c.id: c for c in result.scalars().all()}
    # ensure all ids belong to this family
    missing = [cid for cid in data.ids if cid not in cats]
    if missing:
        raise HTTPException(status_code=400, detail="Ungültige Kategorie-IDs")
    for idx, cid in enumerate(data.ids):
        cats[cid].position = idx
    await db.flush()


@router.put("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: int,
    data: CategoryUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Category).where(Category.id == category_id, Category.family_id == family_id)
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Kategorie nicht gefunden")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(category, key, value)
    await db.flush()
    await db.refresh(category)
    return category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Category).where(Category.id == category_id, Category.family_id == family_id)
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Kategorie nicht gefunden")
    await db.delete(category)
