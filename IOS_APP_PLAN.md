# Familienkalender iOS App — Entwicklungsplan

**Erstellt:** 2026-03-26
**Zweck:** Vollstaendige Spezifikation fuer einen Agenten, der eine native iOS-App (SwiftUI) baut, die funktional aequivalent zur bestehenden Web-App ist — inklusive Verbesserungen.
**Backend:** Das bestehende FastAPI-Backend bleibt unveraendert. Die iOS-App kommuniziert ausschliesslich ueber die REST-API.

---

## Inhaltsverzeichnis

1. [Technologie-Stack](#1-technologie-stack)
2. [Architektur](#2-architektur)
3. [Datenmodell (Swift)](#3-datenmodell-swift)
4. [API-Client](#4-api-client)
5. [Authentifizierung & Onboarding](#5-authentifizierung--onboarding)
6. [Feature-Module (Detail)](#6-feature-module-detail)
   - 6.1 [Kalender](#61-kalender)
   - 6.2 [Todos](#62-todos)
   - 6.3 [Terminvorschlaege (Proposals)](#63-terminvorschlaege-proposals)
   - 6.4 [Familienmitglieder](#64-familienmitglieder)
   - 6.5 [Kategorien](#65-kategorien)
   - 6.6 [Rezepte](#66-rezepte)
   - 6.7 [Essensplanung (Wochenplan)](#67-essensplanung-wochenplan)
   - 6.8 [KI-Essensplanung](#68-ki-essensplanung)
   - 6.9 [Einkaufsliste](#69-einkaufsliste)
   - 6.10 [Vorratskammer (Pantry)](#610-vorratskammer-pantry)
   - 6.11 [Cookidoo-Integration](#611-cookidoo-integration)
   - 6.12 [KI-Sprachassistent](#612-ki-sprachassistent)
7. [Offline-Modus & Sync](#7-offline-modus--sync)
8. [Design-System & Theming](#8-design-system--theming)
9. [Navigationsstruktur](#9-navigationsstruktur)
10. [Verbesserungen gegenueber Web-App](#10-verbesserungen-gegenueber-web-app)
11. [Projektstruktur](#11-projektstruktur)
12. [API-Endpunkt-Referenz (Komplett)](#12-api-endpunkt-referenz-komplett)
13. [Implementierungsreihenfolge](#13-implementierungsreihenfolge)
14. [Testing-Strategie](#14-testing-strategie)

---

## 1. Technologie-Stack

| Aspekt | Entscheidung | Begruendung |
|--------|-------------|-------------|
| **Sprache** | Swift 6+ | Aktueller Standard, Concurrency-Support |
| **UI-Framework** | SwiftUI | Deklarativ, moderne iOS-Entwicklung, native Widgets |
| **Min. iOS-Version** | iOS 17+ | Fuer Observable Macro, moderne SwiftUI-APIs |
| **Netzwerk** | URLSession + async/await | Kein Drittanbieter noetig, nativ performant |
| **Lokale DB** | SwiftData | Apple-native Persistenz, harmoniert mit SwiftUI |
| **Auth-Token** | Keychain (via KeychainAccess) | Sicher, ueberlebt App-Updates |
| **Dependency Manager** | Swift Package Manager | Standard, keine CocoaPods noetig |
| **Architektur** | MVVM + Repository Pattern | Trennung View/Logic/Data, testbar |
| **Spracheingabe** | Speech Framework (Apple) | Nativ, kein Drittanbieter |

---

## 2. Architektur

### Schichtenmodell

```
┌─────────────────────────────────────────────┐
│  UI Layer (SwiftUI Views + ViewModels)      │
├─────────────────────────────────────────────┤
│  Domain Layer (Models + Business Logic)     │
├─────────────────────────────────────────────┤
│  Data Layer                                 │
│  ├─ APIClient (URLSession, JWT)             │
│  ├─ LocalStore (SwiftData)                  │
│  └─ Repository (Online/Offline-Entscheid)   │
├─────────────────────────────────────────────┤
│  Infrastructure (Keychain, Speech, etc.)    │
└─────────────────────────────────────────────┘
```

### Datenfluss

```
View → ViewModel.action() → Repository.fetch()
  → APIClient.request() → JSON → DTO → Domain Model
  → ViewModel.state update → View re-renders

Offline:
  → Repository.fetch() → LocalStore → Cached Model
  → Queue change → Background sync on reconnect
```

### Dependency Injection

Verwende `@Environment` und ein zentrales `AppDependencies`-Objekt:

```swift
@Observable
final class AppDependencies {
    let apiClient: APIClient
    let authManager: AuthManager
    let eventRepository: EventRepository
    let todoRepository: TodoRepository
    // ... alle Repositories
}
```

---

## 3. Datenmodell (Swift)

Alle Models als `Codable` Structs fuer API-Kommunikation + SwiftData `@Model` Klassen fuer lokale Persistenz.

### 3.1 API DTOs (Codable Structs)

```swift
// MARK: - Auth
struct LoginRequest: Codable {
    let username: String
    let password: String
}
struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
}
struct UserResponse: Codable {
    let id: Int
    let username: String
    let family_id: Int?
    let family: FamilyResponse?
    let member_id: Int?
    let member: FamilyMemberResponse?
}

// MARK: - Family
struct FamilyCreate: Codable { let name: String }
struct FamilyJoin: Codable { let invite_code: String }
struct FamilyResponse: Codable {
    let id: Int
    let name: String
    let invite_code: String
    let created_at: String
}

// MARK: - FamilyMember
struct FamilyMemberCreate: Codable {
    let name: String
    var color: String = "#0052CC"
    var avatar_emoji: String = "👤"
}
struct FamilyMemberUpdate: Codable {
    let name: String?
    let color: String?
    let avatar_emoji: String?
}
struct FamilyMemberResponse: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String
    let avatar_emoji: String
    let created_at: String
}

// MARK: - Category
struct CategoryCreate: Codable {
    let name: String
    var color: String = "#0052CC"
    var icon: String = "📁"
}
struct CategoryResponse: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String
    let icon: String
}

// MARK: - Event
struct EventCreate: Codable {
    let title: String
    let description: String?
    let start: String  // ISO datetime
    let end: String
    var all_day: Bool = false
    let category_id: Int?
    var member_ids: [Int] = []
}
struct EventUpdate: Codable {
    let title: String?
    let description: String?
    let start: String?
    let end: String?
    let all_day: Bool?
    let category_id: Int?
    let member_ids: [Int]?
}
struct EventResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let start: String
    let end: String
    let all_day: Bool
    let category: CategoryResponse?
    let members: [FamilyMemberResponse]
    let todos: [EventTodoResponse]
    let created_at: String
    let updated_at: String
}
struct EventTodoResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let completed: Bool
    let priority: String
}

// MARK: - Todo
enum Priority: String, Codable, CaseIterable {
    case low, medium, high
    var displayName: String {
        switch self {
        case .low: "Niedrig"
        case .medium: "Mittel"
        case .high: "Hoch"
        }
    }
}
struct TodoCreate: Codable {
    let title: String
    let description: String?
    var priority: String = "medium"
    let due_date: String?  // "YYYY-MM-DD"
    let category_id: Int?
    let event_id: Int?
    let parent_id: Int?
    var requires_multiple: Bool = false
    var member_ids: [Int] = []
}
struct TodoUpdate: Codable {
    let title: String?
    let description: String?
    let priority: String?
    let due_date: String?
    let category_id: Int?
    let event_id: Int?
    let requires_multiple: Bool?
    let member_ids: [Int]?
}
struct SubtodoResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let completed: Bool
    let completed_at: String?
    let created_at: String
}
struct TodoResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let priority: String
    let due_date: String?
    let completed: Bool
    let completed_at: String?
    let category: CategoryResponse?
    let event_id: Int?
    let parent_id: Int?
    let requires_multiple: Bool
    let members: [FamilyMemberResponse]
    let subtodos: [SubtodoResponse]
    let created_at: String
    let updated_at: String
}

// MARK: - Recipe
enum RecipeSource: String, Codable { case manual, cookidoo, web }
enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard
    var displayName: String {
        switch self {
        case .easy: "Einfach"
        case .medium: "Mittel"
        case .hard: "Aufwendig"
        }
    }
}
struct IngredientCreate: Codable {
    let name: String
    let amount: Double?
    let unit: String?
    var category: String = "sonstiges"
}
struct IngredientResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let amount: Double?
    let unit: String?
    let category: String
}
struct RecipeCreate: Codable {
    let title: String
    var source: String = "manual"
    let cookidoo_id: String?
    var servings: Int = 4
    let prep_time_active_minutes: Int?
    let prep_time_passive_minutes: Int?
    var difficulty: String = "medium"
    let instructions: String?
    let notes: String?
    let image_url: String?
    var ai_accessible: Bool = true
    var ingredients: [IngredientCreate] = []
}
struct RecipeResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let source: String
    let cookidoo_id: String?
    let servings: Int
    let prep_time_active_minutes: Int?
    let prep_time_passive_minutes: Int?
    let difficulty: String
    let last_cooked_at: String?
    let cook_count: Int
    let instructions: String?
    let notes: String?
    let image_url: String?
    let ai_accessible: Bool
    let ingredients: [IngredientResponse]
    let created_at: String
    let updated_at: String
}
struct RecipeSuggestion: Codable, Identifiable {
    let id: Int
    let title: String
    let difficulty: String
    let prep_time_active_minutes: Int?
    let last_cooked_at: String?
    let cook_count: Int
    let days_since_cooked: Int?
}

// MARK: - Meal Plan
struct MealSlotUpdate: Codable {
    let recipe_id: Int
    var servings_planned: Int = 4
}
struct MarkCookedRequest: Codable {
    let servings_cooked: Int?
    let rating: Int?
    let notes: String?
}
struct MealSlotResponse: Codable, Identifiable {
    let id: Int
    let plan_date: String
    let slot: String
    let recipe_id: Int
    let servings_planned: Int
    let recipe: RecipeResponse
    let created_at: String
    let updated_at: String
}
struct DayPlan: Codable, Identifiable {
    let date: String
    let weekday: String
    let lunch: MealSlotResponse?
    let dinner: MealSlotResponse?
    var id: String { date }
}
struct WeekPlanResponse: Codable {
    let week_start: String
    let days: [DayPlan]
}
struct CookingHistoryEntry: Codable, Identifiable {
    let id: Int
    let recipe_id: Int
    let recipe_title: String
    let recipe_difficulty: String?
    let recipe_image_url: String?
    let cooked_at: String
    let servings_cooked: Int
    let rating: Int?
}

// MARK: - Shopping
struct ShoppingItemCreate: Codable {
    let name: String
    let amount: String?
    let unit: String?
    var category: String = "sonstiges"
}
struct ShoppingItemResponse: Codable, Identifiable {
    let id: Int
    let shopping_list_id: Int
    let name: String
    let amount: String?
    let unit: String?
    let category: String
    let checked: Bool
    let source: String
    let recipe_id: Int?
    let ai_accessible: Bool
    let sort_order: Int?
    let store_section: String?
    let created_at: String
    let updated_at: String
}
struct ShoppingListResponse: Codable, Identifiable {
    let id: Int
    let week_start_date: String
    let status: String
    let sorted_by_store: String?
    let items: [ShoppingItemResponse]
    let created_at: String
}
struct GenerateRequest: Codable { let week_start: String }

// MARK: - Pantry
struct PantryItemCreate: Codable {
    let name: String
    let amount: Double?
    let unit: String?
    var category: String = "sonstiges"
    let expiry_date: String?   // "YYYY-MM-DD"
    let min_stock: Double?
}
struct PantryItemUpdate: Codable {
    let name: String?
    let amount: Double?
    let unit: String?
    let category: String?
    let expiry_date: String?
    let min_stock: Double?
}
struct PantryBulkAddRequest: Codable {
    let items: [PantryItemCreate]
}
struct PantryItemResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let amount: Double?
    let unit: String?
    let category: String
    let expiry_date: String?     // "YYYY-MM-DD" or nil
    let min_stock: Double?
    let is_low_stock: Bool       // computed: amount <= (min_stock ?? 2)
    let is_expiring_soon: Bool   // computed: expiry_date <= today + 7 days
    let created_at: String
    let updated_at: String
}
struct PantryAlertItem: Codable, Identifiable {
    let id: Int
    let name: String
    let amount: Double?
    let unit: String?
    let reason: String           // "low_stock" | "expiring_soon"
    let expiry_date: String?
}

// MARK: - AI
struct SlotSelection: Codable {
    let date: String
    let slot: String
}
struct GenerateMealPlanRequest: Codable {
    let week_start: String
    var servings: Int = 4
    var preferences: String = ""
    var selected_slots: [SlotSelection] = []
    var include_cookidoo: Bool = false
}
struct MealSuggestion: Codable, Identifiable {
    let date: String
    let slot: String
    let recipe_id: Int?
    let cookidoo_id: String?
    let recipe_title: String
    let servings_planned: Int
    let source: String
    let difficulty: String?
    let prep_time: Int?
    var id: String { "\(date)_\(slot)" }
}
struct PreviewMealPlanResponse: Codable {
    let suggestions: [MealSuggestion]
    let reasoning: String?
}
struct ConfirmMealPlanRequest: Codable {
    let week_start: String
    let items: [MealSuggestion]
}
struct ConfirmMealPlanResponse: Codable {
    let message: String
    let meals_created: Int
    let meal_ids: [Int]
    let shopping_list_generated: Bool
}
struct UndoMealPlanRequest: Codable { let meal_ids: [Int] }

// MARK: - Voice Command
struct VoiceCommandRequest: Codable { let text: String }
struct VoiceCommandAction: Codable {
    let type: String
    let ref: String?
    let params: [String: AnyCodable]  // Use AnyCodable wrapper
    let result: [String: AnyCodable]?
}
struct VoiceCommandResponse: Codable {
    let summary: String
    let actions: [VoiceCommandAction]
}

// MARK: - Proposals
struct ProposalCreate: Codable {
    let proposed_date: String
    let message: String?
}
struct ProposalRespondRequest: Codable {
    let response: String  // "accepted" | "rejected"
    let message: String?
    let counter_date: String?
}
struct ProposalDetail: Codable, Identifiable {
    let id: Int
    let todo_id: Int
    let proposer: FamilyMemberResponse
    let proposed_date: String
    let message: String?
    let status: String
    let responses: [ProposalResponseDetail]
    let created_at: String
}
struct ProposalResponseDetail: Codable, Identifiable {
    let id: Int
    let member: FamilyMemberResponse
    let response: String
    let counter_proposal_id: Int?
    let message: String?
    let created_at: String
}
struct PendingProposalDetail: Codable, Identifiable {
    let id: Int
    let todo_id: Int
    let todo_title: String
    let proposer: FamilyMemberResponse
    let proposed_date: String
    let message: String?
    let status: String
    let created_at: String
}

// MARK: - Cookidoo
struct CookidooCollection: Codable, Identifiable {
    let id: String
    let name: String
    let chapters: [CookidooChapter]
}
struct CookidooChapter: Codable {
    let name: String
    let recipes: [CookidooRecipeSummary]
}
struct CookidooRecipeSummary: Codable, Identifiable {
    let cookidoo_id: String
    let name: String
    var id: String { cookidoo_id }
}
```

---

## 4. API-Client

### Kernprinzipien

- Singleton `APIClient` mit konfigurierbarer `baseURL`
- JWT-Token wird im Keychain gespeichert
- Automatischer 401-Handling: Token loeschen → Login-Screen zeigen
- `async throws` auf allen Methoden
- Generisch typisiert: `func request<T: Decodable>(...) -> T`

### Implementierungsdetail

```swift
actor APIClient {
    var baseURL: URL
    private let session = URLSession.shared
    private let keychain: KeychainManager
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T

    // Convenience
    func get<T: Decodable>(_ path: String, query: [URLQueryItem]?) async throws -> T
    func post<T: Decodable>(_ path: String, body: any Encodable) async throws -> T
    func put<T: Decodable>(_ path: String, body: any Encodable) async throws -> T
    func patch<T: Decodable>(_ path: String, body: any Encodable) async throws -> T
    func delete(_ path: String) async throws
}
```

### Fehlerbehandlung

```swift
enum APIError: LocalizedError {
    case unauthorized           // 401 → Auto-Logout
    case forbidden(String)      // 403 → Keine Familie
    case notFound(String)       // 404
    case conflict(String)       // 409 → Duplikat
    case serverError(String)    // 500+
    case networkError(Error)    // Offline
    case decodingError(Error)

    var errorDescription: String? { ... }
}
```

### Server-URL Konfiguration

Die Server-URL muss konfigurierbar sein (wie in der Android-App). Speicherung in `UserDefaults`. Standard: `http://localhost:8000`.

---

## 5. Authentifizierung & Onboarding

### Flow

```
App-Start
  ↓
Keychain hat Token?
  ├─ Ja → GET /api/auth/me
  │        ├─ Erfolg → user.family_id?
  │        │            ├─ Ja → Haupt-App
  │        │            └─ Nein → Family-Onboarding
  │        └─ 401 → Login-Screen
  └─ Nein → Login-Screen
```

### Login-Screen

- Felder: Benutzername, Passwort
- Toggle: "Anmelden" / "Registrieren"
- Server-URL konfigurierbar (Zahnrad-Icon oben rechts)
- Bei Register: `POST /api/auth/register` → automatisch `POST /api/auth/login`
- Token im Keychain speichern
- User-Objekt im `AuthManager` (Observable)

### Family-Onboarding Screen

Wird angezeigt wenn `user.family_id == nil`:

- **Option 1:** "Familie erstellen" → Name eingeben → `POST /api/auth/family`
- **Option 2:** "Familie beitreten" → Einladungscode eingeben → `POST /api/auth/family/join`
- Nach Erfolg: Weiter zur Member-Verknuepfung

### Member-Verknuepfung

Falls `user.member_id == nil` UND Familienmitglieder existieren:
- Sheet mit Picker: "Welches Familienmitglied bist du?"
- `PATCH /api/auth/link-member` mit `member_id`
- Wird fuer Proposals benoetigt

### Verbesserung: Biometrische Authentifizierung

**Neu in iOS-App:** Nach erstem Login Face ID / Touch ID aktivieren. Token wird nur biometrisch geschuetzt im Keychain gespeichert. Kein erneutes Passwort-Eingeben noetig.

---

## 6. Feature-Module (Detail)

### 6.1 Kalender

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/events/` | Query: `date_from`, `date_to`, `member_id`, `category_id` | `[EventResponse]` |
| GET | `/api/events/{id}` | – | `EventResponse` |
| POST | `/api/events/` | `EventCreate` | `EventResponse` |
| PUT | `/api/events/{id}` | `EventUpdate` | `EventResponse` |
| DELETE | `/api/events/{id}` | – | 204 |

#### Views

1. **CalendarView** (Hauptansicht)
   - **Verbesserung:** 4 Ansichten wie Android (Monat, Woche, 3 Tage, Tag) — Web hat nur Monat
   - Monat: Grid mit farbkodierten Event-Dots (Kategorie-Farbe)
   - Woche: Horizontales Zeitraster (7:00-22:00) mit Event-Bloecken
   - Tag: Vertikale Zeitleiste mit allen Events
   - Navigation: Swipe-Gesten oder Pfeil-Buttons
   - "Heute"-Button zum Zurueckspringen

2. **DayDetailView** (Sheet)
   - Liste aller Events des Tages
   - Farbiger Dot + Uhrzeit + Titel + Member-Emojis
   - Tap → Event-Detail
   - "+" Button fuer neues Event

3. **EventFormView** (Sheet/NavigationLink)
   - Titel (Pflicht)
   - Beschreibung (optional)
   - Ganztaegig-Toggle
   - Start-Datum/Uhrzeit (DatePicker)
   - End-Datum/Uhrzeit (DatePicker)
   - Kategorie-Picker (Dropdown mit Icon+Name+Farbe)
   - Member-Chips (Multi-Select mit Emoji+Name)
   - **Verbesserung:** Zugehoerige Todos direkt im Event-Formular anlegen (wie Web)
   - Loeschen-Button (nur bei Edit)

#### UX-Details

- Beim Erstellen: Default-Datum = ausgewaehlter Tag, Start 09:00, Ende 10:00
- Ganztaegig: Uhrzeit-Picker ausblenden
- Uhrzeit in 15-Minuten-Schritten
- Events farblich nach Kategorie kodiert
- Haptic Feedback bei Aktionen

### 6.2 Todos

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/todos/` | Query: `completed`, `priority`, `member_id`, `category_id` | `[TodoResponse]` |
| GET | `/api/todos/{id}` | – | `TodoResponse` |
| POST | `/api/todos/` | `TodoCreate` | `TodoResponse` |
| PUT | `/api/todos/{id}` | `TodoUpdate` | `TodoResponse` |
| PATCH | `/api/todos/{id}/complete` | – | `TodoResponse` |
| PATCH | `/api/todos/{id}/link-event` | `{"event_id": Int?}` | `TodoResponse` |
| DELETE | `/api/todos/{id}` | – | 204 |

#### Views

1. **TodoListView** (Hauptansicht)
   - **Verbesserung:** Quick-Add-Leiste oben (Textfeld + Prioritaet-Picker + "+") — wie Web, fehlt in Android
   - Filter-Bar: Prioritaet, Mitglied, "Erledigte anzeigen"-Toggle
   - **Verbesserung:** Zusaetzlicher Filter nach Kategorie
   - Liste mit Sections: ueberfaellig (rot), heute, diese Woche, spaeter, ohne Datum
   - Swipe-Actions: Links = erledigt, Rechts = loeschen

2. **TodoItemRow**
   - Checkbox (Toggle completed)
   - Titel + Sub-Todo-Count Badge
   - Priority-Badge (farbkodiert: rot/orange/grau)
   - Member-Emojis
   - Kategorie-Icon
   - Faelligkeitsdatum (rot wenn ueberfaellig)
   - "Mehrere"-Badge wenn `requires_multiple`
   - Eingeklappt: Sub-Todos als DisclosureGroup

3. **TodoFormView** (Sheet)
   - Titel, Beschreibung, Prioritaet, Faelligkeitsdatum
   - Kategorie-Picker, Event-Verknuepfung, Member-Chips
   - `requires_multiple` Toggle
   - Proposals-Timeline (nur bei Edit + requires_multiple)
   - Sub-Todos-Liste (nur bei Edit)

4. **SubTodoAddView** (Alert oder Mini-Sheet)
   - Nur Titel-Feld + Hinzufuegen

#### UX-Details

- Erledigte Todos: durchgestrichen, ausgegraut, am Ende
- Sub-Todos: eingerueckt mit kleinerem Checkbox
- Sortierung: Nach Faelligkeitsdatum (asc, null zuletzt), dann nach Erstelldatum (desc)
- Pull-to-Refresh

### 6.3 Terminvorschlaege (Proposals)

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| POST | `/api/todos/{id}/proposals` | `ProposalCreate` | `ProposalDetail` |
| GET | `/api/todos/{id}/proposals` | – | `[ProposalDetail]` |
| POST | `/api/proposals/{id}/respond` | `ProposalRespondRequest` | `ProposalDetail` |
| GET | `/api/proposals/pending` | – | `[PendingProposalDetail]` |

#### Views

1. **PendingProposalsView** (Sheet, erreichbar ueber Badge in Navigation)
   - Liste offener Vorschlaege: Todo-Titel, Vorschlagender (Emoji+Name), Datum
   - Pro Vorschlag: "Annehmen" / "Ablehnen" / "Gegenvorschlag" Buttons
   - Gegenvorschlag: DatePicker + optionale Nachricht

2. **ProposalTimelineView** (im Todo-Edit eingebettet)
   - Chronologische Liste aller Vorschlaege fuer ein Todo
   - Status-Badge: Offen (blau), Angenommen (gruen), Abgelehnt (rot), Ersetzt (grau)
   - Pro Vorschlag: Antworten der Mitglieder

3. **Badge in TabBar oder Navigation**
   - Zeigt Anzahl offener Vorschlaege
   - Polling alle 60 Sekunden oder bei App-Foreground

#### Logik

- Vorschlag erstellen: Nur bei Todos mit `requires_multiple == true`
- Annehmen/Ablehnen: `POST /api/proposals/{id}/respond`
- Gegenvorschlag: Response "rejected" + `counter_date` → erstellt automatisch neuen Vorschlag
- Vorschlag gilt als "accepted" wenn ALLE zugewiesenen Mitglieder (ausser Vorschlagender) zugestimmt haben

### 6.4 Familienmitglieder

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/family-members/` | – | `[FamilyMemberResponse]` |
| POST | `/api/family-members/` | `FamilyMemberCreate` | `FamilyMemberResponse` |
| PUT | `/api/family-members/{id}` | `FamilyMemberUpdate` | `FamilyMemberResponse` |
| DELETE | `/api/family-members/{id}` | – | 204 |

#### Views

1. **MembersListView**: Grid mit Karten (Avatar-Emoji + Farbe + Name + "Seit"-Datum)
2. **MemberFormView** (Sheet):
   - Name (Pflicht)
   - Farb-Picker: 10 vordefinierte Farben als Kreise
   - Emoji-Picker: 12 vordefinierte Emojis als Grid
   - **Verbesserung:** Eigenes Emoji per Emoji-Keyboard moeglich (nicht nur die 12 vordefinierten)
   - Loeschen-Button (nur Edit)

#### Vordefinierte Werte

Farben: `#0052CC, #00875A, #DE350B, #FF8B00, #6B778C, #8777D9, #E91E63, #00BCD4, #4CAF50, #FF5722`
Emojis: `👨, 👩, 👦, 👧, 👶, 🧑, 👴, 👵, 🐶, 🐱, 🦊, 🐻`

### 6.5 Kategorien

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/categories/` | – | `[CategoryResponse]` |
| POST | `/api/categories/` | `CategoryCreate` | `CategoryResponse` |
| PUT | `/api/categories/{id}` | `CategoryUpdate` | `CategoryResponse` |
| DELETE | `/api/categories/{id}` | – | 204 |

#### Views

**Verbesserung:** Eigene Kategorie-Verwaltungs-UI (fehlt in Web UND Android, nur API existiert):

1. **CategoriesListView** (erreichbar aus Einstellungen):
   - Liste mit Icon + Name + Farb-Dot
   - Swipe-to-Delete
   - "+"-Button

2. **CategoryFormView** (Sheet):
   - Name
   - Farb-Picker (wie bei Members)
   - Emoji-Picker fuer Icon

#### Default-Kategorien (Backend seedet automatisch bei Family-Erstellung)

| Name | Farbe | Icon |
|------|-------|------|
| Arbeit | #0052CC | 💼 |
| Familie | #00875A | 👨‍👩‍👧‍👦 |
| Gesundheit | #DE350B | ❤️ |
| Einkauf | #FF8B00 | 🛒 |
| Sonstiges | #6B778C | 📌 |

### 6.6 Rezepte

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/recipes/` | Query: `sort_by`, `order` | `[RecipeResponse]` |
| GET | `/api/recipes/{id}` | – | `RecipeDetailResponse` |
| POST | `/api/recipes/` | `RecipeCreate` | `RecipeResponse` |
| PUT | `/api/recipes/{id}` | `RecipeUpdate` | `RecipeResponse` |
| DELETE | `/api/recipes/{id}` | – | 204 |
| GET | `/api/recipes/suggestions` | Query: `limit` | `[RecipeSuggestion]` |
| GET | `/api/recipes/{id}/history` | – | `[CookingHistoryResponse]` |
| POST | `/api/recipes/parse-url` | `{"url": String}` | `UrlImportPreview` |

#### Views

1. **RecipeListView** (Hauptansicht)
   - **Verbesserung:** Suchleiste oben (Client-seitig filtern nach Titel)
   - **Verbesserung:** Filter-Chips: Schwierigkeit (einfach/mittel/aufwendig), Quelle (manuell/cookidoo/web)
   - Sortierung: Titel, Zuletzt gekocht, Anzahl gekocht, Zubereitungszeit
   - Grid-Layout (2 Spalten) mit Karten:
     - Bild (AsyncImage, Placeholder wenn kein Bild)
     - Titel
     - Difficulty-Badge (gruen/orange/rot)
     - Zubereitungszeit
     - "Zuletzt gekocht vor X Tagen" oder "Noch nie gekocht"
   - FAB "+" fuer neues Rezept

2. **RecipeDetailView** (NavigationLink)
   - Grosses Bild (wenn vorhanden)
   - Titel, Schwierigkeit, Portionen, Zeiten
   - Zutaten-Liste (gruppiert nach Kategorie)
   - Zubereitungsanleitung
   - **Verbesserung:** Kochhistorie anzeigen (letzte Eintraege mit Datum + Bewertung)
   - **Verbesserung:** "Rezeptvorschlaege" Section (selten/nie gekochte Rezepte)
   - Bearbeiten/Loeschen-Buttons

3. **RecipeFormView** (Sheet, gross)
   - Titel, Portionen, Schwierigkeit-Picker
   - Aktive Zubereitungszeit, Passive Zubereitungszeit (Min.)
   - Anleitung (Mehrzeiliges Textfeld)
   - Notizen
   - Bild-URL (oder Kamera/Galerie-Picker als Verbesserung)
   - AI-Zugaenglich Toggle
   - Zutaten-Liste (dynamisch):
     - Pro Zeile: Name + Menge + Einheit + Kategorie-Picker
     - "+"-Button fuer neue Zeile
     - Swipe-to-Delete
   - **Verbesserung:** URL-Import: URL eingeben → `POST /api/recipes/parse-url` → Felder vorausfuellen

4. **RecipeSuggestionsView** (Section in Rezepte-Tab)
   - **Verbesserung:** Top 5-10 Vorschlaege prominent anzeigen (API: `GET /api/recipes/suggestions`)
   - "Schon lange nicht gekocht"-Badge

#### Zutatenkategorien (Enum)

| Wert | Anzeige |
|------|---------|
| kuehlregal | Kuehlregal |
| obst_gemuese | Obst & Gemuese |
| trockenware | Trockenware |
| drogerie | Drogerie |
| sonstiges | Sonstiges |

### 6.7 Essensplanung (Wochenplan)

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/meals/plan` | Query: `week` (YYYY-MM-DD) | `WeekPlanResponse` |
| PUT | `/api/meals/plan/{date}/{slot}` | `MealSlotUpdate` | `MealSlotResponse` |
| DELETE | `/api/meals/plan/{date}/{slot}` | – | 204 |
| PATCH | `/api/meals/plan/{date}/{slot}/done` | `MarkCookedRequest` | `MarkCookedResponse` |
| GET | `/api/meals/history` | Query: `limit` | `[CookingHistoryEntry]` |

#### Views

1. **WeekPlanView** (Hauptansicht)
   - Wochennavi: "< KW 13 >" mit Swipe
   - 7 Tagesreihen: Mo-So
   - Pro Tag: 2 Slots (Mittag / Abend)
   - Gefuellter Slot: Rezeptname + Difficulty-Badge + Rezeptbild (klein)
   - Leerer Slot: "+" Button → Rezept-Zuweisungs-Sheet
   - **Verbesserung:** Long-Press auf gefuellten Slot → Kontextmenue (Bearbeiten, Als gekocht, Leeren)
   - **Verbesserung:** "Schon lange nicht gekocht" Hinweis (> 28 Tage) als Badge
   - KI-Button (Sparkle-Icon) → AI-Essensplanung
   - "Einkaufsliste generieren" Button

2. **AssignSlotView** (Sheet)
   - Rezept-Liste mit Suchfeld
   - Portionen-Stepper
   - **Verbesserung:** Schnellrezept erstellen (Titel + "Erstellen & Zuweisen")
   - **Verbesserung:** Aus Kochhistorie waehlen (letzte 10 Gerichte)

3. **MarkCookedSheet**
   - Portionen (vorausgefuellt)
   - Bewertung (1-5 Sterne)
   - Notizen
   - Anzeige der Vorrats-Abzuege (pantry_deductions)

4. **CookingHistoryView** (Section oder eigener Tab)
   - **Verbesserung:** Horizontale ScrollView der letzten 10 Gerichte mit Bild + Titel
   - Tap → direkt in Slot zuweisen

### 6.8 KI-Essensplanung

**Komplett neu fuer iOS** (fehlt in Android, vorhanden in Web).

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/ai/available-recipes` | Query: `week_start` | JSON (siehe unten) |
| POST | `/api/ai/generate-meal-plan` | `GenerateMealPlanRequest` | `PreviewMealPlanResponse` |
| POST | `/api/ai/confirm-meal-plan` | `ConfirmMealPlanRequest` | `ConfirmMealPlanResponse` |
| POST | `/api/ai/undo-meal-plan` | `UndoMealPlanRequest` | JSON |

#### Available-Recipes Response

```json
{
    "local_count": 15,
    "local_recipes": [{"id": 1, "title": "...", "difficulty": "easy"}],
    "cookidoo_available": true,
    "cookidoo_count": 45,
    "filled_slots": [{"date": "2026-03-23", "day": "Montag", "slot": "lunch", "label": "Mittag", "recipe_title": "..."}],
    "empty_slots": [{"date": "2026-03-23", "day": "Montag", "slot": "dinner", "label": "Abend"}]
}
```

#### Flow (2-Schritt-Wizard)

**Schritt 1: Konfiguration**
- Woche anzeigen (Mo-So)
- Slot-Grid: 7x2 Matrix, bereits belegte Slots grau, freie Slots anklickbar (Toggle)
- Default: Alle freien Slots ausgewaehlt
- Portionen-Stepper (Default 4)
- Cookidoo-Toggle (nur sichtbar wenn `cookidoo_available`)
- Wuensche-Textfeld (z.B. "vegetarisch", "schnelle Gerichte")
- "Plan generieren" Button → Spinner

**Schritt 2: Vorschau**
- Tabelle: Tag | Slot | Rezept | Schwierigkeit | Quelle-Badge (Lokal/Cookidoo)
- KI-Begruendung anzeigen (expandierbar)
- "Bestaetigen" → `POST /api/ai/confirm-meal-plan`
  - Backend importiert Cookidoo-Rezepte automatisch
  - Backend generiert automatisch Einkaufsliste
- "Neu generieren" → zurueck zu Spinner + neuer Claude-Aufruf
- "Zurueck" → zurueck zu Schritt 1

**Nach Bestaetigung:**
- Undo-Bar (60 Sekunden Timer): "KI-Plan rueckgaengig machen"
- `POST /api/ai/undo-meal-plan` mit den `meal_ids`
- Automatisch Wochenplan neu laden

### 6.9 Einkaufsliste

#### API-Endpunkte

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| GET | `/api/shopping/list` | – | `ShoppingListResponse?` |
| POST | `/api/shopping/generate` | `GenerateRequest` | `ShoppingListResponse` |
| POST | `/api/shopping/items` | `ShoppingItemCreate` | `ShoppingItemResponse` |
| PATCH | `/api/shopping/items/{id}/check` | – | `ShoppingItemResponse` |
| DELETE | `/api/shopping/items/{id}` | – | 204 |
| POST | `/api/shopping/sort` | – | `ShoppingListResponse` |
| POST | `/api/shopping/clear-all` | – | JSON |

#### Views

1. **ShoppingListView** (Hauptansicht)
   - Fortschrittsanzeige: "12/18 erledigt" mit ProgressView
   - Quick-Add: Textfeld + Kategorie-Picker + "+"
   - **Verbesserung:** Schnellerfassung: Einfach tippen → automatisch "sonstiges", Kategorie spaeter aenderbar
   - Wenn `sorted_by_store != nil`: Nach Supermarkt-Abteilungen gruppiert (sort_order)
   - Sonst: Nach Zutatenkategorie gruppiert

2. **ShoppingCategorySection** (Section)
   - Header: Icon + Kategoriename + Count-Badge
   - Items: Checkbox + Name + Menge/Einheit
   - Tap → Check/Uncheck (Toggle)
   - Swipe → Loeschen (nur bei source == "manual")

3. **Action-Buttons**
   - "KI-Sortierung" → `POST /api/shopping/sort` (Spinner waehrend Laden)
   - "An Knuspr senden" → `POST /api/knuspr/cart/send-list/{id}`
   - "Liste leeren" → Bestaetigungs-Dialog → `POST /api/shopping/clear-all`
   - **Verbesserung:** Share-Sheet um Liste als Text zu teilen

#### KI-Sortierung

Sortiert nach typischem Supermarkt-Rundgang (Obst → Backwaren → Fleisch → Kaese → Kuehl → Tiefkuehl → Trockenware → Gewuerze → Getraenke → Suessigkeiten → Drogerie → Kasse). Jeder Artikel bekommt eine `store_section` und `sort_order`. Nach Sortierung werden Sections mit Icons angezeigt.

#### Section-Icons

```swift
let sectionIcons: [String: String] = [
    "Obst & Gemuese": "🍎", "Backwaren": "🍞", "Fleisch & Wurst": "🥩",
    "Kaese": "🧀", "Kuehlregal": "🧊", "Molkereiprodukte": "🥛",
    "Tiefkuehl": "❄️", "Trockenware": "🥫", "Gewuerze & Backen": "🧂",
    "Getraenke": "🥤", "Suessigkeiten": "🍬", "Drogerie": "🧹",
    "Sonstiges": "📦", "Erledigt": "✅"
]
```

### 6.10 Vorratskammer (Pantry)

#### API-Endpunkte

| Methode | Pfad | Body/Query | Response |
|---------|------|------------|----------|
| GET | `/api/pantry/` | Query: `category`, `search` | `[PantryItemResponse]` |
| POST | `/api/pantry/` | `PantryItemCreate` | `PantryItemResponse` |
| POST | `/api/pantry/bulk` | `PantryBulkAddRequest` | `[PantryItemResponse]` |
| PATCH | `/api/pantry/{id}` | `PantryItemUpdate` | `PantryItemResponse` |
| DELETE | `/api/pantry/{id}` | – | 204 |
| GET | `/api/pantry/alerts` | – | `[PantryAlertItem]` |
| POST | `/api/pantry/alerts/{id}/add-to-shopping` | – | `{"message": String}` |
| POST | `/api/pantry/alerts/{id}/dismiss` | – | `{"message": String}` |

#### Backend-Logik (wichtig fuer UX)

- **Merge-bei-Duplikaten:** Wenn ein Artikel mit gleichem normalisierten Namen + Einheit existiert, werden Mengen addiert (nicht doppelt angelegt)
- **Niedrigbestand-Schwelle:** `min_stock` pro Artikel (Default: 2). Response hat `is_low_stock: Bool`
- **Ablauf-Warnung:** 7 Tage vorher. Response hat `is_expiring_soon: Bool`
- **Alerts API:** Gibt kombinierte Liste aller Warnungen mit `reason: "low_stock" | "expiring_soon"`
- **"Zur Einkaufsliste":** Erstellt Shopping-Item + setzt Pantry-Item amount/expiry auf nil (Warnung verschwindet)
- **"Verwerfen":** Setzt amount/expiry auf nil (Warnung verschwindet)

#### Kategorie-Darstellung (aus Frontend)

| Kategorie-Key | Label | Icon | Sortierung |
|---------------|-------|------|-----------|
| `kuehlregal` | Kuehlregal | 🧊 | 1 |
| `obst_gemuese` | Obst & Gemuese | 🍇 | 2 |
| `trockenware` | Trockenware | 🍞 | 3 |
| `drogerie` | Drogerie | 🧴 | 4 |
| `sonstiges` | Sonstiges | 📦 | 5 |

#### Item-Status-Farben

| Zustand | Bedingung | Visuelle Darstellung |
|---------|-----------|---------------------|
| Normal | Kein Problem | Standard |
| Niedrigbestand | `is_low_stock == true` | Gelb/Orange Akzent |
| Aufgebraucht | `is_low_stock && amount <= 0` | Rot |
| Ablauf naht | `is_expiring_soon == true` | Badge mit Ablaufdatum orange |

#### Ablaufdatum-Formatierung

- Wenn Tag == 1 (Monatserster): Nur Monat + Jahr anzeigen mit "ca." Praefix (z.B. "ca. Januar 2026")
- Sonst: Tag + Kurzmonat + Jahr (z.B. "15. Jan. 2026")
- Wenn `amount == null`: "Menge unbekannt" anzeigen (grauer Text)

#### Views

1. **PantryView** (Hauptansicht)
   - **Verbesserung:** Warnungen als Banner oben (Niedrigbestand, Ablauf innerhalb 7 Tage)
   - Gruppiert nach Kategorie (Reihenfolge: siehe Tabelle oben)
   - Leere Kategorien werden nicht angezeigt
   - Pro Kategorie: Icon + Label + Artikelanzahl als Header
   - Pro Item: Name + Menge/Einheit + Ablaufdatum (wenn vorhanden)
   - Status-Farben je nach Zustand (siehe Tabelle)
   - **Quick-Add Bar** am unteren Rand:
     - Name (Textfeld, Enter loest Hinzufuegen aus)
     - Menge (optional, numerisch)
     - Einheit (optional)
     - Kategorie (Dropdown, Default: sonstiges)
     - Ablaufdatum (optional, DatePicker)
   - Swipe-Actions: Bearbeiten, Loeschen
   - Badge in Tab-Header: "[n] Warnung(en)" wenn Alerts vorhanden
   - Artikel-Zaehler: "[n] Artikel"

2. **PantryItemFormView** (Sheet)
   - Name, Menge, Einheit, Kategorie, Ablaufdatum (optional)
   - Mindestbestand (optional, Placeholder: "Standard: 2")

3. **PantryAlertsView** (Banner oder Section)
   - Header: "⚠ Vorrat pruefen"
   - Pro Warnung:
     - `low_stock`: "Nur noch [amount] [unit] vorhanden" (oder "Niedrig" wenn kein amount)
     - `expiring_soon`: "Laeuft ab: [formatiertes Datum]"
   - Actions pro Item:
     - "Zur Einkaufsliste" (Primary Button) → `POST /api/pantry/alerts/{id}/add-to-shopping`
     - "Noch vorhanden" (Secondary Button) → `POST /api/pantry/alerts/{id}/dismiss`

### 6.11 Cookidoo-Integration

#### API-Endpunkte

| Methode | Pfad | Response |
|---------|------|----------|
| GET | `/api/cookidoo/status` | `{"available": Bool}` |
| GET | `/api/cookidoo/collections` | `[CookidooCollection]` |
| GET | `/api/cookidoo/shopping-list` | `[CookidooRecipeSummary]` |
| GET | `/api/cookidoo/recipes/{id}` | Rezeptdetails |
| POST | `/api/cookidoo/recipes/{id}/import` | `RecipeResponse` |

#### Views

1. **CookidooBrowserView** (Modal/Sheet)
   - Status-Check zuerst (`GET /api/cookidoo/status`)
   - Falls nicht verfuegbar: Info-Hinweis
   - Navigation: Sammlungen → Kapitel → Rezepte
   - Rezeptkarte: Bild + Name
   - Tap → Vorschau mit grossem Bild + "Importieren"-Button
   - Import → lokales Rezept wird erstellt → Feedback-Toast

### 6.12 KI-Sprachassistent

**Komplett neu fuer iOS** (fehlt in Android, vorhanden in Web).

#### API-Endpunkt

| Methode | Pfad | Body | Response |
|---------|------|------|----------|
| POST | `/api/ai/voice-command` | `VoiceCommandRequest` | `VoiceCommandResponse` |

#### Implementierung

1. **Floating Action Button (FAB)**
   - Auf allen Tabs sichtbar (unten rechts, ueber TabBar)
   - 3 Zustaende: Idle (Mikrofon-Icon), Listening (pulsierend rot), Processing (Spinner)

2. **Spracheingabe**
   - Apple Speech Framework (`SFSpeechRecognizer`, Locale: `de-DE`)
   - Tap → Start Listening → Echtzeit-Transkription
   - 5 Sekunden Pause → automatisches Senden
   - Oder manuell "Senden" tippen
   - **Fallback:** Textfeld wenn keine Mikrofon-Berechtigung

3. **Verarbeitung**
   - Transkribierter Text → `POST /api/ai/voice-command`
   - Backend sendet an Claude → parsed Actions → fuehrt sie aus

4. **Ergebnis-Anzeige (Bottom Sheet)**
   - Header: "🎤 Sprachbefehl ausgefuehrt"
   - Input-Text: Zeigt den transkribierten Befehl in Anfuehrungszeichen
   - Summary-Text (von Claude): Natuerlichsprachige Zusammenfassung
   - Liste aller ausgefuehrten Aktionen:
     - Pro Aktion: ✅/❌ Icon + Action-Label + Detail (title/name/count)
     - **Spezialfall `generate_meal_plan`:** Erweiterte Darstellung mit:
       - "[n] Mahlzeiten geplant" + optional "+ Einkaufsliste erstellt"
       - Liste der einzelnen Mahlzeiten (🍽 Icon pro Eintrag)
       - Optionaler Reasoning-Text (💡 Icon)
   - Tippen auf Overlay oder X-Button schliesst das Sheet
   - **Auto-Refresh der aktiven Ansicht** nach Ausfuehrung:
     - Kalender → `refresh()`, Todos → `refresh()`, Meals → `loadWeek()` + optional Pantry
   - **Fehler-Anzeige:** Separater Fehler-Header (⚠ Fehler) mit rotem Text

5. **Text-Fallback** (wenn keine Mikrofon-Berechtigung)
   - Textfeld-Modal: "Sprachbefehl als Text eingeben"
   - Placeholder: "z.B. Morgen um 10 Uhr Arzttermin..."
   - Gleiche Verarbeitung wie Sprachbefehl

#### Unterstuetzte Aktionen

| Aktion | Typ | Beispiel |
|--------|-----|---------|
| Termin erstellen | `create_event` | "Am Montag um 14 Uhr Meeting" |
| Serientermin | `create_recurring_event` | "Jeden Mittwoch um 18 Uhr Stammtisch" |
| Todo erstellen | `create_todo` | "Ich muss Kaffee vorbereiten" |
| Rezept erstellen | `create_recipe` | "Neues Rezept Kartoffelsuppe" |
| Essensplan belegen | `set_meal_slot` | "Dienstag Abend gibt es Spaghetti" |
| Einkaufsartikel | `add_shopping_item` | "500g Mehl auf die Einkaufsliste" |
| Vorrat befuellen | `add_pantry_items` | "Wir haben noch Salz und Pfeffer" |
| KI-Essensplan | `generate_meal_plan` | "Plane mir die Woche" |
| Termin bearbeiten | `update_event` | "Verschiebe das Meeting auf Mittwoch" |
| Todo erledigen | `complete_todo` | "Kaffee vorbereiten ist erledigt" |
| Als gekocht markieren | `mark_cooked` | "Wir haben die Spaghetti gekocht" |
| Loeschen | `delete_event/todo` | "Loesche den Termin Basketball" |

---

## 7. Offline-Modus & Sync

### Strategie: Cache-First mit Background Sync

1. **Lesen:** Immer erst lokalen Cache zeigen, dann API aufrufen und aktualisieren
2. **Schreiben:** Optimistisch lokal aendern, API-Call im Hintergrund
3. **Offline-Queue:** Fehlgeschlagene Writes in Queue → Retry bei Reconnect
4. **Sync-Intervall:** Alle 15 Minuten via Background Task (wie Android)

### SwiftData Models (Lokaler Cache)

Fuer jede API-Entity ein SwiftData `@Model`:
- `CachedEvent`, `CachedTodo`, `CachedRecipe`, `CachedMealPlan`, etc.
- `lastSyncedAt: Date` Feld pro Entity
- `PendingChange` Model fuer die Offline-Queue

### Pending Changes Queue

```swift
@Model
class PendingChange {
    var id: UUID
    var entityType: String     // "event", "todo", etc.
    var operation: String      // "create", "update", "delete"
    var endpoint: String       // "/api/events/"
    var method: String         // "POST", "PUT", "DELETE"
    var payload: Data?         // JSON body
    var createdAt: Date
    var retryCount: Int
}
```

### Sync-Anzeige

- **Verbesserung:** In der Navigation-Bar: kleines Cloud-Icon
  - Gruen-Haekchen: Alles synchronisiert
  - Orange-Pfeil: Synchronisierung laeuft
  - Rot-Ausrufezeichen: Offline, X Aenderungen in Queue
  - Tap → Detail: "3 Aenderungen warten auf Sync. Zuletzt synchronisiert: vor 5 Min."

---

## 8. Design-System & Theming

### Farben

```swift
extension Color {
    static let appPrimary = Color(hex: "#0052CC")
    static let appSuccess = Color(hex: "#00875A")
    static let appDanger = Color(hex: "#DE350B")
    static let appWarning = Color(hex: "#FF8B00")
    static let appSecondary = Color(hex: "#6B778C")
    static let appBackground = Color(.systemGroupedBackground)
    static let appCardBackground = Color(.secondarySystemGroupedBackground)
}
```

### Dark Mode

- **Verbesserung:** Automatisch via `@Environment(\.colorScheme)` + manueller Toggle in Einstellungen
- Semantische Farben verwenden (`.primary`, `.secondary`, `Color(.systemBackground)`)
- Kategorie-Farben bleiben in beiden Modi identisch

### Typografie

- System-Font (San Francisco) in allen Groessen
- Rezept-Titel: `.title2.bold()`
- Section-Header: `.headline`
- Body: `.body`
- Badges: `.caption.bold()`

### Komponenten-Bibliothek

Wiederverwendbare SwiftUI-Views:
- `MemberChipView(member:, selected:)` — Emoji + Name, toggle-bar
- `PriorityBadge(priority:)` — Farbkodiert (rot/orange/grau)
- `DifficultyBadge(difficulty:)` — Gruen/Orange/Rot
- `CategoryPicker(categories:, selected:)`
- `SlotCellView(dayPlan:, slot:)` — Fuer Wochenplan
- `RecipeCardView(recipe:)` — Grid-Karte mit Bild
- `EmptyStateView(icon:, title:, subtitle:)`
- `LoadingOverlay()`
- `ToastView(message:, type:)` — **Verbesserung:** Nicht-blockierende Notifications statt Alerts

---

## 9. Navigationsstruktur

### TabBar (5 Tabs)

```
┌──────┬──────┬──────┬──────┬──────┐
│  📅  │  ✅  │  🍽  │  🛒  │  ⚙️  │
│Kalend│Todos │Essen │Einkau│ Mehr │
└──────┴──────┴──────┴──────┴──────┘
```

1. **Kalender** — Monats/Wochen/Tagesansicht, Events
2. **Todos** — Aufgabenliste mit Filtern
3. **Essen** — Wochenplan + Rezepte (Segmented Control oben)
4. **Einkauf** — Einkaufsliste + Vorratskammer (Segmented Control oben)
5. **Mehr** — Familienmitglieder, Kategorien, Cookidoo, Einstellungen, Family-Info

### "Mehr"-Tab Inhalt

| Zeile | Icon | Ziel |
|-------|------|------|
| Familienmitglieder | 👥 | MembersListView |
| Kategorien | 📁 | CategoriesListView |
| Cookidoo Browser | 🍳 | CookidooBrowserView |
| Rezeptvorschlaege | 💡 | RecipeSuggestionsView |
| Kochhistorie | 📊 | CookingHistoryView |
| Einstellungen | ⚙️ | SettingsView |
| Familie | 👨‍👩‍👧‍👦 | FamilyInfoView (Name, Einladungscode, teilen) |

### FAB (Floating Action Button)

- Auf Tabs 1-4 sichtbar (als Overlay)
- Mikrofon-Icon → Sprachassistent
- **Verbesserung:** 3D Touch / Haptic Touch → Schnellaktionen (Neues Event, Neues Todo, Neues Rezept)

---

## 10. Verbesserungen gegenueber Web-App

Hier alle Verbesserungen zusammengefasst, die direkt in der iOS-App umgesetzt werden sollen:

### UX-Verbesserungen

| # | Verbesserung | Betroffenes Modul |
|---|-------------|-------------------|
| 1 | **4 Kalenderansichten** (Monat, Woche, 3 Tage, Tag) statt nur Monat | Kalender |
| 2 | **Rezeptsuche und Filter** (Schwierigkeit, Quelle, Zubereitungszeit) | Rezepte |
| 3 | **Rezeptvorschlaege prominent anzeigen** (selten/nie gekocht) | Rezepte |
| 4 | **Kochhistorie anzeigen** im Rezept-Detail und als eigene Ansicht | Rezepte, Wochenplan |
| 5 | **Kategorie-Verwaltungs-UI** (fehlt in Web und Android komplett) | Kategorien |
| 6 | **Toast-Benachrichtigungen** statt blockierende Alerts | Global |
| 7 | **Pull-to-Refresh** auf allen Listen | Global |
| 8 | **Biometrische Authentifizierung** (Face ID / Touch ID) | Auth |
| 9 | **Share-Sheet fuer Einkaufsliste** als Text teilen | Einkaufsliste |
| 10 | **Offline-Sync-Status-Anzeige** mit Details | Global |
| 11 | **Haptic Feedback** bei Aktionen (Check, Delete, Create) | Global |
| 12 | **Drag & Drop im Wochenplan** (Rezept zwischen Slots verschieben) | Wochenplan |
| 13 | **Schnellrezept beim Slot-Zuweisen** (Titel eingeben → erstellen + zuweisen) | Wochenplan |
| 14 | **URL-Import fuer Rezepte** (Chefkoch, etc. via parse-url Endpoint) | Rezepte |
| 15 | **Eigenes Emoji per Keyboard** bei Familienmitgliedern | Mitglieder |

### Fehlende Features aus Web ergaenzt

| # | Feature | Status in Web | iOS-Plan |
|---|---------|--------------|----------|
| 1 | KI-Essensplanung (komplett) | ✅ Web-only | Vollstaendig implementieren |
| 2 | KI-Einkaufslisten-Sortierung | ✅ Web-only | Vollstaendig implementieren |
| 3 | KI-Sprachassistent | ✅ Web-only | Vollstaendig implementieren (Apple Speech) |
| 4 | Vorratskammer | ✅ Web-only | Vollstaendig implementieren |
| 5 | Cookidoo-Browser | ✅ Web + Android | Implementieren |
| 6 | URL-Import fuer Rezepte | ✅ Web-only | Implementieren |

### Technische Verbesserungen

| # | Verbesserung | Detail |
|---|-------------|--------|
| 1 | **Keychain statt localStorage** fuer Token | Sicherer als Android SharedPreferences |
| 2 | **SwiftData statt Room** fuer Offline-Cache | Native Apple-Persistenz |
| 3 | **Background App Refresh** fuer Sync | `BGAppRefreshTask` alle 15 Min |
| 4 | **Widget-Vorbereitung** | WidgetKit-Extension fuer Tagesagenda vorbereiten |
| 5 | **Push-Notification-Vorbereitung** | Struktur fuer spaetere FCM/APNs-Integration |

---

## 11. Projektstruktur

```
Familienkalender/
├── FamilienkalenderApp.swift          ← App-Einstiegspunkt
├── AppDependencies.swift              ← DI-Container
│
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift            ← HTTP-Client mit JWT
│   │   ├── APIError.swift             ← Fehlertypen
│   │   └── Endpoints.swift            ← Pfad-Konstanten
│   ├── Auth/
│   │   ├── AuthManager.swift          ← Token-Management, Login-State
│   │   └── KeychainManager.swift      ← Keychain-Zugriff
│   ├── Storage/
│   │   ├── LocalStore.swift           ← SwiftData-Container
│   │   └── PendingChangeQueue.swift   ← Offline-Queue
│   ├── Sync/
│   │   └── BackgroundSyncManager.swift
│   └── Extensions/
│       ├── Date+Extensions.swift
│       ├── Color+Hex.swift
│       └── String+Extensions.swift
│
├── Models/                            ← API DTOs (alle Codable Structs)
│   ├── Auth.swift
│   ├── Family.swift
│   ├── Event.swift
│   ├── Todo.swift
│   ├── Recipe.swift
│   ├── MealPlan.swift
│   ├── Shopping.swift
│   ├── Pantry.swift
│   ├── AI.swift
│   ├── Proposal.swift
│   ├── Cookidoo.swift
│   └── VoiceCommand.swift
│
├── Repositories/                      ← Online/Offline-Logik
│   ├── EventRepository.swift
│   ├── TodoRepository.swift
│   ├── RecipeRepository.swift
│   ├── MealPlanRepository.swift
│   ├── ShoppingRepository.swift
│   ├── PantryRepository.swift
│   ├── CategoryRepository.swift
│   ├── MemberRepository.swift
│   └── ProposalRepository.swift
│
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── CalendarViewModel.swift
│   ├── TodoViewModel.swift
│   ├── RecipeViewModel.swift
│   ├── MealPlanViewModel.swift
│   ├── ShoppingViewModel.swift
│   ├── PantryViewModel.swift
│   ├── AIMealPlanViewModel.swift
│   ├── VoiceCommandViewModel.swift
│   ├── MemberViewModel.swift
│   ├── CategoryViewModel.swift
│   └── CookidooViewModel.swift
│
├── Views/
│   ├── App/
│   │   ├── ContentView.swift          ← Root: Auth vs App Router
│   │   ├── MainTabView.swift          ← TabBar
│   │   └── MoreTabView.swift          ← "Mehr"-Tab Liste
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   ├── FamilyOnboardingView.swift
│   │   └── ServerConfigView.swift
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   ├── MonthGridView.swift
│   │   ├── WeekTimelineView.swift
│   │   ├── DayDetailView.swift
│   │   └── EventFormView.swift
│   ├── Todos/
│   │   ├── TodoListView.swift
│   │   ├── TodoItemRow.swift
│   │   ├── TodoFormView.swift
│   │   └── ProposalViews.swift
│   ├── Recipes/
│   │   ├── RecipeListView.swift
│   │   ├── RecipeCardView.swift
│   │   ├── RecipeDetailView.swift
│   │   ├── RecipeFormView.swift
│   │   └── RecipeSuggestionsView.swift
│   ├── Meals/
│   │   ├── WeekPlanView.swift
│   │   ├── SlotCellView.swift
│   │   ├── AssignSlotView.swift
│   │   ├── MarkCookedSheet.swift
│   │   └── CookingHistoryView.swift
│   ├── AI/
│   │   ├── AIMealPlanWizard.swift
│   │   ├── AIConfigStepView.swift
│   │   ├── AIPreviewStepView.swift
│   │   └── UndoBarView.swift
│   ├── Shopping/
│   │   ├── ShoppingListView.swift
│   │   ├── ShoppingItemRow.swift
│   │   └── ShoppingCategorySection.swift
│   ├── Pantry/
│   │   ├── PantryView.swift
│   │   ├── PantryItemRow.swift
│   │   ├── PantryFormView.swift
│   │   └── PantryAlertsView.swift
│   ├── Members/
│   │   ├── MembersListView.swift
│   │   └── MemberFormView.swift
│   ├── Categories/
│   │   ├── CategoriesListView.swift
│   │   └── CategoryFormView.swift
│   ├── Cookidoo/
│   │   ├── CookidooBrowserView.swift
│   │   └── CookidooRecipePreview.swift
│   ├── Voice/
│   │   ├── VoiceFABView.swift
│   │   └── VoiceResultSheet.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── FamilyInfoView.swift
│   └── Components/                    ← Wiederverwendbare UI
│       ├── MemberChipView.swift
│       ├── PriorityBadge.swift
│       ├── DifficultyBadge.swift
│       ├── CategoryPicker.swift
│       ├── EmptyStateView.swift
│       ├── LoadingOverlay.swift
│       ├── ToastView.swift
│       └── SyncStatusIndicator.swift
│
├── Cache/                             ← SwiftData Models
│   ├── CachedEvent.swift
│   ├── CachedTodo.swift
│   ├── CachedRecipe.swift
│   └── PendingChange.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings (de)
    └── Info.plist
```

---

## 12. API-Endpunkt-Referenz (Komplett)

Alle 72 Endpunkte des Backends, gruppiert nach Router:

### Auth (`/api/auth`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| POST | `/register` | User registrieren |
| POST | `/login` | Login → JWT Token |
| GET | `/me` | Aktuellen User abrufen |
| PATCH | `/link-member` | User mit Familienmitglied verknuepfen |
| POST | `/family` | Neue Familie erstellen |
| POST | `/family/join` | Familie beitreten (Einladungscode) |
| GET | `/family` | Eigene Familie abrufen |

### Events (`/api/events`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/` | Events auflisten (Filter: date_from, date_to, member_id, category_id) |
| GET | `/{id}` | Einzelnes Event |
| POST | `/` | Event erstellen |
| PUT | `/{id}` | Event aktualisieren |
| DELETE | `/{id}` | Event loeschen |

### Todos (`/api/todos`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/` | Todos auflisten (Filter: completed, priority, member_id, category_id) |
| GET | `/{id}` | Einzelnes Todo |
| POST | `/` | Todo erstellen (parent_id fuer Sub-Todos) |
| PUT | `/{id}` | Todo aktualisieren |
| PATCH | `/{id}/complete` | Toggle completed |
| PATCH | `/{id}/link-event` | Mit Event verknuepfen |
| DELETE | `/{id}` | Todo loeschen |

### Proposals (`/api/proposals` + `/api/todos`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| POST | `/api/todos/{id}/proposals` | Terminvorschlag erstellen |
| GET | `/api/todos/{id}/proposals` | Vorschlaege fuer ein Todo |
| POST | `/api/proposals/{id}/respond` | Auf Vorschlag antworten |
| GET | `/api/proposals/pending` | Eigene offene Vorschlaege |

### Recipes (`/api/recipes`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/` | Rezepte auflisten (sort_by, order) |
| POST | `/` | Rezept erstellen |
| POST | `/parse-url` | URL parsen → Rezeptvorschau |
| GET | `/suggestions` | Rezeptvorschlaege (selten gekocht) |
| GET | `/{id}` | Rezeptdetail mit History |
| PUT | `/{id}` | Rezept aktualisieren |
| DELETE | `/{id}` | Rezept loeschen |
| GET | `/{id}/history` | Kochhistorie eines Rezepts |

### Meals (`/api/meals`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/plan` | Wochenplan (Query: week) |
| GET | `/history` | Kochhistorie (Query: limit) |
| PUT | `/plan/{date}/{slot}` | Slot belegen |
| DELETE | `/plan/{date}/{slot}` | Slot leeren |
| PATCH | `/plan/{date}/{slot}/done` | Als gekocht markieren |

### Shopping (`/api/shopping`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/list` | Aktive Einkaufsliste |
| POST | `/generate` | Aus Wochenplan generieren |
| POST | `/items` | Artikel manuell hinzufuegen |
| PATCH | `/items/{id}/check` | Toggle abgehakt |
| DELETE | `/items/{id}` | Artikel loeschen |
| POST | `/sort` | KI-Sortierung nach Supermarkt |
| POST | `/clear-all` | Liste archivieren |

### Pantry (`/api/pantry`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/` | Vorratskammer auflisten |
| POST | `/` | Artikel hinzufuegen |
| POST | `/bulk` | Mehrere Artikel auf einmal |
| PATCH | `/{id}` | Artikel bearbeiten |
| DELETE | `/{id}` | Artikel loeschen |
| GET | `/alerts` | Warnungen (Niedrigbestand, Ablauf) |
| POST | `/alerts/{id}/add-to-shopping` | Warnung → Einkaufsliste |
| POST | `/alerts/{id}/dismiss` | Warnung verwerfen |

### AI (`/api/ai`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/available-recipes` | Rezepte + Slots fuer AI-Dialog |
| POST | `/generate-meal-plan` | KI-Vorschau generieren (kein DB-Save) |
| POST | `/confirm-meal-plan` | Vorschau bestaetigen + speichern |
| POST | `/undo-meal-plan` | KI-Plan rueckgaengig machen |
| POST | `/voice-command` | Sprachbefehl interpretieren + ausfuehren |

### Categories (`/api/categories`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/` | Kategorien auflisten |
| POST | `/` | Kategorie erstellen |
| PUT | `/{id}` | Kategorie aktualisieren |
| DELETE | `/{id}` | Kategorie loeschen |

### Family Members (`/api/family-members`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/` | Mitglieder auflisten |
| POST | `/` | Mitglied erstellen |
| PUT | `/{id}` | Mitglied aktualisieren |
| DELETE | `/{id}` | Mitglied loeschen |

### Cookidoo (`/api/cookidoo`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/status` | Verfuegbarkeit pruefen |
| GET | `/collections` | Sammlungen mit Rezepten |
| GET | `/shopping-list` | Cookidoo-Einkaufsliste |
| GET | `/recipes/{id}` | Rezeptdetails |
| POST | `/recipes/{id}/import` | Rezept importieren |
| GET | `/calendar` | Cookidoo-Wochenkalender |

### Knuspr (`/api/knuspr`)
| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/products/search` | Produktsuche |
| POST | `/cart/add` | Produkt in Warenkorb |
| POST | `/cart/send-list/{id}` | Einkaufsliste senden |
| GET | `/delivery-slots` | Lieferslots |
| DELETE | `/cart` | Warenkorb leeren |

---

## 13. Implementierungsreihenfolge

### Phase 1: Foundation (Woche 1-2)
1. Xcode-Projekt erstellen, Projektstruktur anlegen
2. `APIClient` + `KeychainManager` + `APIError`
3. Alle Codable DTOs (Models/)
4. `AuthManager` + Login/Register-Flow
5. Family-Onboarding
6. `MainTabView` mit leerem Grundgeruest

### Phase 2: Kern-Features (Woche 3-5)
7. Familienmitglieder CRUD
8. Kategorien CRUD
9. Kalender (Monatsansicht + Event-CRUD)
10. Todos (Liste + CRUD + Sub-Todos + Filter)
11. Rezepte (Liste + CRUD + Zutaten)

### Phase 3: Essensplanung (Woche 6-7)
12. Wochenplan (Anzeige + Slot-Zuweisung + Leeren)
13. Als gekocht markieren (mit Bewertung)
14. Kochhistorie-Ansicht
15. Einkaufsliste (Anzeige + Generierung + Check/Uncheck + Quick-Add)

### Phase 4: KI-Features (Woche 8-9)
16. KI-Essensplanung (2-Schritt-Wizard + Undo)
17. KI-Einkaufslistensortierung
18. KI-Sprachassistent (Speech Framework + FAB)

### Phase 5: Erweiterte Features (Woche 10-11)
19. Vorratskammer (CRUD + Alerts)
20. Cookidoo-Browser + Import
21. Terminvorschlaege (Proposals)
22. URL-Import fuer Rezepte
23. Kalender: Wochen-/Tag-Ansichten

### Phase 6: Polish (Woche 12)
24. Offline-Modus + SwiftData Cache
25. Background Sync
26. Dark Mode feintuning
27. Haptic Feedback, Animationen
28. Lokalisierung (deutsch)
29. App-Icon, LaunchScreen

---

## 14. Testing-Strategie

### Unit Tests
- `APIClient`: Mock URLProtocol, teste alle HTTP-Methoden + Fehlerbehandlung
- ViewModels: Teste State-Uebergaenge mit Mock-Repositories
- Repositories: Teste Online/Offline-Logik
- Date-Extensions: Teste `monday_of`, Formatierungen

### UI Tests
- Login-Flow: Register → Login → Family-Onboarding
- Event erstellen und im Kalender sehen
- Todo Quick-Add und Toggle
- Wochenplan Slot zuweisen
- Einkaufsliste Check/Uncheck

### Preview-basierte Entwicklung
- Jede View hat mindestens eine Preview mit Mock-Daten
- Previews fuer Light + Dark Mode
- Previews fuer leere Zustaende (Empty States)

---

## Wichtige Hinweise fuer den Agenten

### Sprache & Lokalisierung
1. **Sprache der App:** Deutsch (alle UI-Texte, Fehlermeldungen, Placeholder)
2. **Backend-Fehlermeldungen sind Deutsch:** z.B. "Benutzername ist bereits vergeben", "Token ungueltig oder abgelaufen"
3. **Datumsformat:** `de-DE` Locale (TT.MM.JJJJ, DD. Monat JJJJ)
4. **Wochentage:** Montag ist erster Tag (ISO 8601), nicht Sonntag

### API-Konventionen
5. **API sendet Datetime als ISO-String:** Immer `DateFormatter` mit `iso8601` konfigurieren, Timezone-Handling beachten. Backend nutzt UTC, Frontend muss in lokale Zeitzone konvertieren
6. **`family_id` ist auf allen Endpunkten Pflicht** (ausser Auth): Backend prueft per JWT → 403 wenn User keiner Familie zugeordnet
7. **Multi-Tenancy:** Alle Daten sind per `family_id` isoliert. User sieht nur Daten seiner Familie. Die `family_id` wird NICHT in Requests mitgesendet — das Backend leitet sie vom JWT-Token ab
8. **Login gibt nur `access_token` zurueck** (kein Refresh-Token). Token-Lifetime: 24h. Bei 401: Token loeschen, Login-Screen zeigen
9. **204 No Content:** DELETE-Endpunkte geben keinen Body zurueck — `JSONDecoder` darf nicht aufgerufen werden

### String-Enums (Backend erwartet exakte Strings)
10. **Ingredient-Kategorie:** `kuehlregal`, `obst_gemuese`, `trockenware`, `drogerie`, `sonstiges`
11. **Meal-Slot:** `lunch` oder `dinner`
12. **Priority:** `low`, `medium`, `high`
13. **Difficulty:** `easy`, `medium`, `hard`
14. **Recipe source:** `manual`, `cookidoo`, `web`
15. **Shopping-Item source:** `manual`, `recipe`
16. **Proposal status:** `pending`, `accepted`, `rejected`, `superseded`
17. **Proposal response:** `accepted`, `rejected`

### Architektur-Entscheidungen
18. **Backend-URL ist konfigurierbar** — nicht hardcoden, in UserDefaults speichern, editierbar im Login-Screen und Einstellungen
19. **Kein Backend-Aenderung noetig** — die iOS-App nutzt ausschliesslich die bestehenden 72 REST-Endpunkte
20. **Cookidoo/Knuspr sind optional** — Backend-Endpunkte koennen 501/503 zurueckgeben wenn die Integration nicht konfiguriert ist. App muss graceful damit umgehen
21. **KI-Features brauchen ANTHROPIC_API_KEY** — Wenn nicht konfiguriert: 503. App sollte KI-Buttons nur zeigen wenn verfuegbar (oder hilfreiche Fehlermeldung)
22. **`name_normalized` bei Pantry-Items** — Wird vom Backend berechnet (Fuzzy-Matching fuer Duplikaterkennung). Wird NICHT vom Client gesendet

### UX-Kritische Details
23. **AI-Essensplanung ist Preview-basiert:** `generate-meal-plan` speichert NICHT in DB. Erst `confirm-meal-plan` schreibt. Das erlaubt "Neu generieren" ohne Datenbankmuell
24. **Undo-Bar nach AI-Confirm:** 60 Sekunden Timer im Frontend, danach verschwinden die `meal_ids` und Undo ist nicht mehr moeglich
25. **Vorrats-Abzug beim Kochen:** `mark-as-cooked` Response hat `pantry_deductions` — zeige dem User welche Vorratsartikel abgezogen wurden
26. **Einkaufsliste: Vorrats-Abgleich:** Beim Generieren werden Vorrats-Mengen automatisch abgezogen. Nur die Differenz landet auf der Liste
27. **Voice-Command Auto-Refresh:** Nach Ausfuehrung muss die aktive Ansicht neu geladen werden (Events, Todos, Meals, etc.)
