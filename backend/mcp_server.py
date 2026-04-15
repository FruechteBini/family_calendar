"""
Familienkalender MCP Server

Exposes calendar, todos, meal planning, shopping, cookidoo and knuspr
functionality as MCP tools and resources for Claude integration.

Transports: stdio and HTTP/SSE (port 8001)
"""

import asyncio
import json
import logging
import os
import sys
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from typing import Any

from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Ensure the backend package is importable
# ---------------------------------------------------------------------------
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import selectinload

# Import models (they register on Base when imported)
from app.database import Base
from app.models.category import Category
from app.models.cooking_history import CookingHistory
from app.models.event import Event
from app.models.family import Family
from app.models.family_member import FamilyMember
from app.models.ingredient import Ingredient
from app.models.meal_plan import MealPlan
from app.models.recipe import Recipe
from app.models.shopping_list import ShoppingItem, ShoppingList
from app.models.todo import Todo
from app.todo_event_binding import apply_event_binding_to_todo

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp_server")

# ---------------------------------------------------------------------------
# Database setup – PostgreSQL
# ---------------------------------------------------------------------------
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://kalender:kalender@localhost:5432/kalender")

engine = create_async_engine(DATABASE_URL, echo=False, pool_size=5, max_overflow=10)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# ---------------------------------------------------------------------------
# Multi-tenancy: all queries are scoped to a single family
# ---------------------------------------------------------------------------
FAMILY_ID = int(os.getenv("MCP_FAMILY_ID", "1"))


async def get_db() -> AsyncSession:
    return async_session()


async def _commit(db: AsyncSession):
    await db.commit()
    await db.close()


async def _close(db: AsyncSession):
    await db.close()


# ---------------------------------------------------------------------------
# Helper: serialise SQLAlchemy models to dicts
# ---------------------------------------------------------------------------

def _dt(v: datetime | date | None) -> str | None:
    if v is None:
        return None
    return v.isoformat()


def _event_dict(e: Event) -> dict:
    rules = []
    if e.recurrence_rules and e.recurrence_rules.strip():
        try:
            raw = json.loads(e.recurrence_rules)
            if isinstance(raw, list):
                rules = raw
        except json.JSONDecodeError:
            pass
    return {
        "id": e.id,
        "title": e.title,
        "description": e.description,
        "start": _dt(e.start),
        "end": _dt(e.end),
        "all_day": e.all_day,
        "color": e.color,
        "category": e.category.name if e.category else None,
        "members": [m.name for m in e.members] if e.members else [],
        "recurrence_rules": rules,
    }


def _todo_dict(t: Todo) -> dict:
    return {
        "id": t.id,
        "title": t.title,
        "description": t.description,
        "priority": t.priority,
        "due_date": _dt(t.due_date),
        "completed": t.completed,
        "completed_at": _dt(t.completed_at),
        "category": t.category.name if t.category else None,
        "event_id": t.event_id,
        "members": [m.name for m in t.members] if t.members else [],
        "subtodos": [
            {"id": s.id, "title": s.title, "completed": s.completed}
            for s in (t.subtodos or [])
        ],
    }


def _recipe_dict(r: Recipe, include_ingredients: bool = True) -> dict:
    d = {
        "id": r.id,
        "title": r.title,
        "source": r.source,
        "servings": r.servings,
        "prep_time_active_minutes": r.prep_time_active_minutes,
        "prep_time_passive_minutes": r.prep_time_passive_minutes,
        "difficulty": r.difficulty,
        "last_cooked_at": _dt(r.last_cooked_at),
        "cook_count": r.cook_count,
        "notes": r.notes,
        "ai_accessible": r.ai_accessible,
    }
    if include_ingredients and r.ingredients:
        d["ingredients"] = [
            {"name": i.name, "amount": i.amount, "unit": i.unit, "category": i.category}
            for i in r.ingredients
        ]
    return d


def _meal_slot_dict(m: MealPlan) -> dict:
    return {
        "id": m.id,
        "plan_date": _dt(m.plan_date),
        "slot": m.slot,
        "recipe": _recipe_dict(m.recipe) if m.recipe else None,
        "servings_planned": m.servings_planned,
    }


def _shopping_item_dict(i: ShoppingItem) -> dict:
    return {
        "id": i.id,
        "name": i.name,
        "amount": i.amount,
        "unit": i.unit,
        "category": i.category,
        "checked": i.checked,
        "source": i.source,
        "recipe_id": i.recipe_id,
    }


# ---------------------------------------------------------------------------
# Helper: resolve family members
# ---------------------------------------------------------------------------
async def _resolve_members(db: AsyncSession, member_ids: list[int]) -> list[FamilyMember]:
    if not member_ids:
        return []
    result = await db.execute(
        select(FamilyMember).where(FamilyMember.id.in_(member_ids), FamilyMember.family_id == FAMILY_ID)
    )
    return list(result.scalars().all())


def _monday_of(d: date) -> date:
    return d - timedelta(days=d.weekday())


# ---------------------------------------------------------------------------
# MCP Server
# ---------------------------------------------------------------------------
mcp = FastMCP(
    "Familienkalender",
    instructions=(
        "Du bist der Assistent für die Familienkalender-App. "
        "Du kannst Termine, To-dos, Essensplanung, Einkaufslisten, "
        "Cookidoo-Rezepte und Knuspr-Bestellungen verwalten. "
        "WICHTIG: Respektiere das ai_accessible-Flag – greife nur auf "
        "Datensätze zu bei denen ai_accessible = TRUE ist."
    ),
)


# ===== KALENDER TOOLS =====

@mcp.tool()
async def get_events(
    date_from: str | None = None,
    date_to: str | None = None,
    category: str | None = None,
) -> str:
    """Termine abrufen. Datumsformat: YYYY-MM-DD oder YYYY-MM-DDTHH:MM:SS.
    Optional nach Kategoriename filtern."""
    db = await get_db()
    try:
        stmt = select(Event).options(
            selectinload(Event.category),
            selectinload(Event.members),
        ).where(Event.family_id == FAMILY_ID)
        if date_from:
            stmt = stmt.where(Event.end >= datetime.fromisoformat(date_from))
        if date_to:
            stmt = stmt.where(Event.start <= datetime.fromisoformat(date_to))
        if category:
            stmt = stmt.where(Event.category.has(Category.name == category))
        stmt = stmt.order_by(Event.start)
        result = await db.execute(stmt)
        events = result.scalars().unique().all()
        return json.dumps([_event_dict(e) for e in events], ensure_ascii=False)
    finally:
        await _close(db)


@mcp.tool()
async def create_event(
    title: str,
    start: str,
    end: str,
    description: str | None = None,
    all_day: bool = False,
    category_id: int | None = None,
    color: str | None = None,
    member_ids: list[int] | None = None,
) -> str:
    """Neuen Termin erstellen. start/end im ISO-Format."""
    db = await get_db()
    try:
        members = await _resolve_members(db, member_ids or [])
        event = Event(
            title=title,
            description=description,
            start=datetime.fromisoformat(start),
            end=datetime.fromisoformat(end),
            all_day=all_day,
            category_id=category_id,
            color=color if color and str(color).strip() else None,
            members=members,
            family_id=FAMILY_ID,
        )
        db.add(event)
        await db.flush()
        await db.refresh(event)
        result = _event_dict(event)
        await _commit(db)
        return json.dumps(result, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def update_event(
    event_id: int,
    title: str | None = None,
    description: str | None = None,
    start: str | None = None,
    end: str | None = None,
    all_day: bool | None = None,
    category_id: int | None = None,
    color: str | None = None,
    member_ids: list[int] | None = None,
) -> str:
    """Bestehenden Termin ändern. Nur übergebene Felder werden aktualisiert."""
    db = await get_db()
    try:
        event = await db.get(Event, event_id, options=[
            selectinload(Event.category), selectinload(Event.members),
        ])
        if not event:
            return json.dumps({"error": "Event nicht gefunden"})
        if title is not None:
            event.title = title
        if description is not None:
            event.description = description
        if start is not None:
            event.start = datetime.fromisoformat(start)
        if end is not None:
            event.end = datetime.fromisoformat(end)
        if all_day is not None:
            event.all_day = all_day
        if category_id is not None:
            event.category_id = category_id
        if color is not None:
            c = str(color).strip()
            event.color = c if c else None
        if member_ids is not None:
            event.members = await _resolve_members(db, member_ids)
        await db.flush()
        await db.refresh(event)
        result = _event_dict(event)
        await _commit(db)
        return json.dumps(result, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def delete_event(event_id: int) -> str:
    """Termin löschen."""
    db = await get_db()
    try:
        event = await db.get(Event, event_id)
        if not event:
            return json.dumps({"error": "Event nicht gefunden"})
        await db.delete(event)
        await _commit(db)
        return json.dumps({"deleted": True, "id": event_id})
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)})


# ===== TODO TOOLS =====

@mcp.tool()
async def get_todos(
    category: str | None = None,
    priority: str | None = None,
    completed: bool | None = None,
) -> str:
    """To-dos abrufen. Optional nach Kategorie (Name), Priorität (low/medium/high)
    und Status filtern."""
    db = await get_db()
    try:
        stmt = select(Todo).options(
            selectinload(Todo.category),
            selectinload(Todo.members),
            selectinload(Todo.subtodos),
        ).where(Todo.parent_id.is_(None), Todo.family_id == FAMILY_ID)
        if completed is not None:
            stmt = stmt.where(Todo.completed == completed)
        if priority:
            stmt = stmt.where(Todo.priority == priority)
        if category:
            stmt = stmt.where(Todo.category.has(Category.name == category))
        stmt = stmt.order_by(Todo.due_date.asc().nulls_last(), Todo.created_at.desc())
        result = await db.execute(stmt)
        todos = result.scalars().unique().all()
        return json.dumps([_todo_dict(t) for t in todos], ensure_ascii=False)
    finally:
        await _close(db)


@mcp.tool()
async def create_todo(
    title: str,
    description: str | None = None,
    priority: str = "medium",
    due_date: str | None = None,
    category_id: int | None = None,
    event_id: int | None = None,
    member_ids: list[int] | None = None,
) -> str:
    """Neues To-do erstellen. Priorität: low/medium/high. due_date: YYYY-MM-DD."""
    db = await get_db()
    try:
        members = await _resolve_members(db, member_ids or [])
        todo = Todo(
            title=title,
            description=description,
            priority=priority,
            due_date=date.fromisoformat(due_date) if due_date else None,
            category_id=category_id,
            event_id=event_id,
            members=members,
            family_id=FAMILY_ID,
        )
        db.add(todo)
        await db.flush()
        await db.refresh(todo)
        result = _todo_dict(todo)
        await _commit(db)
        return json.dumps(result, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def complete_todo(todo_id: int) -> str:
    """To-do als erledigt markieren (Toggle)."""
    db = await get_db()
    try:
        todo = await db.get(Todo, todo_id, options=[
            selectinload(Todo.category), selectinload(Todo.members), selectinload(Todo.subtodos),
        ])
        if not todo:
            return json.dumps({"error": "Todo nicht gefunden"})
        todo.completed = not todo.completed
        todo.completed_at = datetime.now(timezone.utc) if todo.completed else None
        await db.flush()
        await db.refresh(todo)
        result = _todo_dict(todo)
        await _commit(db)
        return json.dumps(result, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def delete_todo(todo_id: int) -> str:
    """To-do löschen."""
    db = await get_db()
    try:
        todo = await db.get(Todo, todo_id)
        if not todo:
            return json.dumps({"error": "Todo nicht gefunden"})
        await db.delete(todo)
        await _commit(db)
        return json.dumps({"deleted": True, "id": todo_id})
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)})


# ===== KOMBINIERTE TOOLS =====

@mcp.tool()
async def get_agenda(date_from: str, date_to: str) -> str:
    """Termine + verknüpfte To-dos für einen Zeitraum abrufen.
    Datumsformat: YYYY-MM-DD oder YYYY-MM-DDTHH:MM:SS."""
    db = await get_db()
    try:
        dt_from = datetime.fromisoformat(date_from)
        dt_to = datetime.fromisoformat(date_to)

        # Events
        stmt = select(Event).options(
            selectinload(Event.category),
            selectinload(Event.members),
            selectinload(Event.todos).selectinload(Todo.category),
        ).where(Event.family_id == FAMILY_ID, Event.end >= dt_from, Event.start <= dt_to).order_by(Event.start)
        result = await db.execute(stmt)
        events = result.scalars().unique().all()

        agenda = []
        for e in events:
            entry = _event_dict(e)
            entry["linked_todos"] = [_todo_dict(t) for t in (e.todos or [])]
            agenda.append(entry)

        # Standalone todos (with due_date in range, no event)
        todo_stmt = select(Todo).options(
            selectinload(Todo.category),
            selectinload(Todo.members),
            selectinload(Todo.subtodos),
        ).where(
            Todo.family_id == FAMILY_ID,
            Todo.parent_id.is_(None),
            Todo.event_id.is_(None),
            Todo.due_date.isnot(None),
            Todo.due_date >= dt_from.date(),
            Todo.due_date <= dt_to.date(),
        ).order_by(Todo.due_date)
        todo_result = await db.execute(todo_stmt)
        standalone_todos = todo_result.scalars().unique().all()

        return json.dumps({
            "events": agenda,
            "standalone_todos": [_todo_dict(t) for t in standalone_todos],
        }, ensure_ascii=False)
    finally:
        await _close(db)


@mcp.tool()
async def get_open_todos_by_category() -> str:
    """Alle offenen To-dos, gruppiert nach Kategorie."""
    db = await get_db()
    try:
        stmt = select(Todo).options(
            selectinload(Todo.category),
            selectinload(Todo.members),
            selectinload(Todo.subtodos),
        ).where(Todo.family_id == FAMILY_ID, Todo.parent_id.is_(None), Todo.completed == False)
        stmt = stmt.order_by(Todo.due_date.asc().nulls_last())
        result = await db.execute(stmt)
        todos = result.scalars().unique().all()

        grouped: dict[str, list] = defaultdict(list)
        for t in todos:
            cat = t.category.name if t.category else "Ohne Kategorie"
            grouped[cat].append(_todo_dict(t))

        return json.dumps(grouped, ensure_ascii=False)
    finally:
        await _close(db)


@mcp.tool()
async def link_todo_to_event(todo_id: int, event_id: int | None) -> str:
    """To-do mit Termin verknüpfen. event_id=null zum Entknüpfen."""
    db = await get_db()
    try:
        todo = await db.get(Todo, todo_id, options=[
            selectinload(Todo.category), selectinload(Todo.members), selectinload(Todo.subtodos),
        ])
        if not todo:
            return json.dumps({"error": "Todo nicht gefunden"})
        if event_id is not None:
            event = await db.get(Event, event_id)
            if not event:
                return json.dumps({"error": "Event nicht gefunden"})
            if event.family_id != todo.family_id:
                return json.dumps({"error": "Termin gehört zu einer anderen Familie"})
            todo.event_id = event_id
            apply_event_binding_to_todo(todo, event)
        else:
            todo.event_id = None
        await db.flush()
        await db.refresh(todo)
        result = _todo_dict(todo)
        await _commit(db)
        return json.dumps(result, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


# ===== ESSENSPLANUNG & KOCHHISTORIE =====

@mcp.tool()
async def get_meal_plan(week: str | None = None) -> str:
    """Wochenplan abrufen. week: YYYY-MM-DD (ein beliebiger Tag der Woche).
    Standard: aktuelle Woche."""
    db = await get_db()
    try:
        d = date.fromisoformat(week) if week else date.today()
        monday = _monday_of(d)
        sunday = monday + timedelta(days=6)

        stmt = (
            select(MealPlan)
            .options(selectinload(MealPlan.recipe).selectinload(Recipe.ingredients))
            .where(and_(MealPlan.family_id == FAMILY_ID, MealPlan.plan_date >= monday, MealPlan.plan_date <= sunday))
            .order_by(MealPlan.plan_date, MealPlan.slot)
        )
        result = await db.execute(stmt)
        slots = result.scalars().unique().all()

        weekday_names = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        days = []
        slot_map = {f"{s.plan_date}_{s.slot}": s for s in slots}

        for i in range(7):
            day = monday + timedelta(days=i)
            lunch = slot_map.get(f"{day}_lunch")
            dinner = slot_map.get(f"{day}_dinner")
            days.append({
                "date": day.isoformat(),
                "weekday": weekday_names[i],
                "lunch": _meal_slot_dict(lunch) if lunch else None,
                "dinner": _meal_slot_dict(dinner) if dinner else None,
            })

        return json.dumps({"week_start": monday.isoformat(), "days": days}, ensure_ascii=False)
    finally:
        await _close(db)


@mcp.tool()
async def set_meal_slot(
    plan_date: str,
    slot: str,
    recipe_id: int,
    servings_planned: int = 4,
) -> str:
    """Slot im Wochenplan mit Rezept befüllen. slot: 'lunch' oder 'dinner'."""
    if slot not in ("lunch", "dinner"):
        return json.dumps({"error": "Slot muss 'lunch' oder 'dinner' sein"})
    db = await get_db()
    try:
        d = date.fromisoformat(plan_date)
        recipe = await db.get(Recipe, recipe_id)
        if not recipe:
            return json.dumps({"error": "Rezept nicht gefunden"})

        stmt = select(MealPlan).where(
            and_(MealPlan.family_id == FAMILY_ID, MealPlan.plan_date == d, MealPlan.slot == slot)
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            existing.recipe_id = recipe_id
            existing.servings_planned = servings_planned
        else:
            meal = MealPlan(
                plan_date=d, slot=slot,
                recipe_id=recipe_id, servings_planned=servings_planned,
                family_id=FAMILY_ID,
            )
            db.add(meal)

        await db.flush()

        # Reload with recipe
        reload_stmt = (
            select(MealPlan)
            .options(selectinload(MealPlan.recipe).selectinload(Recipe.ingredients))
            .where(and_(MealPlan.family_id == FAMILY_ID, MealPlan.plan_date == d, MealPlan.slot == slot))
        )
        reload_result = await db.execute(reload_stmt)
        meal_obj = reload_result.scalar_one()
        result_dict = _meal_slot_dict(meal_obj)
        await _commit(db)
        return json.dumps(result_dict, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def mark_as_cooked(
    plan_date: str,
    slot: str,
    rating: int | None = None,
    notes: str | None = None,
    servings_cooked: int | None = None,
) -> str:
    """Slot als gekocht markieren. Erstellt cooking_history-Eintrag und
    aktualisiert Rezept-Statistiken. rating: 1-5 Sterne (optional)."""
    if slot not in ("lunch", "dinner"):
        return json.dumps({"error": "Slot muss 'lunch' oder 'dinner' sein"})
    db = await get_db()
    try:
        d = date.fromisoformat(plan_date)
        stmt = (
            select(MealPlan)
            .options(selectinload(MealPlan.recipe))
            .where(and_(MealPlan.family_id == FAMILY_ID, MealPlan.plan_date == d, MealPlan.slot == slot))
        )
        result = await db.execute(stmt)
        meal = result.scalar_one_or_none()
        if not meal:
            return json.dumps({"error": "Kein Eintrag für diesen Slot"})

        now = datetime.now(timezone.utc)
        servings = servings_cooked or meal.servings_planned

        history = CookingHistory(
            recipe_id=meal.recipe_id,
            cooked_at=now,
            servings_cooked=servings,
            rating=rating,
            notes=notes,
        )
        db.add(history)

        recipe = await db.get(Recipe, meal.recipe_id)
        if recipe:
            recipe.last_cooked_at = now
            recipe.cook_count = (recipe.cook_count or 0) + 1

        await db.flush()
        await _commit(db)
        return json.dumps({
            "marked_cooked": True,
            "recipe": recipe.title if recipe else None,
            "rating": rating,
            "cook_count": recipe.cook_count if recipe else None,
        }, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def get_cooking_history(recipe_id: int) -> str:
    """Kochhistorie eines Rezepts abrufen."""
    db = await get_db()
    try:
        recipe = await db.get(Recipe, recipe_id)
        if not recipe:
            return json.dumps({"error": "Rezept nicht gefunden"})

        stmt = (
            select(CookingHistory)
            .where(CookingHistory.recipe_id == recipe_id)
            .order_by(CookingHistory.cooked_at.desc())
        )
        result = await db.execute(stmt)
        entries = result.scalars().all()

        return json.dumps({
            "recipe": recipe.title,
            "total_cook_count": recipe.cook_count,
            "last_cooked_at": _dt(recipe.last_cooked_at),
            "history": [
                {
                    "id": h.id,
                    "cooked_at": _dt(h.cooked_at),
                    "servings_cooked": h.servings_cooked,
                    "rating": h.rating,
                    "notes": h.notes,
                }
                for h in entries
            ],
        }, ensure_ascii=False)
    finally:
        await _close(db)


@mcp.tool()
async def get_recipe_suggestions(
    max_prep_time_minutes: int | None = None,
    exclude_cooked_within_days: int | None = None,
    difficulty: str | None = None,
    limit: int = 10,
) -> str:
    """Rezeptvorschläge basierend auf Kochhistorie.
    Bevorzugt Rezepte die lange nicht gekocht wurden und selten vorkommen.
    difficulty: easy/medium/hard. Nur ai_accessible Rezepte."""
    db = await get_db()
    try:
        stmt = select(Recipe).where(Recipe.family_id == FAMILY_ID, Recipe.ai_accessible.is_(True))

        if max_prep_time_minutes is not None:
            stmt = stmt.where(
                (Recipe.prep_time_active_minutes.isnot(None))
                & (Recipe.prep_time_active_minutes <= max_prep_time_minutes)
            )
        if difficulty:
            stmt = stmt.where(Recipe.difficulty == difficulty)
        if exclude_cooked_within_days is not None:
            cutoff = datetime.now(timezone.utc) - timedelta(days=exclude_cooked_within_days)
            stmt = stmt.where(
                (Recipe.last_cooked_at.is_(None)) | (Recipe.last_cooked_at < cutoff)
            )

        stmt = stmt.order_by(
            Recipe.last_cooked_at.asc().nullsfirst(),
            Recipe.cook_count.asc(),
        ).limit(limit)

        result = await db.execute(stmt)
        recipes = result.scalars().all()

        now = datetime.now(timezone.utc)
        suggestions = []
        for r in recipes:
            days_since = None
            if r.last_cooked_at:
                lc = r.last_cooked_at
                if lc.tzinfo is None:
                    lc = lc.replace(tzinfo=timezone.utc)
                days_since = (now - lc).days
            suggestions.append({
                "id": r.id,
                "title": r.title,
                "difficulty": r.difficulty,
                "prep_time_active_minutes": r.prep_time_active_minutes,
                "prep_time_passive_minutes": r.prep_time_passive_minutes,
                "last_cooked_at": _dt(r.last_cooked_at),
                "cook_count": r.cook_count,
                "days_since_cooked": days_since,
                "servings": r.servings,
            })

        return json.dumps(suggestions, ensure_ascii=False)
    finally:
        await _close(db)


# ===== EINKAUF =====

@mcp.tool()
async def get_shopping_list() -> str:
    """Aktuelle Einkaufsliste abrufen. Nur ai_accessible Items."""
    db = await get_db()
    try:
        stmt = (
            select(ShoppingList)
            .options(selectinload(ShoppingList.items))
            .where(ShoppingList.family_id == FAMILY_ID, ShoppingList.status == "active")
            .order_by(ShoppingList.created_at.desc())
            .limit(1)
        )
        result = await db.execute(stmt)
        sl = result.scalar_one_or_none()
        if not sl:
            return json.dumps({"message": "Keine aktive Einkaufsliste"})

        items = [_shopping_item_dict(i) for i in sl.items if i.ai_accessible]
        # Group by category
        grouped: dict[str, list] = defaultdict(list)
        for item in items:
            grouped[item["category"]].append(item)

        return json.dumps({
            "id": sl.id,
            "week_start_date": _dt(sl.week_start_date),
            "status": sl.status,
            "items_by_category": grouped,
            "total_items": len(items),
            "checked_items": sum(1 for i in items if i["checked"]),
        }, ensure_ascii=False)
    finally:
        await _close(db)


@mcp.tool()
async def generate_shopping_list(week_start: str) -> str:
    """Einkaufsliste aus Wochenplan generieren (konsolidierte Zutaten).
    week_start: YYYY-MM-DD (Montag der Woche)."""
    db = await get_db()
    try:
        monday = date.fromisoformat(week_start)
        sunday = monday + timedelta(days=6)

        stmt = (
            select(MealPlan)
            .options(selectinload(MealPlan.recipe).selectinload(Recipe.ingredients))
            .where(and_(MealPlan.family_id == FAMILY_ID, MealPlan.plan_date >= monday, MealPlan.plan_date <= sunday))
        )
        result = await db.execute(stmt)
        meals = result.scalars().unique().all()

        if not meals:
            return json.dumps({"error": "Keine Mahlzeiten im Wochenplan für diese Woche"})

        # Archive old active lists
        old_stmt = select(ShoppingList).where(ShoppingList.family_id == FAMILY_ID, ShoppingList.status == "active")
        old_result = await db.execute(old_stmt)
        for old in old_result.scalars().all():
            old.status = "archived"

        # Consolidate ingredients
        consolidated: dict[str, dict] = {}
        for meal in meals:
            ratio = meal.servings_planned / meal.recipe.servings if meal.recipe.servings else 1
            for ing in meal.recipe.ingredients:
                key = f"{ing.name.lower().strip()}_{ing.unit or ''}"
                if key in consolidated:
                    if ing.amount and consolidated[key]["amount"]:
                        consolidated[key]["amount"] = str(
                            round(float(consolidated[key]["amount"]) + ing.amount * ratio, 2)
                        )
                    elif ing.amount:
                        consolidated[key]["amount"] = str(round(ing.amount * ratio, 2))
                else:
                    consolidated[key] = {
                        "name": ing.name,
                        "amount": str(round(ing.amount * ratio, 2)) if ing.amount else None,
                        "unit": ing.unit,
                        "category": ing.category,
                        "recipe_id": meal.recipe_id,
                    }

        shopping_list = ShoppingList(week_start_date=monday, status="active", family_id=FAMILY_ID)
        for item_data in consolidated.values():
            shopping_list.items.append(ShoppingItem(
                name=item_data["name"],
                amount=item_data["amount"],
                unit=item_data["unit"],
                category=item_data["category"],
                source="recipe",
                recipe_id=item_data["recipe_id"],
            ))
        db.add(shopping_list)
        await db.flush()
        await db.refresh(shopping_list)

        items = [_shopping_item_dict(i) for i in shopping_list.items]
        result_dict = {
            "id": shopping_list.id,
            "week_start_date": monday.isoformat(),
            "items": items,
            "total_items": len(items),
        }
        await _commit(db)
        return json.dumps(result_dict, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def add_shopping_item(
    name: str,
    amount: str | None = None,
    unit: str | None = None,
    category: str = "sonstiges",
) -> str:
    """Manuell einen Artikel zur aktiven Einkaufsliste hinzufügen.
    category: kuehlregal/obst_gemuese/trockenware/drogerie/sonstiges."""
    db = await get_db()
    try:
        stmt = (
            select(ShoppingList)
            .where(ShoppingList.family_id == FAMILY_ID, ShoppingList.status == "active")
            .order_by(ShoppingList.created_at.desc())
            .limit(1)
        )
        result = await db.execute(stmt)
        sl = result.scalar_one_or_none()
        if not sl:
            sl = ShoppingList(week_start_date=date.today(), status="active", family_id=FAMILY_ID)
            db.add(sl)
            await db.flush()

        item = ShoppingItem(
            shopping_list_id=sl.id,
            name=name,
            amount=amount,
            unit=unit,
            category=category,
            source="manual",
        )
        db.add(item)
        await db.flush()
        await db.refresh(item)
        result_dict = _shopping_item_dict(item)
        await _commit(db)
        return json.dumps(result_dict, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


@mcp.tool()
async def check_shopping_item(item_id: int) -> str:
    """Artikel auf der Einkaufsliste abhaken (Toggle)."""
    db = await get_db()
    try:
        item = await db.get(ShoppingItem, item_id)
        if not item:
            return json.dumps({"error": "Artikel nicht gefunden"})
        item.checked = not item.checked
        await db.flush()
        await db.refresh(item)
        result_dict = _shopping_item_dict(item)
        await _commit(db)
        return json.dumps(result_dict, ensure_ascii=False)
    except Exception as exc:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(exc)}, ensure_ascii=False)


# ===== COOKIDOO =====

@mcp.tool()
async def get_cookidoo_recipe(cookidoo_id: str) -> str:
    """Rezept mit Zutaten von Cookidoo laden."""
    try:
        from integrations.cookidoo.client import get_recipe_detail
        detail = await get_recipe_detail(cookidoo_id)
        if not detail:
            return json.dumps({"error": "Rezept nicht gefunden bei Cookidoo"})
        return json.dumps(detail, ensure_ascii=False, default=str)
    except ImportError:
        return json.dumps({"error": "Cookidoo-Bridge nicht installiert"})
    except Exception as e:
        return json.dumps({"error": str(e)})


@mcp.tool()
async def import_recipe_to_plan(cookidoo_id: str) -> str:
    """Cookidoo-Rezept in die lokale Datenbank importieren."""
    db = await get_db()
    try:
        from integrations.cookidoo.importer import import_recipe
        recipe = await import_recipe(cookidoo_id, db)
        if not recipe:
            return json.dumps({"error": "Rezept konnte nicht importiert werden"})
        await db.refresh(recipe, attribute_names=["ingredients"])
        result = _recipe_dict(recipe)
        await _commit(db)
        return json.dumps(result, ensure_ascii=False)
    except ImportError:
        await _close(db)
        return json.dumps({"error": "Cookidoo-Bridge nicht installiert"})
    except Exception as e:
        await db.rollback()
        await _close(db)
        return json.dumps({"error": str(e)})


@mcp.tool()
async def sync_cookidoo_week(week: str) -> str:
    """Cookidoo-Wochenplan importieren. week: YYYY-MM-DD."""
    try:
        from integrations.cookidoo.client import get_calendar_week
        d = date.fromisoformat(week)
        days = await get_calendar_week(d)
        return json.dumps(days, ensure_ascii=False, default=str)
    except ImportError:
        return json.dumps({"error": "Cookidoo-Bridge nicht installiert"})
    except Exception as e:
        return json.dumps({"error": str(e)})


# ===== KNUSPR =====

@mcp.tool()
async def search_knuspr_product(query: str) -> str:
    """Produkt bei Knuspr suchen."""
    try:
        from integrations.knuspr.client import search_products
        results = await search_products(query)
        if not results:
            return json.dumps({"error": "Keine Produkte gefunden oder Knuspr nicht verfügbar"})
        return json.dumps(results, ensure_ascii=False, default=str)
    except ImportError:
        return json.dumps({"error": "Knuspr-Bridge nicht installiert"})
    except Exception as e:
        return json.dumps({"error": str(e)})


@mcp.tool()
async def add_to_knuspr_cart(product_id: str, quantity: int = 1) -> str:
    """Produkt in den Knuspr-Warenkorb legen."""
    try:
        from integrations.knuspr.client import add_to_cart

        await add_to_cart(product_id, quantity=quantity)
        return json.dumps({"success": True, "product_id": product_id, "quantity": quantity})
    except ImportError:
        return json.dumps({"error": "Knuspr-Bridge nicht installiert"})
    except Exception as e:
        return json.dumps({"error": str(e)})


@mcp.tool()
async def send_shopping_list_to_knuspr(shopping_list_id: int) -> str:
    """Nicht abgehakte Artikel mit lieferbarem Knuspr-Suchtreffer „Favorit“ in den Warenkorb legen; Rest bleibt auf der Liste."""
    db = await get_db()
    try:
        from integrations.knuspr.cart import send_list_to_cart
        result = await send_list_to_cart(shopping_list_id, db)
        await _commit(db)
        return json.dumps(result, ensure_ascii=False, default=str)
    except ImportError:
        await _close(db)
        return json.dumps({"error": "Knuspr-Bridge nicht installiert"})
    except Exception as e:
        await _close(db)
        return json.dumps({"error": str(e)})


@mcp.tool()
async def get_knuspr_delivery_slots() -> str:
    """Verfügbare Knuspr-Lieferslots abrufen."""
    try:
        from integrations.knuspr.client import get_delivery_slots
        slots = await get_delivery_slots()
        return json.dumps(slots, ensure_ascii=False, default=str)
    except ImportError:
        return json.dumps({"error": "Knuspr-Bridge nicht installiert"})
    except Exception as e:
        return json.dumps({"error": str(e)})


@mcp.tool()
async def clear_knuspr_cart() -> str:
    """Knuspr-Warenkorb leeren."""
    try:
        from integrations.knuspr.client import clear_cart

        await clear_cart()
        return json.dumps({"success": True, "message": "Warenkorb geleert"})
    except ImportError:
        return json.dumps({"error": "Knuspr-Bridge nicht installiert"})
    except Exception as e:
        return json.dumps({"error": str(e)})


# ===== MCP RESOURCES =====

@mcp.resource("calendar://today")
async def resource_today() -> str:
    """Heutiger Tag komplett: Termine + To-dos."""
    today = date.today()
    return await get_agenda(today.isoformat(), today.isoformat())


@mcp.resource("calendar://week")
async def resource_week() -> str:
    """Aktuelle Woche: Termine + To-dos."""
    today = date.today()
    monday = _monday_of(today)
    sunday = monday + timedelta(days=6)
    return await get_agenda(monday.isoformat(), sunday.isoformat())


@mcp.resource("todos://open")
async def resource_open_todos() -> str:
    """Alle offenen To-dos."""
    return await get_todos(completed=False)


@mcp.resource("todos://high-priority")
async def resource_high_priority() -> str:
    """Nur To-dos mit Priorität 'high'."""
    return await get_todos(priority="high", completed=False)


@mcp.resource("shopping://current-list")
async def resource_shopping_list() -> str:
    """Aktuelle Einkaufsliste."""
    return await get_shopping_list()


@mcp.resource("shopping://week-plan")
async def resource_shopping_week_plan() -> str:
    """Wochenplan Einkauf: Meals + generierte Einkaufsliste."""
    meal_plan = await get_meal_plan()
    shopping = await get_shopping_list()
    return json.dumps({
        "meal_plan": json.loads(meal_plan),
        "shopping_list": json.loads(shopping),
    }, ensure_ascii=False)


@mcp.resource("recipes://suggestions")
async def resource_recipe_suggestions() -> str:
    """Top 5 Rezepte die am längsten nicht gekocht wurden, gewichtet nach cook_count."""
    return await get_recipe_suggestions(limit=5)


@mcp.resource("recipes://history")
async def resource_cooking_history_90d() -> str:
    """Kochhistorie der letzten 90 Tage."""
    db = await get_db()
    try:
        cutoff = datetime.now(timezone.utc) - timedelta(days=90)
        stmt = (
            select(CookingHistory)
            .where(CookingHistory.cooked_at >= cutoff)
            .order_by(CookingHistory.cooked_at.desc())
        )
        result = await db.execute(stmt)
        entries = result.scalars().all()

        # Enrich with recipe titles
        recipe_ids = {h.recipe_id for h in entries}
        recipes_map = {}
        if recipe_ids:
            r_stmt = select(Recipe).where(Recipe.id.in_(recipe_ids), Recipe.family_id == FAMILY_ID)
            r_result = await db.execute(r_stmt)
            for r in r_result.scalars().all():
                recipes_map[r.id] = r.title

        history = [
            {
                "id": h.id,
                "recipe_id": h.recipe_id,
                "recipe_title": recipes_map.get(h.recipe_id, "Unbekannt"),
                "cooked_at": _dt(h.cooked_at),
                "servings_cooked": h.servings_cooked,
                "rating": h.rating,
                "notes": h.notes,
            }
            for h in entries
        ]
        return json.dumps(history, ensure_ascii=False)
    finally:
        await _close(db)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    transport = os.getenv("MCP_TRANSPORT", "stdio")
    if transport == "sse":
        import uvicorn
        from starlette.middleware.base import BaseHTTPMiddleware
        from starlette.requests import Request
        from starlette.responses import Response

        MCP_API_KEY = os.getenv("MCP_API_KEY", "")

        class ApiKeyMiddleware(BaseHTTPMiddleware):
            async def dispatch(self, request: Request, call_next):
                if MCP_API_KEY:
                    token = request.headers.get("Authorization", "")
                    key = request.query_params.get("api_key", "")
                    if token != f"Bearer {MCP_API_KEY}" and key != MCP_API_KEY:
                        return Response("Unauthorized", status_code=401)
                return await call_next(request)

        app = mcp.sse_app()
        app.add_middleware(ApiKeyMiddleware)

        port = int(os.getenv("MCP_PORT", "8001"))
        uvicorn.run(app, host="0.0.0.0", port=port)
    else:
        mcp.run(transport="stdio")