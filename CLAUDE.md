# CLAUDE.md — Familienkalender (Kompakt)

> **Flutter-Pfade:** relativ zu `flutter/lib/`
> **Android-Basispfad (Legacy):** `ANDROID/` = `android/app/src/main/java/de/familienkalender/app/`

## Wann PROJECT_INDEX.md laden

Diese CLAUDE.md enthaelt die Essentials fuer die meisten Aufgaben. Wenn du **detailliertere Informationen** brauchst, lies die entsprechende Sektion aus `PROJECT_INDEX.md` (mit offset/limit, NICHT die ganze Datei):

| Ich brauche ... | → Lies PROJECT_INDEX.md Sektion |
|-----------------|--------------------------------|
| Exakte Zeilennummern fuer Methoden in grossen Dateien | **10** (Methodenkarte) |
| Modul-Abhaengigkeiten / welche Module es gibt | **5** (Modulkarte) |
| Env-Vars, Library-Versionen, externe Services | **7** (Abhaengigkeiten) |
| Detaillierte Dateiliste / Einstiegspunkte / Configs | **4** (Schluesseldateien) |
| Vorhandene Doku-Dateien | **11** (Dokumentation) |
| Verzeichnisstruktur als Tabelle | **3** (Kurzform) |

**Regel:** Lade PROJECT_INDEX.md NICHT komplett. Nutze die Sektionsnummern um gezielt den relevanten Bereich zu lesen.

---

## Projektsteckbrief

| Feld | Wert |
|------|------|
| **Typ** | Fullstack-Webapp + Cross-Platform App (Flutter) + MCP-Server |
| **Sprachen** | Python 3.12+ (Backend), Dart 3.3+ (Flutter), Kotlin (Android Legacy), JavaScript (Web Legacy) |
| **Frameworks** | FastAPI 0.135, Flutter 3.24 + Riverpod 2 (Cross-Platform), Jetpack Compose (Android Legacy), Vanilla JS SPA (Web Legacy) |
| **Datenbank** | PostgreSQL 16 via SQLAlchemy 2.0 (async, asyncpg); Client: Drift/SQLite (Flutter) |
| **Auth** | JWT (python-jose + bcrypt), OAuth2PasswordBearer |
| **Paketmanager** | pip (requirements.txt), Flutter/pub (pubspec.yaml), Gradle (Android Legacy) |
| **Build** | uvicorn (dev), Docker (prod), Flutter CLI (cross-platform) |

---

## Architektur

Layered Architecture: Models → Schemas → Routers → Frontend. Optionale externe Integrationen (Cookidoo, Knuspr) als separate Bridge-Module. MCP-Server als eigener Prozess. Row-Level Multi-Tenancy per `family_id` auf allen Kernmodellen. Flutter-App ersetzt die 3 separaten Client-Codebases (Web/Android/iOS).

```
Flutter App / Browser → HTTP JSON → FastAPI Router → Pydantic Schema (Validierung)
→ SQLAlchemy Model → PostgreSQL DB → Response Schema → JSON → Flutter App / Browser
```

| Schicht | Pfad |
|---------|------|
| **Flutter Cross-Platform** | `flutter/lib/` |
| API-Router | `backend/app/routers/` |
| Pydantic Schemas | `backend/app/schemas/` |
| ORM Models | `backend/app/models/` |
| Externe Bridges | `backend/integrations/` |
| MCP-Server | `backend/mcp_server.py` |
| Frontend SPA (Legacy) | `backend/app/static/` |
| Android App (Legacy) | `ANDROID/` |

---

## Routen-Definitionen

| Pfad | Prefix | Endpunkte |
|------|--------|-----------|
| `routers/auth.py` | `/api/auth` | register, login, me, link-member, family (create/join/get) |
| `routers/events.py` | `/api/events` | CRUD |
| `routers/todos.py` | `/api/todos` | CRUD + complete, link-event |
| `routers/proposals.py` | `/api/proposals` + `/api/todos` | create, list, respond, pending |
| `routers/recipes.py` | `/api/recipes` | CRUD + suggestions, history; Filter `recipe_category_id`, `tag_id` |
| `routers/recipe_categories.py` | `/api/recipe-categories` | CRUD + reorder (eigen von Todo-/Notiz-Kategorien) |
| `routers/recipe_tags.py` | `/api/recipe-tags` | CRUD |
| `routers/meals.py` | `/api/meals` | plan CRUD + mark-as-cooked |
| `routers/shopping.py` | `/api/shopping` | list, generate, items CRUD, sort (KI) |
| `routers/cookidoo.py` | `/api/cookidoo` | status, collections, recipes, import, calendar |
| `routers/knuspr.py` | `/api/knuspr` | status, products, cart (+preview/apply/price-check), slots, mappings |
| `routers/ai.py` | `/api/ai` | available-recipes, generate-meal-plan (preview), confirm-meal-plan, undo-meal-plan, voice-command, prioritize-todos, apply-todo-priorities, categorize-recipes, apply-recipe-categorization |
| `routers/categories.py` | `/api/categories` | CRUD |
| `routers/notes.py` | `/api/notes` | CRUD + pin, archive, preview-link, comments, attachments, convert-to-todo |
| `routers/note_categories.py` | `/api/note-categories` | CRUD + reorder (eigen von Todo-Kategorien) |
| `routers/note_tags.py` | `/api/note-tags` | CRUD |
| `routers/family_members.py` | `/api/family-members` | CRUD |

> Alle Router-Pfade relativ zu `backend/app/`

---

## Patterns und Konventionen

- **Python-Dateien**: snake_case — **Dart-Dateien**: snake_case — **JS-Dateien**: snake_case — **Klassen**: PascalCase
- **Funktionen**: snake_case (Python), camelCase (Dart, JS)
- **API-Pfade**: kebab-case (`/family-members/`) — **DB-Tabellen**: snake_case Plural
- **Fehler**: `HTTPException` mit deutschen Meldungen — Flutter: `ApiException` + `showAppToast`
- **Logging**: Python `logging`, Logger `"kalender"`, `"kalender.cookidoo"`, etc.
- **Auth**: JWT Bearer, `bcrypt` direkt (nicht passlib), Flutter: `flutter_secure_storage`, 401 → Logout
- **State**: Backend: SQLAlchemy async Sessions; Flutter: Riverpod + Drift; Frontend Legacy: IIFE-Closures; Android Legacy: Room + StateFlow
- **Flutter Offline**: `PendingChanges` Drift-Tabelle → `SyncService` Replay (alle Module konsistent)
- **Flutter DI**: Riverpod Providers
- **Flutter Navigation**: GoRouter mit Auth-Redirect, `ShellRoute`
- **Tests**: Basis-Widget-Tests in `flutter/test/`

---

## Haeufige Aufgaben → Dateipfade

> Backend-Pfade ab Repo-Root. Flutter-Pfade relativ zu `flutter/lib/`. Android-Pfade relativ zu `ANDROID/`.

| Aufgabe | Relevante Dateien |
|---------|-------------------|
| Neues DB-Model | `backend/app/models/`, `backend/app/models/__init__.py` |
| Neuer API-Endpunkt | `backend/app/routers/`, `backend/app/main.py` (registrieren) |
| Pydantic Schema | `backend/app/schemas/` |
| Auth/JWT | `backend/app/auth.py`, `backend/app/routers/auth.py` |
| Cookidoo erweitern | `backend/integrations/cookidoo/client.py`, `backend/app/routers/cookidoo.py` |
| Knuspr erweitern | `backend/integrations/knuspr/client.py`, `backend/app/routers/knuspr.py` |
| MCP-Tools | `backend/mcp_server.py` |
| Env-Vars | `backend/app/config.py`, `backend/.env` |
| **Flutter neues Feature** | Domain (`features/<name>/domain/`), Repo (`features/<name>/data/`), Screen (`features/<name>/presentation/`), Endpoint (`core/api/endpoints.dart`) |
| **Flutter Kalender** | `features/calendar/presentation/calendar_screen.dart`, `features/calendar/data/event_repository.dart` |
| **Flutter Todos** | `features/todos/presentation/todo_list_screen.dart`, `features/todos/data/todo_repository.dart` |
| **Flutter Rezepte** | `features/recipes/presentation/recipe_list_screen.dart`, `recipe_form_dialog.dart`, `recipe_categories_screen.dart`, `ai_categorize_sheet.dart`, `data/recipe_repository.dart`, `recipe_category_repository.dart`, `recipe_tag_repository.dart` |
| **Flutter Essensplanung** | `features/meals/presentation/week_plan_screen.dart`, `features/meals/data/meal_repository.dart` |
| **Flutter KI-Essensplanung** | `features/ai/presentation/ai_meal_plan_wizard.dart`, `features/ai/data/ai_repository.dart` |
| **Flutter Einkaufsliste** | `features/shopping/presentation/shopping_list_screen.dart`, `features/shopping/data/shopping_repository.dart` |
| **Flutter Notizen** | `features/notes/presentation/notes_screen.dart`, `features/notes/data/note_repository.dart` |
| **Flutter Vorratskammer** | `features/pantry/presentation/pantry_screen.dart`, `features/pantry/data/pantry_repository.dart` |
| **Flutter Sprachbefehle** | `app/app_shell.dart` (Voice FAB + Sheet), `core/speech/speech_service.dart`, `core/speech/voice_state.dart`, `features/ai/data/ai_repository.dart` |
| **Flutter Navigation** | `app/router.dart`, `app/app_shell.dart` |
| **Flutter Theme/Styling** | `core/theme/app_theme.dart`, `core/theme/colors.dart` |
| **Flutter Offline-Sync** | `core/sync/sync_service.dart`, `core/database/tables/tables.dart`, `core/database/app_database.dart` |
| **Flutter Docker (Web)** | `flutter/Dockerfile`, `flutter/nginx.conf` |
| Docker (Backend) | `backend/Dockerfile`, `backend/Dockerfile.mcp`, `backend/docker-compose.yml` |
| Android UI (Legacy) | `ui/` |
| Android neues Feature (Legacy) | DTO, API, Entity+DAO, Repository, ViewModel+Screen |
| Cache-Busting (Legacy) | `backend/app/static/index.html` (`?v=N` an `<script>` und `<link>`) |

---

## Bekannte Besonderheiten

### Backend
- **Kein Alembic-Migrationen**: Schema per `create_all` beim Start. Bei Aenderungen DB manuell zuruecksetzen
- **Externe Integrationen optional**: Cookidoo/Knuspr nur mit Libraries + Credentials, App laeuft ohne
- **MCP-Server eigene DB-Session**: Teilt keine Sessions mit FastAPI
- **CORS offen**: `allow_origins=["*"]`, nur Entwicklung
- **bcrypt direkt**: Kein passlib (Python 3.14 / bcrypt>=5.0 Inkompatibilitaet)
- **AI ist Preview-basiert**: `generate-meal-plan` speichert nicht → `confirm-meal-plan` schreibt DB
- **Multi-Tenancy**: `family_id` auf allen Kern-Tabellen, `require_family_id` Dependency in `auth.py`

### Flutter (Cross-Platform)
- **Ersetzt 3 Codebases**: ~26.600 LOC (Web+Android+iOS) → ~8.100 LOC (~70% Reduktion)
- **Drift Code-Generierung**: `app_database.g.dart` per `dart run build_runner build`
- **Material 3**: Light/Dark-Mode, `ColorScheme.fromSeed`
- **Offline konsistent**: Alle Module haben Offline-Queue (anders als Android Legacy)
- **Server-URL konfigurierbar**: User kann Backend-URL in Login/Settings aendern
- **PWA-faehig**: Web-Build mit `manifest.json`
- **Nginx-Proxy**: Flutter Web Container proxied `/api/` an Backend

### Legacy
- **Frontend ohne Build-System**: Vanilla JS, kein Bundler. Cache-Busting manuell per `?v=N`
- **Android Offline inkonsistent**: Queue nur fuer Events, Todos, Recipes, Categories, Members
- **Android Voice FAB global**: In AppNavigation, nicht screenspezifisch

---

## Quick Reference

```bash
# Backend starten
cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# MCP-Server
cd backend && python mcp_server.py

# Docker (Produktion — Backend)
cd backend && docker-compose up -d

# DB zuruecksetzen
docker-compose exec db psql -U kalender -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Flutter Web starten (Entwicklung)
cd flutter && flutter run -d chrome

# Flutter Android/iOS starten
cd flutter && flutter run

# Flutter Web bauen (Produktion)
cd flutter && flutter build web --wasm

# Flutter Docker (Web)
cd flutter && docker build -t familienkalender-flutter .

# Android bauen (Legacy)
cd android && ./gradlew assembleDebug
```

| Service | URL |
|---------|-----|
| API + Legacy Frontend | `http://localhost:8000` |
| Flutter Web (Nginx) | `http://localhost` |
| OpenAPI Docs | `http://localhost:8000/docs` |
| MCP-Server (SSE) | `http://localhost:8001/sse` |
| PostgreSQL | `localhost:5432` |

**Deployment**: Synology NAS (Docker) — Container: db (:5432), api (:8000), mcp (:8001), flutter (:80)

**Cache-Busting (Legacy)**: Aktuell `?v=21` in `index.html`
