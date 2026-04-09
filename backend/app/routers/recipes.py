import logging
import re

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
from ..models.recipe_category import RecipeCategory
from ..models.recipe_tag import RecipeTag
from ..schemas.recipe import (
    CookingHistoryResponse,
    IngredientCreate,
    RecipeCreate,
    RecipeDetailResponse,
    RecipeResponse,
    RecipeSuggestion,
    RecipeUpdate,
    UrlImportPreview,
    UrlImportRequest,
)

log = logging.getLogger("kalender.recipes")

router = APIRouter(
    prefix="/api/recipes",
    tags=["recipes"],
    dependencies=[Depends(get_current_user)],
)


async def _validate_recipe_category(
    db: AsyncSession, family_id: int, category_id: int | None
) -> None:
    if category_id is None:
        return
    r = await db.execute(
        select(RecipeCategory).where(
            RecipeCategory.id == category_id,
            RecipeCategory.family_id == family_id,
        )
    )
    if r.scalar_one_or_none() is None:
        raise HTTPException(status_code=400, detail="Ungültige Rezept-Kategorie")


async def _load_recipe_tags(
    db: AsyncSession, family_id: int, tag_ids: list[int]
) -> list[RecipeTag]:
    if not tag_ids:
        return []
    r = await db.execute(
        select(RecipeTag).where(
            RecipeTag.family_id == family_id,
            RecipeTag.id.in_(tag_ids),
        )
    )
    tags = list(r.scalars().all())
    if len(tags) != len(set(tag_ids)):
        raise HTTPException(status_code=400, detail="Ungültige Rezept-Tags")
    return tags


def _recipe_load_options():
    return (
        selectinload(Recipe.ingredients),
        selectinload(Recipe.category),
        selectinload(Recipe.tags),
    )


@router.get("/", response_model=list[RecipeResponse])
async def list_recipes(
    sort_by: str = Query("title", pattern="^(title|last_cooked_at|cook_count|prep_time_active_minutes|created_at)$"),
    order: str = Query("asc", pattern="^(asc|desc)$"),
    recipe_category_id: int | None = None,
    tag_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    col = getattr(Recipe, sort_by, Recipe.title)
    stmt = (
        select(Recipe)
        .options(*_recipe_load_options())
        .where(Recipe.family_id == family_id)
    )
    if recipe_category_id is not None:
        stmt = stmt.where(Recipe.recipe_category_id == recipe_category_id)
    if tag_id is not None:
        stmt = stmt.where(Recipe.tags.any(RecipeTag.id == tag_id))
    stmt = stmt.order_by(col.desc() if order == "desc" else col.asc())
    result = await db.execute(stmt)
    return result.scalars().unique().all()


@router.post("/", response_model=RecipeResponse, status_code=status.HTTP_201_CREATED)
async def create_recipe(
    data: RecipeCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    await _validate_recipe_category(db, family_id, data.recipe_category_id)
    tag_objs = await _load_recipe_tags(db, family_id, data.tag_ids)

    recipe = Recipe(
        family_id=family_id,
        title=data.title,
        source=data.source.value,
        cookidoo_id=data.cookidoo_id,
        servings=data.servings,
        prep_time_active_minutes=data.prep_time_active_minutes,
        prep_time_passive_minutes=data.prep_time_passive_minutes,
        difficulty=data.difficulty.value,
        instructions=data.instructions,
        notes=data.notes,
        image_url=data.image_url,
        ai_accessible=data.ai_accessible,
        recipe_category_id=data.recipe_category_id,
    )
    recipe.tags = tag_objs
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


@router.post("/parse-url", response_model=UrlImportPreview)
async def parse_recipe_url(data: UrlImportRequest):
    """Parse a cooking website URL and return structured recipe data."""
    try:
        from recipe_scrapers import scrape_html
    except ImportError:
        raise HTTPException(status_code=501, detail="recipe-scrapers nicht installiert")

    import requests as req_lib

    url = data.url.strip()
    if not url.startswith(("http://", "https://")):
        url = "https://" + url

    try:
        resp = req_lib.get(url, timeout=15, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept-Language": "de-DE,de;q=0.9,en;q=0.8",
        })
        resp.raise_for_status()
    except Exception as exc:
        log.warning("URL fetch failed: %s – %s", url, exc)
        raise HTTPException(status_code=422, detail=f"Seite konnte nicht geladen werden: {exc}")

    try:
        scraper = scrape_html(html=resp.text, org_url=url)
    except Exception as exc:
        log.warning("Scraper failed for %s: %s", url, exc)
        raise HTTPException(
            status_code=422,
            detail="Rezept konnte nicht erkannt werden. Eventuell wird diese Seite nicht unterstützt.",
        )

    # Extract fields
    title = scraper.title() or "Unbekanntes Rezept"

    servings = 4
    try:
        yields_str = scraper.yields()
        if yields_str:
            m = re.search(r"(\d+)", yields_str)
            if m:
                servings = int(m.group(1))
    except Exception:
        pass

    prep_active = None
    prep_passive = None
    try:
        total_min = scraper.total_time()
        prep_min = scraper.prep_time()
        cook_min = scraper.cook_time()
        if prep_min:
            prep_active = int(prep_min)
        elif cook_min:
            prep_active = int(cook_min)
        elif total_min:
            prep_active = int(total_min)
        if total_min and prep_active and total_min > prep_active:
            prep_passive = int(total_min - prep_active)
    except Exception:
        pass

    image_url = None
    try:
        image_url = scraper.image()
    except Exception:
        pass

    # Parse instructions
    instructions = None
    try:
        inst_list = scraper.instructions_list()
        if inst_list:
            instructions = "\n".join(f"{i+1}. {step}" for i, step in enumerate(inst_list) if step.strip())
        if not instructions:
            raw_inst = scraper.instructions()
            if raw_inst and raw_inst.strip():
                instructions = raw_inst.strip()
    except Exception:
        pass

    # Parse ingredients
    ingredients: list[IngredientCreate] = []
    try:
        raw_ings = scraper.ingredients()
        for raw in raw_ings:
            parsed = _parse_ingredient(raw)
            ingredients.append(parsed)
    except Exception:
        pass

    return UrlImportPreview(
        title=title,
        servings=servings,
        prep_time_active_minutes=prep_active,
        prep_time_passive_minutes=prep_passive,
        instructions=instructions,
        image_url=image_url,
        source_url=url,
        ingredients=ingredients,
    )


def _parse_ingredient(text: str) -> IngredientCreate:
    """Parse a free-text ingredient string like '200 g Mehl' into structured data."""
    text = text.strip()
    # Try to match: optional amount (number, fraction, range) + optional unit + name
    m = re.match(
        r"^(\d+[\.,/]?\d*(?:\s*[-–]\s*\d+[\.,/]?\d*)?)\s*"  # amount (e.g. 200, 1.5, 1/2, 2-3)
        r"(g|kg|ml|l|EL|TL|Prise|Prisen|Stk|Stück|Stück|Packung|Pkg|Dose|Dosen|Becher|Bund|Scheibe|Scheiben|Zehe|Zehen|Blatt|Blätter|Handvoll|cm|Tasse|Tassen|Beutel|Pck)\.?\s+"  # unit
        r"(.+)$",
        text, re.IGNORECASE
    )
    if m:
        amount_str, unit, name = m.group(1), m.group(2), m.group(3)
        amount = _parse_amount(amount_str)
        return IngredientCreate(name=name.strip(), amount=amount, unit=unit.strip())

    # Try: amount + name (no unit)
    m2 = re.match(r"^(\d+[\.,/]?\d*)\s+(.+)$", text)
    if m2:
        amount_str, name = m2.group(1), m2.group(2)
        amount = _parse_amount(amount_str)
        return IngredientCreate(name=name.strip(), amount=amount)

    return IngredientCreate(name=text)


def _parse_amount(s: str) -> float | None:
    """Parse amount string to float. Handles '1.5', '1,5', '1/2', '2-3' (takes first)."""
    s = s.strip().replace(",", ".")
    # Range: take first value
    if "-" in s or "–" in s:
        s = re.split(r"[-–]", s)[0].strip()
    # Fraction
    if "/" in s:
        parts = s.split("/")
        try:
            return round(float(parts[0]) / float(parts[1]), 2)
        except (ValueError, ZeroDivisionError):
            return None
    try:
        return round(float(s), 2)
    except ValueError:
        return None


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
        .options(
            selectinload(Recipe.ingredients),
            selectinload(Recipe.history),
            selectinload(Recipe.category),
            selectinload(Recipe.tags),
        )
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
        .options(
            selectinload(Recipe.ingredients),
            selectinload(Recipe.category),
            selectinload(Recipe.tags),
        )
        .where(Recipe.id == recipe_id, Recipe.family_id == family_id)
    )
    recipe = result.scalar_one_or_none()
    if not recipe:
        raise HTTPException(status_code=404, detail="Rezept nicht gefunden")

    update_fields = data.model_dump(exclude_unset=True)
    new_ingredients_raw = update_fields.pop("ingredients", None)
    new_tag_ids = update_fields.pop("tag_ids", None)

    if "difficulty" in update_fields and update_fields["difficulty"] is not None:
        update_fields["difficulty"] = update_fields["difficulty"].value

    if "recipe_category_id" in update_fields:
        await _validate_recipe_category(db, family_id, update_fields["recipe_category_id"])

    for key, value in update_fields.items():
        setattr(recipe, key, value)

    if new_tag_ids is not None:
        recipe.tags = await _load_recipe_tags(db, family_id, new_tag_ids)

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
