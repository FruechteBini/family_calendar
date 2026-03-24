from pydantic import BaseModel

from .family import FamilyResponse
from .family_member import FamilyMemberResponse


class SetupRequest(BaseModel):
    username: str
    password: str


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class LinkMemberRequest(BaseModel):
    member_id: int


class UserResponse(BaseModel):
    id: int
    username: str
    family_id: int | None = None
    family: FamilyResponse | None = None
    member_id: int | None = None
    member: FamilyMemberResponse | None = None

    model_config = {"from_attributes": True}
