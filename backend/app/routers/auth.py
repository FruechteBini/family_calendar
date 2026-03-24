from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)
from ..database import get_db
from ..models.category import Category
from ..models.family import Family
from ..models.family_member import FamilyMember
from ..models.user import User
from ..schemas.auth import (
    LinkMemberRequest,
    LoginRequest,
    SetupRequest,
    TokenResponse,
    UserResponse,
)
from ..schemas.family import FamilyCreate, FamilyJoin, FamilyResponse

router = APIRouter(prefix="/api/auth", tags=["auth"])

DEFAULT_CATEGORIES = [
    {"name": "Arbeit", "color": "#0052CC", "icon": "💼"},
    {"name": "Familie", "color": "#00875A", "icon": "👨‍👩‍👧‍👦"},
    {"name": "Gesundheit", "color": "#DE350B", "icon": "❤️"},
    {"name": "Einkauf", "color": "#FF8B00", "icon": "🛒"},
    {"name": "Sonstiges", "color": "#6B778C", "icon": "📌"},
]


async def _seed_categories_for_family(family_id: int, db: AsyncSession) -> None:
    for cat in DEFAULT_CATEGORIES:
        db.add(Category(family_id=family_id, **cat))


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(data: SetupRequest, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.username == data.username))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Benutzername ist bereits vergeben.",
        )
    user = User(username=data.username, hashed_password=hash_password(data.password))
    db.add(user)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Benutzername ist bereits vergeben.",
        )
    await db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.username == data.username))
    user = result.scalar_one_or_none()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Benutzername oder Passwort falsch",
        )
    token = create_access_token(user.username)
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
async def me(user: User = Depends(get_current_user)):
    return user


@router.patch("/link-member", response_model=UserResponse)
async def link_member(
    data: LinkMemberRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    member = await db.get(FamilyMember, data.member_id)
    if not member:
        raise HTTPException(status_code=404, detail="Familienmitglied nicht gefunden")
    if user.family_id and member.family_id != user.family_id:
        raise HTTPException(status_code=403, detail="Familienmitglied gehoert nicht zu deiner Familie")
    user.member_id = data.member_id
    await db.flush()
    await db.refresh(user)
    return user


@router.post("/family", response_model=FamilyResponse, status_code=status.HTTP_201_CREATED)
async def create_family(
    data: FamilyCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if user.family_id:
        raise HTTPException(status_code=400, detail="Du bist bereits Mitglied einer Familie")
    family = Family(name=data.name)
    db.add(family)
    await db.flush()

    user.family_id = family.id
    await _seed_categories_for_family(family.id, db)
    await db.flush()
    await db.refresh(family)
    return family


@router.post("/family/join", response_model=FamilyResponse)
async def join_family(
    data: FamilyJoin,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if user.family_id:
        raise HTTPException(status_code=400, detail="Du bist bereits Mitglied einer Familie")
    result = await db.execute(
        select(Family).where(Family.invite_code == data.invite_code)
    )
    family = result.scalar_one_or_none()
    if not family:
        raise HTTPException(status_code=404, detail="Ungültiger Einladungscode")
    user.family_id = family.id
    await db.flush()
    await db.refresh(family)
    return family


@router.get("/family", response_model=FamilyResponse)
async def get_family(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not user.family_id:
        raise HTTPException(status_code=404, detail="Keiner Familie zugeordnet")
    family = await db.get(Family, user.family_id)
    if not family:
        raise HTTPException(status_code=404, detail="Familie nicht gefunden")
    return family
