import logging
import re
from urllib.parse import quote, urlencode

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token as google_id_token
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)
from ..config import settings
from ..database import get_db
from ..models.category import Category
from ..models.family import Family
from ..models.family_member import FamilyMember
from ..models.user import User
from ..schemas.auth import (
    GoogleAuthRequest,
    GoogleGrantSyncRequest,
    LinkMemberRequest,
    LoginRequest,
    SetupRequest,
    TokenResponse,
    UserPreferencesResponse,
    UserPreferencesUpdate,
    UserResponse,
)
from ..schemas.family import FamilyCreate, FamilyJoin, FamilyResponse

logger = logging.getLogger("kalender")

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
    if not user or not user.hashed_password or not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Benutzername oder Passwort falsch",
        )
    token = create_access_token(user.username)
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
async def me(user: User = Depends(get_current_user)):
    return user


@router.get("/preferences", response_model=UserPreferencesResponse)
async def get_preferences(user: User = Depends(get_current_user)):
    return UserPreferencesResponse(
        require_subtodos_complete=user.require_subtodos_complete,
        auto_complete_parent=user.auto_complete_parent,
    )


@router.patch("/preferences", response_model=UserPreferencesResponse)
async def update_preferences(
    data: UserPreferencesUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.require_subtodos_complete is not None:
        user.require_subtodos_complete = data.require_subtodos_complete
    if data.auto_complete_parent is not None:
        user.auto_complete_parent = data.auto_complete_parent
    await db.flush()
    await db.refresh(user)
    return UserPreferencesResponse(
        require_subtodos_complete=user.require_subtodos_complete,
        auto_complete_parent=user.auto_complete_parent,
    )


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


def _require_google_oauth_config() -> None:
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google-Login ist nicht konfiguriert (GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET fehlen).",
        )


def _slugify_username(raw: str) -> str:
    # Keep compatible with existing username constraints (String(50), unique).
    cleaned = re.sub(r"[^a-zA-Z0-9_.-]+", "_", raw).strip("._-")
    return (cleaned or "user")[:50]


_GOOGLE_TOKEN_URI = "https://oauth2.googleapis.com/token"


def _token_exchange_redirect_uris() -> list[str]:
    """redirect_uri must match how the auth code was issued (varies by platform / Sign-In version)."""
    ru = (settings.GOOGLE_REDIRECT_URI or "").strip()
    if ru:
        return [ru]
    # Standard: leer (Android serverAuthCode + Web-Client). Nur bei redirect_uri_mismatch wird unten
    # nacheinander localhost versucht — niemals nach invalid_grant (Code ist dann oft verbraucht).
    seen: set[str] = set()
    out: list[str] = []
    for candidate in ("", "http://localhost", "http://127.0.0.1"):
        if candidate not in seen:
            seen.add(candidate)
            out.append(candidate)
    return out


def _oauth_token_error_code(resp: httpx.Response) -> str | None:
    try:
        err = resp.json().get("error")
        return str(err) if err else None
    except Exception:
        return None


def _format_token_exchange_error(resp: httpx.Response) -> str:
    detail = "Google-Authentifizierung fehlgeschlagen (Token exchange)."
    raw = (resp.text or "").strip()
    try:
        body = resp.json()
        err = body.get("error")
        desc = body.get("error_description")
        if err or desc:
            # Google liefert oft error_description="Bad Request" — der Code steht in error.
            if desc in (None, "", "Bad Request") and err:
                detail = f"Google Token exchange: {err}"
            elif err and desc and desc != "Bad Request":
                detail = f"Google Token exchange: {err} — {desc}"
            else:
                detail = f"Google Token exchange: {desc or err}"
        elif raw:
            detail = f"Google Token exchange: {raw[:500]}"
    except Exception:
        if raw:
            detail = f"Google Token exchange: {raw[:500]}"
    return detail


def _google_oauth_creds_stripped() -> tuple[str, str]:
    cid = (settings.GOOGLE_CLIENT_ID or "").strip()
    sec = (settings.GOOGLE_CLIENT_SECRET or "").strip()
    return cid, sec


async def _post_token_exchange_httpx(
    client: httpx.AsyncClient, code: str, redirect_uri: str
) -> httpx.Response:
    """RFC 6749 form body; quote_via=quote so '+' and '/' in auth codes are not mangled."""
    cid, sec = _google_oauth_creds_stripped()
    body = urlencode(
        {
            "code": code,
            "client_id": cid,
            "client_secret": sec,
            "grant_type": "authorization_code",
            "redirect_uri": redirect_uri,
        },
        quote_via=quote,
    )
    return await client.post(
        _GOOGLE_TOKEN_URI,
        content=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )


async def _exchange_auth_code(server_auth_code: str) -> dict:
    _require_google_oauth_config()
    code = (server_auth_code or "").strip()
    if not code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google-Authentifizierung: serverAuthCode fehlt oder ist leer.",
        )

    redirect_uris = _token_exchange_redirect_uris()
    last_resp: httpx.Response | None = None
    async with httpx.AsyncClient(timeout=15.0) as client:
        for ru in redirect_uris:
            resp = await _post_token_exchange_httpx(client, code, ru)
            if resp.status_code < 400:
                return resp.json()
            last_resp = resp
            logger.warning(
                "Google oauth2/token failed with redirect_uri=%r HTTP %s body=%r",
                ru,
                resp.status_code,
                (resp.text or "")[:2000],
            )
            # Derselbe Auth-Code darf nur einmal eingelöst werden. Nach invalid_grant (falscher
            # redirect_uri, Timing, …) weiterzuproduzieren erzeugt nur Folge-invalid_grant — typisch
            # beim zweiten Scope-Grant (Kalender nach Todos).
            err_c = _oauth_token_error_code(resp)
            if err_c != "redirect_uri_mismatch":
                break

    assert last_resp is not None
    detail = _format_token_exchange_error(last_resp)
    raw = (last_resp.text or "")
    if "redirect_uri_mismatch" in raw:
        detail += (
            " — In der Google Cloud (OAuth-Client „Webanwendung“) sind nur URIs mit http:// oder https:// erlaubt, "
            "nicht „postmessage“. Trage z. B. http://localhost unter „Autorisierte Weiterleitungs-URIs“ ein und setze "
            "in backend/.env: GOOGLE_REDIRECT_URI=http://localhost"
        )
    elif "invalid_grant" in raw:
        detail += (
            " — Kalender-Grant erneut anstoßen (Schalter aus/an, dann wieder aktivieren), damit ein neuer Code kommt. "
            "Wenn Todos mit leerem GOOGLE_REDIRECT_URI funktionierten: nicht auf http://localhost wechseln — "
            "Redirect muss für alle Grants gleich bleiben."
        )
    elif last_resp.text and "Bad Request" in detail and len(detail) < 120:
        detail = (
            f"{detail} — Prüfe GOOGLE_CLIENT_ID/SECRET (Web-Client), .env ohne Anführungszeichen/Leerzeichen, "
            "und ob der serverAuthCode frisch ist (nicht zweimal verwendet)."
        )
    logger.warning(
        "Google oauth2/token exhausted redirects %r: %s",
        redirect_uris,
        detail,
    )
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
    )


def _verify_google_id_token(id_token: str) -> dict:
    _require_google_oauth_config()
    try:
        payload = google_id_token.verify_oauth2_token(
            id_token, GoogleRequest(), settings.GOOGLE_CLIENT_ID
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google-Authentifizierung fehlgeschlagen (ID token ungültig).",
        )
    return payload


async def _ensure_unique_username(base: str, db: AsyncSession) -> str:
    base = _slugify_username(base)
    # Try base, then base_2, base_3, ...
    candidate = base
    for i in range(0, 100):
        if i > 0:
            suffix = f"_{i+1}"
            candidate = (base[: max(1, 50 - len(suffix))] + suffix)[:50]
        existing = await db.execute(select(User).where(User.username == candidate))
        if not existing.scalar_one_or_none():
            return candidate
    raise HTTPException(status_code=409, detail="Konnte keinen freien Benutzernamen erzeugen.")


@router.post("/google", response_model=TokenResponse)
async def google_login(data: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    payload = _verify_google_id_token(data.id_token)
    google_sub = payload.get("sub")
    email = payload.get("email")
    if not google_sub:
        raise HTTPException(status_code=401, detail="Google-Authentifizierung fehlgeschlagen (sub fehlt).")

    token_json = await _exchange_auth_code(data.server_auth_code)
    access_token = token_json.get("access_token")
    refresh_token = token_json.get("refresh_token")
    expires_in = token_json.get("expires_in")
    if not access_token:
        raise HTTPException(status_code=401, detail="Google-Authentifizierung fehlgeschlagen (access_token fehlt).")

    result = await db.execute(select(User).where(User.google_id == google_sub))
    user = result.scalar_one_or_none()

    if not user:
        # Create a new local user for this Google account.
        base = (email.split("@")[0] if isinstance(email, str) and "@" in email else f"google_{google_sub[:8]}")
        username = await _ensure_unique_username(base, db)
        user = User(username=username, hashed_password=None)
        db.add(user)
        await db.flush()

    user.google_id = google_sub
    user.google_email = email if isinstance(email, str) else None
    user.google_access_token = access_token
    # refresh_token might only be returned on first consent; keep existing if missing
    if refresh_token:
        user.google_refresh_token = refresh_token
    if expires_in is not None:
        try:
            # backend uses timezone-aware utcnow()
            from datetime import timedelta
            from ..database import utcnow

            user.google_token_expiry = utcnow() + timedelta(seconds=int(expires_in))
        except Exception:
            pass
    await db.flush()
    await db.refresh(user)

    token = create_access_token(user.username)
    return TokenResponse(access_token=token)


@router.post("/google/link", response_model=UserResponse)
async def google_link(
    data: GoogleAuthRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    payload = _verify_google_id_token(data.id_token)
    google_sub = payload.get("sub")
    email = payload.get("email")
    if not google_sub:
        raise HTTPException(status_code=401, detail="Google-Authentifizierung fehlgeschlagen (sub fehlt).")

    # Ensure this google_id isn't linked to another user.
    result = await db.execute(select(User).where(User.google_id == google_sub))
    existing = result.scalar_one_or_none()
    if existing and existing.id != user.id:
        raise HTTPException(status_code=409, detail="Dieses Google-Konto ist bereits verknüpft.")

    token_json = await _exchange_auth_code(data.server_auth_code)
    access_token = token_json.get("access_token")
    refresh_token = token_json.get("refresh_token")
    expires_in = token_json.get("expires_in")
    if not access_token:
        raise HTTPException(status_code=401, detail="Google-Authentifizierung fehlgeschlagen (access_token fehlt).")

    user.google_id = google_sub
    user.google_email = email if isinstance(email, str) else None
    user.google_access_token = access_token
    if refresh_token:
        user.google_refresh_token = refresh_token
    if expires_in is not None:
        try:
            from datetime import timedelta
            from ..database import utcnow

            user.google_token_expiry = utcnow() + timedelta(seconds=int(expires_in))
        except Exception:
            pass
    await db.flush()
    await db.refresh(user)
    return user


@router.post("/google/unlink", response_model=UserResponse)
async def google_unlink(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not user.hashed_password:
        raise HTTPException(
            status_code=400,
            detail="Google-Verknüpfung kann nur entfernt werden, wenn ein Passwort gesetzt ist.",
        )
    user.google_id = None
    user.google_email = None
    user.google_access_token = None
    user.google_refresh_token = None
    user.google_token_expiry = None
    user.sync_calendar_enabled = False
    user.sync_todos_enabled = False
    await db.flush()
    await db.refresh(user)
    return user


@router.post("/google/grant-sync", response_model=UserResponse)
async def google_grant_sync(
    data: GoogleGrantSyncRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not user.google_id:
        raise HTTPException(status_code=400, detail="Kein Google-Konto verknüpft.")
    token_json = await _exchange_auth_code(data.server_auth_code)
    access_token = token_json.get("access_token")
    refresh_token = token_json.get("refresh_token")
    expires_in = token_json.get("expires_in")
    if not access_token:
        raise HTTPException(status_code=401, detail="Google-Authentifizierung fehlgeschlagen (access_token fehlt).")
    user.google_access_token = access_token
    if refresh_token:
        user.google_refresh_token = refresh_token
    if expires_in is not None:
        try:
            from datetime import timedelta
            from ..database import utcnow

            user.google_token_expiry = utcnow() + timedelta(seconds=int(expires_in))
        except Exception:
            pass
    await db.flush()
    await db.refresh(user)
    return user
