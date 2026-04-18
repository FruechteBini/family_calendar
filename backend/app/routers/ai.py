"""AI-powered meal planning using Claude API with preview/confirm workflow."""

import json
import logging
from datetime import date, datetime, timedelta

import anthropic
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id, require_member_id
from ..config import settings
from ..database import get_db, utcnow
from ..models.meal_plan import MealPlan
from ..models.recipe import Recipe
from ..models.recipe_category import RecipeCategory
from ..models.recipe_tag import RecipeTag
from ..models.category import Category
from ..models.event import Event, event_members
from ..models.family_member import FamilyMember
from ..models.ingredient import Ingredient
from ..models.pantry_item import PantryItem
from ..models.shopping_list import ShoppingItem, ShoppingList
from ..models.todo import Todo, todo_members
from ..schemas.ai import (
    ApplyRecipeCategorizationRequest,
    ApplyRecipeCategorizationResponse,
    ApplyTodoPrioritiesRequest,
    ApplyTodoPrioritiesResponse,
    ConfirmMealPlanRequest,
    ConfirmMealPlanResponse,
    GenerateMealPlanRequest,
    MealSuggestion,
    PreviewMealPlanResponse,
    RecipeCategorizationAssignment,
    RecipeCategorizationPreview,
    RecipeNewCategorySpec,
    RecipeNewTagSpec,
    TodoPrioritizeResponse,
    TodoPrioritization,
    UndoMealPlanRequest,
    VoiceCommandAction,
    VoiceCommandRequest,
    VoiceCommandResponse,
)
from ..utils import ensure_aware, monday_of, normalize_ingredient_name

logger = logging.getLogger("kalender.ai")

router = APIRouter(
    prefix="/api/ai",
    tags=["ai"],
    dependencies=[Depends(get_current_user)],
)

WEEKDAY_NAMES_DE = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]


def _build_recipe_descriptions(
    recipes: list[Recipe],
    now: datetime,
) -> list[str]:
    """Build human-readable recipe descriptions for the Claude prompt."""
    descriptions: list[str] = []
    for r in recipes:
        days_since = None
        if r.last_cooked_at:
            days_since = (now - ensure_aware(r.last_cooked_at)).days

        ingredients_str = ", ".join(
            f"{ing.name}" + (f" ({ing.amount} {ing.unit or ''})" if ing.amount else "")
            for ing in r.ingredients
        )

        last_cooked_str = f"vor {days_since} Tagen" if days_since is not None else "noch nie gekocht"
        descriptions.append(
            f"- [LOKAL] ID {r.id}: \"{r.title}\" | Schwierigkeit: {r.difficulty} | "
            f"Portionen: {r.servings} | Aktive Zeit: {r.prep_time_active_minutes or '?'} min | "
            f"Zuletzt gekocht: {last_cooked_str} (insgesamt {r.cook_count}x) | "
            f"Zutaten: {ingredients_str or 'keine angegeben'}"
        )
    return descriptions


def _build_prompt(
    recipe_descriptions: list[str],
    target_slots: list[dict],
    servings: int,
    preferences: str,
    include_cookidoo: bool,
    cookidoo_lookup: dict[str, str],
) -> str:
    """Assemble the Claude prompt from recipe descriptions and slot data."""
    recipes_text = "\n".join(recipe_descriptions)
    slots_text = "\n".join(f"- {s['day']} ({s['date']}) {s['label']}" for s in target_slots)

    preferences_text = (
        f"\n\nBesondere Wünsche des Nutzers: {preferences}"
        if preferences else ""
    )

    if include_cookidoo and cookidoo_lookup:
        source_instruction = (
            '- Du kannst sowohl LOKALE als auch COOKIDOO Rezepte verwenden\n'
            '- Für lokale Rezepte: "source": "local", "recipe_id": <Integer>\n'
            '- Für Cookidoo Rezepte: "source": "cookidoo", "cookidoo_id": "<String>"\n'
            '- Bevorzuge lokale Rezepte (da Zutaten bekannt), nutze Cookidoo für Abwechslung'
        )
    else:
        source_instruction = '- Verwende NUR lokale Rezept-IDs ("source": "local")'

    return f"""Du bist ein Essensplaner für eine Familie. Erstelle einen Wochenplan für die folgenden freien Slots.

## Verfügbare Rezepte
{recipes_text}

## Freie Slots (diese müssen gefüllt werden)
{slots_text}

## Regeln
{source_instruction}
- Bevorzuge Rezepte, die länger nicht gekocht wurden (Abwechslung!)
- Vermeide das gleiche Rezept mehrfach in einer Woche
- Berücksichtige eine gute Mischung aus einfachen und aufwendigeren Gerichten
- Plane aufwendigere Gerichte eher fürs Wochenende
- Portionen pro Mahlzeit: {servings}{preferences_text}

## Antwort-Format
Antworte AUSSCHLIESSLICH mit einem JSON-Objekt. Keine Erklärung, kein Markdown, nur das JSON.
Das Objekt hat zwei Felder:
- "plan": Ein Array mit den Mahlzeiten. Jedes Element hat: "date" (YYYY-MM-DD), "slot" ("lunch" oder "dinner"), "source" ("local" oder "cookidoo"), "recipe_id" (Integer, nur bei local) ODER "cookidoo_id" (String, nur bei cookidoo), "recipe_title" (String), "servings_planned" (Integer)
- "reasoning": Ein String mit 3-5 Sätzen, der erklärt WARUM du diese Rezepte ausgewählt und so verteilt hast (z.B. Abwechslung, Schwierigkeitsgrad-Verteilung, Nutzerwünsche, lange nicht gekochte Gerichte).

Beispiel:
{{"plan": [{{"date": "2026-03-23", "slot": "lunch", "source": "local", "recipe_id": 5, "recipe_title": "Spaghetti Bolognese", "servings_planned": 4}}], "reasoning": "Ich habe Spaghetti Bolognese gewählt, weil es ein einfaches Gericht ist und schon lange nicht mehr gekocht wurde."}}
"""


async def _call_claude(prompt: str, max_tokens: int = 2000) -> str:
    """Send prompt to Claude and return the raw text response."""
    try:
        client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        response = await client.messages.create(
            model=settings.ANTHROPIC_MODEL,
            max_tokens=max_tokens,
            messages=[{"role": "user", "content": prompt}],
        )
    except anthropic.AuthenticationError:
        raise HTTPException(status_code=503, detail="Ungültiger ANTHROPIC_API_KEY")
    except anthropic.APIError as e:
        logger.error("Claude API error: %s", e)
        raise HTTPException(status_code=502, detail=f"Claude API Fehler: {e}")

    return response.content[0].text.strip()


def _parse_claude_json(raw_text: str) -> tuple[list[dict], str | None]:
    """Strip markdown fences and parse JSON from Claude response."""
    text = raw_text
    if text.startswith("```"):
        lines = text.split("\n")
        lines = [line for line in lines if not line.strip().startswith("```")]
        text = "\n".join(lines).strip()

    try:
        result = json.loads(text)
    except json.JSONDecodeError:
        logger.error("Claude returned invalid JSON: %s", text[:500])
        raise HTTPException(
            status_code=502,
            detail="KI hat ungültiges Format zurückgegeben. Bitte erneut versuchen.",
        )

    reasoning: str | None = None
    if isinstance(result, dict):
        reasoning = result.get("reasoning")
        result = result.get("plan", [])

    if not isinstance(result, list):
        raise HTTPException(status_code=502, detail="KI hat ungültiges Format zurückgegeben.")
    return result, reasoning


def _validate_suggestions(
    plan_items: list[dict],
    valid_recipe_ids: set[int],
    recipe_lookup: dict[int, Recipe],
    cookidoo_lookup: dict[str, str],
    target_slot_keys: set[str],
    default_servings: int,
) -> list[MealSuggestion]:
    """Validate Claude suggestions against known recipes and target slots."""
    suggestions: list[MealSuggestion] = []
    used_slots: set[str] = set()

    for item in plan_items:
        try:
            item_date = item["date"]
            item_slot = item["slot"]
            item_source = item.get("source", "local")
            item_title = item.get("recipe_title", "?")
            item_servings = int(item.get("servings_planned", default_servings))
        except (KeyError, ValueError, TypeError):
            continue

        if item_slot not in ("lunch", "dinner"):
            continue
        slot_key = f"{item_date}_{item_slot}"
        if slot_key not in target_slot_keys or slot_key in used_slots:
            continue

        suggestion = MealSuggestion(
            date=item_date,
            slot=item_slot,
            recipe_title=item_title,
            servings_planned=item_servings,
            source=item_source,
        )

        if item_source == "cookidoo":
            cid = item.get("cookidoo_id")
            if not cid:
                continue
            suggestion.cookidoo_id = cid
            if cid in cookidoo_lookup:
                suggestion.recipe_title = cookidoo_lookup[cid]
        else:
            rid = item.get("recipe_id")
            if not rid or int(rid) not in valid_recipe_ids:
                continue
            rid = int(rid)
            suggestion.recipe_id = rid
            r = recipe_lookup[rid]
            suggestion.recipe_title = r.title
            suggestion.difficulty = r.difficulty
            suggestion.prep_time = r.prep_time_active_minutes

        suggestions.append(suggestion)
        used_slots.add(slot_key)

    return suggestions


# ── Endpoints ────────────────────────────────────────────


@router.get("/available-recipes")
async def available_recipes(
    week_start: date = Query(...),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    """Return recipe counts and slot status for the AI dialog."""
    monday = monday_of(week_start)
    sunday = monday + timedelta(days=6)

    stmt = (
        select(Recipe)
        .where(Recipe.ai_accessible.is_(True), Recipe.family_id == family_id)
        .order_by(Recipe.title)
    )
    result = await db.execute(stmt)
    recipes = result.scalars().all()

    local_recipes = [
        {"id": r.id, "title": r.title, "difficulty": r.difficulty}
        for r in recipes
    ]

    existing_stmt = (
        select(MealPlan)
        .where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date >= monday,
            MealPlan.plan_date <= sunday,
        ))
    )
    existing_result = await db.execute(existing_stmt)
    existing_meals = existing_result.scalars().all()
    filled_set = {f"{m.plan_date}_{m.slot}": m for m in existing_meals}

    filled_slots: list[dict] = []
    empty_slots: list[dict] = []
    for i in range(7):
        d = monday + timedelta(days=i)
        day_name = WEEKDAY_NAMES_DE[i]
        for slot in ["lunch", "dinner"]:
            key = f"{d}_{slot}"
            entry = {
                "date": str(d),
                "day": day_name,
                "slot": slot,
                "label": "Mittag" if slot == "lunch" else "Abend",
            }
            if key in filled_set:
                meal = filled_set[key]
                entry["recipe_title"] = meal.recipe.title if meal.recipe else "?"
                filled_slots.append(entry)
            else:
                empty_slots.append(entry)

    cookidoo_available = False
    cookidoo_count = 0
    try:
        from integrations.cookidoo import client as cookidoo_client
        c = await cookidoo_client.get_client()
        if c:
            cookidoo_available = True
            collections = await cookidoo_client.get_collections()
            for col in collections:
                for ch in col.get("chapters", []):
                    cookidoo_count += len(ch.get("recipes", []))
    except Exception:
        pass

    return {
        "local_count": len(local_recipes),
        "local_recipes": local_recipes,
        "cookidoo_available": cookidoo_available,
        "cookidoo_count": cookidoo_count,
        "filled_slots": filled_slots,
        "empty_slots": empty_slots,
    }


@router.post("/generate-meal-plan", response_model=PreviewMealPlanResponse)
async def generate_meal_plan(
    data: GenerateMealPlanRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    """Generate a meal plan preview via Claude. Does NOT save to DB."""
    if not settings.ANTHROPIC_API_KEY:
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY ist nicht konfiguriert")

    monday = monday_of(data.week_start)
    sunday = monday + timedelta(days=6)

    stmt = (
        select(Recipe)
        .where(Recipe.ai_accessible.is_(True), Recipe.family_id == family_id)
        .options(selectinload(Recipe.ingredients), selectinload(Recipe.history))
        .order_by(Recipe.title)
    )
    result = await db.execute(stmt)
    recipes = result.scalars().unique().all()

    if not recipes and not data.include_cookidoo:
        raise HTTPException(status_code=400, detail="Keine Rezepte vorhanden. Bitte zuerst Rezepte anlegen.")

    recipe_lookup = {r.id: r for r in recipes}

    existing_stmt = (
        select(MealPlan)
        .where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date >= monday,
            MealPlan.plan_date <= sunday,
        ))
    )
    existing_result = await db.execute(existing_stmt)
    existing_meals = existing_result.scalars().all()
    filled_slots = {f"{m.plan_date}_{m.slot}" for m in existing_meals}

    if data.selected_slots:
        target_slots = []
        for s in data.selected_slots:
            key = f"{s.date}_{s.slot}"
            if key in filled_slots:
                continue
            d = date.fromisoformat(s.date)
            day_idx = (d - monday).days
            if 0 <= day_idx <= 6:
                target_slots.append({
                    "date": s.date,
                    "day": WEEKDAY_NAMES_DE[day_idx],
                    "slot": s.slot,
                    "label": "Mittag" if s.slot == "lunch" else "Abend",
                })
    else:
        target_slots = []
        for i in range(7):
            d = monday + timedelta(days=i)
            for slot in ["lunch", "dinner"]:
                key = f"{d}_{slot}"
                if key not in filled_slots:
                    target_slots.append({
                        "date": str(d),
                        "day": WEEKDAY_NAMES_DE[i],
                        "slot": slot,
                        "label": "Mittag" if slot == "lunch" else "Abend",
                    })

    if not target_slots:
        raise HTTPException(status_code=400, detail="Keine freien Slots ausgewählt.")

    now = utcnow()
    recipe_descriptions = _build_recipe_descriptions(recipes, now)

    cookidoo_lookup: dict[str, str] = {}
    if data.include_cookidoo:
        try:
            from integrations.cookidoo import client as cookidoo_client
            c = await cookidoo_client.get_client()
            if c:
                collections = await cookidoo_client.get_collections()
                for col in collections:
                    for ch in col.get("chapters", []):
                        for rec in ch.get("recipes", []):
                            cid = rec["cookidoo_id"]
                            name = rec["name"]
                            cookidoo_lookup[cid] = name
                            recipe_descriptions.append(
                                f'- [COOKIDOO] CID "{cid}": "{name}" | Sammlung: {col["name"]}'
                            )
        except Exception as e:
            logger.warning("Cookidoo fetch for AI failed: %s", e)

    if not recipe_descriptions:
        raise HTTPException(status_code=400, detail="Keine Rezepte verfügbar.")

    prompt = _build_prompt(
        recipe_descriptions, target_slots, data.servings,
        data.preferences, data.include_cookidoo, cookidoo_lookup,
    )

    raw_text = await _call_claude(prompt)
    plan_items, reasoning = _parse_claude_json(raw_text)

    suggestions = _validate_suggestions(
        plan_items,
        valid_recipe_ids={r.id for r in recipes},
        recipe_lookup=recipe_lookup,
        cookidoo_lookup=cookidoo_lookup,
        target_slot_keys={f"{s['date']}_{s['slot']}" for s in target_slots},
        default_servings=data.servings,
    )

    return PreviewMealPlanResponse(suggestions=suggestions, reasoning=reasoning)


@router.post("/confirm-meal-plan", response_model=ConfirmMealPlanResponse)
async def confirm_meal_plan(
    data: ConfirmMealPlanRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    """Save the previewed meal plan to the database."""
    monday = monday_of(data.week_start)
    sunday = monday + timedelta(days=6)

    existing_stmt = (
        select(MealPlan)
        .where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date >= monday,
            MealPlan.plan_date <= sunday,
        ))
    )
    existing_result = await db.execute(existing_stmt)
    existing_meals = existing_result.scalars().all()
    filled_slots = {f"{m.plan_date}_{m.slot}" for m in existing_meals}

    meal_ids: list[int] = []
    meals_created = 0

    for item in data.items:
        slot_key = f"{item.date}_{item.slot}"
        if slot_key in filled_slots:
            continue

        item_date = date.fromisoformat(item.date)
        if item_date < monday or item_date > sunday:
            continue

        recipe_id = item.recipe_id

        if item.source == "cookidoo" and item.cookidoo_id:
            try:
                from integrations.cookidoo.importer import import_recipe
                imported = await import_recipe(item.cookidoo_id, db, family_id)
                if imported:
                    recipe_id = imported.id
                else:
                    logger.warning("Could not import Cookidoo recipe %s", item.cookidoo_id)
                    continue
            except Exception as e:
                logger.warning("Cookidoo import failed for %s: %s", item.cookidoo_id, e)
                continue

        if not recipe_id:
            continue

        meal = MealPlan(
            family_id=family_id,
            plan_date=item_date,
            slot=item.slot,
            recipe_id=recipe_id,
            servings_planned=item.servings_planned,
        )
        db.add(meal)
        await db.flush()
        meal_ids.append(meal.id)
        filled_slots.add(slot_key)
        meals_created += 1

    shopping_generated = False
    shopping_list_id: int | None = None
    knuspr_payload: dict | None = None
    if meals_created > 0:
        try:
            from .shopping import _generate_shopping_list

            sl = await _generate_shopping_list(monday, family_id, db)
            shopping_generated = True
            shopping_list_id = sl.id
        except Exception:
            logger.warning("Auto-Einkaufsliste konnte nicht erstellt werden", exc_info=True)

    if data.send_to_knuspr and shopping_list_id:
        try:
            from integrations.knuspr.cart import send_list_to_cart

            knuspr_payload = await send_list_to_cart(
                shopping_list_id, db, family_id=family_id
            )
        except Exception as e:
            logger.warning("Knuspr nach Essensplan: %s", e)
            knuspr_payload = {"success": False, "error": str(e)}

    return ConfirmMealPlanResponse(
        message=f"{meals_created} Mahlzeiten wurden per KI geplant.",
        meals_created=meals_created,
        meal_ids=meal_ids,
        shopping_list_generated=shopping_generated,
        shopping_list_id=shopping_list_id,
        knuspr=knuspr_payload,
    )


@router.post("/undo-meal-plan")
async def undo_meal_plan(
    data: UndoMealPlanRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    """Remove AI-generated meal plan entries."""
    if not data.meal_ids:
        raise HTTPException(status_code=400, detail="Keine Einträge zum Rückgängigmachen")

    stmt = select(MealPlan).where(
        MealPlan.id.in_(data.meal_ids), MealPlan.family_id == family_id
    )
    result = await db.execute(stmt)
    meals = result.scalars().all()

    deleted = 0
    for meal in meals:
        await db.delete(meal)
        deleted += 1

    return {"message": f"{deleted} Mahlzeiten rückgängig gemacht.", "deleted": deleted}


# ── Voice Command ─────────────────────────────────────────


_MODIFY_KEYWORDS = {
    "verschieb", "verschoben", "aender", "änder", "bearbeit", "aktualisier",
    "umbenennen", "umbenenn", "loesch", "lösch", "entfern", "stornier",
    "absag", "erledigt", "fertig", "abhak", "abgehakt", "gemacht",
    "streich", "weg damit", "nicht mehr", "schon passiert",
    "update", "delete", "edit", "move", "cancel", "done",
}


def _needs_existing_context(text: str) -> bool:
    """Check if the voice command likely references existing items."""
    lower = text.lower()
    return any(kw in lower for kw in _MODIFY_KEYWORDS)


async def _build_voice_context(
    db: AsyncSession, now: datetime, include_existing: bool, family_id: int,
) -> dict:
    """Load context for the voice prompt. Only loads events/todos when needed."""
    members_result = await db.execute(
        select(FamilyMember)
        .where(FamilyMember.family_id == family_id)
        .order_by(FamilyMember.name)
    )
    members = members_result.scalars().all()

    categories_result = await db.execute(
        select(Category)
        .where(Category.family_id == family_id)
        .order_by(Category.name)
    )
    categories = categories_result.scalars().all()

    recipes_result = await db.execute(
        select(Recipe)
        .where(Recipe.family_id == family_id)
        .order_by(Recipe.title)
        .limit(50)
    )
    recipes = recipes_result.scalars().all()

    ctx: dict = {
        "members": [{"id": m.id, "name": m.name} for m in members],
        "categories": [{"id": c.id, "name": c.name, "icon": c.icon} for c in categories],
        "recipes": [{"id": r.id, "title": r.title} for r in recipes],
        "events": [],
        "todos": [],
    }

    if include_existing:
        window_start = now - timedelta(days=7)
        window_end = now + timedelta(days=30)
        events_result = await db.execute(
            select(Event)
            .where(
                Event.family_id == family_id,
                Event.end >= window_start,
                Event.start <= window_end,
            )
            .order_by(Event.start)
            .limit(80)
        )
        events = events_result.scalars().all()

        todos_result = await db.execute(
            select(Todo)
            .where(
                Todo.family_id == family_id,
                Todo.completed.is_(False),
                Todo.parent_id.is_(None),
            )
            .order_by(Todo.created_at.desc())
            .limit(60)
        )
        todos = todos_result.scalars().all()

        def _fmt_dt(dt):
            return dt.strftime("%Y-%m-%d %H:%M") if dt else "?"

        ctx["events"] = [
            {"id": e.id, "title": e.title, "start": _fmt_dt(e.start), "end": _fmt_dt(e.end),
             "members": [m.name for m in e.members]}
            for e in events
        ]
        ctx["todos"] = [
            {"id": t.id, "title": t.title, "priority": t.priority,
             "due_date": str(t.due_date) if t.due_date else None,
             "event_id": t.event_id}
            for t in todos
        ]

    return ctx


def _build_voice_prompt(
    text: str, context: dict, now: datetime, include_existing: bool,
) -> str:
    """Build the system + user prompt for voice command interpretation."""
    today = now.date()
    weekday_idx = today.weekday()
    current_weekday = WEEKDAY_NAMES_DE[weekday_idx]

    members_text = "\n".join(
        f"- ID {m['id']}: {m['name']}" for m in context["members"]
    ) or "Keine Mitglieder vorhanden"

    categories_text = "\n".join(
        f"- ID {c['id']}: {c['icon']} {c['name']}" for c in context["categories"]
    ) or "Keine Kategorien vorhanden"

    recipes_text = "\n".join(
        f"- ID {r['id']}: {r['title']}" for r in context["recipes"]
    ) or "Keine Rezepte vorhanden"

    existing_context_block = ""
    modify_actions_block = ""

    if include_existing:
        events_text = "\n".join(
            f"- ID {e['id']}: \"{e['title']}\" ({e['start']} bis {e['end']})"
            + (f" mit {', '.join(e['members'])}" if e['members'] else "")
            for e in context["events"]
        ) or "Keine Termine vorhanden"

        todos_text = "\n".join(
            f"- ID {t['id']}: \"{t['title']}\" (Prio: {t['priority']}"
            + (f", Fällig: {t['due_date']}" if t['due_date'] else "")
            + (f", Event-ID: {t['event_id']}" if t['event_id'] else "")
            + ")"
            for t in context["todos"]
        ) or "Keine offenen Todos vorhanden"

        existing_context_block = f"""
## Bestehende Termine (zum Bearbeiten/Verschieben/Löschen)
{events_text}

## Offene Todos (zum Bearbeiten/Erledigen/Löschen)
{todos_text}
"""

        modify_actions_block = """
### update_event
Bearbeitet einen bestehenden Kalendereintrag (z.B. verschieben, umbenennen).
Parameter:
- "event_id" (Integer, PFLICHT - verwende ID aus "Bestehende Termine")
- "title" (String, optional)
- "description" (String, optional)
- "start" (ISO-Datetime, optional)
- "end" (ISO-Datetime, optional)
- "all_day" (Boolean, optional)
- "category_id" (Integer, optional)
- "member_ids" (Array von Integers, optional - ERSETZT die aktuelle Zuordnung)

### update_todo
Bearbeitet ein bestehendes Todo (z.B. umbenennen, Priorität ändern, Fälligkeitsdatum setzen).
Parameter:
- "todo_id" (Integer, PFLICHT - verwende ID aus "Offene Todos")
- "title" (String, optional)
- "description" (String, optional)
- "priority" (String: "low", "medium", "high", optional)
- "due_date" (ISO-Datum, optional)
- "category_id" (Integer, optional)
- "event_id" (Integer, optional - mit Event verknüpfen oder null zum Entknüpfen)
- "member_ids" (Array von Integers, optional)

### complete_todo
Markiert ein Todo als erledigt.
Parameter:
- "todo_id" (Integer, PFLICHT - verwende ID aus "Offene Todos")

### delete_event
Löscht einen Kalendereintrag.
Parameter:
- "event_id" (Integer, PFLICHT - verwende ID aus "Bestehende Termine")

### delete_todo
Löscht ein Todo.
Parameter:
- "todo_id" (Integer, PFLICHT - verwende ID aus "Offene Todos")
"""

    return f"""Du bist der Sprachassistent des Familienkalenders. Der Benutzer gibt dir eine gesprochene Anweisung.
Analysiere die Anweisung und erstelle die passenden Aktionen.

## Aktuelles Datum und Zeit
- Heute ist {current_weekday}, der {today.isoformat()}
- Aktuelle Uhrzeit: {now.strftime("%H:%M")}
- Wenn der Nutzer "Montag" sagt, meine den NAECHSTEN Montag (oder heute, falls heute Montag ist).
  Nutze den Wochentag relativ zu heute um das Datum zu berechnen.

## Verfügbare Familienmitglieder
{members_text}

## Verfügbare Kategorien
{categories_text}

## Verfügbare Rezepte (für Essensplanung)
{recipes_text}
{existing_context_block}
## Verfügbare Aktionstypen

### create_event
Erstellt einen einzelnen Kalendereintrag.
Parameter:
- "title" (String, PFLICHT)
- "description" (String, optional)
- "start" (ISO-Datetime "YYYY-MM-DDTHH:MM:SS", PFLICHT)
- "end" (ISO-Datetime, PFLICHT - wenn nicht angegeben, setze 1 Stunde nach start)
- "all_day" (Boolean, optional, default false)
- "category_id" (Integer, optional - verwende ID aus Kategorieliste)
- "member_ids" (Array von Integers, optional - verwende IDs aus Mitgliederliste)

### create_recurring_event
Erstellt einen Serientermin (z.B. wöchentlich, täglich). Das Backend generiert automatisch alle Einzeltermine.
WICHTIG: Verwende diesen Typ IMMER wenn ein wiederkehrender Termin gemeint ist (z.B. "jeden Mittwoch", "täglich", "jeden Monat am 1.").
Parameter:
- "title" (String, PFLICHT)
- "description" (String, optional)
- "start_time" (String "HH:MM", PFLICHT - Uhrzeit des Termins)
- "end_time" (String "HH:MM", optional - default: 1 Stunde nach start_time)
- "frequency" (String: "daily", "weekly", "monthly", PFLICHT)
- "day_of_week" (Integer 0=Montag bis 6=Sonntag, PFLICHT bei "weekly")
- "day_of_month" (Integer 1-31, PFLICHT bei "monthly")
- "start_date" (ISO-Datum "YYYY-MM-DD", PFLICHT - ab wann)
- "end_date" (ISO-Datum "YYYY-MM-DD", PFLICHT - bis wann, inklusive)
- "all_day" (Boolean, optional, default false)
- "category_id" (Integer, optional)
- "member_ids" (Array von Integers, optional)

### create_todo
Erstellt eine Aufgabe.
Parameter:
- "title" (String, PFLICHT)
- "description" (String, optional)
- "priority" (String: "low", "medium", "high", default "medium")
- "due_date" (ISO-Datum "YYYY-MM-DD", optional)
- "category_id" (Integer, optional)
- "event_ref" (String, optional - Referenz auf ein in dieser Anweisung erstelltes Event, z.B. "evt1")
- "event_id" (Integer, optional - ID eines existierenden Events)
- "parent_ref" (String, optional - Referenz auf ein in dieser Anweisung erstelltes Todo, für Sub-Todos)
WICHTIG — Zuordnung (Sprachbefehl): Setze "member_ids" NICHT / lasse es weg. Das Backend weist das Todo
automatisch dem Sprecher zu. Nur wenn der Nutzer ausdrücklich will, dass ALLE betroffen sind
(z.B. "für alle", "ganze Familie", "alle Mitglieder"), weist das Backend alle Familienmitglieder zu.

### create_recipe
Erstellt ein Rezept.
Parameter:
- "title" (String, PFLICHT)
- "servings" (Integer, default 4)
- "prep_time_active_minutes" (Integer, optional)
- "difficulty" (String: "easy", "medium", "hard", default "medium")
- "notes" (String, optional)
- "ingredients" (Array von Objekten mit "name" (String), "amount" (Float, optional), "unit" (String, optional), "category" (String: "kuehlregal", "obst_gemuese", "trockenware", "drogerie", "sonstiges", default "sonstiges"))

### set_meal_slot
Belegt einen Essensplan-Slot.
Parameter:
- "date" (ISO-Datum "YYYY-MM-DD", PFLICHT)
- "slot" ("lunch" oder "dinner", PFLICHT)
- "recipe_id" (Integer, PFLICHT - verwende ID aus Rezeptliste)
- "servings_planned" (Integer, default 4)

### add_shopping_item
Fügt einen Artikel zur Einkaufsliste hinzu.
Parameter:
- "name" (String, PFLICHT)
- "amount" (String, optional, z.B. "500")
- "unit" (String, optional, z.B. "g", "ml", "Stück")
- "category" (String: "kuehlregal", "obst_gemuese", "trockenware", "drogerie", "sonstiges", default "sonstiges")

### add_pantry_items
Fügt Artikel zur Vorratskammer hinzu. Verwende diesen Typ wenn der Nutzer sagt was er im Vorrat/Schrank/Speisekammer hat.
Erkennung: "Wir haben noch...", "Im Vorrat haben wir...", "Auf Lager...", "In der Vorratskammer...", "Daheim haben wir noch..."
Parameter:
- "items" (Array von Objekten, PFLICHT) - jedes mit:
  - "name" (String, PFLICHT - z.B. "Tomaten gehackt")
  - "amount" (Float, optional - z.B. 20)
  - "unit" (String, optional - z.B. "Dosen", "kg", "Stück")
  - "category" (String: "kuehlregal", "obst_gemuese", "trockenware", "drogerie", "sonstiges", default "sonstiges")
  - "expiry_date" (ISO-Datum "YYYY-MM-DD", optional - bei "reicht bis Juni" setze den 1. des Monats, z.B. "2026-06-01")

Beispiel: "Wir haben noch: Salz, Pfeffer, 20 Dosen Tomaten gehackt, Mehl - das reicht ca bis Juni"
-> {{"type": "add_pantry_items", "params": {{"items": [
  {{"name": "Salz", "category": "trockenware"}},
  {{"name": "Pfeffer", "category": "trockenware"}},
  {{"name": "Tomaten gehackt", "amount": 20, "unit": "Dosen", "category": "trockenware"}},
  {{"name": "Mehl", "category": "trockenware", "expiry_date": "2026-06-01"}}
]}}}}

### generate_meal_plan
Erstellt einen kompletten KI-Essensplan für eine Woche. Verwende diesen Typ wenn der Nutzer sagt, er möchte eine Woche (oder mehrere Tage) planen lassen, z.B. "plane mir die Woche", "mach mir einen Essensplan", "was sollen wir diese Woche kochen".
WICHTIG: Dieser Typ generiert den Plan UND speichert ihn direkt. Es wird auch automatisch eine Einkaufsliste erstellt.
Parameter:
- "week_start" (ISO-Datum "YYYY-MM-DD", PFLICHT - der Montag der gewünschten Woche. Wenn der Nutzer "diese Woche" sagt, verwende den aktuellen oder nächsten Montag)
- "servings" (Integer, default 4 - Portionen pro Mahlzeit)
- "preferences" (String, optional - Besondere Wünsche des Nutzers, z.B. "vegetarisch", "ein neues Gericht und eins das wir schon kennen", "schnelle Gerichte unter der Woche")
- "selected_slots" (Array von Objekten mit "date" (YYYY-MM-DD) und "slot" ("lunch" oder "dinner"), optional - wenn leer, werden ALLE freien Slots der Woche geplant. Wenn der Nutzer spezifische Tage/Mahlzeiten nennt, gib nur diese an)

Beispiel: "Plane mir diese Woche, Montag Abend und Mittwoch Mittag soll was Neues sein"
-> {{"type": "generate_meal_plan", "params": {{"week_start": "2026-03-23", "servings": 4, "preferences": "Montag Abend und Mittwoch Mittag sollen neue Gerichte sein, die wir noch nie gekocht haben", "selected_slots": [{{"date": "2026-03-23", "slot": "dinner"}}, {{"date": "2026-03-25", "slot": "lunch"}}]}}}}

Beispiel: "Mach einen Essensplan für die ganze Woche, 3 Portionen, eher einfach"
-> {{"type": "generate_meal_plan", "params": {{"week_start": "2026-03-23", "servings": 3, "preferences": "eher einfache Gerichte bevorzugen", "selected_slots": []}}}}

### send_to_knuspr
Sendet die aktuelle Einkaufsliste an Knuspr (alle nicht abgehakten Artikel werden im Warenkorb ergänzt).
Parameter: leeres Objekt {{}} (keine Pflichtfelder).
Nutze diesen Typ wenn der Nutzer z.B. sagt: "Schick die Liste zu Knuspr", "Bestelle bei Knuspr", "Einkauf an Knuspr senden".
{modify_actions_block}

## Referenz-System

Wenn eine Aktion von einer anderen abhängt (z.B. ein Todo soll mit einem Event verknüpft werden),
verwende das "ref"-Feld als Platzhalter-ID und referenziere es in späteren Aktionen.

Beispiel: Event erstellen und Todos daran linken:
- Aktion 1: create_event mit "ref": "evt1"
- Aktion 2: create_todo mit "event_ref": "evt1" (wird automatisch aufgelöst)

Für Sub-Todos:
- Aktion 1: create_todo mit "ref": "todo1"
- Aktion 2: create_todo mit "parent_ref": "todo1" (wird als Unteraufgabe angelegt)

## Antwort-Format

Antworte AUSSCHLIESSLICH mit einem JSON-Objekt. Kein Markdown, keine Erklärung.
Das Objekt hat:
- "actions": Array von Aktionsobjekten. Jedes hat:
  - "type": Der Aktionstyp (z.B. "create_event")
  - "ref": Optionaler Platzhalter-Name (z.B. "evt1", "todo1")
  - "params": Objekt mit den Parametern der Aktion
- "summary": Ein kurzer deutscher Satz, der zusammenfasst was du gemacht hast (für den Benutzer)

## Beispiel

Eingabe: "Ich habe am Montag um 14 Uhr ein Meeting mit Michi und muss dafür noch Kaffee vorbereiten und das Dokument ausfüllen"

Antwort:
{{"actions": [
  {{"type": "create_event", "ref": "evt1", "params": {{"title": "Meeting mit Michi", "start": "2026-03-23T14:00:00", "end": "2026-03-23T15:00:00", "member_ids": [1]}}}},
  {{"type": "create_todo", "ref": "todo1", "params": {{"title": "Kaffee vorbereiten", "event_ref": "evt1", "due_date": "2026-03-23", "priority": "medium"}}}},
  {{"type": "create_todo", "ref": "todo2", "params": {{"title": "Dokument ausfüllen", "event_ref": "evt1", "due_date": "2026-03-23", "priority": "medium"}}}}
], "summary": "Meeting mit Michi am Montag um 14 Uhr erstellt und 2 Todos (Kaffee vorbereiten, Dokument ausfüllen) verknüpft."}}

## Wichtig
- Löse Wochentage immer zu konkreten Daten auf (basierend auf dem heutigen Datum).
- Wenn keine Uhrzeit genannt wird, nutze 09:00 als Standard für Events.
- Wenn Personen namentlich erwähnt werden, versuche sie den Familienmitgliedern zuzuordnen (auch Teilnamen, z.B. "Michi" -> "Michael").
- Erstelle NUR Aktionen, die sich klar aus der Anweisung ableiten lassen.
- Die "summary" soll freundlich, kurz und auf Deutsch sein.

## Benutzereingabe
"{text}"
"""


def _voice_command_means_family_wide_todo(text: str) -> bool:
    """True when the user explicitly wants a family-wide todo (all members)."""
    t = text.lower()
    phrases = (
        "für alle",
        "fur alle",
        "fuer alle",
        "ganze familie",
        "die ganze familie",
        "ganzen familie",
        "alle mitglieder",
        "alle in der familie",
        "für die ganze familie",
        "fur die ganze familie",
    )
    return any(p in t for p in phrases)


ACTION_TYPE_ORDER = {
    "create_event": 0,
    "create_recurring_event": 0,
    "create_recipe": 1,
    "create_todo": 2,
    "update_event": 3,
    "update_todo": 4,
    "complete_todo": 5,
    "set_meal_slot": 6,
    "generate_meal_plan": 6,
    "add_shopping_item": 7,
    "add_pantry_items": 7,
    "send_to_knuspr": 7,
    "delete_todo": 8,
    "delete_event": 9,
}


async def _execute_voice_actions(
    actions: list[dict],
    db: AsyncSession,
    family_id: int,
    actor_member_id: int,
    voice_assign_family_wide_todos: bool,
) -> list[VoiceCommandAction]:
    """Execute parsed voice actions, resolving cross-references."""
    ref_map: dict[str, int] = {}
    results: list[VoiceCommandAction] = []

    sorted_actions = sorted(actions, key=lambda a: ACTION_TYPE_ORDER.get(a.get("type", ""), 99))

    for action in sorted_actions:
        action_type = action.get("type", "")
        params = action.get("params", {})
        ref = action.get("ref")

        result_data: dict = {}
        try:
            if action_type == "create_event":
                result_data = await _exec_create_event(params, ref_map, db, family_id)
            elif action_type == "create_recurring_event":
                result_data = await _exec_create_recurring_event(params, db, family_id)
            elif action_type == "create_todo":
                result_data = await _exec_create_todo(
                    params,
                    ref_map,
                    db,
                    family_id,
                    actor_member_id,
                    voice_assign_family_wide_todos,
                )
            elif action_type == "create_recipe":
                result_data = await _exec_create_recipe(params, db, family_id)
            elif action_type == "set_meal_slot":
                result_data = await _exec_set_meal_slot(params, db, family_id)
            elif action_type == "add_shopping_item":
                result_data = await _exec_add_shopping_item(params, db, family_id)
            elif action_type == "add_pantry_items":
                result_data = await _exec_add_pantry_items(params, db, family_id)
            elif action_type == "send_to_knuspr":
                result_data = await _exec_send_to_knuspr(db, family_id)
            elif action_type == "generate_meal_plan":
                result_data = await _exec_generate_meal_plan(params, db, family_id)
            elif action_type == "update_event":
                result_data = await _exec_update_event(params, db, family_id)
            elif action_type == "update_todo":
                result_data = await _exec_update_todo(params, db, family_id)
            elif action_type == "complete_todo":
                result_data = await _exec_complete_todo(params, db, family_id)
            elif action_type == "delete_event":
                result_data = await _exec_delete_event(params, db, family_id)
            elif action_type == "delete_todo":
                result_data = await _exec_delete_todo(params, db, family_id)
            else:
                result_data = {"error": f"Unbekannter Aktionstyp: {action_type}"}

            if ref and "id" in result_data:
                ref_map[ref] = result_data["id"]

        except Exception as e:
            logger.error("Voice action %s failed: %s", action_type, e)
            result_data = {"error": str(e)}

        results.append(VoiceCommandAction(
            type=action_type,
            ref=ref,
            params=params,
            result=result_data,
        ))

    return results


async def _exec_create_event(
    params: dict, ref_map: dict[str, int], db: AsyncSession, family_id: int,
) -> dict:
    start_str = params.get("start")
    end_str = params.get("end")
    if not start_str:
        return {"error": "Kein Startdatum angegeben"}

    start = datetime.fromisoformat(start_str)
    end = datetime.fromisoformat(end_str) if end_str else start + timedelta(hours=1)

    event = Event(
        family_id=family_id,
        title=params.get("title", "Ohne Titel"),
        description=params.get("description"),
        start=start,
        end=end,
        all_day=params.get("all_day", False),
        category_id=params.get("category_id"),
    )
    db.add(event)
    await db.flush()

    member_ids = params.get("member_ids", [])
    if member_ids:
        for mid in member_ids:
            await db.execute(event_members.insert().values(event_id=event.id, member_id=mid))

    return {"id": event.id, "title": event.title, "start": str(event.start)}


async def _exec_create_recurring_event(params: dict, db: AsyncSession, family_id: int) -> dict:
    title = params.get("title", "Ohne Titel")
    start_time_str = params.get("start_time", "09:00")
    end_time_str = params.get("end_time")
    frequency = params.get("frequency", "weekly")
    start_date = date.fromisoformat(params.get("start_date", str(date.today())))
    end_date = date.fromisoformat(params.get("end_date", str(date.today())))

    sh, sm = (int(x) for x in start_time_str.split(":"))
    if end_time_str:
        eh, em = (int(x) for x in end_time_str.split(":"))
    else:
        eh, em = sh + 1, sm

    is_all_day = params.get("all_day", False)
    category_id = params.get("category_id")
    member_ids = params.get("member_ids", [])
    description = params.get("description")

    dates: list[date] = []
    current = start_date
    if frequency == "daily":
        while current <= end_date:
            dates.append(current)
            current += timedelta(days=1)
    elif frequency == "weekly":
        target_dow = params.get("day_of_week", start_date.weekday())
        delta = (target_dow - current.weekday()) % 7
        current = current + timedelta(days=delta)
        while current <= end_date:
            dates.append(current)
            current += timedelta(days=7)
    elif frequency == "monthly":
        target_dom = params.get("day_of_month", start_date.day)
        while current <= end_date:
            try:
                candidate = current.replace(day=target_dom)
            except ValueError:
                current = (current.replace(day=1) + timedelta(days=32)).replace(day=1)
                continue
            if candidate >= start_date and candidate <= end_date:
                dates.append(candidate)
            current = (current.replace(day=1) + timedelta(days=32)).replace(day=1)

    if not dates:
        return {"error": "Keine Termine im angegebenen Zeitraum"}

    if len(dates) > 200:
        dates = dates[:200]

    created_ids: list[int] = []
    for d in dates:
        event = Event(
            family_id=family_id,
            title=title,
            description=description,
            start=datetime(d.year, d.month, d.day, sh, sm),
            end=datetime(d.year, d.month, d.day, eh, em),
            all_day=is_all_day,
            category_id=category_id,
        )
        db.add(event)
        await db.flush()
        for mid in member_ids:
            await db.execute(event_members.insert().values(event_id=event.id, member_id=mid))
        created_ids.append(event.id)

    return {
        "id": created_ids[0],
        "title": title,
        "count": len(created_ids),
        "first_date": str(dates[0]),
        "last_date": str(dates[-1]),
    }


async def _exec_create_todo(
    params: dict,
    ref_map: dict[str, int],
    db: AsyncSession,
    family_id: int,
    actor_member_id: int,
    assign_all_members: bool,
) -> dict:
    event_id = params.get("event_id")
    event_ref = params.get("event_ref")
    if event_ref and event_ref in ref_map:
        event_id = ref_map[event_ref]

    parent_id = params.get("parent_id")
    parent_ref = params.get("parent_ref")
    if parent_ref and parent_ref in ref_map:
        parent_id = ref_map[parent_ref]

    due_date_val = None
    if params.get("due_date"):
        due_date_val = date.fromisoformat(params["due_date"])

    todo = Todo(
        family_id=family_id,
        title=params.get("title", "Ohne Titel"),
        description=params.get("description"),
        priority=params.get("priority", "medium"),
        due_date=due_date_val,
        category_id=params.get("category_id"),
        event_id=event_id,
        parent_id=parent_id,
        requires_multiple=params.get("requires_multiple", False),
    )
    db.add(todo)
    await db.flush()

    # Voice: default assign to speaker; only if user said "for everyone" assign all members.
    # Ignore model-supplied member_ids for voice-created todos.
    if assign_all_members:
        r = await db.execute(select(FamilyMember.id).where(FamilyMember.family_id == family_id))
        member_ids = [row[0] for row in r.all()]
    else:
        member_ids = [actor_member_id]
    for mid in member_ids:
        await db.execute(todo_members.insert().values(todo_id=todo.id, member_id=mid))

    return {"id": todo.id, "title": todo.title}


async def _exec_create_recipe(params: dict, db: AsyncSession, family_id: int) -> dict:
    recipe = Recipe(
        family_id=family_id,
        title=params.get("title", "Ohne Titel"),
        servings=params.get("servings", 4),
        prep_time_active_minutes=params.get("prep_time_active_minutes"),
        difficulty=params.get("difficulty", "medium"),
        notes=params.get("notes"),
    )
    db.add(recipe)
    await db.flush()

    for ing_data in params.get("ingredients", []):
        ingredient = Ingredient(
            recipe_id=recipe.id,
            name=ing_data.get("name", "?"),
            amount=ing_data.get("amount"),
            unit=ing_data.get("unit"),
            category=ing_data.get("category", "sonstiges"),
        )
        db.add(ingredient)

    return {"id": recipe.id, "title": recipe.title}


async def _exec_set_meal_slot(params: dict, db: AsyncSession, family_id: int) -> dict:
    plan_date = date.fromisoformat(params["date"])
    slot = params["slot"]
    recipe_id = params["recipe_id"]

    existing = await db.execute(
        select(MealPlan).where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date == plan_date,
            MealPlan.slot == slot,
        ))
    )
    meal = existing.scalars().first()
    if meal:
        meal.recipe_id = recipe_id
        meal.servings_planned = params.get("servings_planned", 4)
    else:
        meal = MealPlan(
            family_id=family_id,
            plan_date=plan_date,
            slot=slot,
            recipe_id=recipe_id,
            servings_planned=params.get("servings_planned", 4),
        )
        db.add(meal)
        await db.flush()

    return {"id": meal.id, "date": str(plan_date), "slot": slot}


async def _exec_add_shopping_item(params: dict, db: AsyncSession, family_id: int) -> dict:
    active_list = await db.execute(
        select(ShoppingList)
        .where(ShoppingList.status == "active", ShoppingList.family_id == family_id)
        .order_by(ShoppingList.created_at.desc())
    )
    shopping_list = active_list.scalars().first()

    if not shopping_list:
        shopping_list = ShoppingList(
            family_id=family_id,
            week_start_date=date.today(),
            status="active",
        )
        db.add(shopping_list)
        await db.flush()

    item = ShoppingItem(
        shopping_list_id=shopping_list.id,
        name=params.get("name", "?"),
        amount=params.get("amount"),
        unit=params.get("unit"),
        category=params.get("category", "sonstiges"),
        source="manual",
    )
    db.add(item)
    await db.flush()

    return {"id": item.id, "name": item.name}


async def _exec_add_pantry_items(params: dict, db: AsyncSession, family_id: int) -> dict:
    items_data = params.get("items", [])
    added = 0
    updated = 0

    for item_data in items_data:
        name = item_data.get("name", "?")
        norm_name = normalize_ingredient_name(name)
        unit = item_data.get("unit")

        stmt = select(PantryItem).where(
            PantryItem.family_id == family_id,
            PantryItem.name_normalized == norm_name,
        )
        if unit:
            stmt = stmt.where(PantryItem.unit == unit)
        else:
            stmt = stmt.where(PantryItem.unit.is_(None))
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        new_amount = item_data.get("amount")
        expiry_str = item_data.get("expiry_date")
        expiry = date.fromisoformat(expiry_str) if expiry_str else None

        if existing:
            if new_amount is not None and existing.amount is not None:
                existing.amount = round(existing.amount + new_amount, 2)
            elif new_amount is not None:
                existing.amount = new_amount
            if expiry:
                existing.expiry_date = expiry
            updated += 1
        else:
            pantry_item = PantryItem(
                family_id=family_id,
                name=name,
                name_normalized=norm_name,
                amount=new_amount,
                unit=unit,
                category=item_data.get("category", "sonstiges"),
                expiry_date=expiry,
            )
            db.add(pantry_item)
            added += 1

    await db.flush()
    return {"added": added, "updated": updated, "count": added + updated}


async def _exec_send_to_knuspr(db: AsyncSession, family_id: int) -> dict:
    stmt = (
        select(ShoppingList)
        .where(ShoppingList.status == "active", ShoppingList.family_id == family_id)
        .order_by(ShoppingList.created_at.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    sl = result.scalar_one_or_none()
    if not sl:
        return {"error": "Keine aktive Einkaufsliste"}
    try:
        from integrations.knuspr.cart import send_list_to_cart

        return await send_list_to_cart(sl.id, db, family_id=family_id)
    except ImportError:
        return {"error": "Knuspr-Bridge nicht installiert"}
    except Exception as e:
        return {"error": str(e)}


async def _exec_generate_meal_plan(params: dict, db: AsyncSession, family_id: int) -> dict:
    """Generate and confirm a full meal plan via Claude, reusing existing logic."""
    week_start_str = params.get("week_start")
    if not week_start_str:
        return {"error": "Kein week_start angegeben"}

    monday = monday_of(date.fromisoformat(week_start_str))
    sunday = monday + timedelta(days=6)
    servings = params.get("servings", 4)
    preferences = params.get("preferences", "")
    selected_slots_raw = params.get("selected_slots", [])

    # Load recipes
    stmt = (
        select(Recipe)
        .where(Recipe.ai_accessible.is_(True), Recipe.family_id == family_id)
        .options(selectinload(Recipe.ingredients), selectinload(Recipe.history))
        .order_by(Recipe.title)
    )
    result = await db.execute(stmt)
    recipes = result.scalars().unique().all()

    if not recipes:
        return {"error": "Keine Rezepte vorhanden. Bitte zuerst Rezepte anlegen."}

    recipe_lookup = {r.id: r for r in recipes}

    # Determine filled slots
    existing_stmt = (
        select(MealPlan)
        .where(and_(
            MealPlan.family_id == family_id,
            MealPlan.plan_date >= monday,
            MealPlan.plan_date <= sunday,
        ))
    )
    existing_result = await db.execute(existing_stmt)
    existing_meals = existing_result.scalars().all()
    filled_slots = {f"{m.plan_date}_{m.slot}" for m in existing_meals}

    # Build target slots
    if selected_slots_raw:
        target_slots = []
        for s in selected_slots_raw:
            s_date = s.get("date", "") if isinstance(s, dict) else ""
            s_slot = s.get("slot", "") if isinstance(s, dict) else ""
            key = f"{s_date}_{s_slot}"
            if key in filled_slots:
                continue
            d = date.fromisoformat(s_date)
            day_idx = (d - monday).days
            if 0 <= day_idx <= 6:
                target_slots.append({
                    "date": s_date,
                    "day": WEEKDAY_NAMES_DE[day_idx],
                    "slot": s_slot,
                    "label": "Mittag" if s_slot == "lunch" else "Abend",
                })
    else:
        target_slots = []
        for i in range(7):
            d = monday + timedelta(days=i)
            for slot in ["lunch", "dinner"]:
                key = f"{d}_{slot}"
                if key not in filled_slots:
                    target_slots.append({
                        "date": str(d),
                        "day": WEEKDAY_NAMES_DE[i],
                        "slot": slot,
                        "label": "Mittag" if slot == "lunch" else "Abend",
                    })

    if not target_slots:
        return {"error": "Keine freien Slots in dieser Woche"}

    now = utcnow()
    recipe_descriptions = _build_recipe_descriptions(recipes, now)
    prompt = _build_prompt(
        recipe_descriptions, target_slots, servings,
        preferences, False, {},
    )

    raw_text = await _call_claude(prompt)
    plan_items, reasoning = _parse_claude_json(raw_text)

    suggestions = _validate_suggestions(
        plan_items,
        valid_recipe_ids={r.id for r in recipes},
        recipe_lookup=recipe_lookup,
        cookidoo_lookup={},
        target_slot_keys={f"{s['date']}_{s['slot']}" for s in target_slots},
        default_servings=servings,
    )

    if not suggestions:
        return {"error": "KI konnte keinen passenden Essensplan erstellen"}

    # Save the plan directly (confirm step)
    meal_ids: list[int] = []
    meals_created = 0
    for item in suggestions:
        slot_key = f"{item.date}_{item.slot}"
        if slot_key in filled_slots:
            continue

        item_date = date.fromisoformat(item.date)
        if not item.recipe_id:
            continue

        meal = MealPlan(
            family_id=family_id,
            plan_date=item_date,
            slot=item.slot,
            recipe_id=item.recipe_id,
            servings_planned=item.servings_planned,
        )
        db.add(meal)
        await db.flush()
        meal_ids.append(meal.id)
        filled_slots.add(slot_key)
        meals_created += 1

    # Auto-generate shopping list
    shopping_generated = False
    if meals_created > 0:
        try:
            from .shopping import _generate_shopping_list
            await _generate_shopping_list(monday, family_id, db)
            shopping_generated = True
        except Exception:
            logger.warning("Auto-Einkaufsliste konnte nicht erstellt werden", exc_info=True)

    # Build meal plan details for the voice result
    meal_details = []
    for s in suggestions:
        d = date.fromisoformat(s.date)
        day_idx = (d - monday).days
        day_name = WEEKDAY_NAMES_DE[day_idx] if 0 <= day_idx <= 6 else s.date
        slot_label = "Mittag" if s.slot == "lunch" else "Abend"
        meal_details.append(f"{day_name} {slot_label}: {s.recipe_title}")

    return {
        "id": meal_ids[0] if meal_ids else 0,
        "meals_created": meals_created,
        "meal_ids": meal_ids,
        "shopping_list_generated": shopping_generated,
        "reasoning": reasoning,
        "meal_details": meal_details,
    }


async def _exec_update_event(params: dict, db: AsyncSession, family_id: int) -> dict:
    event_id = params.get("event_id")
    if not event_id:
        return {"error": "Keine event_id angegeben"}

    result = await db.execute(
        select(Event).where(Event.id == int(event_id), Event.family_id == family_id)
    )
    event = result.scalars().first()
    if not event:
        return {"error": f"Event {event_id} nicht gefunden"}

    if "title" in params:
        event.title = params["title"]
    if "description" in params:
        event.description = params["description"]
    if "start" in params:
        event.start = datetime.fromisoformat(params["start"])
    if "end" in params:
        event.end = datetime.fromisoformat(params["end"])
    if "all_day" in params:
        event.all_day = params["all_day"]
    if "category_id" in params:
        event.category_id = params["category_id"]

    if "member_ids" in params:
        await db.execute(event_members.delete().where(event_members.c.event_id == event.id))
        for mid in params["member_ids"]:
            await db.execute(event_members.insert().values(event_id=event.id, member_id=mid))

    return {"id": event.id, "title": event.title}


async def _exec_update_todo(params: dict, db: AsyncSession, family_id: int) -> dict:
    todo_id = params.get("todo_id")
    if not todo_id:
        return {"error": "Keine todo_id angegeben"}

    result = await db.execute(
        select(Todo).where(Todo.id == int(todo_id), Todo.family_id == family_id)
    )
    todo = result.scalars().first()
    if not todo:
        return {"error": f"Todo {todo_id} nicht gefunden"}

    if "title" in params:
        todo.title = params["title"]
    if "description" in params:
        todo.description = params["description"]
    if "priority" in params:
        todo.priority = params["priority"]
    if "due_date" in params:
        todo.due_date = date.fromisoformat(params["due_date"]) if params["due_date"] else None
    if "category_id" in params:
        todo.category_id = params["category_id"]
    if "event_id" in params:
        todo.event_id = params["event_id"]

    if "member_ids" in params:
        await db.execute(todo_members.delete().where(todo_members.c.todo_id == todo.id))
        for mid in params["member_ids"]:
            await db.execute(todo_members.insert().values(todo_id=todo.id, member_id=mid))

    return {"id": todo.id, "title": todo.title}


async def _exec_complete_todo(params: dict, db: AsyncSession, family_id: int) -> dict:
    todo_id = params.get("todo_id")
    if not todo_id:
        return {"error": "Keine todo_id angegeben"}

    result = await db.execute(
        select(Todo).where(Todo.id == int(todo_id), Todo.family_id == family_id)
    )
    todo = result.scalars().first()
    if not todo:
        return {"error": f"Todo {todo_id} nicht gefunden"}

    todo.completed = True
    todo.completed_at = utcnow()
    return {"id": todo.id, "title": todo.title}


async def _exec_delete_event(params: dict, db: AsyncSession, family_id: int) -> dict:
    event_id = params.get("event_id")
    if not event_id:
        return {"error": "Keine event_id angegeben"}

    result = await db.execute(
        select(Event).where(Event.id == int(event_id), Event.family_id == family_id)
    )
    event = result.scalars().first()
    if not event:
        return {"error": f"Event {event_id} nicht gefunden"}

    title = event.title
    await db.delete(event)
    return {"id": int(event_id), "title": title}


async def _exec_delete_todo(params: dict, db: AsyncSession, family_id: int) -> dict:
    todo_id = params.get("todo_id")
    if not todo_id:
        return {"error": "Keine todo_id angegeben"}

    result = await db.execute(
        select(Todo).where(Todo.id == int(todo_id), Todo.family_id == family_id)
    )
    todo = result.scalars().first()
    if not todo:
        return {"error": f"Todo {todo_id} nicht gefunden"}

    title = todo.title
    await db.delete(todo)
    return {"id": int(todo_id), "title": title}


def _parse_voice_response(raw_text: str) -> tuple[list[dict], str]:
    """Parse Claude's voice command response into actions and summary."""
    text = raw_text
    if text.startswith("```"):
        lines = text.split("\n")
        lines = [ln for ln in lines if not ln.strip().startswith("```")]
        text = "\n".join(lines).strip()

    try:
        result = json.loads(text)
    except json.JSONDecodeError:
        logger.error("Voice command: invalid JSON: %s", text[:500])
        raise HTTPException(
            status_code=502,
            detail="KI hat ungültiges Format zurückgegeben. Bitte erneut versuchen.",
        )

    if not isinstance(result, dict):
        raise HTTPException(status_code=502, detail="KI hat ungültiges Format zurückgegeben.")

    actions = result.get("actions", [])
    summary = result.get("summary", "Aktion ausgeführt.")
    if not isinstance(actions, list):
        raise HTTPException(status_code=502, detail="KI hat ungültiges Format zurückgegeben.")

    return actions, summary


@router.post("/voice-command", response_model=VoiceCommandResponse)
async def voice_command(
    data: VoiceCommandRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    actor_member_id: int = Depends(require_member_id),
):
    """Interpret a voice command via Claude and execute the resulting actions."""
    if not settings.ANTHROPIC_API_KEY:
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY ist nicht konfiguriert")

    if not data.text.strip():
        raise HTTPException(status_code=400, detail="Kein Text angegeben")

    now = utcnow()
    user_text = data.text.strip()
    include_existing = _needs_existing_context(user_text)
    context = await _build_voice_context(db, now, include_existing, family_id)
    prompt = _build_voice_prompt(user_text, context, now, include_existing)

    raw_text = await _call_claude(prompt, max_tokens=4096)
    actions_raw, summary = _parse_voice_response(raw_text)

    assign_all_todos = _voice_command_means_family_wide_todo(user_text)
    executed = await _execute_voice_actions(
        actions_raw,
        db,
        family_id,
        actor_member_id,
        assign_all_todos,
    )

    return VoiceCommandResponse(summary=summary, actions=executed)


# ── Todo Prioritization Endpoints ─────────────────────────────────────────


def _build_todo_prioritize_prompt(
    todos: list[Todo],
    categories: list[Category],
) -> str:
    cats_text = "\n".join(f"- ID {c.id}: {c.name}" for c in categories) or "- (keine Kategorien)"

    def _todo_line(t: Todo) -> str:
        due = str(t.due_date) if t.due_date else "-"
        cat = str(t.category_id) if t.category_id else "-"
        who = ", ".join(m.name for m in t.members) if t.members else "-"
        kind = "personal" if t.is_personal else "family"
        return (
            f"- ID {t.id} | {kind} | title={t.title!r} | "
            f"priority={t.priority} | due={due} | category_id={cat} | members={who} | "
            f"description={t.description!r}"
        )

    todos_text = "\n".join(_todo_line(t) for t in todos) or "- (keine Todos)"

    return f"""Du bist ein Produktivitäts-Assistent für eine Familie.
Du bekommst eine Liste von Todos und verfügbare Kategorien.

## Kategorien (nur diese IDs sind erlaubt)
{cats_text}

## Todos
{todos_text}

## Aufgabe
Priorisiere die Todos und schlage pro Todo vor:
- suggested_priority: low|medium|high
- suggested_category_id: eine Kategorie-ID aus der Liste oder null
- urgency_score: Zahl von 0.0 bis 1.0
- reasoning: kurze Begründung

## Regeln
- Nutze Fälligkeit (due), bestehende priority, Inhalt/Keywords, und sinnvolle Heuristiken.
- Wenn ein Todo bereits eine passende Kategorie hat, lass suggested_category_id gleich (oder null, wenn keine Änderung nötig).
- Gib ALLE Todos in items zurück.

## Antwortformat
Antworte AUSSCHLIESSLICH mit einem JSON-Objekt, ohne Markdown.
Schema:
{{\"summary\": \"...\", \"items\": [{{\"todo_id\": 1, \"suggested_priority\": \"high\", \"suggested_category_id\": 3, \"urgency_score\": 0.9, \"reasoning\": \"...\"}}]}}
"""


@router.post("/prioritize-todos", response_model=TodoPrioritizeResponse)
async def prioritize_todos(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if not settings.ANTHROPIC_API_KEY:
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY ist nicht konfiguriert")

    todos_result = await db.execute(
        select(Todo)
        .where(Todo.family_id == family_id, Todo.parent_id.is_(None), Todo.completed.is_(False))
        .options(selectinload(Todo.members))
        .order_by(Todo.due_date.asc().nulls_last(), Todo.created_at.desc())
    )
    todos = todos_result.scalars().unique().all()

    cats_result = await db.execute(
        select(Category).where(Category.family_id == family_id).order_by(Category.name)
    )
    categories = cats_result.scalars().all()

    prompt = _build_todo_prioritize_prompt(todos, categories)
    raw_text = await _call_claude(prompt, max_tokens=4096)

    # Parse expected dict shape (summary + items)
    text = raw_text
    if text.startswith("```"):
        lines = text.split("\n")
        lines = [ln for ln in lines if not ln.strip().startswith("```")]
        text = "\n".join(lines).strip()
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        logger.error("Todo prioritize: invalid JSON: %s", text[:500])
        raise HTTPException(
            status_code=502,
            detail="KI hat ungültiges Format zurückgegeben. Bitte erneut versuchen.",
        )
    if not isinstance(parsed, dict) or not isinstance(parsed.get("items"), list):
        raise HTTPException(status_code=502, detail="KI hat ungültiges Format zurückgegeben.")

    valid_cat_ids = {c.id for c in categories}
    valid_todo_ids = {t.id for t in todos}

    items: list[TodoPrioritization] = []
    for it in parsed.get("items", []):
        if not isinstance(it, dict):
            continue
        todo_id = it.get("todo_id")
        if not isinstance(todo_id, int) or todo_id not in valid_todo_ids:
            continue
        pr = it.get("suggested_priority")
        if pr not in ("low", "medium", "high"):
            pr = "medium"
        cat_id = it.get("suggested_category_id")
        if cat_id is not None and (not isinstance(cat_id, int) or cat_id not in valid_cat_ids):
            cat_id = None
        try:
            score = float(it.get("urgency_score", 0.5))
        except (TypeError, ValueError):
            score = 0.5
        score = max(0.0, min(1.0, score))
        reasoning = it.get("reasoning")
        if not isinstance(reasoning, str):
            reasoning = ""
        items.append(
            TodoPrioritization(
                todo_id=todo_id,
                suggested_priority=pr,
                suggested_category_id=cat_id,
                urgency_score=score,
                reasoning=reasoning[:500],
            )
        )

    summary = parsed.get("summary")
    if not isinstance(summary, str):
        summary = ""

    # Ensure every todo appears at least once (fallback defaults)
    seen = {i.todo_id for i in items}
    for t in todos:
        if t.id in seen:
            continue
        items.append(
            TodoPrioritization(
                todo_id=t.id,
                suggested_priority=t.priority if t.priority in ("low", "medium", "high") else "medium",
                suggested_category_id=t.category_id,
                urgency_score=0.5,
                reasoning="",
            )
        )

    return TodoPrioritizeResponse(items=items, summary=summary)


@router.post("/apply-todo-priorities", response_model=ApplyTodoPrioritiesResponse)
async def apply_todo_priorities(
    data: ApplyTodoPrioritiesRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    updated = 0
    for it in data.items:
        todo = await db.get(Todo, it.todo_id)
        if not todo or todo.family_id != family_id:
            continue
        if it.suggested_priority in ("low", "medium", "high"):
            todo.priority = it.suggested_priority
        todo.category_id = it.suggested_category_id
        updated += 1

    await db.flush()
    return ApplyTodoPrioritiesResponse(updated=updated)


# ── Recipe categorization + tags (Claude) ──────────────────────────────────


def _strip_json_fence(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        lines = [ln for ln in lines if not ln.strip().startswith("```")]
        text = "\n".join(lines).strip()
    return text


def _recipe_categorize_line(r: Recipe) -> str:
    ings = ", ".join(i.name for i in (r.ingredients or [])) or "-"
    active = r.prep_time_active_minutes
    passive = r.prep_time_passive_minutes
    total = (active or 0) + (passive or 0)
    prep = f"gesamt ca. {total}min (aktiv={active}, passiv={passive})"
    notes = (r.notes or "")[:500]
    inst = (r.instructions or "")[:500]
    return (
        f"- ID {r.id} | title={r.title!r} | difficulty={r.difficulty} | {prep} | "
        f"notes={notes!r} | instructions_preview={inst!r} | ingredients={ings}"
    )


def _build_recipe_categorize_prompt(
    recipes: list[Recipe],
    categories: list[RecipeCategory],
    tags: list[RecipeTag],
) -> str:
    cats_text = (
        "\n".join(f"- ID {c.id}: {c.name}" for c in categories) or "- (keine Kategorien — du darfst neue vorschlagen)"
    )
    tags_text = "\n".join(f"- ID {t.id}: {t.name}" for t in tags) or "- (keine Tags — du darfst neue vorschlagen)"

    recipes_text = "\n".join(_recipe_categorize_line(r) for r in recipes) or "- (keine Rezepte)"

    return f"""Du bist ein erfahrener Koch und Food-Organisator für eine Familie.
Du bekommst alle Rezepte und sollst sie **kategorisieren** und mit **Labels (Tags)** versehen.

## Vorhandene Rezept-Kategorien (IDs beibehalten wenn passend)
{cats_text}

## Vorhandene Rezept-Tags (IDs beibehalten / Namen wiederverwenden)
{tags_text}

## Rezepte
{recipes_text}

## Aufgabe 1: Kategorien (genau eine pro Rezept)
Ordne jedes Rezept **einer** Kategorie zu.
- Primär nach **Küche / Herkunft**: z.B. "Asiatisch", "Italienisch", "Deutsch/Österreichisch",
  "Mexikanisch", "Orientalisch/Mediterran", "Amerikanisch", "Indisch", "International"
- Ergänzend: **Gerichtstyp** wenn sinnvoller als Herkunft: z.B. "Suppen & Eintöpfe",
  "Salate & Bowls", "Aufläufe & Ofengerichte", "Desserts & Süßes", "Frühstück & Brunch"
- Insgesamt **5–12** Kategorien im System anstreben (nicht pro Rezept neu erfinden — konsolidieren).
- Wenn eine **bestehende Kategorie** passt: setze "suggested_category_id" auf ihre ID und "category_name" exakt gleich.
- Wenn **neu nötig**: "suggested_category_id": null, "category_name" = neuer Name, und **new_categories** um {{name, color}} ergänzen (passende Hex-Farben, z.B. Italienisch #CE2B37).

## Aufgabe 2: Tags (1–5 pro Rezept, übergreifend)
Vergib passende Tags aus diesen **Dimensionen** (nur sinnvolle, nicht alle):
- **Zeit**: "Schnell" (≤20 Min Gesamtzeit aus Daten schätzen), "30 Minuten", "Aufwendig" (>60 Min)
- **Mahlzeit**: "Frühstück", "Hauptgericht", "Beilage", "Nachtisch", "Snack"
- **Ernährung**: "Vegetarisch", "Vegan", "Low Carb", "Proteinreich"
- **Anlass**: "Kinderfreundlich", "Meal Prep", "Comfort Food", "Festlich", "Sommer", "Winter", "Unter der Woche"
Neue Tag-Namen in **new_tags** mit {{name, color}} aufnehmen. Bestehende Tags nach Namen wiederverwenden.

## Antwortformat
Antworte **AUSSCHLIESSLICH** mit JSON, **ohne** Markdown-Codeblöcke.
Schema:
{{
  "summary": "Kurzfassung auf Deutsch",
  "new_categories": [{{"name": "Italienisch", "color": "#CE2B37"}}],
  "new_tags": [{{"name": "Schnell", "color": "#2A9D8F"}}],
  "items": [
    {{
      "recipe_id": 1,
      "category_name": "Italienisch",
      "suggested_category_id": null,
      "tag_names": ["Schnell", "Hauptgericht"]
    }}
  ]
}}

## Regeln
- **Jedes** Rezept aus der Liste muss **genau einmal** in "items" vorkommen.
- Tag-Namen konsistent und kurz (wie in den Dimensionen).
- Bei Unsicherheit: Kategorie "International" oder "Sonstiges" und weniger Tags.
"""


def _normalize_name(s: str) -> str:
    return " ".join(s.strip().lower().split())


def _merge_recipe_categorization(
    parsed: dict,
    recipes: list[Recipe],
    categories: list[RecipeCategory],
    tags: list[RecipeTag],
) -> RecipeCategorizationPreview:
    valid_recipe_ids = {r.id for r in recipes}
    cat_by_id = {c.id: c for c in categories}
    cat_by_norm = {_normalize_name(c.name): c for c in categories}
    tag_by_norm = {_normalize_name(t.name): t for t in tags}

    new_cat_specs: dict[str, RecipeNewCategorySpec] = {}
    new_tag_specs: dict[str, RecipeNewTagSpec] = {}

    for nc in parsed.get("new_categories") or []:
        if not isinstance(nc, dict):
            continue
        name = nc.get("name")
        if not isinstance(name, str) or not name.strip():
            continue
        color = nc.get("color") if isinstance(nc.get("color"), str) else "#0052CC"
        if not color.startswith("#") or len(color) != 7:
            color = "#0052CC"
        new_cat_specs[_normalize_name(name)] = RecipeNewCategorySpec(name=name.strip(), color=color)

    for nt in parsed.get("new_tags") or []:
        if not isinstance(nt, dict):
            continue
        name = nt.get("name")
        if not isinstance(name, str) or not name.strip():
            continue
        color = nt.get("color") if isinstance(nt.get("color"), str) else "#6B7280"
        if not color.startswith("#") or len(color) != 7:
            color = "#6B7280"
        new_tag_specs[_normalize_name(name)] = RecipeNewTagSpec(name=name.strip(), color=color)

    assignments: list[RecipeCategorizationAssignment] = []
    raw_items = parsed.get("items") if isinstance(parsed.get("items"), list) else []

    for it in raw_items:
        if not isinstance(it, dict):
            continue
        rid = it.get("recipe_id")
        if not isinstance(rid, int) or rid not in valid_recipe_ids:
            continue
        cat_name = it.get("category_name")
        if not isinstance(cat_name, str) or not cat_name.strip():
            cat_name = "Sonstiges"
        cat_name = cat_name.strip()
        cat_norm = _normalize_name(cat_name)

        sug_id = it.get("suggested_category_id")
        if sug_id is not None and (not isinstance(sug_id, int) or sug_id not in cat_by_id):
            sug_id = None
        if sug_id is None and cat_norm in cat_by_norm:
            sug_id = cat_by_norm[cat_norm].id

        if sug_id is None and cat_norm not in new_cat_specs:
            new_cat_specs[cat_norm] = RecipeNewCategorySpec(name=cat_name, color="#6B7280")

        raw_tags = it.get("tag_names") or []
        tag_names: list[str] = []
        if isinstance(raw_tags, list):
            for tn in raw_tags:
                if isinstance(tn, str) and tn.strip():
                    tstrip = tn.strip()
                    tag_names.append(tstrip)
                    tn_norm = _normalize_name(tstrip)
                    if tn_norm not in tag_by_norm and tn_norm not in new_tag_specs:
                        new_tag_specs[tn_norm] = RecipeNewTagSpec(name=tstrip, color="#6B7280")

        assignments.append(
            RecipeCategorizationAssignment(
                recipe_id=rid,
                category_name=cat_name,
                suggested_category_id=sug_id,
                tag_names=tag_names,
            )
        )

    seen_r = {a.recipe_id for a in assignments}
    for r in recipes:
        if r.id in seen_r:
            continue
        assignments.append(
            RecipeCategorizationAssignment(
                recipe_id=r.id,
                category_name="Sonstiges",
                suggested_category_id=None,
                tag_names=[],
            )
        )
        if _normalize_name("Sonstiges") not in cat_by_norm and _normalize_name("Sonstiges") not in new_cat_specs:
            new_cat_specs[_normalize_name("Sonstiges")] = RecipeNewCategorySpec(
                name="Sonstiges", color="#6B7280"
            )

    summary = parsed.get("summary")
    if not isinstance(summary, str):
        summary = ""

    return RecipeCategorizationPreview(
        new_categories=list(new_cat_specs.values()),
        new_tags=list(new_tag_specs.values()),
        assignments=assignments,
        summary=summary,
    )


@router.post("/categorize-recipes", response_model=RecipeCategorizationPreview)
async def categorize_recipes(
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if not settings.ANTHROPIC_API_KEY:
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY ist nicht konfiguriert")

    recipes_result = await db.execute(
        select(Recipe)
        .where(Recipe.family_id == family_id)
        .options(selectinload(Recipe.ingredients))
        .order_by(Recipe.title)
    )
    recipes = list(recipes_result.scalars().unique().all())

    if not recipes:
        return RecipeCategorizationPreview(assignments=[], summary="Keine Rezepte vorhanden.")

    cats_result = await db.execute(
        select(RecipeCategory)
        .where(RecipeCategory.family_id == family_id)
        .order_by(RecipeCategory.position, RecipeCategory.name)
    )
    categories = list(cats_result.scalars().all())

    tags_result = await db.execute(
        select(RecipeTag).where(RecipeTag.family_id == family_id).order_by(RecipeTag.name)
    )
    tags = list(tags_result.scalars().all())

    prompt = _build_recipe_categorize_prompt(recipes, categories, tags)
    raw_text = await _call_claude(prompt, max_tokens=8192)
    text = _strip_json_fence(raw_text)

    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        logger.error("Recipe categorize: invalid JSON: %s", text[:500])
        raise HTTPException(
            status_code=502,
            detail="KI hat ungültiges Format zurückgegeben. Bitte erneut versuchen.",
        )
    if not isinstance(parsed, dict):
        raise HTTPException(status_code=502, detail="KI hat ungültiges Format zurückgegeben.")

    return _merge_recipe_categorization(parsed, recipes, categories, tags)


@router.post("/apply-recipe-categorization", response_model=ApplyRecipeCategorizationResponse)
async def apply_recipe_categorization(
    data: ApplyRecipeCategorizationRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    categories_created = 0
    tags_created = 0

    for nc in data.new_categories:
        name = nc.name.strip()
        if not name:
            continue
        existing = await db.execute(
            select(RecipeCategory).where(
                RecipeCategory.family_id == family_id,
                func.lower(RecipeCategory.name) == func.lower(name),
            )
        )
        if existing.scalar_one_or_none():
            continue
        max_pos = await db.scalar(
            select(func.coalesce(func.max(RecipeCategory.position), 0)).where(
                RecipeCategory.family_id == family_id
            )
        )
        row = RecipeCategory(
            family_id=family_id,
            position=int(max_pos or 0) + 1,
            name=name,
            color=nc.color,
            icon="🍽",
        )
        db.add(row)
        categories_created += 1
    await db.flush()

    for nt in data.new_tags:
        name = nt.name.strip()
        if not name:
            continue
        existing = await db.execute(
            select(RecipeTag).where(
                RecipeTag.family_id == family_id,
                func.lower(RecipeTag.name) == func.lower(name),
            )
        )
        if existing.scalar_one_or_none():
            continue
        db.add(RecipeTag(family_id=family_id, name=name, color=nt.color))
        tags_created += 1
    await db.flush()

    cats_result = await db.execute(
        select(RecipeCategory).where(RecipeCategory.family_id == family_id)
    )
    cats_list = list(cats_result.scalars().all())
    cat_by_lower = {c.name.strip().lower(): c for c in cats_list}
    cat_by_id = {c.id: c for c in cats_list}

    tags_result = await db.execute(select(RecipeTag).where(RecipeTag.family_id == family_id))
    tag_by_lower = {t.name.strip().lower(): t for t in tags_result.scalars().all()}

    updated = 0
    for a in data.assignments:
        result = await db.execute(
            select(Recipe)
            .options(selectinload(Recipe.tags))
            .where(Recipe.id == a.recipe_id, Recipe.family_id == family_id)
        )
        recipe = result.scalar_one_or_none()
        if not recipe:
            continue

        cid = a.suggested_category_id
        if cid is not None and cid not in cat_by_id:
            cid = None
        if cid is None:
            c = cat_by_lower.get(a.category_name.strip().lower())
            if c:
                cid = c.id
        if cid is None:
            logger.warning("apply recipe categorization: skip recipe %s — no category", a.recipe_id)
            continue

        recipe.recipe_category_id = cid

        tag_objs: list[RecipeTag] = []
        for tn in a.tag_names:
            t = tag_by_lower.get(tn.strip().lower())
            if t:
                tag_objs.append(t)
        recipe.tags = tag_objs
        updated += 1

    await db.flush()
    return ApplyRecipeCategorizationResponse(
        updated=updated,
        categories_created=categories_created,
        tags_created=tags_created,
    )
