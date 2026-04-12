"""Pydantic schemas for Knuspr API responses and requests."""

from pydantic import BaseModel, Field


class KnusprProductResponse(BaseModel):
    id: str
    name: str
    price: float | None = None
    unit: str | None = None
    available: bool = True
    image_url: str | None = None
    category: str | None = None


class KnusprDeliverySlotResponse(BaseModel):
    id: str
    start: str | None = None
    end: str | None = None
    date: str | None = None
    time_range: str | None = None
    available: bool = True
    fee: float | None = None


class KnusprCartLineResponse(BaseModel):
    order_field_id: str
    product_id: str
    name: str
    quantity: int = 0
    price: float = 0.0


class KnusprCartResponse(BaseModel):
    items: list[KnusprCartLineResponse] = []
    total_price: float = 0.0
    total_items: int = 0
    can_make_order: bool = False


class KnusprCartAddResult(BaseModel):
    success: bool = True


class KnusprCartSendItemResult(BaseModel):
    item: str
    product: str


class KnusprCartSendFail(BaseModel):
    item: str
    reason: str


class KnusprCartSkippedItem(BaseModel):
    item: str


class KnusprCartResult(BaseModel):
    success: bool
    added: list[KnusprCartSendItemResult] = []
    failed: list[KnusprCartSendFail] = []
    skipped: list[KnusprCartSkippedItem] = []
    total_added: int = 0
    total_failed: int = 0
    total_skipped: int = 0
    error: str | None = None


class AddToCartRequest(BaseModel):
    product_id: str
    quantity: int = Field(default=1, ge=1, le=99)


class CartAddBatchItem(BaseModel):
    product_id: str
    quantity: int = Field(default=1, ge=1, le=99)


class CartAddBatchRequest(BaseModel):
    items: list[CartAddBatchItem]


class CartAddBatchResponse(BaseModel):
    success: bool = True
    added: int = 0


class KnusprStatusResponse(BaseModel):
    available: bool
    configured: bool
    message: str | None = None


class PreviewMatchProduct(BaseModel):
    product_id: str
    name: str
    price: float | None = None
    unit: str | None = None
    available: bool = True
    favourite: bool = False


class PreviewListLine(BaseModel):
    shopping_item_id: int
    item_name: str
    quantity: int = 1
    matches: list[PreviewMatchProduct] = []


class PreviewShoppingListResponse(BaseModel):
    shopping_list_id: int
    lines: list[PreviewListLine] = []


class ApplySelectionItem(BaseModel):
    item_name: str
    product_id: str
    quantity: int = Field(default=1, ge=1, le=99)
    product_name: str | None = None
    shopping_item_id: int | None = None


class ApplySelectionsRequest(BaseModel):
    selections: list[ApplySelectionItem]


class PriceCheckItem(BaseModel):
    name: str
    shopping_item_id: int | None = None


class PriceCheckRequest(BaseModel):
    items: list[PriceCheckItem]


class PriceCheckLine(BaseModel):
    name: str
    shopping_item_id: int | None = None
    product_id: str | None = None
    product_name: str | None = None
    price: float | None = None
    unit: str | None = None
    found: bool = False


class PriceCheckResponse(BaseModel):
    lines: list[PriceCheckLine] = []
    estimated_total: float | None = None


class BookDeliverySlotRequest(BaseModel):
    slot_id: str


class BookDeliverySlotResponse(BaseModel):
    success: bool
    message: str | None = None


class KnusprMappingResponse(BaseModel):
    id: int
    item_name: str
    knuspr_product_id: str
    knuspr_product_name: str
    use_count: int = 0


class KnusprMappingCreate(BaseModel):
    item_name: str
    knuspr_product_id: str
    knuspr_product_name: str = ""
