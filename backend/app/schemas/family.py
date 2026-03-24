from datetime import datetime

from pydantic import BaseModel


class FamilyCreate(BaseModel):
    name: str


class FamilyJoin(BaseModel):
    invite_code: str


class FamilyResponse(BaseModel):
    id: int
    name: str
    invite_code: str
    created_at: datetime

    model_config = {"from_attributes": True}
