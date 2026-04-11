import logging
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_DEFAULT_UPLOAD_DIR = Path(__file__).resolve().parent.parent / "uploads" / "notes"

logger = logging.getLogger("kalender")

_INSECURE_DEFAULT_KEY = "change-me-to-a-random-secret-key"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

    SECRET_KEY: str = _INSECURE_DEFAULT_KEY
    DATABASE_URL: str = "postgresql+asyncpg://kalender:kalender@localhost:5432/kalender"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24h
    ALGORITHM: str = "HS256"

    CORS_ORIGINS: str = "http://localhost:8000,http://localhost:3000"

    COOKIDOO_EMAIL: str = ""
    COOKIDOO_PASSWORD: str = ""
    KNUSPR_EMAIL: str = ""
    KNUSPR_PASSWORD: str = ""

    ANTHROPIC_API_KEY: str = ""
    # Use a stable default model name; can be overridden via .env
    ANTHROPIC_MODEL: str = "claude-3-5-haiku-latest"

    # Note attachments (local filesystem)
    UPLOAD_DIR: str = str(_DEFAULT_UPLOAD_DIR)
    MAX_NOTE_ATTACHMENT_BYTES: int = 10 * 1024 * 1024  # 10 MB

    # Push notifications (Firebase Cloud Messaging)
    # If neither is set, push sending is disabled (no errors; just no pushes).
    FIREBASE_CREDENTIALS_PATH: str = ""
    FIREBASE_CREDENTIALS_JSON: str = ""
    NOTIFICATION_SCHEDULER_ENABLED: bool = True
    NOTIFICATION_CHECK_INTERVAL_SECONDS: int = 30

    # Google OAuth / Sync (optional)
    # If unset, Google login + sync endpoints will return a clear error.
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""

    # Used when exchanging the auth code for tokens. For installed-app flows
    # (Android/iOS) this is typically an empty string.
    GOOGLE_REDIRECT_URI: str = ""

    @field_validator("GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", mode="after")
    @classmethod
    def _strip_google_oauth_fields(cls, v: str) -> str:
        return (v or "").strip()

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]


settings = Settings()

if settings.SECRET_KEY == _INSECURE_DEFAULT_KEY:
    logger.warning(
        "SECRET_KEY is using the insecure default. "
        "Set a proper SECRET_KEY in your .env file for production."
    )
