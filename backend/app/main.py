import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .database import Base, engine
from .models import *  # noqa: F401,F403 – register models
from .routers import ai, auth, categories, cookidoo, events, family_members, knuspr, meals, pantry, proposals, recipes, shopping, todos

logger = logging.getLogger("kalender")


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Datenbank-Tabellen erstellt")
    yield


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
app.include_router(family_members.router)
app.include_router(categories.router)
app.include_router(events.router)
app.include_router(todos.router)
app.include_router(proposals.router)
app.include_router(recipes.router)
app.include_router(meals.router)
app.include_router(shopping.router)
app.include_router(pantry.router)
app.include_router(cookidoo.router)
app.include_router(knuspr.router)

static_dir = Path(__file__).parent / "static"
if static_dir.exists():
    app.mount("/", StaticFiles(directory=str(static_dir), html=True), name="static")
