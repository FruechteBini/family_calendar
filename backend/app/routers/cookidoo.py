import logging
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..schemas.recipe import RecipeResponse

router = APIRouter(
    prefix="/api/cookidoo",
    tags=["cookidoo"],
    dependencies=[Depends(get_current_user)],
)

logger = logging.getLogger("kalender.cookidoo")


class CookidooPlanDayRequest(BaseModel):
    """Rezepte auf einen Cookidoo-Planungstag legen (z. B. „heute kochen“ → Thermomix)."""

    cookidoo_ids: list[str] = Field(..., min_length=1)
    day: date | None = None


def _get_integration():
    try:
        from integrations.cookidoo import client
        return client
    except ImportError:
        raise HTTPException(status_code=503, detail="Cookidoo-Bridge nicht installiert")


@router.get("/status")
async def cookidoo_status():
    """Check if Cookidoo integration is available and configured."""
    try:
        client = _get_integration()
        c = await client.get_client()
        if c is None:
            return {"available": False, "message": "Nicht konfiguriert oder Login fehlgeschlagen"}
        return {"available": True}
    except HTTPException:
        return {"available": False, "message": "cookidoo-api nicht installiert"}
    except Exception as e:
        logger.error("Cookidoo status error: %s", e)
        return {"available": False, "message": str(e)}


@router.get("/collections")
async def list_collections():
    """List all managed Cookidoo collections (recipe books)."""
    client = _get_integration()
    try:
        collections = await client.get_collections()
        logger.info("Cookidoo collections response count=%s", len(collections or []))
        # Empty list is a valid state (e.g. no managed collections).
        # Don't convert that to an error; the UI can show an empty-state message.
        return collections
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Cookidoo collections error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))


@router.get("/shopping-list")
async def shopping_list():
    """Get recipes currently on the Cookidoo shopping list."""
    client = _get_integration()
    try:
        recipes = await client.get_shopping_list()
        return recipes
    except Exception as e:
        logger.error("Cookidoo shopping list error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))


@router.get("/recipes/{cookidoo_id}")
async def recipe_detail(cookidoo_id: str):
    """Get full details for a Cookidoo recipe."""
    client = _get_integration()
    try:
        detail = await client.get_recipe_detail(cookidoo_id)
        if not detail:
            raise HTTPException(status_code=404, detail="Rezept nicht gefunden")
        return detail
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Cookidoo detail error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))


@router.post("/recipes/{cookidoo_id}/import", response_model=RecipeResponse, status_code=status.HTTP_201_CREATED)
async def import_from_cookidoo(
    cookidoo_id: str,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    """Import a Cookidoo recipe into the local database."""
    try:
        from integrations.cookidoo.importer import import_recipe
        recipe = await import_recipe(cookidoo_id, db, family_id)
        if not recipe:
            raise HTTPException(status_code=502, detail="Rezept konnte nicht von Cookidoo geladen werden")
        await db.refresh(recipe, attribute_names=["ingredients"])
        return recipe
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Cookidoo import error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.post("/plan-day")
async def plan_recipes_on_cookidoo_day(body: CookidooPlanDayRequest):
    """Rezepte in Cookidoo „Mein Tag“ einplanen (erscheint u. a. am Gerät in der Kochliste)."""
    _get_integration()
    try:
        from integrations.cookidoo.client import add_recipes_to_planning_day
    except ImportError as e:
        logger.error("Cookidoo plan-day: fehlende Erweiterung: %s", e)
        raise HTTPException(
            status_code=503,
            detail=(
                "Cookidoo-Backend veraltet oder unvollständig: "
                "Neuesten Stand deployen (Docker-Image neu bauen / API neu starten)."
            ),
        ) from e
    try:
        result = await add_recipes_to_planning_day(
            body.cookidoo_ids,
            day=body.day,
        )
        if not result:
            raise HTTPException(
                status_code=503,
                detail="Cookidoo nicht verfügbar oder nicht konfiguriert",
            )
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Cookidoo plan-day error: %s", e, exc_info=True)
        msg = str(e)
        if "add_recipes_to_planning_day" in msg or "has no attribute" in msg:
            raise HTTPException(
                status_code=503,
                detail=(
                    "API-Server nutzt noch alten Code ohne „Heute kochen“. "
                    "Bitte Backend neu deployen (Image bauen, Container neu starten)."
                ),
            ) from e
        raise HTTPException(
            status_code=502,
            detail=f"Cookidoo: {msg}",
        ) from e


@router.get("/calendar")
async def calendar_week(week: str = Query(..., pattern=r"^\d{4}-\d{2}-\d{2}$")):
    """Get recipes planned in Cookidoo for a given week."""
    client = _get_integration()
    try:
        day = date.fromisoformat(week)
        days = await client.get_calendar_week(day)
        return days
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Cookidoo calendar error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))
