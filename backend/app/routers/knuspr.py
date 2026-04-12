import logging

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.knuspr_mapping import KnusprProductMapping
from ..models.shopping_list import ShoppingList
from ..schemas.knuspr import (
    AddToCartRequest,
    ApplySelectionsRequest,
    BookDeliverySlotRequest,
    BookDeliverySlotResponse,
    CartAddBatchRequest,
    CartAddBatchResponse,
    KnusprCartAddResult,
    KnusprCartLineResponse,
    KnusprCartResponse,
    KnusprCartResult,
    KnusprDeliverySlotResponse,
    KnusprMappingCreate,
    KnusprMappingResponse,
    KnusprProductResponse,
    KnusprStatusResponse,
    PreviewShoppingListResponse,
    PriceCheckRequest,
    PriceCheckResponse,
    PriceCheckLine,
)

router = APIRouter(
    prefix="/api/knuspr",
    tags=["knuspr"],
    dependencies=[Depends(get_current_user)],
)

logger = logging.getLogger("kalender.knuspr")


def _knuspr_installed() -> bool:
    try:
        from knuspr import KnusprClient  # noqa: F401

        return True
    except ImportError:
        return False


@router.get("/status", response_model=KnusprStatusResponse)
async def knuspr_status():
    try:
        from integrations.knuspr.client import knuspr_status_probe

        if not _knuspr_installed():
            return KnusprStatusResponse(
                available=False, configured=False, message="knuspr-api nicht installiert"
            )
        from app.config import settings

        configured = bool(settings.KNUSPR_EMAIL and settings.KNUSPR_PASSWORD)
        if not configured:
            return KnusprStatusResponse(
                available=False, configured=False, message="Knuspr nicht konfiguriert"
            )
        ok, err = await knuspr_status_probe()
        return KnusprStatusResponse(
            available=ok, configured=True, message=err if not ok else None
        )
    except Exception as e:
        logger.error("Knuspr status error: %s", e)
        return KnusprStatusResponse(available=False, configured=True, message=str(e))


@router.get("/products/search", response_model=list[KnusprProductResponse])
async def search_knuspr(q: str = Query(..., min_length=2)):
    try:
        from integrations.knuspr.client import search_products

        results = await search_products(q)
        if not results:
            raise HTTPException(
                status_code=503,
                detail="Knuspr nicht verfügbar oder nicht konfiguriert",
            )
        return [KnusprProductResponse.model_validate(x) for x in results]
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr search error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))


@router.post("/cart/add", response_model=KnusprCartAddResult)
async def add_to_cart(data: AddToCartRequest):
    try:
        from integrations.knuspr.client import add_to_cart as kn_add

        await kn_add(data.product_id, quantity=data.quantity)
        return KnusprCartAddResult(success=True)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr add to cart error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.post("/cart/add-batch", response_model=CartAddBatchResponse)
async def add_batch(data: CartAddBatchRequest):
    try:
        from integrations.knuspr.client import add_to_cart as kn_add

        for it in data.items:
            await kn_add(it.product_id, quantity=it.quantity)
        return CartAddBatchResponse(success=True, added=len(data.items))
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr batch add error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/cart", response_model=KnusprCartResponse)
async def get_cart():
    try:
        from integrations.knuspr.client import get_cart_payload

        raw = await get_cart_payload()
        lines = [
            KnusprCartLineResponse(
                order_field_id=x["order_field_id"],
                product_id=x["product_id"],
                name=x["name"],
                quantity=x["quantity"],
                price=x["price"],
            )
            for x in raw["items"]
        ]
        return KnusprCartResponse(
            items=lines,
            total_price=raw["total_price"],
            total_items=raw["total_items"],
            can_make_order=raw["can_make_order"],
        )
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr get cart error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.delete("/cart/items/{order_field_id}", response_model=KnusprCartAddResult)
async def remove_cart_item(order_field_id: str):
    try:
        from integrations.knuspr.client import remove_cart_line

        await remove_cart_line(order_field_id)
        return KnusprCartAddResult(success=True)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr remove cart line error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.post("/cart/send-list/{shopping_list_id}", response_model=KnusprCartResult)
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

        result = await send_list_to_cart(shopping_list_id, db, family_id=family_id)
        if not result.get("success"):
            raise HTTPException(status_code=502, detail=result.get("error", "Unbekannter Fehler"))
        return KnusprCartResult.model_validate(result)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr send list error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.post(
    "/cart/preview-list/{shopping_list_id}",
    response_model=PreviewShoppingListResponse,
)
async def preview_list(
    shopping_list_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    try:
        from integrations.knuspr.cart import preview_shopping_list

        data = await preview_shopping_list(shopping_list_id, db, family_id)
        if not data:
            raise HTTPException(status_code=404, detail="Einkaufsliste nicht gefunden")
        return PreviewShoppingListResponse.model_validate(data)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr preview list error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.post("/cart/apply-selections/{shopping_list_id}", response_model=KnusprCartResult)
async def apply_selections(
    shopping_list_id: int,
    data: ApplySelectionsRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    try:
        from integrations.knuspr.cart import apply_selections_to_cart

        payload = [s.model_dump() for s in data.selections]
        result = await apply_selections_to_cart(shopping_list_id, family_id, payload, db)
        if not result.get("success"):
            raise HTTPException(status_code=400, detail=result.get("error", "Fehler"))
        return KnusprCartResult.model_validate(result)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Knuspr apply selections error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.post("/price-check", response_model=PriceCheckResponse)
async def price_check(data: PriceCheckRequest):
    try:
        from integrations.knuspr.client import pick_search_hit_for_cart, search_products

        lines: list[PriceCheckLine] = []
        total = 0.0
        for it in data.items:
            found_list = await search_products(it.name, limit=8)
            p = pick_search_hit_for_cart(found_list) if found_list else None
            if p:
                price = p.get("price")
                if price is not None:
                    total += float(price)
                lines.append(
                    PriceCheckLine(
                        name=it.name,
                        shopping_item_id=it.shopping_item_id,
                        product_id=p["id"],
                        product_name=p.get("name"),
                        price=p.get("price"),
                        unit=p.get("unit"),
                        found=True,
                    )
                )
            else:
                lines.append(
                    PriceCheckLine(
                        name=it.name,
                        shopping_item_id=it.shopping_item_id,
                        found=False,
                    )
                )
        return PriceCheckResponse(lines=lines, estimated_total=total or None)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr price check error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/delivery-slots", response_model=list[KnusprDeliverySlotResponse])
async def delivery_slots():
    try:
        from integrations.knuspr.client import get_delivery_slots

        slots = await get_delivery_slots()
        return [KnusprDeliverySlotResponse.model_validate(s) for s in slots]
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr delivery slots error: %s", e)
        raise HTTPException(status_code=503, detail=str(e))


@router.post("/delivery-slots/book", response_model=BookDeliverySlotResponse)
async def book_slot(data: BookDeliverySlotRequest):
    try:
        from integrations.knuspr.client import book_delivery_slot

        ok, msg = await book_delivery_slot(data.slot_id)
        return BookDeliverySlotResponse(success=ok, message=msg or None)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr book slot error: %s", e)
        return BookDeliverySlotResponse(success=False, message=str(e))


@router.delete("/cart", response_model=KnusprCartAddResult)
async def clear_cart():
    try:
        from integrations.knuspr.client import clear_cart as kn_clear

        await kn_clear()
        return KnusprCartAddResult(success=True)
    except ImportError:
        raise HTTPException(status_code=503, detail="Knuspr-Bridge nicht installiert")
    except Exception as e:
        logger.error("Knuspr clear cart error: %s", e)
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/mappings", response_model=list[KnusprMappingResponse])
async def list_mappings(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    r = await db.execute(
        select(KnusprProductMapping)
        .where(KnusprProductMapping.family_id == family_id)
        .order_by(KnusprProductMapping.last_used_at.desc())
    )
    rows = r.scalars().all()
    return [
        KnusprMappingResponse(
            id=m.id,
            item_name=m.item_name_normalized,
            knuspr_product_id=m.knuspr_product_id,
            knuspr_product_name=m.knuspr_product_name,
            use_count=m.use_count,
        )
        for m in rows
    ]


@router.post("/mappings", response_model=KnusprMappingResponse, status_code=201)
async def create_mapping(
    data: KnusprMappingCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    from app.utils import normalize_ingredient_name

    norm = normalize_ingredient_name(data.item_name)
    r = await db.execute(
        select(KnusprProductMapping).where(
            KnusprProductMapping.family_id == family_id,
            KnusprProductMapping.item_name_normalized == norm,
        )
    )
    row = r.scalar_one_or_none()
    if row:
        row.knuspr_product_id = data.knuspr_product_id
        row.knuspr_product_name = data.knuspr_product_name
    else:
        row = KnusprProductMapping(
            family_id=family_id,
            item_name_normalized=norm,
            knuspr_product_id=data.knuspr_product_id,
            knuspr_product_name=data.knuspr_product_name,
        )
        db.add(row)
    await db.flush()
    await db.refresh(row)
    return KnusprMappingResponse(
        id=row.id,
        item_name=data.item_name,
        knuspr_product_id=row.knuspr_product_id,
        knuspr_product_name=row.knuspr_product_name,
        use_count=row.use_count,
    )


@router.delete("/mappings/{mapping_id}", status_code=204, response_class=Response)
async def delete_mapping(
    mapping_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    await db.execute(
        delete(KnusprProductMapping).where(
            KnusprProductMapping.id == mapping_id,
            KnusprProductMapping.family_id == family_id,
        )
    )
    return Response(status_code=204)
