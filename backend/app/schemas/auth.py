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
    google_email: str | None = None
    sync_calendar_enabled: bool = False
    sync_todos_enabled: bool = False
    require_subtodos_complete: bool = False
    auto_complete_parent: bool = False

    model_config = {"from_attributes": True}


class UserPreferencesResponse(BaseModel):
    require_subtodos_complete: bool
    auto_complete_parent: bool


class UserPreferencesUpdate(BaseModel):
    require_subtodos_complete: bool | None = None
    auto_complete_parent: bool | None = None


class GoogleAuthRequest(BaseModel):
    id_token: str
    server_auth_code: str


class GoogleGrantSyncRequest(BaseModel):
    server_auth_code: str
    # optional: the client can indicate which scopes it requested
    calendar: bool = False
    tasks: bool = False
