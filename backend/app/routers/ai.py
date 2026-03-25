"""AI-powered meal planning using Claude API with preview/confirm workflow."""

import json
import logging
from datetime import date, datetime, timedelta

import anthropic
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..config import settings
from ..database import get_db, utcnow
from ..models.meal_plan import MealPlan
from ..models.recipe import Recipe
from ..models.category import Category
from ..models.event import Event, event_members
from ..models.family_member import FamilyMember
from ..models.ingredient import Ingredient
from ..models.pantry_item import PantryItem
from ..models.shopping_list import ShoppingItem, ShoppingList
from ..models.todo import Todo, todo_members
from ..schemas.ai import (
    ConfirmMealPlanRequest,
    ConfirmMealPlanResponse,
    GenerateMealPlanRequest,
    MealSuggestion,
    PreviewMealPlanResponse,
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
        f"\n\nBesondere Wuensche des Nutzers: {preferences}"
        if preferences else ""
    )

    if include_cookidoo and cookidoo_lookup:
        source_instruction = (
            '- Du kannst sowohl LOKALE als auch COOKIDOO Rezepte verwenden\n'
            '- Fuer lokale Rezepte: "source": "local", "recipe_id": <Integer>\n'
            '- Fuer Cookidoo Rezepte: "source": "cookidoo", "cookidoo_id": "<String>"\n'
            '- Bevorzuge lokale Rezepte (da Zutaten bekannt), nutze Cookidoo fuer Abwechslung'
        )
    else:
        source_instruction = '- Verwende NUR lokale Rezept-IDs ("source": "local")'

    return f"""Du bist ein Essensplaner fuer eine Familie. Erstelle einen Wochenplan fuer die folgenden freien Slots.

## Verfuegbare Rezepte
{recipes_text}

## Freie Slots (diese muessen gefuellt werden)
{slots_text}

## Regeln
{source_instruction}
- Bevorzuge Rezepte, die laenger nicht gekocht wurden (Abwechslung!)
- Vermeide das gleiche Rezept mehrfach in einer Woche
- Beruecksichtige eine gute Mischung aus einfachen und aufwendigeren Gerichten
- Plane aufwendigere Gerichte eher fuers Wochenende
- Portionen pro Mahlzeit: {servings}{preferences_text}

## Antwort-Format
Antworte AUSSCHLIESSLICH mit einem JSON-Objekt. Keine Erklaerung, kein Markdown, nur das JSON.
Das Objekt hat zwei Felder:
- "plan": Ein Array mit den Mahlzeiten. Jedes Element hat: "date" (YYYY-MM-DD), "slot" ("lunch" oder "dinner"), "source" ("local" oder "cookidoo"), "recipe_id" (Integer, nur bei local) ODER "cookidoo_id" (String, nur bei cookidoo), "recipe_title" (String), "servings_planned" (Integer)
- "reasoning": Ein String mit 3-5 Saetzen, der erklaert WARUM du diese Rezepte ausgewaehlt und so verteilt hast (z.B. Abwechslung, Schwierigkeitsgrad-Verteilung, Nutzerwuensche, lange nicht gekochte Gerichte).

Beispiel:
{{"plan": [{{"date": "2026-03-23", "slot": "lunch", "source": "local", "recipe_id": 5, "recipe_title": "Spaghetti Bolognese", "servings_planned": 4}}], "reasoning": "Ich habe Spaghetti Bolognese gewaehlt, weil es ein einfaches Gericht ist und schon lange nicht mehr gekocht wurde."}}
"""


async def _call_claude(prompt: str, max_tokens: int = 2000) -> str:
    """Send prompt to Claude and return the raw text response."""
    try:
        client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        response = await client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=max_tokens,
            messages=[{"role": "user", "content": prompt}],
        )
    except anthropic.AuthenticationError:
        raise HTTPException(status_code=503, detail="Ungueltiger ANTHROPIC_API_KEY")
    except anthropic.APIError as e:
        logger.error("Claude API error: %s", e)
        raise HTTPException(status_code=502, detail="Claude API Fehler")

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
            detail="KI hat ungueltiges Format zurueckgegeben. Bitte erneut versuchen.",
        )

    reasoning: str | None = None
    if isinstance(result, dict):
        reasoning = result.get("reasoning")
        result = result.get("plan", [])

    if not isinstance(result, list):
        raise HTTPException(status_code=502, detail="KI hat ungueltiges Format zurueckgegeben.")
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
        raise HTTPException(status_code=400, detail="Keine freien Slots ausgewaehlt.")

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
        raise HTTPException(status_code=400, detail="Keine Rezepte verfuegbar.")

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
    if meals_created > 0:
        try:
            from .shopping import _generate_shopping_list
            await _generate_shopping_list(monday, family_id, db)
            shopping_generated = True
        except Exception:
            logger.warning("Auto-Einkaufsliste konnte nicht erstellt werden", exc_info=True)

    return ConfirmMealPlanResponse(
        message=f"{meals_created} Mahlzeiten wurden per KI geplant.",
        meals_created=meals_created,
        meal_ids=meal_ids,
        shopping_list_generated=shopping_generated,
    )


@router.post("/undo-meal-plan")
async def undo_meal_plan(
    data: UndoMealPlanRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    """Remove AI-generated meal plan entries."""
    if not data.meal_ids:
        raise HTTPException(status_code=400, detail="Keine Eintraege zum Rueckgaengigmachen")

    stmt = select(MealPlan).where(
        MealPlan.id.in_(data.meal_ids), MealPlan.family_id == family_id
    )
    result = await db.execute(stmt)
    meals = result.scalars().all()

    deleted = 0
    for meal in meals:
        await db.delete(meal)
        deleted += 1

    return {"message": f"{deleted} Mahlzeiten rueckgaengig gemacht.", "deleted": deleted}


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
            + (f", Faellig: {t['due_date']}" if t['due_date'] else "")
            + (f", Event-ID: {t['event_id']}" if t['event_id'] else "")
            + ")"
            for t in context["todos"]
        ) or "Keine offenen Todos vorhanden"

        existing_context_block = f"""
## Bestehende Termine (zum Bearbeiten/Verschieben/Loeschen)
{events_text}

## Offene Todos (zum Bearbeiten/Erledigen/Loeschen)
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
Bearbeitet ein bestehendes Todo (z.B. umbenennen, Prioritaet aendern, Faelligkeitsdatum setzen).
Parameter:
- "todo_id" (Integer, PFLICHT - verwende ID aus "Offene Todos")
- "title" (String, optional)
- "description" (String, optional)
- "priority" (String: "low", "medium", "high", optional)
- "due_date" (ISO-Datum, optional)
- "category_id" (Integer, optional)
- "event_id" (Integer, optional - mit Event verknuepfen oder null zum Entknuepfen)
- "member_ids" (Array von Integers, optional)

### complete_todo
Markiert ein Todo als erledigt.
Parameter:
- "todo_id" (Integer, PFLICHT - verwende ID aus "Offene Todos")

### delete_event
Loescht einen Kalendereintrag.
Parameter:
- "event_id" (Integer, PFLICHT - verwende ID aus "Bestehende Termine")

### delete_todo
Loescht ein Todo.
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

## Verfuegbare Familienmitglieder
{members_text}

## Verfuegbare Kategorien
{categories_text}

## Verfuegbare Rezepte (fuer Essensplanung)
{recipes_text}
{existing_context_block}
## Verfuegbare Aktionstypen

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
Erstellt einen Serientermin (z.B. woechentlich, taeglich). Das Backend generiert automatisch alle Einzeltermine.
WICHTIG: Verwende diesen Typ IMMER wenn ein wiederkehrender Termin gemeint ist (z.B. "jeden Mittwoch", "taeglich", "jeden Monat am 1.").
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
- "parent_ref" (String, optional - Referenz auf ein in dieser Anweisung erstelltes Todo, fuer Sub-Todos)
- "member_ids" (Array von Integers, optional)

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
Fuegt einen Artikel zur Einkaufsliste hinzu.
Parameter:
- "name" (String, PFLICHT)
- "amount" (String, optional, z.B. "500")
- "unit" (String, optional, z.B. "g", "ml", "Stueck")
- "category" (String: "kuehlregal", "obst_gemuese", "trockenware", "drogerie", "sonstiges", default "sonstiges")

### add_pantry_items
Fuegt Artikel zur Vorratskammer hinzu. Verwende diesen Typ wenn der Nutzer sagt was er im Vorrat/Schrank/Speisekammer hat.
Erkennung: "Wir haben noch...", "Im Vorrat haben wir...", "Auf Lager...", "In der Vorratskammer...", "Daheim haben wir noch..."
Parameter:
- "items" (Array von Objekten, PFLICHT) - jedes mit:
  - "name" (String, PFLICHT - z.B. "Tomaten gehackt")
  - "amount" (Float, optional - z.B. 20)
  - "unit" (String, optional - z.B. "Dosen", "kg", "Stueck")
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
Erstellt einen kompletten KI-Essensplan fuer eine Woche. Verwende diesen Typ wenn der Nutzer sagt, er moechte eine Woche (oder mehrere Tage) planen lassen, z.B. "plane mir die Woche", "mach mir einen Essensplan", "was sollen wir diese Woche kochen".
WICHTIG: Dieser Typ generiert den Plan UND speichert ihn direkt. Es wird auch automatisch eine Einkaufsliste erstellt.
Parameter:
- "week_start" (ISO-Datum "YYYY-MM-DD", PFLICHT - der Montag der gewuenschten Woche. Wenn der Nutzer "diese Woche" sagt, verwende den aktuellen oder naechsten Montag)
- "servings" (Integer, default 4 - Portionen pro Mahlzeit)
- "preferences" (String, optional - Besondere Wuensche des Nutzers, z.B. "vegetarisch", "ein neues Gericht und eins das wir schon kennen", "schnelle Gerichte unter der Woche")
- "selected_slots" (Array von Objekten mit "date" (YYYY-MM-DD) und "slot" ("lunch" oder "dinner"), optional - wenn leer, werden ALLE freien Slots der Woche geplant. Wenn der Nutzer spezifische Tage/Mahlzeiten nennt, gib nur diese an)

Beispiel: "Plane mir diese Woche, Montag Abend und Mittwoch Mittag soll was Neues sein"
-> {{"type": "generate_meal_plan", "params": {{"week_start": "2026-03-23", "servings": 4, "preferences": "Montag Abend und Mittwoch Mittag sollen neue Gerichte sein, die wir noch nie gekocht haben", "selected_slots": [{{"date": "2026-03-23", "slot": "dinner"}}, {{"date": "2026-03-25", "slot": "lunch"}}]}}}}

Beispiel: "Mach einen Essensplan fuer die ganze Woche, 3 Portionen, eher einfach"
-> {{"type": "generate_meal_plan", "params": {{"week_start": "2026-03-23", "servings": 3, "preferences": "eher einfache Gerichte bevorzugen", "selected_slots": []}}}}
{modify_actions_block}

## Referenz-System

Wenn eine Aktion von einer anderen abhaengt (z.B. ein Todo soll mit einem Event verknuepft werden),
verwende das "ref"-Feld als Platzhalter-ID und referenziere es in spaeteren Aktionen.

Beispiel: Event erstellen und Todos daran linken:
- Aktion 1: create_event mit "ref": "evt1"
- Aktion 2: create_todo mit "event_ref": "evt1" (wird automatisch aufgeloest)

Fuer Sub-Todos:
- Aktion 1: create_todo mit "ref": "todo1"
- Aktion 2: create_todo mit "parent_ref": "todo1" (wird als Unteraufgabe angelegt)

## Antwort-Format

Antworte AUSSCHLIESSLICH mit einem JSON-Objekt. Kein Markdown, keine Erklaerung.
Das Objekt hat:
- "actions": Array von Aktionsobjekten. Jedes hat:
  - "type": Der Aktionstyp (z.B. "create_event")
  - "ref": Optionaler Platzhalter-Name (z.B. "evt1", "todo1")
  - "params": Objekt mit den Parametern der Aktion
- "summary": Ein kurzer deutscher Satz, der zusammenfasst was du gemacht hast (fuer den Benutzer)

## Beispiel

Eingabe: "Ich habe am Montag um 14 Uhr ein Meeting mit Michi und muss dafuer noch Kaffee vorbereiten und das Dokument ausfuellen"

Antwort:
{{"actions": [
  {{"type": "create_event", "ref": "evt1", "params": {{"title": "Meeting mit Michi", "start": "2026-03-23T14:00:00", "end": "2026-03-23T15:00:00", "member_ids": [1]}}}},
  {{"type": "create_todo", "ref": "todo1", "params": {{"title": "Kaffee vorbereiten", "event_ref": "evt1", "due_date": "2026-03-23", "priority": "medium"}}}},
  {{"type": "create_todo", "ref": "todo2", "params": {{"title": "Dokument ausfuellen", "event_ref": "evt1", "due_date": "2026-03-23", "priority": "medium"}}}}
], "summary": "Meeting mit Michi am Montag um 14 Uhr erstellt und 2 Todos (Kaffee vorbereiten, Dokument ausfuellen) verknuepft."}}

## Wichtig
- Loese Wochentage immer zu konkreten Daten auf (basierend auf dem heutigen Datum).
- Wenn keine Uhrzeit genannt wird, nutze 09:00 als Standard fuer Events.
- Wenn Personen namentlich erwaehnt werden, versuche sie den Familienmitgliedern zuzuordnen (auch Teilnamen, z.B. "Michi" -> "Michael").
- Erstelle NUR Aktionen, die sich klar aus der Anweisung ableiten lassen.
- Die "summary" soll freundlich, kurz und auf Deutsch sein.

## Benutzereingabe
"{text}"
"""


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
    "delete_todo": 8,
    "delete_event": 9,
}


async def _execute_voice_actions(
    actions: list[dict], db: AsyncSession, family_id: int,
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
                result_data = await _exec_create_todo(params, ref_map, db, family_id)
            elif action_type == "create_recipe":
                result_data = await _exec_create_recipe(params, db, family_id)
            elif action_type == "set_meal_slot":
                result_data = await _exec_set_meal_slot(params, db, family_id)
            elif action_type == "add_shopping_item":
                result_data = await _exec_add_shopping_item(params, db, family_id)
            elif action_type == "add_pantry_items":
                result_data = await _exec_add_pantry_items(params, db, family_id)
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
    params: dict, ref_map: dict[str, int], db: AsyncSession, family_id: int,
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

    member_ids = params.get("member_ids", [])
    if member_ids:
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
            detail="KI hat ungueltiges Format zurueckgegeben. Bitte erneut versuchen.",
        )

    if not isinstance(result, dict):
        raise HTTPException(status_code=502, detail="KI hat ungueltiges Format zurueckgegeben.")

    actions = result.get("actions", [])
    summary = result.get("summary", "Aktion ausgefuehrt.")
    if not isinstance(actions, list):
        raise HTTPException(status_code=502, detail="KI hat ungueltiges Format zurueckgegeben.")

    return actions, summary


@router.post("/voice-command", response_model=VoiceCommandResponse)
async def voice_command(
    data: VoiceCommandRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
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

    executed = await _execute_voice_actions(actions_raw, db, family_id)

    return VoiceCommandResponse(summary=summary, actions=executed)
