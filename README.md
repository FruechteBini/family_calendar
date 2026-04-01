# Familienkalender

Familienkalender ist eine Self-Hosted Fullstack-Anwendung zur Organisation des Familienalltags. Sie verbindet Kalender, Aufgaben, Essensplanung, Einkaufslisten und Vorratsverwaltung in einer Plattform — steuerbar per Web-App, nativer Android-App, iOS-App, KI-Sprachassistent oder Claude Desktop (MCP).

Das System laeuft auf einer Synology NAS (Docker) und wird ueber das lokale Netzwerk genutzt.

---

## Inhaltsverzeichnis

1. [Architektur](#architektur)
2. [Features](#features)
3. [Tech-Stack](#tech-stack)
4. [Setup & Installation](#setup--installation)
5. [Entwicklung](#entwicklung)
6. [API-Uebersicht](#api-uebersicht)
7. [Physisches Setup (Tablet / NFC)](#physisches-setup-tablet--nfc)
8. [Projektstruktur](#projektstruktur)

---

## Architektur

### Ueberblick

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Web-SPA     │  │ Android App  │  │   iOS App    │  │ Claude       │
│  (Vanilla JS)│  │ (Kotlin/     │  │ (Swift/      │  │ Desktop      │
│              │  │  Compose)    │  │  SwiftUI)    │  │ (MCP)        │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                  │
       └────────────┬────┴─────────┬───────┘                  │
                    ▼              ▼                           ▼
              ┌─────────────────────────┐          ┌──────────────────┐
              │  FastAPI Backend        │          │  MCP-Server      │
              │  REST API (72 Endpunkte)│          │  (28 Tools,      │
              │  Port 8000             │          │   8 Resources)   │
              └───────────┬────────────┘          │  Port 8001       │
                          │                        └────────┬─────────┘
                          ▼                                 │
              ┌─────────────────────────┐                   │
              │  PostgreSQL 16          │◄──────────────────┘
              │  Port 5432             │
              └─────────────────────────┘
                          ▲
              ┌───────────┴────────────┐
              │  Externe Integrationen │
              │  • Cookidoo (Thermomix)│
              │  • Knuspr (Supermarkt) │
              │  • Claude AI (Anthropic)│
              └────────────────────────┘
```

### Schichtenmodell

| Schicht | Technologie | Pfad |
|---------|-------------|------|
| Web-Frontend | Vanilla JS SPA, CSS | `backend/app/static/` |
| API | FastAPI Router + Pydantic Schemas | `backend/app/routers/`, `backend/app/schemas/` |
| Persistenz | SQLAlchemy 2.0 (async) ORM Models | `backend/app/models/` |
| Externe Bridges | Cookidoo, Knuspr Python-Clients | `backend/integrations/` |
| MCP-Server | FastMCP SDK, eigene DB-Session | `backend/mcp_server.py` |
| Android App | Kotlin, Jetpack Compose, Room, Retrofit | `android/` |
| iOS App | Swift, SwiftUI, CoreData | `ios/` |

### Datenfluss

```
Client → HTTP JSON → FastAPI Router → Pydantic Schema (Validierung)
→ SQLAlchemy Model → PostgreSQL → Response Schema → JSON → Client
```

### Multi-Tenancy

Alle Daten sind per `family_id` isoliert. Jeder User gehoert zu genau einer Familie. Das Backend filtert automatisch per JWT — Clients muessen die `family_id` nicht mitsenden.

---

## Features

### Kalender & Termine
- Monatsansicht (Web), zusaetzlich Wochen-/3-Tage-/Tagesansicht (Android/iOS)
- Events mit Kategorien (farbkodiert), Mitglieder-Zuweisung, ganztaegig
- Serientermine per Sprachbefehl (bis zu 200 Einzeltermine)
- Tages-Detailansicht mit verknuepften Todos

### Aufgaben (Todos)
- Prioritaeten (hoch/mittel/niedrig), Faelligkeitsdatum, Kategorien
- Sub-Todos (Unteraufgaben)
- Schnelleingabe und Filter nach Prioritaet, Mitglied, Status
- Verknuepfung mit Events
- Terminvorschlaege (Proposals) fuer Mehrpersonen-Aufgaben mit Annehmen/Ablehnen/Gegenvorschlag

### Essensplanung
- Wochenplan (Mo–So, Mittag/Abend) mit Rezeptzuweisung
- Als-gekocht-markieren mit Bewertung (1–5 Sterne)
- Kochhistorie und "Schon lange nicht gekocht"-Hinweise
- Automatischer Vorrats-Abzug beim Kochen

### KI-Essensplanung (Claude API)
- 3-Schritt-Dialog: Slot-Auswahl → KI-Vorschlag (Preview) → Bestaetigen
- Beruecksichtigt lokale Rezepte und optional Cookidoo-Rezeptpool
- KI-Begruendung einsehbar, Portionen und Praeferenzen konfigurierbar
- Automatischer Cookidoo-Import und Einkaufslistengenerierung bei Bestaetigung
- 60-Sekunden-Undo

### Rezeptverwaltung
- CRUD mit Zutaten, Schwierigkeit, Zubereitungszeit, Bild
- Import aus Cookidoo (Thermomix) und beliebigen Koch-Webseiten (URL-Parser)
- Rezeptvorschlaege (selten/nie gekocht)

### Einkaufsliste
- Automatische Generierung aus Wochenplan mit Vorrats-Abgleich
- KI-Sortierung nach Supermarkt-Abteilungen (Claude API)
- Manuelles Hinzufuegen, Abhaken, Fortschrittsanzeige
- Export an Knuspr (Online-Supermarkt)

### Vorratskammer (Pantry)
- Mengen-Tracking mit optionalem Ablaufdatum und Mindestbestand
- Fuzzy-Matching zwischen Vorrat und Rezeptzutaten
- Warnungen bei Niedrigbestand und Ablauf
- Automatischer Abzug beim Kochen, Duplikat-Merge
- Bulk-Hinzufuegen per Sprachbefehl

### KI-Sprachassistent
- Floating-Button auf allen Seiten (Web: Web Speech API, Android: SpeechRecognizer)
- 13 Aktionstypen: Events, Todos, Rezepte, Essensplan, Einkauf, Vorrat erstellen/bearbeiten/loeschen
- Kontexterkennung: Familienmitglieder per Name, Wochentag-Aufloesung, Event-Todo-Referenzen
- Ergebnis-Popup mit Zusammenfassung aller ausgefuehrten Aktionen

### Cookidoo-Integration (Thermomix)
- Sammlungen durchblaettern, Rezeptvorschau mit Bild und Zutaten
- One-Click-Import in lokale Rezeptdatenbank
- Optional in KI-Essensplanung einbeziehbar

### Knuspr-Integration (Online-Supermarkt)
- Produktsuche, Warenkorb, Lieferslots (ueber MCP/API)
- Einkaufsliste direkt an Knuspr senden

### MCP-Server (Claude Desktop)
- 28 Tools und 8 Resources fuer die Steuerung des gesamten Familienkalenders
- Kalender, Todos, Essensplanung, Einkauf, Cookidoo, Knuspr — alles per Claude Desktop steuerbar

### Familienverwaltung
- Familie erstellen oder per Einladungscode beitreten
- Mitglieder mit Avatar (Emoji + Farbe)
- Kategorien (farbig, mit Icon) — 5 Default-Kategorien bei Familienerstellung

### Android-exklusive Features
- Offline-Modus: Room-Cache + Pending-Change-Queue, automatische Sync alle 15 Minuten
- 4 Kalenderansichten (Monat, Woche, 3 Tage, Tag)
- Konfigurierbare Server-URL

---

## Tech-Stack

### Backend

| Komponente | Technologie | Version |
|------------|-------------|---------|
| Web-Framework | FastAPI | 0.135 |
| ASGI Server | uvicorn | 0.42 |
| ORM | SQLAlchemy (async) | 2.0 |
| DB-Driver | asyncpg | 0.30+ |
| Validierung | Pydantic | 2.12 |
| Auth | JWT (python-jose + bcrypt) | — |
| KI | Anthropic Claude API | — |
| Cookidoo | cookidoo-api | 0.16 |
| Knuspr | knuspr-api | 0.3 |
| MCP | FastMCP SDK | — |

### Android

| Komponente | Technologie | Version |
|------------|-------------|---------|
| Sprache | Kotlin | 2.1 |
| UI | Jetpack Compose (Material 3) | BOM 2024.12 |
| HTTP | Retrofit 2 + OkHttp | 2.11 / 4.12 |
| Lokale DB | Room | 2.6.1 |
| Background Sync | WorkManager | 2.10 |
| Navigation | Compose Navigation | 2.8.5 |
| Image Loading | Coil | 2.7 |

### iOS

| Komponente | Technologie |
|------------|-------------|
| Sprache | Swift |
| UI | SwiftUI |
| Persistenz | CoreData / Keychain |
| HTTP | URLSession |

### Infrastruktur

| Komponente | Details |
|------------|---------|
| Datenbank | PostgreSQL 16 (Docker) |
| Containerisierung | Docker + docker-compose |
| Deployment | Synology NAS |
| Frontend | Vanilla JS SPA (kein Bundler) |

---

## Setup & Installation

### Voraussetzungen

- Docker und Docker Compose
- Python 3.12+ (fuer lokale Entwicklung)
- PostgreSQL 16 (laeuft im Docker-Container)

### Produktion (Docker)

```bash
cd backend

# .env Datei anlegen (Vorlage siehe unten)
cp .env.example .env
# → SECRET_KEY, DATABASE_URL, ANTHROPIC_API_KEY etc. setzen

# Container starten
docker-compose up -d
```

Das startet drei Container:
- `familienkalender-db` — PostgreSQL (Port 5432)
- `familienkalender-api` — FastAPI + Web-Frontend (Port 8000)
- `familienkalender-mcp` — MCP-Server fuer Claude Desktop (Port 8001)

### Umgebungsvariablen

| Variable | Pflicht | Beschreibung |
|----------|---------|-------------|
| `SECRET_KEY` | Ja | JWT-Signierung (beliebiger langer String) |
| `DATABASE_URL` | Ja | PostgreSQL-Verbindung (wird in Docker automatisch gesetzt) |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Nein | JWT-Lebensdauer (Default: 1440 = 24h) |
| `ALGORITHM` | Nein | JWT-Algorithmus (Default: HS256) |
| `ANTHROPIC_API_KEY` | Nein | Fuer KI-Essensplanung und Sprachassistent |
| `COOKIDOO_EMAIL` | Nein | Cookidoo/Thermomix Account |
| `COOKIDOO_PASSWORD` | Nein | Cookidoo Account Passwort |
| `KNUSPR_EMAIL` | Nein | Knuspr.de Account |
| `KNUSPR_PASSWORD` | Nein | Knuspr Account Passwort |
| `MCP_TRANSPORT` | Nein | MCP-Modus: `stdio` oder `sse` |
| `MCP_FAMILY_ID` | Nein | Familie fuer MCP-Server (Default: 1) |

### Erster Start

1. Container starten (`docker-compose up -d`)
2. Web-App oeffnen: `http://<NAS-IP>:8000`
3. Account erstellen (Registrierung)
4. Familie erstellen oder per Einladungscode beitreten
5. Familienmitglieder anlegen
6. Loslegen — Kalender, Todos, Rezepte, Essensplanung

### URLs

| Service | URL |
|---------|-----|
| Web-App + API | `http://localhost:8000` |
| OpenAPI Docs (Swagger) | `http://localhost:8000/docs` |
| MCP-Server (SSE) | `http://localhost:8001/sse` |
| PostgreSQL | `localhost:5432` |

---

## Entwicklung

### Backend lokal starten

```bash
cd backend
pip install -r requirements.txt

# PostgreSQL muss laufen (z.B. via Docker)
docker-compose up -d db

# .env konfigurieren
# DATABASE_URL=postgresql+asyncpg://kalender:kalender@localhost:5432/kalender

python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### MCP-Server starten

```bash
cd backend
pip install -r requirements-mcp.txt
python mcp_server.py
```

### Android-App bauen

```bash
cd android
./gradlew assembleDebug
./gradlew installDebug
```

Die Server-URL ist im Login-Screen und in den Einstellungen konfigurierbar.

| Einstellung | Wert |
|-------------|------|
| compileSdk / targetSdk | 35 |
| minSdk | 26 |
| applicationId | `de.familienkalender.app` |

### Datenbank zuruecksetzen

```bash
docker-compose exec db psql -U kalender -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

Schema wird beim naechsten App-Start automatisch per `create_all` neu erstellt.

### Cache-Busting (Web-Frontend)

Das Frontend nutzt kein Build-System. Bei Aenderungen an JS/CSS den Query-Parameter `?v=N` in `backend/app/static/index.html` erhoehen (aktuell `?v=21`).

---

## API-Uebersicht

Die API umfasst 72 Endpunkte, aufgeteilt auf 13 Router. Vollstaendige interaktive Dokumentation unter `/docs` (Swagger UI).

| Router | Prefix | Endpunkte | Beschreibung |
|--------|--------|-----------|-------------|
| Auth | `/api/auth` | 7 | Registrierung, Login, JWT, Familien-Management |
| Events | `/api/events` | 5 | Termin-CRUD |
| Todos | `/api/todos` | 7 | Aufgaben-CRUD + Sub-Todos, Completion, Event-Link |
| Proposals | `/api/proposals` | 4 | Terminvorschlaege erstellen/beantworten |
| Recipes | `/api/recipes` | 7 | Rezepte-CRUD + URL-Import, Vorschlaege |
| Meals | `/api/meals` | 4 | Wochenplan-CRUD + Als-gekocht-markieren |
| Shopping | `/api/shopping` | 6 | Einkaufsliste generieren/bearbeiten + KI-Sort |
| Pantry | `/api/pantry` | 8 | Vorratskammer-CRUD + Alerts |
| AI | `/api/ai` | 5 | KI-Essensplanung + Sprachbefehle |
| Cookidoo | `/api/cookidoo` | 6 | Thermomix-Integration |
| Knuspr | `/api/knuspr` | 5 | Online-Supermarkt |
| Categories | `/api/categories` | 4 | Kategorie-CRUD |
| Family Members | `/api/family-members` | 4 | Familienmitglieder-CRUD |

---

## Physisches Setup (Tablet / NFC)

> **Hinweis:** Dieser Abschnitt wird noch ergaenzt.

<!-- TODO: Beschreibung des physischen Setups mit NFC-Reader, Screen-Unlock, Tablet-Wandmontage etc. -->

---

## Projektstruktur

```
familienkalender/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI App-Einstiegspunkt
│   │   ├── auth.py              # JWT + bcrypt Auth-Logik
│   │   ├── config.py            # Pydantic Settings (Env-Vars)
│   │   ├── database.py          # Async SQLAlchemy Engine + Session
│   │   ├── models/              # 13 SQLAlchemy ORM Models
│   │   ├── schemas/             # Pydantic Request/Response Schemas
│   │   ├── routers/             # 13 FastAPI Router
│   │   └── static/              # Web-Frontend (SPA)
│   │       ├── index.html       # Haupt-HTML
│   │       ├── css/style.css    # Gesamtes Styling (~1700 Zeilen)
│   │       └── js/              # 8 JS-Module (App, Calendar, Todos, ...)
│   ├── integrations/
│   │   ├── cookidoo/            # Thermomix Bridge (Client + Importer)
│   │   └── knuspr/              # Knuspr Bridge (Client + Cart)
│   ├── mcp_server.py            # MCP-Server (28 Tools, 8 Resources)
│   ├── docker-compose.yml       # 3 Container: db, api, mcp
│   ├── Dockerfile               # API-Container
│   ├── Dockerfile.mcp           # MCP-Container
│   ├── requirements.txt         # Python-Dependencies
│   └── .env                     # Laufzeit-Konfiguration (nicht im Git)
│
├── android/                     # Native Android App
│   └── app/src/main/java/de/familienkalender/app/
│       ├── MainActivity.kt      # App-Einstiegspunkt
│       ├── FamilienkalenderApp.kt # Service-Locator (DI)
│       ├── data/
│       │   ├── local/           # Room DB (Entities, DAOs, TokenManager)
│       │   ├── remote/          # Retrofit APIs + DTOs
│       │   └── repository/      # Business-Logik + Offline-Queue
│       ├── ui/                  # Jetpack Compose Screens
│       │   ├── auth/            # Login, Family Onboarding
│       │   ├── calendar/        # Kalender (4 Ansichten)
│       │   ├── todos/           # Aufgaben + Proposals
│       │   ├── meals/           # Wochenplan, Rezepte, Einkauf, Vorrat
│       │   ├── voice/           # Sprachassistent
│       │   ├── categories/      # Kategorie-Verwaltung
│       │   ├── settings/        # Einstellungen
│       │   └── navigation/      # App-Shell + Bottom Nav
│       └── sync/                # SyncWorker (15min Background-Sync)
│
├── ios/                         # Native iOS App
│   └── Familienkalender/
│       ├── Core/                # Auth, Networking, Persistence
│       ├── Models/              # Swift Data Models
│       ├── ViewModels/          # ObservableObject ViewModels
│       └── Views/               # SwiftUI Views
│
├── CLAUDE.md                    # Projekt-Kontext fuer KI-Assistenten
├── PROJECT_INDEX.md             # Detaillierter Projekt-Index
├── FEATURES.md                  # Feature-Uebersicht nach Plattform
├── IMPROVEMENTS.md              # Verbesserungsvorschlaege + Roadmap
├── ANDROID_APP_PLAN.md          # Detaillierter Android-Bauplan
└── IOS_APP_PLAN.md              # Detaillierter iOS-Bauplan
```

---

## Bekannte Besonderheiten

- **Kein Alembic-Migrationen:** Schema wird per `create_all` beim Start erstellt. Bei Schema-Aenderungen muss die DB manuell zurueckgesetzt werden.
- **Frontend ohne Build-System:** Vanilla JS, kein Bundler. Cache-Busting manuell per `?v=N`.
- **Externe Integrationen optional:** Cookidoo und Knuspr funktionieren nur mit konfigurierten Credentials. Die App laeuft vollstaendig ohne.
- **CORS offen:** `allow_origins=["*"]` — nur fuer Entwicklung/LAN geeignet.
- **bcrypt direkt:** Kein passlib wegen Python 3.14 / bcrypt 5.0 Inkompatibilitaet.
- **KI-Essensplanung ist Preview-basiert:** `generate-meal-plan` speichert nicht, erst `confirm-meal-plan` schreibt in die DB.
- **Android Offline inkonsistent:** Queue nur fuer Events, Todos, Recipes, Categories, Members. MealPlan und Shopping nicht.
- **Keine automatisierten Tests vorhanden.**

---

## Lizenz

Privates Projekt. Nicht zur oeffentlichen Nutzung bestimmt.
