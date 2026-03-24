from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..database import get_db, utcnow
from ..utils import ensure_aware
from ..models.cooking_history import CookingHistory
from ..models.ingredient import Ingredient
from ..models.recipe import Recipe
from ..schemas.recipe import (
    CookingHistoryResponse,
    RecipeCreate,
    RecipeDetailResponse,
    RecipeResponse,
    RecipeSuggestion,
    RecipeUpdate,
)

router = APIRouter(
    prefix="/api/recipes",
    tags=["recipes"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/", response_model=list[RecipeResponse])
async def list_recipes(
    sort_by: str = Query("title", pattern="^(title|last_cooked_at|cook_count|prep_time_active_minutes|created_at)$"),
    order: str = Query("asc", pattern="^(asc|desc)$"),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    col = getattr(Recipe, sort_by, Recipe.title)
    stmt = (
        select(Recipe)
        .options(selectinload(Recipe.ingredients))
        .where(Recipe.family_id == family_id)
    )
    stmt = stmt.order_by(col.desc() if order == "desc" else col.asc())
    result = await db.execute(stmt)
    return result.scalars().unique().all()


@router.post("/", response_model=RecipeResponse, status_code=status.HTTP_201_CREATED)
async def create_recipe(
    data: RecipeCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    recipe = Recipe(
        family_id=family_id,
        title=data.title,
        source=data.source.value,
        cookidoo_id=data.cookidoo_id,
        servings=data.servings,
        prep_time_active_minutes=data.prep_time_active_minutes,
        prep_time_passive_minutes=data.prep_time_passive_minutes,
        difficulty=data.difficulty.value,
        notes=data.notes,
        image_url=data.image_url,
        ai_accessible=data.ai_accessible,
    )
    for ing in data.ingredients:
        recipe.ingredients.append(Ingredient(
            name=ing.name,
            amount=ing.amount,
            unit=ing.unit,
            category=ing.category.value,
        ))
    db.add(recipe)
    await db.flush()
    await db.refresh(recipe)
    return recipe


@router.get("/suggestions", response_model=list[RecipeSuggestion])
async def recipe_suggestions(
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(Recipe)
        .where(Recipe.ai_accessible.is_(True), Recipe.family_id == family_id)
        .order_by(Recipe.last_cooked_at.asc().nulls_first(), Recipe.cook_count.asc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    recipes = result.scalars().all()
    now = utcnow()
    suggestions = []
    for r in recipes:
        days = None
        if r.last_cooked_at:
            days = (now - ensure_aware(r.last_cooked_at)).days
        suggestions.append(RecipeSuggestion(
            id=r.id,
            title=r.title,
            difficulty=r.difficulty,
            prep_time_active_minutes=r.prep_time_active_minutes,
            last_cooked_at=r.last_cooked_at,
            cook_count=r.cook_count,
            days_since_cooked=days,
        ))
    return suggestions


@router.get("/{recipe_id}", response_model=RecipeDetailResponse)
async def get_recipe(
    recipe_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Recipe)
        .options(selectinload(Recipe.ingredients), selectinload(Recipe.history))
        .where(Recipe.id == recipe_id, Recipe.family_id == family_id)
    )
    recipe = result.scalar_one_or_none()
    if not recipe:
        raise HTTPException(status_code=404, detail="Rezept nicht gefunden")
    return recipe


@router.put("/{recipe_id}", response_model=RecipeResponse)
async def update_recipe(
    recipe_id: int,
    data: RecipeUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Recipe)
        .options(selectinload(Recipe.ingredients))
        .where(Recipe.id == recipe_id, Recipe.family_id == family_id)
    )
    recipe = result.scalar_one_or_none()
    if not recipe:
        raise HTTPException(status_code=404, detail="Rezept nicht gefunden")

    update_fields = data.model_dump(exclude_unset=True)
    new_ingredients_raw = update_fields.pop("ingredients", None)

    if "difficulty" in update_fields and update_fields["difficulty"] is not None:
        update_fields["difficulty"] = update_fields["difficulty"].value

    for key, value in update_fields.items():
        setattr(recipe, key, value)

    if new_ingredients_raw is not None:
        recipe.ingredients.clear()
        for ing in new_ingredients_raw:
            cat = ing.get("category", "sonstiges")
            recipe.ingredients.append(Ingredient(
                name=ing["name"],
                amount=ing.get("amount"),
                unit=ing.get("unit"),
                category=str(cat),
            ))

    await db.flush()
    await db.refresh(recipe)
    return recipe


@router.delete("/{recipe_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recipe(
    recipe_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Recipe).where(Recipe.id == recipe_id, Recipe.family_id == family_id)
    )
    recipe = result.scalar_one_or_none()
    if not recipe:
        raise HTTPException(status_code=404, detail="Rezept nicht gefunden")
    await db.delete(recipe)


@router.get("/{recipe_id}/history", response_model=list[CookingHistoryResponse])
async def recipe_history(
    recipe_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Recipe).where(Recipe.id == recipe_id, Recipe.family_id == family_id)
    )
    recipe = result.scalar_one_or_none()
    if not recipe:
        raise HTTPException(status_code=404, detail="Rezept nicht gefunden")
    stmt = (
        select(CookingHistory)
        .where(CookingHistory.recipe_id == recipe_id)
        .order_by(CookingHistory.cooked_at.desc())
    )
    result = await db.execute(stmt)
    return result.scalars().all()
