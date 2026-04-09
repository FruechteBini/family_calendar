from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.recipe_category import RecipeCategory
from ..schemas.recipe_category import (
    RecipeCategoryCreate,
    RecipeCategoryResponse,
    RecipeCategoryUpdate,
)

router = APIRouter(
    prefix="/api/recipe-categories",
    tags=["recipe-categories"],
    dependencies=[Depends(get_current_user)],
)


class RecipeCategoryReorderRequest(BaseModel):
    ids: list[int]


@router.get("/", response_model=list[RecipeCategoryResponse])
async def list_recipe_categories(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(RecipeCategory)
        .where(RecipeCategory.family_id == family_id)
        .order_by(RecipeCategory.position.asc(), RecipeCategory.name.asc())
    )
    return result.scalars().all()


@router.post("/", response_model=RecipeCategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_recipe_category(
    data: RecipeCategoryCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    existing = await db.execute(
        select(RecipeCategory).where(
            RecipeCategory.name == data.name,
            RecipeCategory.family_id == family_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Rezept-Kategorie existiert bereits")
    max_pos = await db.scalar(
        select(func.coalesce(func.max(RecipeCategory.position), 0)).where(
            RecipeCategory.family_id == family_id
        )
    )
    category = RecipeCategory(
        family_id=family_id,
        position=int(max_pos or 0) + 1,
        **data.model_dump(),
    )
    db.add(category)
    await db.flush()
    await db.refresh(category)
    return category


@router.put("/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_recipe_categories(
    data: RecipeCategoryReorderRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if not data.ids:
        return
    result = await db.execute(
        select(RecipeCategory).where(
            RecipeCategory.family_id == family_id,
            RecipeCategory.id.in_(data.ids),
        )
    )
    cats = {c.id: c for c in result.scalars().all()}
    missing = [cid for cid in data.ids if cid not in cats]
    if missing:
        raise HTTPException(status_code=400, detail="Ungültige Rezept-Kategorie-IDs")
    for idx, cid in enumerate(data.ids):
        cats[cid].position = idx
    await db.flush()


@router.put("/{category_id}", response_model=RecipeCategoryResponse)
async def update_recipe_category(
    category_id: int,
    data: RecipeCategoryUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(RecipeCategory).where(
            RecipeCategory.id == category_id,
            RecipeCategory.family_id == family_id,
        )
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Rezept-Kategorie nicht gefunden")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(category, key, value)
    await db.flush()
    await db.refresh(category)
    return category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recipe_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(RecipeCategory).where(
            RecipeCategory.id == category_id,
            RecipeCategory.family_id == family_id,
        )
    )
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Rezept-Kategorie nicht gefunden")
    await db.delete(category)
