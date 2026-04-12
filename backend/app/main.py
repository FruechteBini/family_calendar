import logging
import os
import sys
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy import select

def _configure_logging() -> None:
    # Uvicorn configures handlers, but our app logger defaults to WARNING.
    level_name = (os.getenv("LOG_LEVEL") or "INFO").upper()
    level = getattr(logging, level_name, logging.INFO)
    root = logging.getLogger()
    root.setLevel(level)

    app_logger = logging.getLogger("kalender")
    app_logger.setLevel(level)
    app_logger.disabled = False

    # Ensure our app logs always reach stdout inside Docker.
    if not app_logger.handlers:
        handler = logging.StreamHandler(stream=sys.stdout)
        handler.setLevel(level)
        handler.setFormatter(
            logging.Formatter("%(asctime)s %(levelname)s %(name)s | %(message)s")
        )
        app_logger.addHandler(handler)
        app_logger.propagate = False


_configure_logging()

from .config import settings
from .database import Base, async_session, engine
from .models import *  # noqa: F401,F403 – register models
from .models.user import User
from .notification_service import notification_service
from .google_sync_service import GoogleSyncService
from .routers import (
    ai,
    auth,
    categories,
    cookidoo,
    events,
    family_members,
    google_sync,
    knuspr,
    meals,
    note_categories,
    note_tags,
    notes,
    notifications,
    pantry,
    proposals,
    recipe_categories,
    recipe_tags,
    recipes,
    shopping,
    todos,
)

logger = logging.getLogger("kalender")
_google_sync = GoogleSyncService()


def _add_missing_columns(conn):
    """Add columns that were added after initial table creation."""
    from sqlalchemy import text, inspect as sa_inspect
    inspector = sa_inspect(conn)
    columns = {c["name"] for c in inspector.get_columns("recipes")}
    if "instructions" not in columns:
        conn.execute(text("ALTER TABLE recipes ADD COLUMN instructions TEXT"))
        logger.info("Spalte 'instructions' zu recipes hinzugefügt")

    todo_columns = {c["name"] for c in inspector.get_columns("todos")}
    if "created_by_member_id" not in todo_columns:
        conn.execute(
            text(
                """
                ALTER TABLE todos
                ADD COLUMN created_by_member_id INTEGER
                REFERENCES family_members(id)
                ON DELETE SET NULL
                """
            )
        )
        conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_todos_created_by_member_id ON todos (created_by_member_id)"
            )
        )
        logger.info("Spalte 'created_by_member_id' zu todos hinzugefügt")

    if "is_personal" not in todo_columns:
        conn.execute(
            text(
                """
                ALTER TABLE todos
                ADD COLUMN is_personal BOOLEAN NOT NULL DEFAULT FALSE
                """
            )
        )
        logger.info("Spalte 'is_personal' zu todos hinzugefügt")

    # Push notifications: optional notification_level_id for todos
    if "notification_level_id" not in todo_columns:
        conn.execute(
            text(
                """
                ALTER TABLE todos
                ADD COLUMN notification_level_id INTEGER
                REFERENCES notification_levels(id)
                ON DELETE SET NULL
                """
            )
        )
        logger.info("Spalte 'notification_level_id' zu todos hinzugefügt")

    if "sort_order" not in todo_columns:
        conn.execute(
            text(
                """
                ALTER TABLE todos
                ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0
                """
            )
        )
        logger.info("Spalte 'sort_order' zu todos hinzugefügt")

    event_columns = {c["name"] for c in inspector.get_columns("events")}
    if "notification_level_id" not in event_columns:
        conn.execute(
            text(
                """
                ALTER TABLE events
                ADD COLUMN notification_level_id INTEGER
                REFERENCES notification_levels(id)
                ON DELETE SET NULL
                """
            )
        )
        logger.info("Spalte 'notification_level_id' zu events hinzugefügt")

    category_columns = {c["name"] for c in inspector.get_columns("categories")}
    if "position" not in category_columns:
        conn.execute(
            text(
                """
                ALTER TABLE categories
                ADD COLUMN position INTEGER NOT NULL DEFAULT 0
                """
            )
        )
        conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_categories_position ON categories (position)"
            )
        )
        logger.info("Spalte 'position' zu categories hinzugefügt")

    # Existing DBs: recipes table may predate recipe_categories FK (new tables via create_all)
    recipe_columns = {c["name"] for c in inspector.get_columns("recipes")}
    if "recipe_category_id" not in recipe_columns:
        conn.execute(
            text(
                """
                ALTER TABLE recipes
                ADD COLUMN recipe_category_id INTEGER
                REFERENCES recipe_categories(id) ON DELETE SET NULL
                """
            )
        )
        logger.info("Spalte 'recipe_category_id' zu recipes hinzugefügt")

    # Google auth/sync: optional columns on users
    user_columns = {c["name"] for c in inspector.get_columns("users")}
    if "google_id" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN google_id VARCHAR(255)"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ux_users_google_id ON users (google_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_users_google_id ON users (google_id)"))
        logger.info("Spalte 'google_id' zu users hinzugefügt")

    if "google_email" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN google_email VARCHAR(255)"))
        logger.info("Spalte 'google_email' zu users hinzugefügt")

    if "google_access_token" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN google_access_token TEXT"))
        logger.info("Spalte 'google_access_token' zu users hinzugefügt")

    if "google_refresh_token" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN google_refresh_token TEXT"))
        logger.info("Spalte 'google_refresh_token' zu users hinzugefügt")

    if "google_token_expiry" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN google_token_expiry TIMESTAMPTZ"))
        logger.info("Spalte 'google_token_expiry' zu users hinzugefügt")

    if "sync_calendar_enabled" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN sync_calendar_enabled BOOLEAN NOT NULL DEFAULT FALSE"))
        logger.info("Spalte 'sync_calendar_enabled' zu users hinzugefügt")

    if "sync_todos_enabled" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN sync_todos_enabled BOOLEAN NOT NULL DEFAULT FALSE"))
        logger.info("Spalte 'sync_todos_enabled' zu users hinzugefügt")

    if "require_subtodos_complete" not in user_columns:
        conn.execute(
            text(
                "ALTER TABLE users ADD COLUMN require_subtodos_complete BOOLEAN NOT NULL DEFAULT FALSE"
            )
        )
        logger.info("Spalte 'require_subtodos_complete' zu users hinzugefügt")

    if "auto_complete_parent" not in user_columns:
        conn.execute(
            text(
                "ALTER TABLE users ADD COLUMN auto_complete_parent BOOLEAN NOT NULL DEFAULT FALSE"
            )
        )
        logger.info("Spalte 'auto_complete_parent' zu users hinzugefügt")

    if "google_calendar_id" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN google_calendar_id VARCHAR(255) NOT NULL DEFAULT 'primary'"))
        logger.info("Spalte 'google_calendar_id' zu users hinzugefügt")

    if "google_tasklist_id" not in user_columns:
        conn.execute(text("ALTER TABLE users ADD COLUMN google_tasklist_id VARCHAR(255) NOT NULL DEFAULT '@@default@@'"))
        logger.info("Spalte 'google_tasklist_id' zu users hinzugefügt")

    # Google-only users have no password; ORM allows null but legacy DBs may still have NOT NULL.
    hp_col = next((c for c in inspector.get_columns("users") if c["name"] == "hashed_password"), None)
    if hp_col is not None and hp_col.get("nullable") is False:
        conn.execute(text("ALTER TABLE users ALTER COLUMN hashed_password DROP NOT NULL"))
        logger.info("Spalte 'hashed_password' erlaubt NULL (Google-Login)")

    # Google sync mapping tables (create if missing)
    if not inspector.has_table("google_calendar_sync"):
        conn.execute(
            text(
                """
                CREATE TABLE google_calendar_sync (
                    id SERIAL PRIMARY KEY,
                    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
                    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
                    google_calendar_id VARCHAR(255) NOT NULL DEFAULT 'primary',
                    google_event_id VARCHAR(255) NOT NULL,
                    last_synced_at TIMESTAMPTZ NULL,
                    last_local_hash TEXT NULL,
                    last_google_hash TEXT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )
        )
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_google_calendar_sync_family_id ON google_calendar_sync (family_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_google_calendar_sync_user_id ON google_calendar_sync (user_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_google_calendar_sync_event_id ON google_calendar_sync (event_id)"))
        conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS ux_google_calendar_sync_family_user_event ON google_calendar_sync (family_id, user_id, event_id)"
            )
        )
        conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS ux_google_calendar_sync_family_google ON google_calendar_sync (family_id, google_calendar_id, google_event_id)"
            )
        )
        logger.info("Tabelle 'google_calendar_sync' erstellt")

    if not inspector.has_table("google_tasks_sync"):
        conn.execute(
            text(
                """
                CREATE TABLE google_tasks_sync (
                    id SERIAL PRIMARY KEY,
                    family_id INTEGER NOT NULL REFERENCES families(id) ON DELETE CASCADE,
                    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    todo_id INTEGER NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
                    google_tasklist_id VARCHAR(255) NOT NULL,
                    google_task_id VARCHAR(255) NOT NULL,
                    last_synced_at TIMESTAMPTZ NULL,
                    last_local_hash TEXT NULL,
                    last_google_hash TEXT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )
        )
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_google_tasks_sync_family_id ON google_tasks_sync (family_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_google_tasks_sync_user_id ON google_tasks_sync (user_id)"))
        conn.execute(text("CREATE INDEX IF NOT EXISTS ix_google_tasks_sync_todo_id ON google_tasks_sync (todo_id)"))
        conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS ux_google_tasks_sync_family_user_todo ON google_tasks_sync (family_id, user_id, todo_id)"
            )
        )
        conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS ux_google_tasks_sync_family_google ON google_tasks_sync (family_id, google_tasklist_id, google_task_id)"
            )
        )
        logger.info("Tabelle 'google_tasks_sync' erstellt")

    # Google-Sync: früher nur (family_id, event_id) — zweites Familienmitglied mit Sync → 500.
    if inspector.has_table("google_calendar_sync"):
        cal_ix = {i["name"] for i in inspector.get_indexes("google_calendar_sync") if i.get("name")}
        cal_uc = {u["name"] for u in inspector.get_unique_constraints("google_calendar_sync")}
        if "ux_google_calendar_sync_family_event" in cal_ix:
            conn.execute(text("DROP INDEX IF EXISTS ux_google_calendar_sync_family_event"))
            logger.info("Index ux_google_calendar_sync_family_event entfernt (ersetzt durch family+user+event)")
        if "ux_google_calendar_sync_family_event" in cal_uc:
            conn.execute(
                text(
                    "ALTER TABLE google_calendar_sync DROP CONSTRAINT IF EXISTS ux_google_calendar_sync_family_event"
                )
            )
            logger.info("Constraint ux_google_calendar_sync_family_event entfernt")
        if "ux_google_calendar_sync_family_user_event" not in cal_ix and "ux_google_calendar_sync_family_user_event" not in cal_uc:
            conn.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS ux_google_calendar_sync_family_user_event "
                    "ON google_calendar_sync (family_id, user_id, event_id)"
                )
            )
            logger.info("Index ux_google_calendar_sync_family_user_event angelegt")

    if inspector.has_table("google_tasks_sync"):
        todo_ix = {i["name"] for i in inspector.get_indexes("google_tasks_sync") if i.get("name")}
        todo_uc = {u["name"] for u in inspector.get_unique_constraints("google_tasks_sync")}
        if "ux_google_tasks_sync_family_todo" in todo_ix:
            conn.execute(text("DROP INDEX IF EXISTS ux_google_tasks_sync_family_todo"))
            logger.info("Index ux_google_tasks_sync_family_todo entfernt (ersetzt durch family+user+todo)")
        if "ux_google_tasks_sync_family_todo" in todo_uc:
            conn.execute(
                text(
                    "ALTER TABLE google_tasks_sync DROP CONSTRAINT IF EXISTS ux_google_tasks_sync_family_todo"
                )
            )
            logger.info("Constraint ux_google_tasks_sync_family_todo entfernt")
        if "ux_google_tasks_sync_family_user_todo" not in todo_ix and "ux_google_tasks_sync_family_user_todo" not in todo_uc:
            conn.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS ux_google_tasks_sync_family_user_todo "
                    "ON google_tasks_sync (family_id, user_id, todo_id)"
                )
            )
            logger.info("Index ux_google_tasks_sync_family_user_todo angelegt")


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_add_missing_columns)
    logger.info("Datenbank-Tabellen erstellt")

    scheduler: AsyncIOScheduler | None = None
    if settings.NOTIFICATION_SCHEDULER_ENABLED:
        scheduler = AsyncIOScheduler()

        async def _tick():
            async with async_session() as db:
                try:
                    await notification_service.process_due(db)
                    await db.commit()
                except Exception as e:
                    await db.rollback()
                    logger.warning(f"Notification scheduler tick failed: {e}")

        scheduler.add_job(
            _tick,
            "interval",
            seconds=settings.NOTIFICATION_CHECK_INTERVAL_SECONDS,
            max_instances=1,
            coalesce=True,
        )
        scheduler.start()
        logger.info("Notification scheduler started")

        async def _google_sync_tick():
            if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
                return
            async with async_session() as db:
                try:
                    res = await db.execute(
                        select(User).where(
                            (User.sync_calendar_enabled.is_(True)) | (User.sync_todos_enabled.is_(True))
                        )
                    )
                    users = res.scalars().all()
                    for u in users:
                        if not u.google_refresh_token or not u.family_id:
                            continue
                        if u.sync_calendar_enabled:
                            await _google_sync.sync_calendar(
                                user=u,
                                db=db,
                                client_id=settings.GOOGLE_CLIENT_ID,
                                client_secret=settings.GOOGLE_CLIENT_SECRET,
                            )
                        if u.sync_todos_enabled:
                            await _google_sync.sync_tasks(
                                user=u,
                                db=db,
                                client_id=settings.GOOGLE_CLIENT_ID,
                                client_secret=settings.GOOGLE_CLIENT_SECRET,
                            )
                    await db.commit()
                except Exception as e:
                    await db.rollback()
                    logger.warning(f"Google sync scheduler tick failed: {e}")

        scheduler.add_job(
            _google_sync_tick,
            "interval",
            minutes=5,
            max_instances=1,
            coalesce=True,
        )
        logger.info("Google sync scheduler started")
    yield
    if scheduler:
        scheduler.shutdown(wait=False)


app = FastAPI(
    title="Familienkalender API",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ai.router)
app.include_router(auth.router)
app.include_router(google_sync.router)
app.include_router(family_members.router)
app.include_router(categories.router)
app.include_router(recipe_categories.router)
app.include_router(recipe_tags.router)
app.include_router(note_categories.router)
app.include_router(note_tags.router)
app.include_router(notes.router)
app.include_router(events.router)
app.include_router(todos.router)
app.include_router(proposals.router)
app.include_router(recipes.router)
app.include_router(meals.router)
app.include_router(shopping.router)
app.include_router(pantry.router)
app.include_router(cookidoo.router)
app.include_router(knuspr.router)
app.include_router(notifications.router)

static_dir = Path(__file__).parent / "static"
if static_dir.exists():
    app.mount("/", StaticFiles(directory=str(static_dir), html=True), name="static")
