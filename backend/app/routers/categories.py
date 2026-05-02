from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.category import Category
from ..models.user import User
from ..schemas.category import CategoryCreate, CategoryResponse, CategoryUpdate

router = APIRouter(
    prefix="/api/categories",
    tags=["categories"],
    dependencies=[Depends(get_current_user)],
)


class CategoryReorderRequest(BaseModel):
    ids: list[int]


@router.get("/", response_model=list[CategoryResponse])
async def list_categories(
    scope: str = Query("all", pattern="^(all|personal|family)$"),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_user: User = Depends(get_current_user),
):
    if scope == "personal":
        result = await db.execute(
            select(Category)
            .where(
                Category.family_id == family_id,
                Category.is_personal.is_(True),
                Category.user_id == current_user.id,
            )
            .order_by(Category.position.asc(), Category.name.asc())
        )
        return result.scalars().all()
    if scope == "family":
        result = await db.execute(
            select(Category)
            .where(
                Category.family_id == family_id,
                Category.is_personal.is_(False),
            )
            .order_by(Category.position.asc(), Category.name.asc())
        )
        return result.scalars().all()
    rp = await db.execute(
        select(Category)
        .where(
            Category.family_id == family_id,
            Category.is_personal.is_(True),
            Category.user_id == current_user.id,
        )
        .order_by(Category.position.asc(), Category.name.asc())
    )
    rf = await db.execute(
        select(Category)
        .where(
            Category.family_id == family_id,
            Category.is_personal.is_(False),
        )
        .order_by(Category.position.asc(), Category.name.asc())
    )
    return list(rp.scalars().all()) + list(rf.scalars().all())


@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    data: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_user: User = Depends(get_current_user),
):
    if data.is_personal:
        existing = await db.execute(
            select(Category).where(
                Category.name == data.name,
                Category.user_id == current_user.id,
                Category.is_personal.is_(True),
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="Kategorie existiert bereits")
        max_pos = await db.scalar(
            select(func.coalesce(func.max(Category.position), 0)).where(
                Category.family_id == family_id,
                Category.user_id == current_user.id,
                Category.is_personal.is_(True),
            )
        )
        category = Category(
            family_id=family_id,
            user_id=current_user.id,
            is_personal=True,
            position=int(max_pos or 0) + 1,
            name=data.name,
            color=data.color,
            icon=data.icon,
        )
    else:
        existing = await db.execute(
            select(Category).where(
                Category.name == data.name,
                Category.family_id == family_id,
                Category.is_personal.is_(False),
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="Kategorie existiert bereits")
        max_pos = await db.scalar(
            select(func.coalesce(func.max(Category.position), 0)).where(
                Category.family_id == family_id,
                Category.is_personal.is_(False),
            )
        )
        category = Category(
            family_id=family_id,
            user_id=None,
            is_personal=False,
            position=int(max_pos or 0) + 1,
            name=data.name,
            color=data.color,
            icon=data.icon,
        )
    db.add(category)
    await db.flush()
    await db.refresh(category)
    return category


@router.put("/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_categories(
    data: CategoryReorderRequest,
    scope: str = Query(..., pattern="^(personal|family)$"),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_user: User = Depends(get_current_user),
):
    if not data.ids:
        return
    if scope == "personal":
        result = await db.execute(
            select(Category).where(
                Category.family_id == family_id,
                Category.user_id == current_user.id,
                Category.is_personal.is_(True),
                Category.id.in_(data.ids),
            )
        )
    else:
        result = await db.execute(
            select(Category).where(
                Category.family_id == family_id,
                Category.is_personal.is_(False),
                Category.id.in_(data.ids),
            )
        )
    cats = {c.id: c for c in result.scalars().all()}
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
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Category).where(
            Category.id == category_id,
            Category.family_id == family_id,
        )
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Kategorie nicht gefunden")
    if category.is_personal:
        if category.user_id != current_user.id:
            raise HTTPException(status_code=404, detail="Kategorie nicht gefunden")
    if data.name is not None and data.name != category.name:
        if category.is_personal:
            clash = await db.execute(
                select(Category).where(
                    Category.user_id == current_user.id,
                    Category.is_personal.is_(True),
                    Category.name == data.name,
                    Category.id != category_id,
                )
            )
        else:
            clash = await db.execute(
                select(Category).where(
                    Category.family_id == family_id,
                    Category.is_personal.is_(False),
                    Category.name == data.name,
                    Category.id != category_id,
                )
            )
        if clash.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="Kategorie existiert bereits")
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
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Category).where(
            Category.id == category_id,
            Category.family_id == family_id,
        )
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Kategorie nicht gefunden")
    if category.is_personal and category.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Kategorie nicht gefunden")
    await db.delete(category)
