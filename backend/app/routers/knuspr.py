import logging

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.shopping_list import ShoppingList

router = APIRouter(
    prefix="/api/knuspr",
    tags=["knuspr"],
    dependencies=[Depends(get_current_user)],
)

logger = logging.getLogger("kalender.knuspr")


class AddToCartRequest(BaseModel):
    product_id: str
    quantity: int = 1


@router.get("/products/search")
async def search_knuspr(q: str = Query(..., min_length=2)):
    try:
        from integrations.knuspr.client import search_products
        results = await search_products(q)
        if not results:
            raise HTTPException(
                status_code=503,
                detail="Knuspr nicht verfügbar oder nicht konfiguriert",
            )
        return results
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr search error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))


@router.post("/cart/add")
async def add_to_cart(data: AddToCartRequest):
    try:
        from integrations.knuspr.client import get_client
        kn = await get_client()
        if not kn:
            raise HTTPException(status_code=503, detail="Knuspr nicht konfiguriert")
        await kn.add_to_cart(data.product_id, quantity=data.quantity)
        return {"success": True}
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr add to cart error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.post("/cart/send-list/{shopping_list_id}")
async def send_list(
    shopping_list_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    sl_check = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == shopping_list_id, ShoppingList.family_id == family_id
        )
    )
    if not sl_check.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Einkaufsliste nicht gefunden")

    try:
        from integrations.knuspr.cart import send_list_to_cart
        result = await send_list_to_cart(shopping_list_id, db)
        if not result.get("success"):
            raise HTTPException(status_code=502, detail=result.get("error", "Unbekannter Fehler"))
        return result
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr send list error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/delivery-slots")
async def delivery_slots():
    try:
        from integrations.knuspr.client import get_delivery_slots
        slots = await get_delivery_slots()
        return slots
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr delivery slots error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))


@router.delete("/cart")
async def clear_cart():
    try:
        from integrations.knuspr.client import get_client
        kn = await get_client()
        if not kn:
            raise HTTPException(status_code=503, detail="Knuspr nicht konfiguriert")
        await kn.clear_cart()
        return {"success": True}
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr clear cart error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))
