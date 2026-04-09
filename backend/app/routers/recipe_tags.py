from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.recipe_tag import RecipeTag
from ..schemas.recipe_tag import RecipeTagCreate, RecipeTagResponse, RecipeTagUpdate

router = APIRouter(
    prefix="/api/recipe-tags",
    tags=["recipe-tags"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/", response_model=list[RecipeTagResponse])
async def list_recipe_tags(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(RecipeTag)
        .where(RecipeTag.family_id == family_id)
        .order_by(RecipeTag.name.asc())
    )
    return result.scalars().all()


@router.post("/", response_model=RecipeTagResponse, status_code=status.HTTP_201_CREATED)
async def create_recipe_tag(
    data: RecipeTagCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    existing = await db.execute(
        select(RecipeTag).where(
            RecipeTag.name == data.name,
            RecipeTag.family_id == family_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Rezept-Tag existiert bereits")
    tag = RecipeTag(family_id=family_id, **data.model_dump())
    db.add(tag)
    await db.flush()
    await db.refresh(tag)
    return tag


@router.put("/{tag_id}", response_model=RecipeTagResponse)
async def update_recipe_tag(
    tag_id: int,
    data: RecipeTagUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(RecipeTag).where(
            RecipeTag.id == tag_id,
            RecipeTag.family_id == family_id,
        )
    )
    tag = result.scalar_one_or_none()
    if not tag:
        raise HTTPException(status_code=404, detail="Rezept-Tag nicht gefunden")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(tag, key, value)
    await db.flush()
    await db.refresh(tag)
    return tag


@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recipe_tag(
    tag_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(RecipeTag).where(
            RecipeTag.id == tag_id,
            RecipeTag.family_id == family_id,
        )
    )
    tag = result.scalar_one_or_none()
    if not tag:
        raise HTTPException(status_code=404, detail="Rezept-Tag nicht gefunden")
    await db.delete(tag)
