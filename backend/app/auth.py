import logging
from datetime import timedelta

import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .config import settings
from .database import get_db, utcnow
from .models.user import User

logger = logging.getLogger("kalender")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


def create_access_token(subject: str) -> str:
    expire = utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": subject, "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    logger.info(f"[AUTH] get_current_user called, token length={len(token) if token else 0}")
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token ungueltig oder abgelaufen",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str | None = payload.get("sub")
        logger.info(f"[AUTH] Token decoded, sub={username}")
        if username is None:
            logger.warning("[AUTH] No sub in token")
            raise credentials_exception
    except JWTError as e:
        logger.warning(f"[AUTH] JWT decode error: {e}")
        raise credentials_exception

    result = await db.execute(select(User).where(User.username == username))
    user = result.scalar_one_or_none()
    if user is None:
        logger.warning(f"[AUTH] User '{username}' not found in DB")
        raise credentials_exception
    logger.info(f"[AUTH] User '{username}' authenticated (family_id={user.family_id})")
    return user


def require_family_id(user: User = Depends(get_current_user)) -> int:
    """Dependency that extracts and validates the user's family_id.

    Raises 403 if the user has not joined a family yet.
    """
    if user.family_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Du musst zuerst einer Familie beitreten oder eine erstellen.",
        )
    return user.family_id
