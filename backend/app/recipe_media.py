"""Rezeptbild-URL für API-Antworten (eingebettete Cover vs. externe image_url)."""

from __future__ import annotations

from .models.recipe import Recipe


def public_recipe_image_url(recipe: Recipe) -> str | None:
    if getattr(recipe, "cover_image_path", None):
        return f"/api/recipes/{recipe.id}/cover"
    return recipe.image_url
