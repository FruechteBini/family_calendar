"""Import Cookidoo recipes into the local database."""

import logging
import re

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.ingredient import Ingredient
from app.models.recipe import Recipe
from . import client

logger = logging.getLogger("kalender.cookidoo")


def _parse_amount_unit(description: str) -> tuple[float | None, str | None]:
    """Parse '200 g' or '0.5 TL' or '2 Dosen' from ingredient description."""
    if not description:
        return None, None
    desc = description.strip()
    match = re.match(r"^([\d.,/]+(?:\s*-\s*[\d.,/]+)?)\s*(.*)", desc)
    if not match:
        return None, desc if desc else None
    raw_amount = match.group(1).strip()
    unit = match.group(2).strip() or None

    raw_amount = raw_amount.replace(",", ".")
    if "-" in raw_amount:
        raw_amount = raw_amount.split("-")[0].strip()
    if "/" in raw_amount:
        parts = raw_amount.split("/")
        try:
            return float(parts[0]) / float(parts[1]), unit
        except (ValueError, ZeroDivisionError):
            return None, unit
    try:
        return float(raw_amount), unit
    except ValueError:
        return None, unit


async def import_recipe(cookidoo_id: str, db: AsyncSession, family_id: int) -> Recipe | None:
    """Fetch a recipe from Cookidoo and store it locally. Skips if already imported for this family."""

    existing = await db.execute(
        select(Recipe)
        .where(Recipe.cookidoo_id == cookidoo_id, Recipe.family_id == family_id)
        .options(selectinload(Recipe.ingredients))
    )
    found = existing.scalar_one_or_none()
    if found:
        logger.info("Cookidoo recipe %s already imported as id=%d", cookidoo_id, found.id)
        return found

    detail = await client.get_recipe_detail(cookidoo_id)
    if not detail:
        return None

    total_time = detail.get("total_time")
    active_time = detail.get("active_time")

    active_min = int(active_time / 60) if active_time else None
    passive_min = None
    if total_time and active_time:
        passive_min = max(0, int((total_time - active_time) / 60))
    elif total_time:
        active_min = int(total_time / 60)

    recipe = Recipe(
        family_id=family_id,
        title=detail["name"],
        source="cookidoo",
        cookidoo_id=cookidoo_id,
        servings=detail.get("serving_size", 4),
        prep_time_active_minutes=active_min,
        prep_time_passive_minutes=passive_min,
        difficulty=client._map_difficulty(detail.get("difficulty")),
        instructions=detail.get("instructions"),
        # Store a human-readable description as notes as well, so the UI shows it
        # in the "Beschreibung" field (Flutter maps notes/description there).
        notes=(detail.get("description") or detail.get("instructions")),
        image_url=detail.get("image"),
    )

    for ing in detail.get("ingredients", []):
        amount, unit = _parse_amount_unit(ing.get("description", ""))
        recipe.ingredients.append(Ingredient(
            name=ing["name"],
            amount=amount,
            unit=unit,
            category="sonstiges",
        ))

    db.add(recipe)
    await db.flush()
    await db.refresh(recipe)
    logger.info("Imported Cookidoo recipe: %s (id=%d)", recipe.title, recipe.id)
    return recipe
