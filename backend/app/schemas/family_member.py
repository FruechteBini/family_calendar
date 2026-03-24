from datetime import datetime

from pydantic import BaseModel


class FamilyMemberCreate(BaseModel):
    name: str
    color: str = "#0052CC"
    avatar_emoji: str = "👤"


class FamilyMemberUpdate(BaseModel):
    name: str | None = None
    color: str | None = None
    avatar_emoji: str | None = None


class FamilyMemberResponse(BaseModel):
    id: int
    name: str
    color: str
    avatar_emoji: str
    created_at: datetime

    model_config = {"from_attributes": True}
