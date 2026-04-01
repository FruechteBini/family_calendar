# PROJECT_INDEX.md — Familienkalender

> **Android-Basispfad:** Alle `ANDROID/`-Pfade in diesem Dokument sind relativ zu
> `android/app/src/main/java/de/familienkalender/app/`

## Quick Lookup

| Frage | Sektion |
|-------|---------|
| Welche Dateien brauche ich fuer Aufgabe X? | **8** (Aufgaben → Dateipfade) |
| Wo beginnt Methode Y in grosser Datei? | **10** (Methodenkarte) |
| Welche Schichten hat das Projekt? | **2** (Architektur) + **5** (Modulkarte) |
| API-Endpunkte / Routen-Prefixe? | **4** (Routen-Definitionen) |
| Gotchas, Fallstricke, Workarounds? | **9** (Bekannte Besonderheiten) |
| Naming, Auth, Fehlerbehandlung? | **6** (Patterns + Konventionen) |
| Env-Vars, externe APIs? | **7** (Abhaengigkeiten) |
| Build-, Run-, Deploy-Befehle? | **12** (Quick Reference) |

---

## 1. Projektsteckbrief

| Feld | Wert |
|------|------|
| **Projektname** | Familienkalender |
| **Typ** | Fullstack-Webapp + Cross-Platform App (Flutter) + MCP-Server |
| **Primaere Sprachen** | Python 3.12+ (Backend), Dart 3.3+ (Flutter), Kotlin (Android Legacy), Swift (iOS Legacy), JavaScript (Web Legacy) |
| **Frameworks** | FastAPI 0.135, Flutter 3.24 + Riverpod 2 (Cross-Platform), Jetpack Compose (Android Legacy), SwiftUI (iOS Legacy), Vanilla JS SPA (Web Legacy) |
| **Paketmanager** | pip (requirements.txt), Flutter/pub (pubspec.yaml), Gradle (Android Legacy) |
| **Build-Tool** | uvicorn (dev), Docker (prod), Flutter CLI (cross-platform), Gradle (Android Legacy) |
| **Datenbank** | PostgreSQL 16 via SQLAlchemy 2.0 (async, asyncpg); Client: Drift/SQLite (Flutter) |
| **State Management** | Backend: SQLAlchemy ORM; Flutter: Riverpod + Drift; Android Legacy: Room + Retrofit; Web Legacy: IIFE-Closures |
| **Auth** | JWT (python-jose + bcrypt), OAuth2PasswordBearer |

---

## 2. Architekturuebersicht

### Architekturmuster
Layered Architecture mit klarer Trennung: Models → Schemas → Routers → Frontend. Optionale externe Integrationen (Cookidoo, Knuspr) als separate Bridge-Module. MCP-Server als eigener Prozess fuer Claude-Integration. Row-Level Multi-Tenancy: Jede Familie sieht nur eigene Daten (family_id auf allen Kernmodellen).

### Datenfluss
```
Browser/App → HTTP JSON → FastAPI Router → Pydantic Schema (Validierung)
→ SQLAlchemy Model → PostgreSQL DB → Response Schema → JSON → Browser/App
```

### Schichtenmodell
| Schicht | Verantwortung | Pfad |
|---------|---------------|------|
| Praesentationsschicht | Vanilla JS SPA, HTML, CSS (Legacy) | `backend/app/static/` |
| **Flutter Cross-Platform** | Dart/Flutter App (Web + Android + iOS) | `flutter/lib/` |
| API-Schicht | FastAPI Router, Endpunkte, Auth | `backend/app/routers/` |
| Validierungsschicht | Pydantic Schemas | `backend/app/schemas/` |
| Geschaeftslogik | In Routern + Integrations | `backend/app/routers/`, `backend/integrations/` |
| Persistenzschicht | SQLAlchemy ORM Models | `backend/app/models/` |
| Externe Integrationen | Cookidoo, Knuspr Bridges | `backend/integrations/` |
| MCP-Schicht | Claude AI Tools/Resources | `backend/mcp_server.py` |
| Mobile Schicht (Legacy) | Kotlin/Compose Android + SwiftUI iOS | `android/`, `ios/` |

---

## 3. Verzeichnisstruktur

> Detail-Pfade → Sektion 4 (Schluesseldateien), Sektion 8 (Aufgaben → Dateien)

| Verzeichnis | Zweck | Inhalt |
|-------------|-------|--------|
| `backend/app/models/` | SQLAlchemy ORM | 13 Models (Family, User, Event, Todo, Proposal, Recipe, Ingredient, MealPlan, CookingHistory, ShoppingList, Category, FamilyMember) |
| `backend/app/schemas/` | Pydantic Validierung | 10 Schema-Dateien (Create/Update/Response je Modul) |
| `backend/app/routers/` | FastAPI Endpunkte | 12 Router (auth, events, todos, proposals, recipes, meals, shopping, cookidoo, knuspr, ai, categories, family_members) |
| `backend/app/static/` | Frontend SPA | `index.html` (226 Z.), `css/style.css` (1699 Z.), `js/` (8 Module, ~2300 Z.) |
| `backend/integrations/` | Externe Bridges | `cookidoo/` (client + importer), `knuspr/` (client + cart) |
| `backend/mcp_server.py` | Claude MCP-Server | 1171 Zeilen, 28 Tools + 8 Resources |
| `backend/alembic/` | DB-Migration | Konfiguriert, noch keine Versionen |
| `ANDROID/data/local/db/` | Room DB | 9 Entities, 9 DAOs, `AppDatabase.kt` (Room v2) |
| `ANDROID/data/local/prefs/` | Encrypted Prefs | `TokenManager.kt` (JWT, familyId, serverUrl) |
| `ANDROID/data/remote/api/` | Retrofit Interfaces | 12 API-Interfaces |
| `ANDROID/data/remote/dto/` | Transfer Objects | 13 DTO-Dateien (580 Z.) |
| `ANDROID/data/repository/` | Business-Logik + Offline | 10 Repositories (1288 Z. gesamt) |
| `ANDROID/ui/` | Compose Screens | 11 Packages: auth, calendar, meals, todos, members, categories, settings, voice, navigation, common, theme |
| `ANDROID/sync/` | Background Sync | `SyncWorker.kt` (WorkManager, 15min-Intervall) |
| **`flutter/lib/core/`** | **Flutter Kern-Infrastruktur** | API-Client (Dio), Auth (JWT + Riverpod), Theme (Material 3), Database (Drift), Sync-Service |
| **`flutter/lib/features/`** | **Flutter Feature-Module** | 11 Features: auth, family, calendar, todos, recipes, meals, shopping, pantry, ai, cookidoo, knuspr, settings |
| **`flutter/lib/shared/`** | **Flutter Shared Widgets/Utils** | Wiederverwendbare Widgets (MemberChip, CategoryPicker, Toast, Skeleton), DateUtils, Validators |
| **`flutter/lib/app/`** | **Flutter App-Shell** | GoRouter-Konfiguration, App-Shell mit NavigationBar, Theme-Setup |
| **`flutter/web/`** | **Flutter Web-Assets** | PWA manifest, index.html fuer Web-Build |
| **`flutter/.github/`** | **Flutter CI/CD** | GitHub Actions Workflow (Web WASM + Android APK + iOS) |

---

## 4. Schluesseldateien

### Einstiegspunkte
| Pfad | Zweck |
|------|-------|
| `backend/app/main.py` | FastAPI App, Lifespan, Router-Registrierung, Static Mount |
| `backend/mcp_server.py` | MCP-Server fuer Claude-Integration (stdio/SSE) |
| **`flutter/lib/main.dart`** | **Flutter App Einstiegspunkt (Cross-Platform)** |
| `ANDROID/MainActivity.kt` | Android App Einstiegspunkt (Legacy) |
| `backend/app/static/index.html` | SPA Haupt-HTML (Legacy) |

### Konfigurationsdateien
| Pfad | Konfiguriert |
|------|-------------|
| `backend/app/config.py` | Umgebungsvariablen via Pydantic Settings |
| `backend/.env` | Laufzeit-Konfiguration (SECRET_KEY, DB, Credentials) |
| `backend/docker-compose.yml` | Container-Orchestrierung (api + mcp) |
| `backend/Dockerfile` | API-Container Build |
| `backend/Dockerfile.mcp` | MCP-Container Build |
| `backend/alembic.ini` | Alembic Migrations-Konfiguration |
| `backend/requirements.txt` | Python-Abhaengigkeiten |
| `backend/requirements-mcp.txt` | MCP-spezifische Abhaengigkeiten |
| **`flutter/pubspec.yaml`** | **Flutter-Abhaengigkeiten (Riverpod, Dio, Drift, GoRouter, etc.)** |
| **`flutter/Dockerfile`** | **Flutter Web Container Build (Nginx)** |
| **`flutter/nginx.conf`** | **Nginx-Konfiguration fuer Flutter Web + API-Proxy** |
| `.gitignore` | Git-Ausschluesse |

### Zentrale Typdefinitionen
| Pfad | Inhalt |
|------|--------|
| `backend/app/models/__init__.py` | Re-exports aller 13 ORM Models (inkl. Family) |
| `backend/app/schemas/recipe.py` | RecipeSource, Difficulty, IngredientCategory Enums |
| `backend/app/schemas/meal_plan.py` | MealSlot Enum (lunch/dinner) |

### Routen-Definitionen
| Pfad | Prefix | Endpunkte |
|------|--------|-----------|
| `backend/app/routers/auth.py` | `/api/auth` | register, login, me, link-member, family (create/join/get) |
| `backend/app/routers/events.py` | `/api/events` | CRUD |
| `backend/app/routers/todos.py` | `/api/todos` | CRUD + complete, link-event |
| `backend/app/routers/proposals.py` | `/api/proposals` + `/api/todos` | create, list, respond, pending |
| `backend/app/routers/recipes.py` | `/api/recipes` | CRUD + suggestions, history |
| `backend/app/routers/meals.py` | `/api/meals` | plan CRUD + mark-as-cooked |
| `backend/app/routers/shopping.py` | `/api/shopping` | list, generate, items CRUD, sort (KI) |
| `backend/app/routers/cookidoo.py` | `/api/cookidoo` | status, collections, recipes, import, calendar |
| `backend/app/routers/knuspr.py` | `/api/knuspr` | products, cart, delivery-slots |
| `backend/app/routers/ai.py` | `/api/ai` | available-recipes, generate-meal-plan (preview), confirm-meal-plan, undo-meal-plan |
| `backend/app/routers/categories.py` | `/api/categories` | CRUD |
| `backend/app/routers/family_members.py` | `/api/family-members` | CRUD |

### Infrastruktur-Dateien
| Pfad | Zweck |
|------|-------|
| `backend/app/database.py` | Async Engine, SessionMaker, Base, get_db |
| `backend/alembic/env.py` | Alembic async Migration-Umgebung |

---

## 5. Modul- und Komponentenkarte

> Backend-Pfade relativ zu `backend/app/`. Android-Pfade relativ zu `ANDROID/`. Flutter-Pfade relativ zu `flutter/lib/`.

### Backend-Module

| Modul | Zweck | Hauptdateien | Abhaengigkeiten |
|-------|-------|-------------|-----------------|
| **Family** | Multi-Tenancy: Familien-Verwaltung, Einladungscodes | `models/family.py`, `schemas/family.py`, `routers/auth.py` | Auth |
| **Auth** | Benutzerregistrierung, Login, JWT | `auth.py`, `routers/auth.py`, `schemas/auth.py`, `models/user.py`, `models/family.py` | bcrypt, python-jose |
| **Kalender** | Terminverwaltung | `routers/events.py`, `models/event.py`, `schemas/event.py` | Auth, FamilyMembers, Categories |
| **Todos** | Aufgaben mit Sub-Todos | `routers/todos.py`, `models/todo.py`, `schemas/todo.py` | Auth, Categories, FamilyMembers, Events |
| **Proposals** | Terminvorschlaege fuer Mehrpersonen-Todos | `routers/proposals.py`, `models/proposal.py`, `schemas/proposal.py` | Auth, Todos, FamilyMembers |
| **Rezepte** | Rezeptverwaltung mit Zutaten | `routers/recipes.py`, `models/recipe.py`, `models/ingredient.py`, `schemas/recipe.py` | Auth |
| **Essensplanung** | Wochenplan (7 Tage, Mittag/Abend) | `routers/meals.py`, `models/meal_plan.py`, `models/cooking_history.py`, `schemas/meal_plan.py` | Auth, Rezepte |
| **Einkaufsliste** | Aus Wochenplan generiert, KI-Sortierung | `routers/shopping.py`, `models/shopping_list.py`, `schemas/shopping.py` | Auth, Rezepte, Essensplanung, anthropic |
| **Familienmitglieder** | Personenverwaltung | `routers/family_members.py`, `models/family_member.py`, `schemas/family_member.py` | Auth |
| **Kategorien** | Event/Todo-Kategorien | `routers/categories.py`, `models/category.py`, `schemas/category.py` | Auth |
| **Cookidoo** | Thermomix Rezept-Import | `routers/cookidoo.py`, `integrations/cookidoo/client.py`, `integrations/cookidoo/importer.py` | Auth, Rezepte, cookidoo-api |
| **Knuspr** | Online-Supermarkt Integration | `routers/knuspr.py`, `integrations/knuspr/client.py`, `integrations/knuspr/cart.py` | Auth, Einkaufsliste, knuspr-api |
| **AI** | KI-Essensplanung via Claude (Preview/Confirm/Undo) | `routers/ai.py` | Auth, Rezepte, Cookidoo (optional), anthropic |
| **MCP-Server** | Claude Desktop Integration | `mcp_server.py` | Alle Backend-Models, mcp SDK |

### Flutter-Module (Cross-Platform)

| Modul | Zweck | Hauptdateien | Abhaengigkeiten |
|-------|-------|-------------|-----------------|
| **Flutter Core/API** | Dio HTTP-Client, Endpoints, Auth-Interceptor | `core/api/api_client.dart`, `core/api/endpoints.dart`, `core/auth/auth_interceptor.dart` | Dio |
| **Flutter Auth** | Login, Register, JWT-Persistenz, AuthState | `core/auth/auth_provider.dart`, `features/auth/presentation/login_screen.dart`, `features/auth/domain/user.dart` | Riverpod, flutter_secure_storage |
| **Flutter Family** | Familie erstellen/beitreten Onboarding | `features/family/presentation/family_onboarding_screen.dart` | Auth |
| **Flutter Kalender** | Monatsansicht, Day-Detail, Event CRUD | `features/calendar/domain/event.dart`, `features/calendar/data/event_repository.dart`, `features/calendar/presentation/calendar_screen.dart` | Auth, Members, Categories |
| **Flutter Todos** | Todo CRUD, Proposals, Quick-Add, Filter | `features/todos/domain/todo.dart`, `features/todos/data/todo_repository.dart`, `features/todos/presentation/todo_list_screen.dart` | Auth, Categories, Members |
| **Flutter Rezepte** | Rezept CRUD, URL-Import, Cookidoo-Browser | `features/recipes/domain/recipe.dart`, `features/recipes/data/recipe_repository.dart`, `features/recipes/presentation/recipe_list_screen.dart` | Auth |
| **Flutter Essensplanung** | Wochenplan, Slot-Zuweisung, Gekocht-Markierung | `features/meals/domain/meal_plan.dart`, `features/meals/data/meal_repository.dart`, `features/meals/presentation/week_plan_screen.dart` | Auth, Rezepte |
| **Flutter Einkaufsliste** | Generieren, KI-Sort, Items CRUD | `features/shopping/domain/shopping.dart`, `features/shopping/data/shopping_repository.dart`, `features/shopping/presentation/shopping_list_screen.dart` | Auth, Rezepte, Essensplanung |
| **Flutter Vorratskammer** | Pantry CRUD, Bulk-Add, Alerts | `features/pantry/domain/pantry_item.dart`, `features/pantry/data/pantry_repository.dart`, `features/pantry/presentation/pantry_screen.dart` | Auth |
| **Flutter AI** | KI-Essensplan Wizard, Voice FAB | `features/ai/domain/ai_models.dart`, `features/ai/data/ai_repository.dart`, `features/ai/presentation/ai_meal_plan_wizard.dart`, `features/ai/presentation/voice_fab.dart` | Auth, Rezepte, speech_to_text |
| **Flutter Cookidoo** | Collections browsen, Rezept-Import | `features/cookidoo/domain/cookidoo.dart`, `features/cookidoo/data/cookidoo_repository.dart`, `features/cookidoo/presentation/cookidoo_browser.dart` | Auth, Rezepte |
| **Flutter Knuspr** | Produktsuche, Warenkorb, Lieferslots | `features/knuspr/domain/knuspr.dart`, `features/knuspr/data/knuspr_repository.dart`, `features/knuspr/presentation/knuspr_screen.dart` | Auth, Einkaufsliste |
| **Flutter Settings** | Theme, Server-URL, User/Family Info | `features/settings/presentation/settings_screen.dart` | Auth |
| **Flutter Offline/Sync** | Drift DB, Pending-Queue, Background Sync | `core/database/app_database.dart`, `core/database/tables/tables.dart`, `core/sync/sync_service.dart`, `core/sync/pending_change.dart` | Drift, workmanager |
| **Flutter Theme** | Material 3 Light/Dark, AppColors | `core/theme/app_theme.dart`, `core/theme/colors.dart` | — |
| **Flutter Shared** | Wiederverwendbare Widgets, Utils | `shared/widgets/` (Toast, Skeleton, MemberChip, etc.), `shared/utils/` (DateUtils, Validators) | — |

### Legacy-Module (Web + Android)

| Modul | Zweck | Hauptdateien | Abhaengigkeiten |
|-------|-------|-------------|-----------------|
| **Frontend (Legacy)** | Vanilla JS SPA | `static/js/*.js`, `static/css/style.css`, `static/index.html` | Backend-API |
| **Android Auth (Legacy)** | Login, Register, Family Onboarding | `ui/auth/LoginScreen.kt`, `ui/auth/FamilyOnboardingScreen.kt` | AuthRepository, TokenManager |
| **Android Kalender (Legacy)** | Multi-Mode Kalenderansicht | `ui/calendar/CalendarScreen.kt`, `ui/calendar/CalendarViewModel.kt` | EventRepository, CategoryRepository |
| **Android Todos (Legacy)** | Todo-Liste mit Sub-Todos und Proposals | `ui/todos/TodosScreen.kt`, `ui/todos/TodosViewModel.kt` | TodoRepository |
| **Android Kueche (Legacy)** | Wochenplan, Rezepte, Einkauf, Vorrat, AI | `ui/meals/MealsScreen.kt` (Host), `ui/meals/WeekPlanTab.kt`, `ui/meals/RecipesTab.kt`, `ui/meals/ShoppingTab.kt`, `ui/meals/PantryTab.kt` | MealPlanRepository, RecipeRepository, ShoppingRepository, PantryRepository, AiRepository |
| **Android AI (Legacy)** | KI-Essensplan + Sprachbefehle | `ui/meals/AiMealPlanSheet.kt`, `ui/voice/VoiceOverlay.kt`, `ui/voice/VoiceViewModel.kt` | AiRepository, SpeechRecognizer |
| **Android Data Layer (Legacy)** | Room + Retrofit + Offline-Queue | `data/local/`, `data/remote/`, `data/repository/`, `sync/SyncWorker.kt` | Room 2.6.1, Retrofit 2.11, WorkManager |

---

## 6. Patterns und Konventionen

### Naming Conventions
- **Python-Dateien**: snake_case (`meal_plan.py`, `cooking_history.py`)
- **Dart-Dateien**: snake_case (`meal_plan.dart`, `ai_models.dart`)
- **JS-Dateien**: snake_case (`meals.js`, `shopping.js`) (Legacy)
- **Klassen**: PascalCase (`MealPlan`, `ShoppingItem`, `CookingHistory`)
- **Funktionen**: snake_case (Python), camelCase (Dart, JS)
- **Dart-Variablen**: camelCase, private mit `_` Prefix
- **API-Pfade**: kebab-case (`/family-members/`, `/link-member`)
- **DB-Tabellen**: snake_case Plural (`recipes`, `shopping_items`, `meal_plan`)
- **Drift-Tabellen**: PascalCase Plural (`CachedEvents`, `PendingChanges`)

### Fehlerbehandlung
- Backend: `HTTPException` mit spezifischen Status-Codes und deutschen Fehlermeldungen
- Flutter: try/catch um Repository-Calls, `ApiException` Klasse, Toast-Benachrichtigungen (`showAppToast`)
- Frontend (Legacy): try/catch in async Funktionen, Fehleranzeige in `.modal-error` Elementen oder `alert()`
- Externe Integrationen: Graceful Degradation (Cookidoo/Knuspr optional, `ImportError`-Guards)

### Logging
- Python `logging` Modul, Logger-Name `"kalender"` (main), `"kalender.cookidoo"`, etc.
- Kein strukturiertes Logging-Framework

### Authentifizierung
- JWT Bearer Token, `OAuth2PasswordBearer(tokenUrl="/api/auth/login")`
- Passwort-Hashing: `bcrypt` direkt (nicht passlib)
- Token-Lifetime: 24h (konfigurierbar via `ACCESS_TOKEN_EXPIRE_MINUTES`)
- Frontend: Token in `localStorage`, automatischer Reload bei 401

### State Management
- Backend: SQLAlchemy async Sessions, commit in `get_db` Dependency
- **Flutter**: Riverpod 2 (`StateNotifierProvider`, `FutureProvider`); Drift/SQLite fuer lokale DB; `flutter_secure_storage` fuer JWT
- **Flutter Offline**: `PendingChanges` Drift-Tabelle → `SyncService` Replay (alle Module konsistent)
- **Flutter DI**: Riverpod Providers (kein Service-Locator)
- **Flutter Navigation**: GoRouter mit `ShellRoute`, Auth-Redirect, `NoTransitionPage`
- Frontend (Legacy): IIFE-Module mit Closure-Variablen (`recipes`, `weekData`, `allRecipes`)
- Android (Legacy): Room DB + EncryptedSharedPreferences (TokenManager) + StateFlow/Flow in ViewModels
- Android Offline (Legacy): `PendingChangeEntity` Queue → `SyncWorker` Replay (inkonsistent, nicht alle Module)
- Android DI (Legacy): Manueller Service-Locator in `FamilienkalenderApp` (kein Hilt/Koin)
- Android Navigation (Legacy): Jetpack Compose Navigation mit `NavHost`, sealed `Screen` Routen

### Testing
- **Keine automatisierten Tests vorhanden** (kein pytest, unittest, oder Test-Dateien)

---

## 7. Externe Abhaengigkeiten und Integrationen

### Architekturrelevante Libraries
| Library | Version | Zweck |
|---------|---------|-------|
| fastapi | 0.135.1 | Web-Framework |
| uvicorn | 0.42.0 | ASGI Server |
| sqlalchemy | 2.0.48 | ORM (async) |
| asyncpg | >=0.30.0 | Async PostgreSQL Driver |
| alembic | 1.18.4 | DB Migrationen (konfiguriert, keine Versionen) |
| pydantic | 2.12.5 | Datenvalidierung |
| pydantic-settings | 2.13.1 | Umgebungskonfiguration |
| python-jose | 3.5.0 | JWT Token |
| bcrypt | 5.0.0 | Passwort-Hashing |
| python-multipart | 0.0.22 | Form-Daten Parsing |
| cookidoo-api | 0.16.0 | Thermomix/Cookidoo Integration |
| knuspr-api | 0.3.0 | Knuspr.de Integration |
| anthropic | >=0.42.0 | Claude AI API |
| mcp[cli] | (requirements-mcp.txt) | MCP Server SDK |
| **Flutter (Cross-Platform)** | | |
| flutter_riverpod | ^2.5.0 | State Management (Riverpod 2) |
| dio | ^5.4.0 | HTTP Client |
| go_router | ^14.0.0 | Deklaratives Routing |
| drift + sqlite3_flutter_libs | ^2.15.0 | Lokale SQLite DB (Offline-Cache) |
| flutter_secure_storage | ^9.0.0 | Sichere Token-Persistenz |
| workmanager | ^0.5.0 | Background Sync (Android/iOS) |
| speech_to_text | ^6.6.0 | Spracherkennung |
| cached_network_image | ^3.3.0 | Bild-Caching |
| intl | ^0.19.0 | Datumsformatierung/Lokalisierung |
| uuid | ^4.0.0 | UUID-Generierung |
| **Android (Legacy)** | | |
| Compose BOM | 2024.12.01 | Jetpack Compose UI |
| Navigation Compose | 2.8.5 | Screen-Navigation |
| Retrofit | 2.11.0 | HTTP Client |
| OkHttp | 4.12.0 | HTTP + Auth Interceptor |
| Room | 2.6.1 | Lokale SQLite DB |
| WorkManager | 2.10.0 | Background Sync |
| Coroutines | 1.9.0 | Async Kotlin |
| Coil Compose | 2.7.0 | Image Loading |
| Security Crypto | 1.1.0-alpha06 | Encrypted SharedPreferences |
| Accompanist SwipeRefresh | 0.36.0 | Pull-to-Refresh |

### Externe Services
| Service | Anbindung | Zweck |
|---------|-----------|-------|
| **Cookidoo** (Thermomix) | `cookidoo-api` Python Library | Rezepte importieren, Sammlungen durchblaettern |
| **Knuspr.de** | `knuspr-api` Python Library | Produkte suchen, Warenkorb befuellen |
| **Anthropic Claude** | `anthropic` Python SDK | KI-Essensplanung |

### Umgebungsvariablen
| Variable | Zweck |
|----------|-------|
| `SECRET_KEY` | JWT Signierung |
| `DATABASE_URL` | PostgreSQL-Verbindungsstring |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | JWT-Lebensdauer |
| `ALGORITHM` | JWT-Algorithmus (HS256) |
| `COOKIDOO_EMAIL` | Cookidoo Account E-Mail |
| `COOKIDOO_PASSWORD` | Cookidoo Account Passwort |
| `KNUSPR_EMAIL` | Knuspr Account E-Mail |
| `KNUSPR_PASSWORD` | Knuspr Account Passwort |
| `ANTHROPIC_API_KEY` | Anthropic API Key |
| `MCP_TRANSPORT` | MCP Transport-Modus (stdio/sse, nur mcp_server.py) |
| `MCP_FAMILY_ID` | Familie fuer MCP-Server (Default: 1) |

---

## 8. Haeufige Aufgaben → Dateipfade

> Backend-Pfade vollstaendig ab Repo-Root. Flutter-Pfade relativ zu `flutter/lib/`. Android-Pfade relativ zu `ANDROID/` (s. Dateikopf).

### Backend

| Aufgabe | Relevante Dateien |
|---------|-------------------|
| Neues DB-Model anlegen | `backend/app/models/`, `backend/app/models/__init__.py` |
| Neuen API-Endpunkt hinzufuegen | `backend/app/routers/`, `backend/app/main.py` (Router registrieren) |
| Pydantic Schema aendern | `backend/app/schemas/` |
| Auth/JWT aendern | `backend/app/auth.py`, `backend/app/routers/auth.py` |
| Cookidoo-Integration erweitern | `backend/integrations/cookidoo/client.py`, `backend/app/routers/cookidoo.py` |
| Knuspr-Integration erweitern | `backend/integrations/knuspr/client.py`, `backend/app/routers/knuspr.py` |
| MCP-Tools hinzufuegen | `backend/mcp_server.py` |
| Docker-Konfiguration (Backend) | `backend/Dockerfile`, `backend/Dockerfile.mcp`, `backend/docker-compose.yml` |
| Umgebungsvariablen aendern | `backend/app/config.py`, `backend/.env` |
| Datenbank zuruecksetzen | `docker-compose exec db psql` (PostgreSQL zuruecksetzen) |

### Flutter (Cross-Platform — Primaer)

| Aufgabe | Relevante Dateien |
|---------|-------------------|
| Flutter neues Feature | Domain (`features/<name>/domain/`), Repository (`features/<name>/data/`), Screen (`features/<name>/presentation/`), Endpoint (`core/api/endpoints.dart`), ggf. Drift-Tabelle (`core/database/tables/tables.dart`) |
| Flutter Kalender aendern | `features/calendar/presentation/calendar_screen.dart`, `features/calendar/data/event_repository.dart`, `features/calendar/domain/event.dart` |
| Flutter Todos aendern | `features/todos/presentation/todo_list_screen.dart`, `features/todos/data/todo_repository.dart`, `features/todos/domain/todo.dart` |
| Flutter Rezepte aendern | `features/recipes/presentation/recipe_list_screen.dart`, `features/recipes/data/recipe_repository.dart`, `features/recipes/domain/recipe.dart` |
| Flutter Essensplanung | `features/meals/presentation/week_plan_screen.dart`, `features/meals/data/meal_repository.dart`, `features/meals/domain/meal_plan.dart` |
| Flutter KI-Essensplanung | `features/ai/presentation/ai_meal_plan_wizard.dart`, `features/ai/data/ai_repository.dart`, `features/ai/domain/ai_models.dart` |
| Flutter Einkaufsliste | `features/shopping/presentation/shopping_list_screen.dart`, `features/shopping/data/shopping_repository.dart`, `features/shopping/domain/shopping.dart` |
| Flutter Vorratskammer | `features/pantry/presentation/pantry_screen.dart`, `features/pantry/data/pantry_repository.dart`, `features/pantry/domain/pantry_item.dart` |
| Flutter Sprachbefehle | `features/ai/presentation/voice_fab.dart`, `features/ai/data/ai_repository.dart` |
| Flutter Cookidoo | `features/cookidoo/presentation/cookidoo_browser.dart`, `features/cookidoo/data/cookidoo_repository.dart` |
| Flutter Knuspr | `features/knuspr/presentation/knuspr_screen.dart`, `features/knuspr/data/knuspr_repository.dart` |
| Flutter Auth aendern | `core/auth/auth_provider.dart`, `core/auth/auth_interceptor.dart`, `features/auth/presentation/login_screen.dart` |
| Flutter Navigation/Shell | `app/router.dart`, `app/app_shell.dart` |
| Flutter Theme/Styling | `core/theme/app_theme.dart`, `core/theme/colors.dart` |
| Flutter Offline-Sync | `core/sync/sync_service.dart`, `core/sync/pending_change.dart`, `core/database/tables/tables.dart`, `core/database/app_database.dart` |
| Flutter Shared Widgets | `shared/widgets/` (Toast, Skeleton, MemberChip, CategoryPicker, PriorityBadge, etc.) |
| Flutter Docker (Web) | `flutter/Dockerfile`, `flutter/nginx.conf` |
| Flutter CI/CD | `flutter/.github/workflows/build.yml` |
| Flutter Abhaengigkeiten | `flutter/pubspec.yaml` |

### Legacy (Web + Android)

| Aufgabe | Relevante Dateien |
|---------|-------------------|
| Web Frontend-View (Legacy) | `backend/app/static/index.html`, `backend/app/static/js/`, `backend/app/static/css/style.css` |
| CSS/Styling (Legacy) | `backend/app/static/css/style.css` |
| Cache-Busting (Legacy) | `backend/app/static/index.html` (`?v=N` an `<script>` und `<link>`) |
| Android UI (Legacy) | `ui/` |
| Android neues Feature (Legacy) | DTO (`data/remote/dto/`), API (`data/remote/api/`), Entity+DAO (`data/local/db/`), Repository (`data/repository/`), ViewModel+Screen (`ui/`), `AppDatabase.kt`, `FamilienkalenderApp.kt`, `RetrofitClient.kt` |
| Android Offline-Sync (Legacy) | `sync/SyncWorker.kt`, `data/local/db/entity/PendingChangeEntity.kt`, Repositories |

---

## 9. Bekannte Besonderheiten

### Backend
- **Kein Alembic-Migrationen**: Schema wird per `create_all` beim Start erstellt. Bei Schema-Aenderungen muss die DB manuell zurueckgesetzt werden
- **Externe Integrationen optional**: Cookidoo und Knuspr funktionieren nur mit installierten Libraries und konfigurierten Credentials. App funktioniert vollstaendig ohne
- **MCP-Server eigene DB-Session**: `mcp_server.py` erstellt eigene SQLAlchemy-Engine, teilt sich keine Sessions mit der FastAPI-App
- **CORS**: Komplett offen (`allow_origins=["*"]`), nur fuer Entwicklung geeignet
- **bcrypt direkt statt passlib**: Wegen Python 3.14 / bcrypt>=5.0.0 Inkompatibilitaet mit passlib
- **Cookidoo-API hat keine Suchfunktion**: Import erfolgt ueber Collections durchblaettern oder Shopping-List
- **AI-Essensplanung ist Preview-basiert**: generate-meal-plan speichert nicht direkt, erst confirm-meal-plan schreibt in die DB. Undo per meal_ids moeglich
- **Multi-Tenancy per Row-Level family_id**: Alle Kern-Tabellen haben eine `family_id`-Spalte. `require_family_id` Dependency in `auth.py` sichert Zugriff
- **Family-Erstellung seedet Default-Kategorien**: 5 Standard-Kategorien bei Familien-Erstellung

### Flutter (Cross-Platform — Neu)
- **Ersetzt 3 separate Codebases**: Flutter-App (`flutter/`) ersetzt Web (Vanilla JS), Android (Kotlin), iOS (Swift) — Reduktion von ~26.600 auf ~8.100 LOC (~70%)
- **Kein Flutter SDK fuer Generierung noetig**: Projektstruktur wurde manuell erstellt, `flutter pub get` und Build erfordern Flutter SDK
- **Drift Code-Generierung**: `app_database.g.dart` muss per `dart run build_runner build` generiert werden
- **Material 3**: Durchgehend Material 3 Design mit Light/Dark-Mode, `ColorScheme.fromSeed`
- **Offline konsistent**: Anders als Android-Legacy hat Flutter Offline-Queue fuer ALLE Module (Events, Todos, Recipes, Categories, Members, Shopping, Pantry)
- **GoRouter Auth-Redirect**: Unauthentifizierte User werden automatisch zu `/login` umgeleitet, User ohne Familie zu `/family-onboarding`
- **Voice FAB global**: `VoiceFAB` in `AppShell` eingebunden, auf allen Screens verfuegbar
- **Server-URL konfigurierbar**: User kann Backend-URL in Login-Screen und Settings aendern (gespeichert in Secure Storage)
- **PWA-faehig**: Web-Build inkludiert `manifest.json`, Service-Worker-ready
- **Nginx-Proxy**: Flutter Web Docker-Container proxied `/api/` Requests an Backend (kein CORS noetig)
- **CI/CD**: GitHub Actions baut Web (WASM), Android (APK), iOS (no-codesign) bei Push auf `main`

### Legacy (Web + Android)
- **Web Frontend kein Build-System**: Reines Vanilla JS, kein Bundler. Cache-Busting manuell per `?v=N`
- **Android: Kein DI-Framework**: Manueller Service-Locator in `FamilienkalenderApp.kt` statt Hilt/Koin
- **Android: Room `fallbackToDestructiveMigration()`**: Schema-Aenderungen loeschen lokale Daten
- **Android: Offline-Queue inkonsistent**: Nur Events, Todos, Recipes, Categories, Members
- **Android: `usesCleartextTraffic="true"`**: Fuer LAN-Entwicklung
- **Android: 60s Timeouts**: Retrofit Timeouts auf 60s fuer AI-Calls

---

## 10. Methodenkarte fuer grosse Dateien

> Fuer Dateien >300 Zeilen. Ermoeglicht gezieltes Lesen per Zeilen-Offset statt gesamte Datei.

### `backend/app/routers/ai.py` (494 Zeilen)

| Methode/Endpunkt | Zeile | Zweck |
|------------------|-------|-------|
| `_monday_of` | 31 | Montag der Woche berechnen |
| `GET /available-recipes` | 84 | Lokale Rezepte, Cookidoo-Status und Slot-Belegung fuer AI-Dialog |
| `POST /generate-meal-plan` | 154 | Claude-Vorschau generieren (speichert NICHT in DB) |
| `POST /confirm-meal-plan` | 400 | Vorschau bestaetigen, Cookidoo-Rezepte importieren, Einkaufsliste generieren |
| `POST /undo-meal-plan` | 476 | KI-Plan per Meal-IDs rueckgaengig machen |

### `backend/mcp_server.py` (1171 Zeilen)

| Bereich | Methoden | Zeilen |
|---------|----------|--------|
| Setup | `get_db` | 54 |
| Events | `get_events`, `create_event`, `update_event`, `delete_event` | 186–310 |
| Todos | `get_todos`, `create_todo`, `complete_todo`, `delete_todo` | 312–416 |
| Agenda/Links | `get_agenda`, `get_open_todos_by_category`, `link_todo_to_event` | 418–515 |
| Meals | `get_meal_plan`, `set_meal_slot`, `mark_as_cooked` | 517–662 |
| Recipes | `get_cooking_history`, `get_recipe_suggestions` | 664–761 |
| Shopping | `get_shopping_list`, `generate_shopping_list`, `add_shopping_item`, `check_shopping_item` | 763–938 |
| Cookidoo | `get_cookidoo_recipe`, `import_recipe_to_plan`, `sync_cookidoo_week` | 941–992 |
| Knuspr | `search_knuspr_product`, `add_to_knuspr_cart`, `send_shopping_list_to_knuspr`, `get_knuspr_delivery_slots`, `clear_knuspr_cart` | 994–1070 |
| Resources | `resource_today`, `resource_week`, `resource_open_todos`, `resource_high_priority`, `resource_shopping_list`, `resource_shopping_week_plan`, `resource_recipe_suggestions`, `resource_cooking_history_90d` | 1073–1130 |

### `backend/app/static/js/app.js` (315 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `updateAuthUI` | 10 | Auth-Screen Labels/Toggle synchronisieren |
| `initAuth` | 24 | Login/Register Submit Handler |
| `showAuth` | 48 | Auth-Screen anzeigen |
| `showApp` | 53 | App-Shell anzeigen, Module initialisieren |
| `promptMemberLink` | 74 | Modal: User mit Familienmitglied verknuepfen |
| `refreshProposalBadge` | 97 | Offene Vorschlaege Badge aktualisieren |
| `loadSharedData` | 118 | Kategorien + Mitglieder parallel laden |
| `initNav` | 126 | Navigation-Buttons, Logout, Proposals |
| `switchView` | 140 | View umschalten, Refresh triggern |
| `showPendingProposals` | 150 | Modal: Offene Terminvorschlaege |
| `respondProposal` | 180 | Vorschlag annehmen/ablehnen |
| `counterProposal` | 189 | Gegenvorschlag senden |
| `openModal` | 214 | Modal oeffnen mit optionalem Form-Handler |
| `closeModal` | 240 | Modal schliessen |
| `memberChipsHtml` | 246 | Member-Chips HTML generieren |
| `categoryOptionsHtml` | 252 | Kategorie-Select-Options generieren |
| `initChipSelection` | 257 | Chip-Klick-Selektion |
| `getSelectedChipIds` | 263 | Selektierte Chip-IDs auslesen |
| `formatTime` | 267 | Uhrzeit formatieren (de-DE) |
| `formatDate` | 272 | Datum formatieren (de-DE) |
| `getCategoryColor` | 276 | Kategorie-Farbe nach ID |
| `init` | 282 | Einstiegspunkt: Auth + Nav initialisieren |
| `esc` (global) | 314 | HTML-Escaping |

### `backend/app/static/js/meals.js` (599 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `init` | 19 | Event-Listener: Navigation, Tabs, AI-Button |
| `navigate` | 38 | Woche vor/zurueck |
| `loadWeek` | 44 | Wochenplan + Rezepte laden |
| `render` | 56 | Wochenplan-Grid rendern (inkl. Undo-Bar) |
| `renderSlotCell` | 99 | Einzelne Slot-Zelle (leer/gefuellt) |
| `assignSlot` | 139 | Modal: Rezept einem Slot zuweisen |
| `markCooked` | 202 | Modal: Als gekocht markieren mit Bewertung |
| `_openAiModal` | 227 | AI-Modal oeffnen mit Spinner |
| `openAiMealPlanDialog` | 245 | AI-Dialog starten, available-recipes laden |
| `_showConfigStep` | 263 | Schritt 1: Woche, Slot-Grid, Cookidoo-Toggle, Portionen |
| `_showPreviewStep` | 390 | Schritt 2: Claude-Vorschlaege als Tabelle + Begruendung, Confirm/Regen/Back |
| `_showReasoningPopup` | 531 | Popup mit KI-Begruendung anzeigen |
| `undoAiPlan` | 553 | KI-Plan rueckgaengig machen |
| `dismissUndo` | 565 | Undo-Bar ausblenden |
| `generateShoppingList` | 571 | Einkaufsliste aus Wochenplan generieren |

### `backend/app/static/js/recipes.js` (469 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `init` | 12 | Event-Listener: Add, Cookidoo-Import, Status-Check |
| `checkCookidoo` | 18 | Cookidoo-Verfuegbarkeit pruefen, Button ein/ausblenden |
| `refresh` | 26 | Rezepte laden und rendern |
| `renderList` | 34 | Rezept-Karten-Grid oder Leer-Zustand |
| `formatPrepTime` | 78 | Zubereitungszeiten formatieren |
| `openRecipeForm` | 86 | Erstellen/Bearbeiten-Modal mit Zutaten |
| `ingredientRowHtml` | 185 | HTML fuer eine Zutat-Zeile |
| `collectIngredients` | 205 | Zutaten aus DOM fuer API-Payload sammeln |
| `_setModalWide` | 229 | Modal breit/schmal umschalten |
| `openCookidooBrowser` | 235 | Cookidoo-Browser Modal oeffnen |
| `_renderCookidooMain` | 257 | Einkaufsliste + Sammlungen rendern |
| `openCookidooCollection` | 302 | In Sammlung navigieren |
| `_cookidooCard` | 330 | Einzelne Rezeptkarte (anklickbar) |
| `_goBack` | 354 | Cookidoo-Navigation zurueck |
| `previewCookidoo` | 370 | Rezeptvorschau mit Bild laden |
| `importFromCookidoo` | 432 | Rezept importieren mit Feedback |
| `edit` | 456 | Rezept bearbeiten |
| `remove` | 460 | Rezept loeschen |

### `backend/app/static/css/style.css` (1699 Zeilen)

| Bereich | Zeilen (ca.) | Inhalt |
|---------|--------------|--------|
| CSS-Variablen | 1–20 | Farben, Schatten, Radien |
| Basis-Layout | 20–60 | Body, Topbar, Navigation |
| Auth-Screen | 60–120 | Login/Register |
| Kalender | 120–250 | Monatsgrid, Tageszellen, Events |
| Todos | 250–400 | Liste, Items, Sub-Todos, Badges |
| Modal | 480–510 | Overlay, Modal-Box, Header, Footer |
| Familienmitglieder | 510–570 | Karten-Grid |
| Wochenplan | 580–710 | Week-Grid, Slots, Diff-Badges |
| Einkaufsliste | 710–780 | Kategorien, Items, Check-Buttons |
| Shopping Store Picker | 922–980 | Store-Picker, Sort-Badge, Section-Header |
| Rezepte | 980–1060 | Grid-Karten, Bilder, Badges |
| Zutaten-Formular | 1060–1090 | Ingredient-Rows |
| Cookidoo-Browser | 1090–1320 | Collections, Karten, Vorschau, Spinner |
| AI Meal Plan Dialog | 1320–1550 | Slot-Grid, Cookidoo-Toggle, Preview-Tabelle, Source-Badges, Undo-Bar |
| AI Reasoning Popup | 1600–1665 | Begruendungs-Button, Overlay-Popup, Animation |
| Responsive | 1668–1699 | Mobile Breakpoints (inkl. AI-Responsive) |

### `ANDROID/ui/meals/RecipesTab.kt` (571 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `RecipesTab` | 34 | Rezepte-Tab: Grid, Suche, Cookidoo-Button |
| `RecipeCard` | 144 | Rezept-Karte mit Bild und Badges |
| `RecipeDetailDialog` | 258 | Detailansicht mit Zutaten und History |
| `StatChip` | 392 | Kleine Info-Chips (Schwierigkeit, Zeit) |
| `RecipeFormDialog` | 404 | Erstellen/Bearbeiten-Modal mit Zutatenformular |

### `ANDROID/ui/calendar/CalendarScreen.kt` (485 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `CalendarScreen` | 35 | Kalender-Hauptscreen |
| `ViewModeSelector` | 133 | Monats-/Wochen-/3-Tage-/Tagesansicht Chips |
| `NavigationHeader` | 152 | Titel + Navigation vor/zurueck |
| `headerText` | 186 | Titeltext je nach Ansichtsmodus berechnen |
| `CalendarContent` | 206 | Switch zwischen den Ansichten |
| `DayEventList` | 234 | Eventliste fuer einen Tag |
| `DayStrip` | 290 | Horizontaler Tagesstreifen (Wochen-/3-Tage-Modus) |
| `WeekdayHeaders` | 332 | Mo-So Kopfzeile |
| `MonthGrid` | 349 | Monatsgrid mit Tageszellen |
| `DayCell` | 391 | Einzelne Tageszelle im Monatsgrid |
| `EventItem` | 433 | Event-Zeile mit Kategorie-Farbe |

### `ANDROID/ui/navigation/AppNavigation.kt` (398 Zeilen)

| Funktion/Klasse | Zeile | Zweck |
|-----------------|-------|-------|
| `Screen` (sealed class) | 51 | Routen-Definitionen (Calendar, Todos, Meals, Members, Settings, Categories) |
| `AppNavigation` | 64 | Root-Scaffold: TopBar, BottomNav, NavHost, Voice FAB, Mic-Permission |
| `PendingProposalsDialog` | 293 | Dialog: Offene Terminvorschlaege |
| `PendingProposalRow` | 363 | Einzelne Vorschlag-Zeile mit Antwort-Button |

### `ANDROID/ui/meals/WeekPlanTab.kt` (348 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `WeekPlanTab` | 30 | Wochenplan: Navigation, AI-Button, Undo-Bar |
| `DayRow` | 155 | Ein Tag (Datum + Mittag/Abend Slots) |
| `SlotCard` | 203 | Einzelner Slot (leer oder mit Rezept) |
| `MarkCookedDialog` | 300 | Als-gekocht-markieren mit Bewertung |

### `ANDROID/ui/meals/ShoppingTab.kt` (329 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `ShoppingTab` | 25 | Einkaufsliste: KI-Sort, Clear, Progress |
| `CategoryView` | 156 | Gruppiert nach Kategorie/Store-Section |
| `RecipeView` | 185 | Gruppiert nach Rezept |
| `ShoppingItemRow` | 243 | Einzelner Artikel mit Check/Delete |
| `AddShoppingItemDialog` | 281 | Manuelles Hinzufuegen |

### `ANDROID/ui/meals/PantryTab.kt` (312 Zeilen)

| Funktion | Zeile | Zweck |
|----------|-------|-------|
| `PantryTab` | 25 | Vorratskammer: Alert-Banner, Quick-Add, Kategorie-Liste |
| `PantryAlertBanner` | 112 | Warnungen (niedrig/ablaufend) mit Aktionen |
| `PantryQuickAddBar` | 160 | Schnelles Hinzufuegen mit Name, Menge, Einheit |
| `PantryItemRow` | 215 | Artikel-Zeile mit Status-Indikator |
| `PantryFormDialog` | 266 | Erstellen/Bearbeiten-Dialog mit MHD + Mindestbestand |
| `categoryLabel` | 306 | Kategorie-Code → deutsches Label mit Emoji |

### `ANDROID/ui/meals/MealsViewModel.kt` (252 Zeilen)

| Methode | Zeile | Zweck |
|---------|-------|-------|
| `MealsViewModel` | 22 | ViewModel: Wochenplan + Rezepte + Shopping + Cookidoo + AI |
| `checkCookidooAvailability` | 77 | Cookidoo-Status pruefen |
| `loadCookidoo` | 89 | Collections + Einkaufsliste laden |
| `importFromCookidoo` | 115 | Rezept importieren |
| `refreshAll` | 129 | Wochenplan + Rezepte + Shopping aktualisieren |
| `aiSortShopping` | 213 | KI-Sortierung der Einkaufsliste |
| `setUndoMealIds` | 221 | Undo-IDs fuer KI-Plan speichern |
| `undoAiPlan` | 225 | KI-Plan rueckgaengig machen |
| `Factory` | 240 | ViewModelProvider.Factory (5 Parameter) |

---

## 11. Vorhandene Dokumentation

| Pfad | Beschreibung | Themen (→ Abschnitt 8) |
|------|-------------|------------------------|
| `PROJECT_INDEX.md` | Projektstruktur-Dokumentation (dieses Dokument) | Alle Aufgaben |
| `FEATURES.md` | Funktionsuebersicht aller Features nach Plattform (Web, Flutter, Android, MCP, API) | Alle Aufgaben |
| `IMPROVEMENTS.md` | Verbesserungsvorschlaege mit Priorisierung und Roadmap | Alle Aufgaben |
| `flutter/README.md` | Flutter-App Dokumentation: Tech-Stack, Architektur, Getting Started, Docker, CI/CD | Flutter-Aufgaben |
| `ANDROID_APP_PLAN.md` | Detaillierter Implementierungsplan fuer die Android App (Legacy) | Android-Aufgaben |
| `IOS_APP_PLAN.md` | Implementierungsplan fuer die iOS App (Legacy, ersetzt durch Flutter) | iOS-Aufgaben |
| `plans/cross_platform_migration_*.plan.md` | Migrationsplan: Analyse Web/Android/iOS → Flutter Cross-Platform | Flutter-Migration |

---

## 12. Quick Reference

### Befehle
```bash
# Backend starten (Entwicklung)
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# MCP-Server starten
cd backend
python mcp_server.py

# Docker (Produktion — Backend)
cd backend
docker-compose up -d

# Datenbank zuruecksetzen (PostgreSQL)
docker-compose exec db psql -U kalender -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# PostgreSQL starten (nur DB)
cd backend
docker-compose up -d db

# Abhaengigkeiten installieren (Backend)
cd backend
pip install -r requirements.txt
```

### Flutter (Cross-Platform)
```bash
# Flutter Abhaengigkeiten installieren
cd flutter
flutter pub get

# Code-Generierung (Drift DB)
cd flutter
dart run build_runner build --delete-conflicting-outputs

# Flutter Web starten (Entwicklung)
cd flutter
flutter run -d chrome

# Flutter Android/iOS starten
cd flutter
flutter run

# Flutter Web bauen (WASM, Produktion)
cd flutter
flutter build web --wasm

# Flutter Android bauen (APK)
cd flutter
flutter build apk

# Flutter Docker (Web)
cd flutter
docker build -t familienkalender-flutter .

# Flutter Tests
cd flutter
flutter test
```

| Einstellung | Wert |
|-------------|------|
| Flutter SDK | >=3.24.0 |
| Dart SDK | >=3.3.0 |
| Dart-Dateien | 69 |
| Gesamt-Zeilen | ~8.100 |
| Plattformen | Web (WASM), Android, iOS |
| State Management | Riverpod 2 |
| Lokale DB | Drift (SQLite) |
| Routing | GoRouter |

### Ports und URLs
| Service | Port | URL |
|---------|------|-----|
| FastAPI (API + Legacy Frontend) | 8000 | `http://localhost:8000` |
| Flutter Web (Nginx) | 80 | `http://localhost` |
| MCP-Server (SSE) | 8001 | `http://localhost:8001/sse` |
| OpenAPI Docs | 8000 | `http://localhost:8000/docs` |
| PostgreSQL | 5432 | `localhost:5432` |

### Deployment
- **Zielplattform**: Synology NAS (Docker)
- **Container**: `familienkalender-db` (Port 5432), `familienkalender-api` (Port 8000), `familienkalender-mcp` (Port 8001), `familienkalender-flutter` (Port 80, Nginx)
- **Datenbank-Volume**: `pgdata` (PostgreSQL Docker Volume)
- **Env-File**: `backend/.env` (nicht im Git)
- **Flutter Web**: Nginx serviert Flutter WASM Build, proxied `/api/` an Backend

### Android (Legacy)
```bash
# Android App bauen (Debug)
cd android
./gradlew assembleDebug

# Android App installieren
cd android
./gradlew installDebug
```

| Einstellung | Wert |
|-------------|------|
| compileSdk / targetSdk | 35 |
| minSdk | 26 |
| applicationId | `de.familienkalender.app` |
| Room DB Version | 2 |
| Kotlin / JVM Target | 2.1.0 / 17 |
| Kotlin-Dateien | 93 |
| Gesamt-Zeilen | ~11.500 |

### Cache-Busting (Legacy Web)
Aktueller Stand: `?v=21` (in `index.html` fuer alle JS/CSS Referenzen)
