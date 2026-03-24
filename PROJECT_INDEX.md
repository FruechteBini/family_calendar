# PROJECT_INDEX.md — Familienkalender

## 1. Projektsteckbrief

| Feld | Wert |
|------|------|
| **Projektname** | Familienkalender |
| **Typ** | Fullstack-Webapp + Android App + MCP-Server |
| **Primaere Sprachen** | Python 3.12+ (Backend), Kotlin (Android), JavaScript (Frontend) |
| **Frameworks** | FastAPI 0.135, Jetpack Compose (Android), Vanilla JS SPA |
| **Paketmanager** | pip (requirements.txt), Gradle (Android) |
| **Build-Tool** | uvicorn (dev), Docker (prod), Gradle (Android) |
| **Datenbank** | PostgreSQL 16 via SQLAlchemy 2.0 (async, asyncpg) |
| **State Management** | Backend: SQLAlchemy ORM; Frontend: Module-IIFE-Closures; Android: Room + Retrofit |
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
| Praesentationsschicht | Vanilla JS SPA, HTML, CSS | `backend/app/static/` |
| API-Schicht | FastAPI Router, Endpunkte, Auth | `backend/app/routers/` |
| Validierungsschicht | Pydantic Schemas | `backend/app/schemas/` |
| Geschaeftslogik | In Routern + Integrations | `backend/app/routers/`, `backend/integrations/` |
| Persistenzschicht | SQLAlchemy ORM Models | `backend/app/models/` |
| Externe Integrationen | Cookidoo, Knuspr Bridges | `backend/integrations/` |
| MCP-Schicht | Claude AI Tools/Resources | `backend/mcp_server.py` |
| Mobile Schicht | Kotlin/Compose Android App | `android/` |

---

## 3. Verzeichnisstruktur

```
c:\git\webapps_docs\
├── .gitignore
├── PROJECT_INDEX.md                    ← Dieses Dokument
│
├── android\                            ← Android App (Kotlin, Jetpack Compose)
│   ├── gradle\wrapper\                 ← Gradle Wrapper
│   └── app\src\main\
│       ├── AndroidManifest.xml
│       ├── java\de\familienkalender\app\
│       │   ├── MainActivity.kt         ← App-Einstiegspunkt
│       │   ├── FamilienkalenderApp.kt  ← Application-Klasse
│       │   ├── data\
│       │   │   ├── local\              ← Room DB, Entities, DAOs, TokenManager
│       │   │   ├── remote\             ← Retrofit Client, API-Interfaces, DTOs
│       │   │   └── repository\         ← Repositories (Local + Remote)
│       │   ├── sync\                   ← Background Sync (SyncWorker)
│       │   └── ui\                     ← Compose UI-Screens
│       │       ├── auth\               ← Login/Register
│       │       ├── calendar\           ← Kalenderansicht
│       │       ├── meals\              ← Essensplanung
│       │       ├── members\            ← Familienmitglieder
│       │       ├── todos\              ← Todo-Liste
│       │       ├── settings\           ← Einstellungen
│       │       ├── navigation\         ← Navigation-Composables
│       │       ├── common\             ← Shared Components
│       │       └── theme\              ← Material Theme
│       └── res\                        ← Android Resources
│
├── backend\                            ← FastAPI Backend + Frontend SPA
│   ├── Dockerfile                      ← API-Container (python:3.12-slim)
│   ├── Dockerfile.mcp                  ← MCP-Server-Container
│   ├── docker-compose.yml              ← db + api + mcp Services
│   ├── requirements.txt                ← Python-Abhaengigkeiten
│   ├── requirements-mcp.txt            ← MCP-spezifische Abhaengigkeiten
│   ├── alembic.ini                     ← Alembic-Konfiguration
│   ├── mcp_server.py                   ← MCP-Server (1171 Zeilen)
│   │
│   ├── alembic\                        ← Migrationsumgebung (noch keine Versionen)
│   │   └── env.py
│   │
│   ├── app\                            ← Haupt-Anwendungspaket
│   │   ├── main.py                     ← FastAPI App, Lifespan, Router-Registrierung
│   │   ├── config.py                   ← Pydantic Settings (.env)
│   │   ├── database.py                 ← Async SQLAlchemy Engine + Session
│   │   ├── auth.py                     ← JWT, Passwort-Hashing, get_current_user
│   │   │
│   │   ├── models\                     ← SQLAlchemy ORM Models
│   │   │   ├── __init__.py             ← Re-exports aller Models
│   │   │   ├── family.py              ← Family (Multi-Tenancy Kern-Entity)
│   │   │   ├── user.py                 ← User (Accounts)
│   │   │   ├── family_member.py        ← FamilyMember
│   │   │   ├── category.py             ← Category (Events/Todos)
│   │   │   ├── event.py                ← Event + event_members Assoc.
│   │   │   ├── todo.py                 ← Todo (hierarchisch, mit Sub-Todos)
│   │   │   ├── proposal.py             ← TodoProposal + ProposalResponse
│   │   │   ├── recipe.py               ← Recipe (mit image_url)
│   │   │   ├── ingredient.py           ← Ingredient (FK → Recipe)
│   │   │   ├── meal_plan.py            ← MealPlan (date+slot → Recipe)
│   │   │   ├── cooking_history.py      ← CookingHistory
│   │   │   └── shopping_list.py        ← ShoppingList + ShoppingItem
│   │   │
│   │   ├── schemas\                    ← Pydantic Request/Response Schemas
│   │   │   ├── auth.py                 ← Login, Register, UserResponse
│   │   │   ├── family.py              ← FamilyCreate/Join/Response
│   │   │   ├── category.py             ← CategoryCreate/Response
│   │   │   ├── event.py                ← EventCreate/Update/Response
│   │   │   ├── family_member.py        ← MemberCreate/Response
│   │   │   ├── todo.py                 ← TodoCreate/Update/Response + SubtodoResponse
│   │   │   ├── proposal.py             ← ProposalCreate/Respond/Detail
│   │   │   ├── recipe.py               ← RecipeCreate/Update/Response + Enums
│   │   │   ├── meal_plan.py            ← MealSlot/DayPlan/WeekPlanResponse
│   │   │   └── shopping.py             ← ShoppingItem/ListResponse
│   │   │
│   │   ├── routers\                    ← FastAPI Route-Module
│   │   │   ├── ai.py                   ← AI-Essensplanung mit Preview/Confirm/Undo (494 Z.)
│   │   │   ├── auth.py                 ← Register, Login, Me, Link-Member
│   │   │   ├── categories.py           ← Kategorie-CRUD
│   │   │   ├── cookidoo.py             ← Cookidoo-Integration Endpunkte
│   │   │   ├── events.py               ← Event-CRUD
│   │   │   ├── family_members.py       ← Familienmitglieder-CRUD
│   │   │   ├── knuspr.py               ← Knuspr-Integration Endpunkte
│   │   │   ├── meals.py                ← Wochenplan CRUD + als-gekocht
│   │   │   ├── proposals.py            ← Terminvorschlaege
│   │   │   ├── recipes.py              ← Rezept-CRUD + History + Suggestions
│   │   │   ├── shopping.py             ← Einkaufsliste + Generierung + KI-Sortierung
│   │   │   └── todos.py               ← Todo-CRUD + Sub-Todos
│   │   │
│   │   └── static\                     ← Frontend SPA
│   │       ├── index.html              ← Haupt-HTML (226 Zeilen)
│   │       ├── css\
│   │       │   └── style.css           ← Gesamtes Styling (1699 Zeilen)
│   │       └── js\
│   │           ├── api.js              ← Fetch-Wrapper, Token-Mgmt (46 Z.)
│   │           ├── app.js              ← Auth, Navigation, Modal (315 Z.)
│   │           ├── calendar.js         ← Monatskalender (222 Z.)
│   │           ├── todos.js            ← Todo-Liste + Sub-Todos (284 Z.)
│   │           ├── members.js          ← Familienmitglieder (117 Z.)
│   │           ├── meals.js            ← Wochenplan-Grid + AI-Dialog (578 Z.)
│   │           ├── recipes.js          ← Rezepte + Cookidoo-Browser (469 Z.)
│   │           └── shopping.js         ← Einkaufsliste + KI-Sortierung (266 Z.)
│   │
│   ├── integrations\                   ← Externe Service-Bridges
│   │   ├── cookidoo\
│   │   │   ├── client.py              ← Cookidoo-API Wrapper (190 Z.)
│   │   │   └── importer.py            ← Rezept-Import in lokale DB (94 Z.)
│   │   └── knuspr\
│   │       ├── client.py              ← Knuspr-API Wrapper (77 Z.)
│   │       └── cart.py                ← Warenkorb-Logik (54 Z.)
```

---

## 4. Schluesseldateien

### Einstiegspunkte
| Pfad | Zweck |
|------|-------|
| `backend/app/main.py` | FastAPI App, Lifespan, Router-Registrierung, Static Mount |
| `backend/mcp_server.py` | MCP-Server fuer Claude-Integration (stdio/SSE) |
| `android/app/src/main/java/.../MainActivity.kt` | Android App Einstiegspunkt |
| `backend/app/static/index.html` | SPA Haupt-HTML |

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

### Schema-Dateien
| Pfad | Zeilen |
|------|--------|
| `backend/app/database.py` | Async Engine, SessionMaker, Base, get_db |
| `backend/alembic/env.py` | Alembic async Migration-Umgebung |

---

## 5. Modul- und Komponentenkarte

| Modul | Zweck | Hauptdateien | Abhaengigkeiten |
|-------|-------|-------------|-----------------|
| **Family** | Multi-Tenancy: Familien-Verwaltung, Einladungscodes | `models/family.py`, `schemas/family.py`, `routers/auth.py` | Auth |
| **Auth** | Benutzerregistrierung, Login, JWT | `auth.py`, `routers/auth.py`, `schemas/auth.py`, `models/user.py`, `models/family.py` | bcrypt, python-jose |
| **Kalender** | Terminverwaltung | `routers/events.py`, `models/event.py`, `schemas/event.py` | Auth, FamilyMembers, Categories |
| **Todos** | Aufgaben mit Sub-Todos | `routers/todos.py`, `models/todo.py`, `schemas/todo.py` | Auth, Categories, FamilyMembers, Events |
| **Proposals** | Terminvorschlaege fuer Mehrpersonen-Todos | `routers/proposals.py`, `models/proposal.py`, `schemas/proposal.py` | Auth, Todos, FamilyMembers |
| **Rezepte** | Rezeptverwaltung mit Zutaten | `routers/recipes.py`, `models/recipe.py`, `models/ingredient.py`, `schemas/recipe.py` | Auth |
| **Essensplanung** | Wochenplan (7 Tage, Mittag/Abend) | `routers/meals.py`, `models/meal_plan.py`, `models/cooking_history.py`, `schemas/meal_plan.py` | Auth, Rezepte |
| **Einkaufsliste** | Aus Wochenplan generiert, manuell erweiterbar, KI-Sortierung nach Supermarkt | `routers/shopping.py`, `models/shopping_list.py`, `schemas/shopping.py` | Auth, Rezepte, Essensplanung, anthropic |
| **Familienmitglieder** | Personenverwaltung | `routers/family_members.py`, `models/family_member.py`, `schemas/family_member.py` | Auth |
| **Kategorien** | Event/Todo-Kategorien | `routers/categories.py`, `models/category.py`, `schemas/category.py` | Auth |
| **Cookidoo** | Thermomix Rezept-Import | `routers/cookidoo.py`, `integrations/cookidoo/client.py`, `integrations/cookidoo/importer.py` | Auth, Rezepte, cookidoo-api |
| **Knuspr** | Online-Supermarkt Integration | `routers/knuspr.py`, `integrations/knuspr/client.py`, `integrations/knuspr/cart.py` | Auth, Einkaufsliste, knuspr-api |
| **AI** | KI-Essensplanung via Claude mit Preview/Confirm/Undo + Cookidoo-Rezeptpool | `routers/ai.py` | Auth, Rezepte, Cookidoo (optional), anthropic |
| **MCP-Server** | Claude Desktop Integration | `mcp_server.py` | Alle Backend-Models, mcp SDK |
| **Frontend** | Vanilla JS SPA | `static/js/*.js`, `static/css/style.css`, `static/index.html` | Backend-API |
| **Android** | Native Kotlin App | `android/app/src/main/java/...` | Backend-API, Room, Retrofit |

---

## 6. Patterns und Konventionen

### Naming Conventions
- **Python-Dateien**: snake_case (`meal_plan.py`, `cooking_history.py`)
- **JS-Dateien**: snake_case (`meals.js`, `shopping.js`)
- **Klassen**: PascalCase (`MealPlan`, `ShoppingItem`, `CookingHistory`)
- **Funktionen**: snake_case (Python), camelCase (JS)
- **API-Pfade**: kebab-case (`/family-members/`, `/link-member`)
- **DB-Tabellen**: snake_case Plural (`recipes`, `shopping_items`, `meal_plan`)

### Fehlerbehandlung
- Backend: `HTTPException` mit spezifischen Status-Codes und deutschen Fehlermeldungen
- Frontend: try/catch in async Funktionen, Fehleranzeige in `.modal-error` Elementen oder `alert()`
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
- Frontend: IIFE-Module mit Closure-Variablen (`recipes`, `weekData`, `allRecipes`)
- Android: Room DB + SharedPreferences (TokenManager)

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

| Aufgabe | Relevante Dateien |
|---------|-------------------|
| Neues DB-Model anlegen | `backend/app/models/`, `backend/app/models/__init__.py` |
| Neuen API-Endpunkt hinzufuegen | `backend/app/routers/`, `backend/app/main.py` (Router registrieren) |
| Pydantic Schema aendern | `backend/app/schemas/` |
| Neuen Frontend-View anlegen | `backend/app/static/index.html` (HTML), `backend/app/static/js/` (JS), `backend/app/static/css/style.css` |
| Auth/JWT aendern | `backend/app/auth.py`, `backend/app/routers/auth.py` |
| Cookidoo-Integration erweitern | `backend/integrations/cookidoo/client.py`, `backend/app/routers/cookidoo.py` |
| Knuspr-Integration erweitern | `backend/integrations/knuspr/client.py`, `backend/app/routers/knuspr.py` |
| Rezeptverwaltung aendern | `backend/app/routers/recipes.py`, `backend/app/static/js/recipes.js` |
| Essensplanung aendern | `backend/app/routers/meals.py`, `backend/app/static/js/meals.js` |
| KI-Essensplanung aendern | `backend/app/routers/ai.py`, `backend/app/static/js/meals.js` (AI-Dialog ab Z.232) |
| Einkaufsliste aendern | `backend/app/routers/shopping.py`, `backend/app/static/js/shopping.js` |
| MCP-Tools hinzufuegen | `backend/mcp_server.py` |
| Docker-Konfiguration | `backend/Dockerfile`, `backend/Dockerfile.mcp`, `backend/docker-compose.yml` |
| Umgebungsvariablen aendern | `backend/app/config.py`, `backend/.env` |
| CSS/Styling aendern | `backend/app/static/css/style.css` |
| Android UI aendern | `android/app/src/main/java/.../ui/` |
| Cache-Busting erhoehen | `backend/app/static/index.html` (Query-Parameter `?v=N` an allen `<script>` und `<link>`) |
| Datenbank zuruecksetzen | `docker-compose exec db psql` (PostgreSQL zuruecksetzen) |

---

## 9. Bekannte Besonderheiten

- **Kein Alembic-Migrationen**: Schema wird per `create_all` beim Start erstellt. Bei Schema-Aenderungen muss die DB manuell zurueckgesetzt werden (PostgreSQL: DROP/CREATE oder Alembic nutzen)
- **Frontend ist kein Build-System**: Reines Vanilla JS, kein Bundler, kein TypeScript. Cache-Busting manuell per `?v=N` Query-Parameter
- **Externe Integrationen optional**: Cookidoo und Knuspr funktionieren nur mit installierten Libraries und konfigurierten Credentials. App funktioniert vollstaendig ohne
- **MCP-Server eigene DB-Session**: `mcp_server.py` erstellt eigene SQLAlchemy-Engine, teilt sich keine Sessions mit der FastAPI-App
- **CORS**: Komplett offen (`allow_origins=["*"]`), nur fuer Entwicklung geeignet
- **bcrypt direkt statt passlib**: Wegen Python 3.14 / bcrypt>=5.0.0 Inkompatibilitaet mit passlib
- **Cookidoo-API hat keine Suchfunktion**: Import erfolgt ueber Collections durchblaettern oder Shopping-List. Fuer KI-Essensplanung werden Rezeptnamen aus Collections als Zusatzpool an Claude gesendet
- **AI-Essensplanung ist Preview-basiert**: generate-meal-plan speichert nicht direkt, sondern liefert Vorschlaege. Erst confirm-meal-plan schreibt in die DB. Undo per meal_ids moeglich (60s Timeout im Frontend)
- **Datumsformatierung im Frontend**: `formatDateISO` nutzt lokale Datumskomponenten statt `toISOString()` um UTC-Verschiebung zu vermeiden
- **Keine automatisierten Tests vorhanden**
- **Multi-Tenancy per Row-Level family_id**: Alle Kern-Tabellen haben eine `family_id`-Spalte. Die `require_family_id` Dependency in `auth.py` stellt sicher, dass User nur auf Daten ihrer Familie zugreifen. MCP-Server nutzt konfigurierbare `MCP_FAMILY_ID` Umgebungsvariable
- **Family-Erstellung seedet Default-Kategorien**: Beim Anlegen einer neuen Familie werden automatisch 5 Standard-Kategorien (Arbeit, Familie, Gesundheit, Einkauf, Sonstiges) erstellt

---

## 10. Methodenkarte fuer grosse Dateien (>300 Zeilen)

### `backend/app/routers/ai.py` (494 Zeilen)

| Methode/Endpunkt | Zeile | Zweck |
|------------------|-------|-------|
| `_monday_of` | 31 | Montag der Woche berechnen |
| `GET /available-recipes` | 84 | Lokale Rezepte, Cookidoo-Status und Slot-Belegung fuer AI-Dialog |
| `POST /generate-meal-plan` | 154 | Claude-Vorschau generieren (speichert NICHT in DB) |
| `POST /confirm-meal-plan` | 400 | Vorschau bestaetigen, Cookidoo-Rezepte importieren, Einkaufsliste generieren |
| `POST /undo-meal-plan` | 476 | KI-Plan per Meal-IDs rueckgaengig machen |

### `backend/mcp_server.py` (1171 Zeilen)

| Methode | Zeile | Zweck |
|---------|-------|-------|
| `get_db` | 54 | Async SQLAlchemy Session oeffnen |
| `get_events` | 186 | MCP Tool: Events mit optionalem Datumsbereich und Kategorie-Filter |
| `create_event` | 214 | MCP Tool: Event erstellen |
| `update_event` | 249 | MCP Tool: Event teilweise aktualisieren |
| `delete_event` | 293 | MCP Tool: Event loeschen |
| `get_todos` | 312 | MCP Tool: Todos mit Filtern |
| `create_todo` | 341 | MCP Tool: Todo erstellen |
| `complete_todo` | 376 | MCP Tool: Todo abschliessen/oeffnen |
| `delete_todo` | 399 | MCP Tool: Todo loeschen |
| `get_agenda` | 418 | MCP Tool: Agenda (Events + Todos) fuer Zeitraum |
| `get_open_todos_by_category` | 465 | MCP Tool: Offene Todos nach Kategorie gruppiert |
| `link_todo_to_event` | 489 | MCP Tool: Todo mit Event verknuepfen |
| `get_meal_plan` | 517 | MCP Tool: Wochenplan abrufen |
| `set_meal_slot` | 556 | MCP Tool: Slot mit Rezept belegen |
| `mark_as_cooked` | 608 | MCP Tool: Als gekocht markieren + History |
| `get_cooking_history` | 664 | MCP Tool: Kochhistorie eines Rezepts |
| `get_recipe_suggestions` | 700 | MCP Tool: Rezeptvorschlaege |
| `get_shopping_list` | 763 | MCP Tool: Aktive Einkaufsliste |
| `generate_shopping_list` | 798 | MCP Tool: Einkaufsliste aus Wochenplan generieren |
| `add_shopping_item` | 875 | MCP Tool: Manuellen Artikel hinzufuegen |
| `check_shopping_item` | 919 | MCP Tool: Artikel abhaken |
| `get_cookidoo_recipe` | 941 | MCP Tool: Cookidoo-Rezeptdetails |
| `import_recipe_to_plan` | 956 | MCP Tool: Cookidoo-Rezept importieren |
| `sync_cookidoo_week` | 978 | MCP Tool: Cookidoo-Kalender abrufen |
| `search_knuspr_product` | 994 | MCP Tool: Knuspr-Produktsuche |
| `add_to_knuspr_cart` | 1009 | MCP Tool: Produkt in Knuspr-Warenkorb |
| `send_shopping_list_to_knuspr` | 1025 | MCP Tool: Einkaufsliste an Knuspr senden |
| `get_knuspr_delivery_slots` | 1042 | MCP Tool: Knuspr-Lieferslots |
| `clear_knuspr_cart` | 1055 | MCP Tool: Knuspr-Warenkorb leeren |
| `resource_today` | 1073 | MCP Resource: `calendar://today` |
| `resource_week` | 1080 | MCP Resource: `calendar://week` |
| `resource_open_todos` | 1089 | MCP Resource: `todos://open` |
| `resource_high_priority` | 1095 | MCP Resource: `todos://high-priority` |
| `resource_shopping_list` | 1101 | MCP Resource: `shopping://current-list` |
| `resource_shopping_week_plan` | 1107 | MCP Resource: `shopping://week-plan` |
| `resource_recipe_suggestions` | 1118 | MCP Resource: `recipes://suggestions` |
| `resource_cooking_history_90d` | 1124 | MCP Resource: `recipes://history` |

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

| Bereich | Zeile (ca.) | Inhalt |
|---------|-------------|--------|
| CSS-Variablen | 1-20 | Farben, Schatten, Radien |
| Basis-Layout | 20-60 | Body, Topbar, Navigation |
| Auth-Screen | 60-120 | Login/Register |
| Kalender | 120-250 | Monatsgrid, Tageszellen, Events |
| Todos | 250-400 | Liste, Items, Sub-Todos, Badges |
| Modal | 480-510 | Overlay, Modal-Box, Header, Footer |
| Familienmitglieder | 510-570 | Karten-Grid |
| Wochenplan | 580-710 | Week-Grid, Slots, Diff-Badges |
| Einkaufsliste | 710-780 | Kategorien, Items, Check-Buttons |
| Shopping Store Picker (KI-Sort) | 922-980 | Store-Picker, Sort-Badge, Section-Header |
| Rezepte | 980-1060 | Grid-Karten, Bilder, Badges |
| Zutaten-Formular | 1060-1090 | Ingredient-Rows |
| Cookidoo-Browser | 1090-1320 | Collections, Karten, Vorschau, Spinner |
| AI Meal Plan Dialog | 1320-1550 | Slot-Grid, Cookidoo-Toggle, Preview-Tabelle, Source-Badges, Undo-Bar |
| AI Reasoning Popup | 1600-1665 | Begruendungs-Button, Overlay-Popup, Animation |
| Responsive | 1668-1699 | Mobile Breakpoints (inkl. AI-Responsive) |

---

## 11. Vorhandene Dokumentation

| Pfad | Beschreibung | Themen (→ Abschnitt 8) |
|------|-------------|------------------------|
| `PROJECT_INDEX.md` | Projektstruktur-Dokumentation (dieses Dokument) | Alle Aufgaben |
| `FEATURES.md` | Funktionsuebersicht aller Features nach Plattform (Web, Android, MCP, API) | Alle Aufgaben |
| `IMPROVEMENTS.md` | Verbesserungsvorschlaege mit Priorisierung und Roadmap | Alle Aufgaben |

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

# Docker (Produktion)
cd backend
docker-compose up -d

# Datenbank zuruecksetzen (PostgreSQL)
docker-compose exec db psql -U kalender -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# PostgreSQL starten (nur DB)
cd backend
docker-compose up -d db

# Abhaengigkeiten installieren
cd backend
pip install -r requirements.txt
```

### Ports und URLs
| Service | Port | URL |
|---------|------|-----|
| FastAPI (API + Frontend) | 8000 | `http://localhost:8000` |
| MCP-Server (SSE) | 8001 | `http://localhost:8001/sse` |
| OpenAPI Docs | 8000 | `http://localhost:8000/docs` |
| PostgreSQL | 5432 | `localhost:5432` |

### Deployment
- **Zielplattform**: Synology NAS (Docker)
- **Container**: `familienkalender-db` (Port 5432), `familienkalender-api` (Port 8000), `familienkalender-mcp` (Port 8001)
- **Datenbank-Volume**: `pgdata` (PostgreSQL Docker Volume)
- **Env-File**: `backend/.env` (nicht im Git)

### Cache-Busting
Aktueller Stand: `?v=21` (in `index.html` fuer alle JS/CSS Referenzen)
