# Familienkalender Android App — Vollstaendiger Bauplan

> **Ziel:** Auf Basis dieses Dokuments soll ein Agent eine vollstaendige, native Android-App (Kotlin, Jetpack Compose) bauen koennen, die funktional aequivalent zur bestehenden Web-App ist — inklusive direkt integrierter Verbesserungen.
>
> **Backend:** Das bestehende FastAPI-Backend (72 Endpunkte) bleibt unveraendert. Die App kommuniziert ausschliesslich ueber die REST-API.
>
> **Sprache der App-UI:** Deutsch

---

## Inhaltsverzeichnis

1. [Technologie-Stack & Architektur](#1-technologie-stack--architektur)
2. [Projektstruktur](#2-projektstruktur)
3. [Datenmodell (Room Entities)](#3-datenmodell-room-entities)
4. [API-Schicht (Retrofit)](#4-api-schicht-retrofit)
5. [Repository-Schicht](#5-repository-schicht)
6. [Authentifizierung & Familien-Onboarding](#6-authentifizierung--familien-onboarding)
7. [Screen: Kalender](#7-screen-kalender)
8. [Screen: Aufgaben (Todos)](#8-screen-aufgaben-todos)
9. [Screen: Einkauf & Essen (Tabs)](#9-screen-einkauf--essen-tabs)
10. [Screen: Familienmitglieder](#10-screen-familienmitglieder)
11. [Feature: KI-Essensplanung](#11-feature-ki-essensplanung)
12. [Feature: Einkaufsliste + KI-Sortierung](#12-feature-einkaufsliste--ki-sortierung)
13. [Feature: Vorratskammer (Pantry)](#13-feature-vorratskammer-pantry)
14. [Feature: Terminvorschlaege (Proposals)](#14-feature-terminvorschlaege-proposals)
15. [Feature: Cookidoo-Integration](#15-feature-cookidoo-integration)
16. [Feature: Sprachassistent](#16-feature-sprachassistent)
17. [Offline-Modus & Sync](#17-offline-modus--sync)
18. [Navigation & App-Shell](#18-navigation--app-shell)
19. [Theming & Design-System](#19-theming--design-system)
20. [Verbesserungen gegenueber Web-App](#20-verbesserungen-gegenueber-web-app)
21. [Vollstaendige API-Referenz](#21-vollstaendige-api-referenz)
22. [Enum-Definitionen](#22-enum-definitionen)
23. [Implementierungs-Reihenfolge](#23-implementierungs-reihenfolge)
24. [Anhang A: DTO-Strukturen fuer komplexe Responses](#anhang-a-dto-strukturen-fuer-komplexe-responses)
25. [Anhang B: Wichtige Business-Logik-Details](#anhang-b-wichtige-business-logik-details)
26. [Anhang C: Checkliste fuer den implementierenden Agenten](#anhang-c-checkliste-fuer-den-implementierenden-agenten)

---

## 1. Technologie-Stack & Architektur

### Stack

| Komponente | Technologie | Version |
|------------|-------------|---------|
| Sprache | Kotlin | 2.0+ |
| UI Framework | Jetpack Compose + Material 3 | BOM latest |
| Navigation | Compose Navigation (type-safe) | 2.8+ |
| HTTP Client | Retrofit 2 + OkHttp + Moshi | latest |
| Lokale DB | Room (KSP) | latest |
| DI | Hilt | latest |
| Async | Kotlin Coroutines + Flow | latest |
| Image Loading | Coil (Compose) | latest |
| Background | WorkManager | latest |
| Spracheingabe | Android SpeechRecognizer | Platform API |
| State | ViewModel + StateFlow + SavedStateHandle | latest |

### Architekturmuster: MVVM + Clean Architecture (vereinfacht)

```
UI (Compose Screens)
  ↕ StateFlow / Events
ViewModel (pro Screen)
  ↕ suspend fun / Flow
Repository (pro Feature)
  ↕               ↕
Remote (Retrofit)  Local (Room)
```

### Prinzipien

- **Single Source of Truth:** Room DB fuer alle gecachten Daten. API-Responses werden in Room geschrieben, UI beobachtet Room-Flows.
- **Offline-First:** Alle Lese-Operationen aus Room. Schreib-Operationen gehen direkt an die API; bei Fehler in PendingChange-Queue.
- **Unidirektionaler Datenfluss:** Screen State ist ein einzelnes `data class UiState(...)` im ViewModel, exponiert als `StateFlow`.
- **Multi-Tenancy:** Die `family_id` kommt vom Server (JWT-basiert). Die App muss sie nicht manuell setzen — das Backend filtert automatisch.

---

## 2. Projektstruktur

```
app/src/main/java/de/familienkalender/
├── di/                          ← Hilt Module
│   ├── NetworkModule.kt         ← Retrofit, OkHttp, Moshi, AuthInterceptor
│   ├── DatabaseModule.kt        ← Room DB, DAOs
│   └── RepositoryModule.kt      ← Repository-Bindings
│
├── data/
│   ├── local/
│   │   ├── AppDatabase.kt       ← Room @Database (alle Entities + DAOs)
│   │   ├── entity/              ← Room @Entity Klassen (1:1 API-Modell)
│   │   │   ├── UserEntity.kt
│   │   │   ├── FamilyEntity.kt
│   │   │   ├── FamilyMemberEntity.kt
│   │   │   ├── CategoryEntity.kt
│   │   │   ├── EventEntity.kt
│   │   │   ├── EventMemberCrossRef.kt
│   │   │   ├── TodoEntity.kt
│   │   │   ├── TodoMemberCrossRef.kt
│   │   │   ├── ProposalEntity.kt
│   │   │   ├── ProposalResponseEntity.kt
│   │   │   ├── RecipeEntity.kt
│   │   │   ├── IngredientEntity.kt
│   │   │   ├── MealPlanEntity.kt
│   │   │   ├── CookingHistoryEntity.kt
│   │   │   ├── ShoppingListEntity.kt
│   │   │   ├── ShoppingItemEntity.kt
│   │   │   ├── PantryItemEntity.kt
│   │   │   └── PendingChangeEntity.kt  ← Offline-Queue
│   │   ├── dao/                 ← Room @Dao Interfaces
│   │   │   ├── UserDao.kt
│   │   │   ├── EventDao.kt
│   │   │   ├── TodoDao.kt
│   │   │   ├── RecipeDao.kt
│   │   │   ├── MealPlanDao.kt
│   │   │   ├── ShoppingDao.kt
│   │   │   ├── PantryDao.kt
│   │   │   ├── CategoryDao.kt
│   │   │   ├── MemberDao.kt
│   │   │   ├── ProposalDao.kt
│   │   │   └── PendingChangeDao.kt
│   │   ├── TokenManager.kt      ← DataStore: JWT + User-Info
│   │   └── Converters.kt        ← Room TypeConverters (Date, DateTime, List<Int>)
│   │
│   ├── remote/
│   │   ├── api/                 ← Retrofit @Service Interfaces
│   │   │   ├── AuthApi.kt
│   │   │   ├── EventApi.kt
│   │   │   ├── TodoApi.kt
│   │   │   ├── ProposalApi.kt
│   │   │   ├── RecipeApi.kt
│   │   │   ├── MealApi.kt
│   │   │   ├── ShoppingApi.kt
│   │   │   ├── PantryApi.kt
│   │   │   ├── CookidooApi.kt
│   │   │   ├── KnusprApi.kt
│   │   │   ├── AiApi.kt
│   │   │   ├── CategoryApi.kt
│   │   │   └── FamilyMemberApi.kt
│   │   ├── dto/                 ← Moshi @JsonClass DTOs (Request/Response)
│   │   │   ├── AuthDto.kt
│   │   │   ├── EventDto.kt
│   │   │   ├── TodoDto.kt
│   │   │   ├── RecipeDto.kt
│   │   │   ├── MealPlanDto.kt
│   │   │   ├── ShoppingDto.kt
│   │   │   ├── PantryDto.kt
│   │   │   ├── AiDto.kt
│   │   │   ├── ProposalDto.kt
│   │   │   ├── CookidooDto.kt
│   │   │   └── CommonDto.kt
│   │   ├── AuthInterceptor.kt   ← OkHttp Interceptor: Bearer Token + 401 Handling
│   │   └── NetworkResult.kt     ← sealed class Success/Error/Loading
│   │
│   └── repository/
│       ├── AuthRepository.kt
│       ├── EventRepository.kt
│       ├── TodoRepository.kt
│       ├── RecipeRepository.kt
│       ├── MealPlanRepository.kt
│       ├── ShoppingRepository.kt
│       ├── PantryRepository.kt
│       ├── ProposalRepository.kt
│       ├── CookidooRepository.kt
│       ├── AiRepository.kt
│       ├── CategoryRepository.kt
│       └── MemberRepository.kt
│
├── sync/
│   ├── SyncWorker.kt            ← WorkManager: Periodischer Sync
│   └── PendingChangeProcessor.kt ← Offline-Queue abarbeiten
│
├── ui/
│   ├── FamilienkalenderApp.kt   ← @Composable Root mit NavHost
│   ├── navigation/
│   │   ├── Screen.kt            ← Sealed class/interface fuer Routen
│   │   └── BottomNavBar.kt      ← Bottom Navigation Composable
│   ├── theme/
│   │   ├── Theme.kt             ← MaterialTheme + DarkTheme
│   │   ├── Color.kt             ← Farbpalette
│   │   └── Type.kt              ← Typografie
│   ├── common/
│   │   ├── LoadingIndicator.kt
│   │   ├── ErrorState.kt
│   │   ├── EmptyState.kt
│   │   ├── ConfirmDialog.kt
│   │   ├── ChipSelector.kt       ← Wiederverwendbar: Multi-/Single-Select Chips
│   │   ├── SearchBar.kt
│   │   ├── PullToRefresh.kt
│   │   ├── CategoryBadge.kt
│   │   ├── MemberAvatar.kt
│   │   ├── PriorityBadge.kt
│   │   ├── DateTimePicker.kt
│   │   └── VoiceFab.kt           ← Floating Action Button fuer Sprache
│   ├── auth/
│   │   ├── LoginScreen.kt
│   │   ├── LoginViewModel.kt
│   │   ├── FamilyOnboardingScreen.kt
│   │   └── FamilyOnboardingViewModel.kt
│   ├── calendar/
│   │   ├── CalendarScreen.kt
│   │   ├── CalendarViewModel.kt
│   │   ├── MonthGrid.kt
│   │   ├── WeekView.kt           ← VERBESSERUNG: Web hat nur Monat
│   │   ├── DayDetailSheet.kt     ← BottomSheet statt Panel
│   │   └── EventFormSheet.kt
│   ├── todos/
│   │   ├── TodoScreen.kt
│   │   ├── TodoViewModel.kt
│   │   ├── TodoItem.kt
│   │   ├── SubTodoList.kt
│   │   ├── TodoFormSheet.kt
│   │   ├── QuickAddBar.kt        ← VERBESSERUNG: fehlte in Android
│   │   └── ProposalTimeline.kt
│   ├── meals/
│   │   ├── MealsScreen.kt        ← Tab-Container
│   │   ├── weekplan/
│   │   │   ├── WeekPlanTab.kt
│   │   │   ├── WeekPlanViewModel.kt
│   │   │   ├── DayColumn.kt
│   │   │   ├── SlotCard.kt
│   │   │   ├── AssignSlotSheet.kt
│   │   │   ├── MarkCookedSheet.kt
│   │   │   └── AiMealPlanSheet.kt  ← KI-Essensplanung (NEU fuer Android)
│   │   ├── recipes/
│   │   │   ├── RecipeListTab.kt
│   │   │   ├── RecipeViewModel.kt
│   │   │   ├── RecipeCard.kt
│   │   │   ├── RecipeDetailSheet.kt
│   │   │   ├── RecipeFormSheet.kt
│   │   │   ├── RecipeSearchBar.kt   ← VERBESSERUNG: Suche/Filter
│   │   │   └── CookidooBrowser.kt
│   │   ├── shopping/
│   │   │   ├── ShoppingTab.kt
│   │   │   ├── ShoppingViewModel.kt
│   │   │   ├── ShoppingItemRow.kt
│   │   │   └── AiSortBanner.kt
│   │   └── pantry/
│   │       ├── PantryTab.kt
│   │       ├── PantryViewModel.kt
│   │       ├── PantryItemRow.kt
│   │       ├── PantryAlertBanner.kt
│   │       └── PantryFormSheet.kt
│   ├── members/
│   │   ├── MemberScreen.kt
│   │   ├── MemberViewModel.kt
│   │   ├── MemberCard.kt
│   │   └── MemberFormSheet.kt
│   ├── settings/
│   │   ├── SettingsScreen.kt
│   │   └── SettingsViewModel.kt
│   └── voice/
│       ├── VoiceOverlay.kt
│       ├── VoiceViewModel.kt
│       └── VoiceResultSheet.kt
│
└── util/
    ├── DateUtils.kt              ← mondayOf(), formatDE(), etc.
    ├── Extensions.kt             ← Context, Flow Extensions
    └── Constants.kt
```

---

## 3. Datenmodell (Room Entities)

### 3.1 UserEntity

```kotlin
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: Int,
    val username: String,
    val familyId: Int?,
    val familyName: String?,
    val familyInviteCode: String?,
    val memberId: Int?,
    val memberName: String?,
)
```

### 3.2 FamilyMemberEntity

```kotlin
@Entity(tableName = "family_members")
data class FamilyMemberEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val color: String,        // Hex z.B. "#0052CC"
    val avatarEmoji: String,  // z.B. "👤"
    val createdAt: String,    // ISO datetime
)
```

### 3.3 CategoryEntity

```kotlin
@Entity(tableName = "categories")
data class CategoryEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val color: String,
    val icon: String,
)
```

### 3.4 EventEntity + EventMemberCrossRef

```kotlin
@Entity(tableName = "events")
data class EventEntity(
    @PrimaryKey val id: Int,
    val title: String,
    val description: String?,
    val start: String,         // ISO datetime
    val end: String,           // ISO datetime
    val allDay: Boolean,
    val categoryId: Int?,
    val createdAt: String,
    val updatedAt: String,
)

@Entity(
    tableName = "event_members",
    primaryKeys = ["eventId", "memberId"]
)
data class EventMemberCrossRef(
    val eventId: Int,
    val memberId: Int,
)
```

**Room Relation:**
```kotlin
data class EventWithRelations(
    @Embedded val event: EventEntity,
    @Relation(parentColumn = "categoryId", entityColumn = "id")
    val category: CategoryEntity?,
    @Relation(
        parentColumn = "id", entityColumn = "id",
        associateBy = Junction(EventMemberCrossRef::class, parentColumn = "eventId", entityColumn = "memberId")
    )
    val members: List<FamilyMemberEntity>,
)
```

### 3.5 TodoEntity + TodoMemberCrossRef

```kotlin
@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey val id: Int,
    val title: String,
    val description: String?,
    val priority: String,        // "low" | "medium" | "high"
    val dueDate: String?,        // ISO date
    val completed: Boolean,
    val completedAt: String?,    // ISO datetime
    val categoryId: Int?,
    val eventId: Int?,
    val requiresMultiple: Boolean,
    val parentId: Int?,
    val createdAt: String,
    val updatedAt: String,
)

@Entity(
    tableName = "todo_members",
    primaryKeys = ["todoId", "memberId"]
)
data class TodoMemberCrossRef(
    val todoId: Int,
    val memberId: Int,
)
```

**Room Relation:**
```kotlin
data class TodoWithRelations(
    @Embedded val todo: TodoEntity,
    @Relation(parentColumn = "categoryId", entityColumn = "id")
    val category: CategoryEntity?,
    @Relation(
        parentColumn = "id", entityColumn = "id",
        associateBy = Junction(TodoMemberCrossRef::class, parentColumn = "todoId", entityColumn = "memberId")
    )
    val members: List<FamilyMemberEntity>,
    @Relation(parentColumn = "id", entityColumn = "parentId")
    val subtodos: List<TodoEntity>,
)
```

### 3.6 RecipeEntity + IngredientEntity

```kotlin
@Entity(tableName = "recipes")
data class RecipeEntity(
    @PrimaryKey val id: Int,
    val title: String,
    val source: String,          // "manual" | "cookidoo" | "web"
    val cookidooId: String?,
    val servings: Int,
    val prepTimeActiveMinutes: Int?,
    val prepTimePassiveMinutes: Int?,
    val difficulty: String,      // "easy" | "medium" | "hard"
    val lastCookedAt: String?,
    val cookCount: Int,
    val instructions: String?,
    val notes: String?,
    val imageUrl: String?,
    val aiAccessible: Boolean,
    val createdAt: String,
    val updatedAt: String,
)

@Entity(
    tableName = "ingredients",
    foreignKeys = [ForeignKey(entity = RecipeEntity::class, parentColumns = ["id"], childColumns = ["recipeId"], onDelete = ForeignKey.CASCADE)]
)
data class IngredientEntity(
    @PrimaryKey val id: Int,
    val recipeId: Int,
    val name: String,
    val amount: Double?,
    val unit: String?,
    val category: String,        // "kuehlregal" | "obst_gemuese" | "trockenware" | "drogerie" | "sonstiges"
)
```

### 3.7 MealPlanEntity

```kotlin
@Entity(tableName = "meal_plan")
data class MealPlanEntity(
    @PrimaryKey val id: Int,
    val planDate: String,        // ISO date
    val slot: String,            // "lunch" | "dinner"
    val recipeId: Int,
    val servingsPlanned: Int,
    val createdAt: String,
    val updatedAt: String,
)
```

### 3.8 CookingHistoryEntity

```kotlin
@Entity(tableName = "cooking_history")
data class CookingHistoryEntity(
    @PrimaryKey val id: Int,
    val recipeId: Int,
    val recipeTitle: String,       // denormalized fuer schnellen Zugriff
    val recipeDifficulty: String?,
    val recipeImageUrl: String?,
    val cookedAt: String,
    val servingsCooked: Int,
    val rating: Int?,
)
```

### 3.9 ShoppingListEntity + ShoppingItemEntity

```kotlin
@Entity(tableName = "shopping_lists")
data class ShoppingListEntity(
    @PrimaryKey val id: Int,
    val weekStartDate: String,
    val status: String,          // "active" | "archived"
    val sortedByStore: String?,
    val createdAt: String,
)

@Entity(
    tableName = "shopping_items",
    foreignKeys = [ForeignKey(entity = ShoppingListEntity::class, parentColumns = ["id"], childColumns = ["shoppingListId"], onDelete = ForeignKey.CASCADE)]
)
data class ShoppingItemEntity(
    @PrimaryKey val id: Int,
    val shoppingListId: Int,
    val name: String,
    val amount: String?,
    val unit: String?,
    val category: String,
    val checked: Boolean,
    val source: String,          // "manual" | "generated"
    val recipeId: Int?,
    val sortOrder: Int?,
    val storeSection: String?,
    val createdAt: String,
    val updatedAt: String,
)
```

### 3.10 PantryItemEntity

```kotlin
@Entity(tableName = "pantry_items")
data class PantryItemEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val amount: Double?,
    val unit: String?,
    val category: String,
    val expiryDate: String?,      // ISO date
    val minStock: Double?,
    val isLowStock: Boolean,
    val isExpiringSoon: Boolean,
    val createdAt: String,
    val updatedAt: String,
)
```

### 3.11 ProposalEntity + ProposalResponseEntity

```kotlin
@Entity(tableName = "proposals")
data class ProposalEntity(
    @PrimaryKey val id: Int,
    val todoId: Int,
    val proposedById: Int,
    val proposedDate: String,
    val message: String?,
    val status: String,           // "pending" | "accepted" | "rejected"
    val createdAt: String,
)

@Entity(tableName = "proposal_responses")
data class ProposalResponseEntity(
    @PrimaryKey val id: Int,
    val proposalId: Int,
    val memberId: Int,
    val response: String,         // "accepted" | "rejected"
    val counterProposalId: Int?,
    val message: String?,
    val createdAt: String,
)
```

### 3.12 PendingChangeEntity (Offline-Queue)

```kotlin
@Entity(tableName = "pending_changes")
data class PendingChangeEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val entityType: String,       // "event", "todo", "shopping_item", etc.
    val action: String,           // "create", "update", "delete", "toggle"
    val payload: String,          // JSON-serialisierter Request Body
    val entityId: Int?,           // Falls update/delete
    val createdAt: Long,          // System.currentTimeMillis()
    val retryCount: Int = 0,
)
```

---

## 4. API-Schicht (Retrofit)

### 4.1 AuthApi

```kotlin
interface AuthApi {
    @POST("/api/auth/register")
    suspend fun register(@Body body: SetupRequest): UserResponse

    @POST("/api/auth/login")
    suspend fun login(@Body body: LoginRequest): TokenResponse

    @GET("/api/auth/me")
    suspend fun getMe(): UserResponse

    @PATCH("/api/auth/link-member")
    suspend fun linkMember(@Body body: LinkMemberRequest): UserResponse

    @POST("/api/auth/family")
    suspend fun createFamily(@Body body: FamilyCreateRequest): FamilyResponse

    @POST("/api/auth/family/join")
    suspend fun joinFamily(@Body body: FamilyJoinRequest): FamilyResponse

    @GET("/api/auth/family")
    suspend fun getFamily(): FamilyResponse
}
```

### 4.2 EventApi

```kotlin
interface EventApi {
    @GET("/api/events/")
    suspend fun getEvents(
        @Query("date_from") dateFrom: String? = null,
        @Query("date_to") dateTo: String? = null,
        @Query("member_id") memberId: Int? = null,
        @Query("category_id") categoryId: Int? = null,
    ): List<EventResponse>

    @GET("/api/events/{id}")
    suspend fun getEvent(@Path("id") id: Int): EventResponse

    @POST("/api/events/")
    suspend fun createEvent(@Body body: EventCreateRequest): EventResponse

    @PUT("/api/events/{id}")
    suspend fun updateEvent(@Path("id") id: Int, @Body body: EventUpdateRequest): EventResponse

    @DELETE("/api/events/{id}")
    suspend fun deleteEvent(@Path("id") id: Int)
}
```

### 4.3 TodoApi

```kotlin
interface TodoApi {
    @GET("/api/todos/")
    suspend fun getTodos(
        @Query("completed") completed: Boolean? = null,
        @Query("priority") priority: String? = null,
        @Query("member_id") memberId: Int? = null,
        @Query("category_id") categoryId: Int? = null,
    ): List<TodoResponse>

    @GET("/api/todos/{id}")
    suspend fun getTodo(@Path("id") id: Int): TodoResponse

    @POST("/api/todos/")
    suspend fun createTodo(@Body body: TodoCreateRequest): TodoResponse

    @PUT("/api/todos/{id}")
    suspend fun updateTodo(@Path("id") id: Int, @Body body: TodoUpdateRequest): TodoResponse

    @PATCH("/api/todos/{id}/complete")
    suspend fun toggleComplete(@Path("id") id: Int): TodoResponse

    @PATCH("/api/todos/{id}/link-event")
    suspend fun linkEvent(@Path("id") id: Int, @Body body: LinkEventRequest): TodoResponse

    @DELETE("/api/todos/{id}")
    suspend fun deleteTodo(@Path("id") id: Int)
}
```

### 4.4 ProposalApi

```kotlin
interface ProposalApi {
    @POST("/api/todos/{todoId}/proposals")
    suspend fun createProposal(@Path("todoId") todoId: Int, @Body body: ProposalCreateRequest): ProposalDetail

    @GET("/api/todos/{todoId}/proposals")
    suspend fun getProposals(@Path("todoId") todoId: Int): List<ProposalDetail>

    @POST("/api/proposals/{proposalId}/respond")
    suspend fun respondProposal(@Path("proposalId") proposalId: Int, @Body body: ProposalRespondRequest): ProposalDetail

    @GET("/api/proposals/pending")
    suspend fun getPendingProposals(): List<PendingProposalDetail>
}
```

### 4.5 RecipeApi

```kotlin
interface RecipeApi {
    @GET("/api/recipes/")
    suspend fun getRecipes(
        @Query("sort_by") sortBy: String? = "title",
        @Query("order") order: String? = "asc",
    ): List<RecipeResponse>

    @POST("/api/recipes/")
    suspend fun createRecipe(@Body body: RecipeCreateRequest): RecipeResponse

    @POST("/api/recipes/parse-url")
    suspend fun parseUrl(@Body body: UrlImportRequest): UrlImportPreview

    @GET("/api/recipes/suggestions")
    suspend fun getSuggestions(@Query("limit") limit: Int = 10): List<RecipeSuggestion>

    @GET("/api/recipes/{id}")
    suspend fun getRecipe(@Path("id") id: Int): RecipeDetailResponse

    @PUT("/api/recipes/{id}")
    suspend fun updateRecipe(@Path("id") id: Int, @Body body: RecipeUpdateRequest): RecipeResponse

    @DELETE("/api/recipes/{id}")
    suspend fun deleteRecipe(@Path("id") id: Int)

    @GET("/api/recipes/{id}/history")
    suspend fun getHistory(@Path("id") id: Int): List<CookingHistoryResponse>
}
```

### 4.6 MealApi

```kotlin
interface MealApi {
    @GET("/api/meals/plan")
    suspend fun getWeekPlan(@Query("week") week: String? = null): WeekPlanResponse

    @GET("/api/meals/history")
    suspend fun getHistory(@Query("limit") limit: Int = 10): List<CookingHistoryEntry>

    @PUT("/api/meals/plan/{date}/{slot}")
    suspend fun setSlot(@Path("date") date: String, @Path("slot") slot: String, @Body body: MealSlotUpdate): MealSlotResponse

    @DELETE("/api/meals/plan/{date}/{slot}")
    suspend fun clearSlot(@Path("date") date: String, @Path("slot") slot: String)

    @PATCH("/api/meals/plan/{date}/{slot}/done")
    suspend fun markCooked(@Path("date") date: String, @Path("slot") slot: String, @Body body: MarkCookedRequest?): MarkCookedResponse
}
```

### 4.7 ShoppingApi

```kotlin
interface ShoppingApi {
    @GET("/api/shopping/list")
    suspend fun getActiveList(): ShoppingListResponse?

    @POST("/api/shopping/generate")
    suspend fun generate(@Body body: GenerateRequest): ShoppingListResponse

    @POST("/api/shopping/items")
    suspend fun addItem(@Body body: ShoppingItemCreateRequest): ShoppingItemResponse

    @POST("/api/shopping/clear-all")
    suspend fun clearAll(): Map<String, String>

    @PATCH("/api/shopping/items/{id}/check")
    suspend fun toggleCheck(@Path("id") id: Int): ShoppingItemResponse

    @DELETE("/api/shopping/items/{id}")
    suspend fun deleteItem(@Path("id") id: Int)

    @POST("/api/shopping/sort")
    suspend fun aiSort(): ShoppingListResponse
}
```

### 4.8 PantryApi

```kotlin
interface PantryApi {
    @GET("/api/pantry/")
    suspend fun getItems(
        @Query("category") category: String? = null,
        @Query("search") search: String? = null,
    ): List<PantryItemResponse>

    @POST("/api/pantry/")
    suspend fun addItem(@Body body: PantryItemCreateRequest): PantryItemResponse

    @POST("/api/pantry/bulk")
    suspend fun addBulk(@Body body: PantryBulkAddRequest): List<PantryItemResponse>

    @PATCH("/api/pantry/{id}")
    suspend fun updateItem(@Path("id") id: Int, @Body body: PantryItemUpdateRequest): PantryItemResponse

    @DELETE("/api/pantry/{id}")
    suspend fun deleteItem(@Path("id") id: Int)

    @GET("/api/pantry/alerts")
    suspend fun getAlerts(): List<PantryAlertItem>

    @POST("/api/pantry/alerts/{id}/add-to-shopping")
    suspend fun alertToShopping(@Path("id") id: Int): Map<String, String>

    @POST("/api/pantry/alerts/{id}/dismiss")
    suspend fun dismissAlert(@Path("id") id: Int): Map<String, String>
}
```

### 4.9 AiApi

```kotlin
interface AiApi {
    @GET("/api/ai/available-recipes")
    suspend fun getAvailableRecipes(@Query("week_start") weekStart: String): AvailableRecipesResponse

    @POST("/api/ai/generate-meal-plan")
    suspend fun generateMealPlan(@Body body: GenerateMealPlanRequest): PreviewMealPlanResponse

    @POST("/api/ai/confirm-meal-plan")
    suspend fun confirmMealPlan(@Body body: ConfirmMealPlanRequest): ConfirmMealPlanResponse

    @POST("/api/ai/undo-meal-plan")
    suspend fun undoMealPlan(@Body body: UndoMealPlanRequest): Map<String, Any>

    @POST("/api/ai/voice-command")
    suspend fun voiceCommand(@Body body: VoiceCommandRequest): VoiceCommandResponse
}
```

### 4.10 CookidooApi

```kotlin
interface CookidooApi {
    @GET("/api/cookidoo/status")
    suspend fun getStatus(): CookidooStatus

    @GET("/api/cookidoo/collections")
    suspend fun getCollections(): List<CookidooCollection>

    @GET("/api/cookidoo/shopping-list")
    suspend fun getShoppingList(): List<CookidooShoppingItem>

    @GET("/api/cookidoo/recipes/{cookidooId}")
    suspend fun getRecipe(@Path("cookidooId") id: String): CookidooRecipeDetail

    @POST("/api/cookidoo/recipes/{cookidooId}/import")
    suspend fun importRecipe(@Path("cookidooId") id: String): RecipeResponse

    @GET("/api/cookidoo/calendar")
    suspend fun getCalendar(@Query("week") week: String): Any
}
```

### 4.11 CategoryApi + FamilyMemberApi

```kotlin
interface CategoryApi {
    @GET("/api/categories/")
    suspend fun getAll(): List<CategoryResponse>

    @POST("/api/categories/")
    suspend fun create(@Body body: CategoryCreateRequest): CategoryResponse

    @PUT("/api/categories/{id}")
    suspend fun update(@Path("id") id: Int, @Body body: CategoryUpdateRequest): CategoryResponse

    @DELETE("/api/categories/{id}")
    suspend fun delete(@Path("id") id: Int)
}

interface FamilyMemberApi {
    @GET("/api/family-members/")
    suspend fun getAll(): List<FamilyMemberResponse>

    @POST("/api/family-members/")
    suspend fun create(@Body body: FamilyMemberCreateRequest): FamilyMemberResponse

    @PUT("/api/family-members/{id}")
    suspend fun update(@Path("id") id: Int, @Body body: FamilyMemberUpdateRequest): FamilyMemberResponse

    @DELETE("/api/family-members/{id}")
    suspend fun delete(@Path("id") id: Int)
}
```

### 4.12 JSON-Naming-Konvention (WICHTIG)

Das Backend nutzt **snake_case** fuer alle JSON-Felder (FastAPI/Pydantic Default). Moshi muss entsprechend konfiguriert werden:

```kotlin
val moshi = Moshi.Builder()
    .add(KotlinJsonAdapterFactory())
    .build()
```

DTO-Felder muessen entweder:
- `@Json(name = "snake_case_name")` Annotation haben, oder
- ein globaler `SnakeCaseJsonAdapter` registriert sein

**Beispiele fuer Mapping:**

| Backend JSON | Kotlin DTO |
|-------------|------------|
| `access_token` | `@Json(name = "access_token") val accessToken: String` |
| `family_id` | `@Json(name = "family_id") val familyId: Int?` |
| `member_ids` | `@Json(name = "member_ids") val memberIds: List<Int>` |
| `all_day` | `@Json(name = "all_day") val allDay: Boolean` |
| `due_date` | `@Json(name = "due_date") val dueDate: String?` |
| `prep_time_active_minutes` | `@Json(name = "prep_time_active_minutes") val prepTimeActiveMinutes: Int?` |
| `image_url` | `@Json(name = "image_url") val imageUrl: String?` |
| `week_start_date` | `@Json(name = "week_start_date") val weekStartDate: String` |
| `sort_order` | `@Json(name = "sort_order") val sortOrder: Int?` |
| `store_section` | `@Json(name = "store_section") val storeSection: String?` |
| `pantry_deductions` | `@Json(name = "pantry_deductions") val pantryDeductions: List<PantryDeductionItem>` |

### 4.13 Datumsformate (WICHTIG)

| Typ | Format | Beispiel | Verwendung |
|-----|--------|---------|------------|
| datetime | ISO 8601 | `"2026-03-26T14:30:00+00:00"` | Event start/end, created_at, etc. |
| date | ISO 8601 | `"2026-03-26"` | plan_date, due_date, week_start |
| date Query-Param | ISO 8601 | `2026-03-26` | date_from, date_to, week |

Fuer die Konvertierung in Kotlin:
```kotlin
val isoDateFormatter = DateTimeFormatter.ISO_DATE          // "2026-03-26"
val isoDateTimeFormatter = DateTimeFormatter.ISO_DATE_TIME // "2026-03-26T14:30:00+00:00"
```

### 4.14 AuthInterceptor

```kotlin
class AuthInterceptor @Inject constructor(
    private val tokenManager: TokenManager,
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val token = runBlocking { tokenManager.getToken() }

        val authenticatedRequest = if (token != null) {
            request.newBuilder()
                .addHeader("Authorization", "Bearer $token")
                .build()
        } else request

        val response = chain.proceed(authenticatedRequest)

        if (response.code == 401 && !request.url.encodedPath.contains("/login")) {
            runBlocking { tokenManager.clearToken() }
        }

        return response
    }
}
```

---

## 5. Repository-Schicht

Jedes Repository folgt dem gleichen Pattern:

```kotlin
class EventRepository @Inject constructor(
    private val api: EventApi,
    private val dao: EventDao,
) {
    // Lesen: Flow aus Room
    fun observeEvents(dateFrom: String, dateTo: String): Flow<List<EventWithRelations>>
        = dao.getEventsInRange(dateFrom, dateTo)

    // Refresh: API → Room
    suspend fun refresh(dateFrom: String, dateTo: String) {
        val remote = api.getEvents(dateFrom, dateTo)
        dao.replaceEventsInRange(dateFrom, dateTo, remote.map { it.toEntity() })
        // CrossRefs fuer Members separat
    }

    // Schreiben: API → Room Update
    suspend fun create(request: EventCreateRequest): EventResponse {
        val response = api.createEvent(request)
        dao.insert(response.toEntity())
        return response
    }

    suspend fun update(id: Int, request: EventUpdateRequest): EventResponse { ... }
    suspend fun delete(id: Int) { api.deleteEvent(id); dao.deleteById(id) }
}
```

---

## 6. Authentifizierung & Familien-Onboarding

### 6.1 Flow

```
App-Start
  → TokenManager.getToken()
  → Token vorhanden?
      JA → GET /api/auth/me
           → family_id != null? → App-Shell
           → family_id == null? → FamilyOnboardingScreen
      NEIN → LoginScreen
```

### 6.2 LoginScreen

**UI-Elemente:**
- Server-URL TextField (persistiert in DataStore) — VERBESSERUNG: Konfigurierbare URL
- Username TextField
- Password TextField (mit Toggle-Sichtbarkeit)
- "Anmelden" Button
- "Noch kein Account? Ersteinrichtung" Toggle-Link
- Fehleranzeige (Snackbar)

**Verhalten:**
- Toggle zwischen Login und Registrierung (Ersteinrichtung)
- Bei Registrierung: `POST /api/auth/register`, dann automatisch `POST /api/auth/login`
- Token in DataStore speichern
- Bei Erfolg: `GET /api/auth/me` → Weiterleitung

### 6.3 FamilyOnboardingScreen

**UI-Elemente:**
- Haus-Icon + "Willkommen!" Titel
- Sektion "Neue Familie erstellen" mit Name-Feld + Button
- Divider "oder"
- Sektion "Einladung annehmen" mit Code-Feld + Button
- Fehleranzeige

**Verhalten:**
- Erstellen: `POST /api/auth/family` → App-Shell
- Beitreten: `POST /api/auth/family/join` → App-Shell
- Anschliessend: Modal/Sheet zum Verknuepfen des Users mit einem Familienmitglied (`PATCH /api/auth/link-member`)

---

## 7. Screen: Kalender

### 7.1 Ansichten (VERBESSERUNG: Web hat nur Monatsansicht)

| Ansicht | Beschreibung |
|---------|-------------|
| **Monat** | 7×5/6 Grid, Tage mit Event-Dots, Heute hervorgehoben |
| **Woche** | 7 Tage mit Zeitslots (08:00-22:00), Events als Bloecke |
| **3 Tage** | Wie Woche, aber nur 3 Tage (mobil-optimiert) |
| **Tag** | Ein Tag, Stunden-Raster, alle Events detailliert |

**View-Switch:** SegmentedButton oben (M / W / 3 / T)

### 7.2 Monatsansicht (Hauptansicht)

**UI:**
- Header: `← [Monat Jahr] → [Heute]`
- Grid: Mo-So Spaltenheader, Tageszellen mit:
  - Tageszahl (Heute = farbig hervorgehoben)
  - Bis zu 3 Event-Dots (farbig nach Kategorie)
  - "+2 mehr" bei >3 Events
- Tap auf Tag → DayDetailSheet (BottomSheet)

**API-Aufruf:**
```
GET /api/events/?date_from=2026-03-01&date_to=2026-03-31
```

### 7.3 DayDetailSheet (BottomSheet)

**UI:**
- Datum als Titel ("Donnerstag, 26. Maerz 2026")
- Liste der Events des Tages:
  - Kategorie-Badge (Farbe + Icon)
  - Titel
  - Uhrzeit (oder "Ganztaegig")
  - Member-Avatare
  - Verknuepfte Todos (Anzahl)
- FAB: "+ Event"

**Tap auf Event → EventFormSheet (Bearbeiten)**

### 7.4 EventFormSheet

**Felder:**

| Feld | Typ | Pflicht | Default |
|------|-----|---------|---------|
| Titel | TextField | Ja | "" |
| Beschreibung | TextField (multiline) | Nein | "" |
| Ganztaegig | Switch | Nein | false |
| Start | DateTimePicker | Ja | Tages-Datum + naechste volle Stunde |
| Ende | DateTimePicker | Ja | Start + 1h |
| Kategorie | Dropdown | Nein | null |
| Mitglieder | ChipSelector (multi) | Nein | [] |

**Bei Ganztaegig:** Zeiteingabe ausblenden, Start/Ende werden als reine Daten gesendet.

**Verknuepfte Todos:**
- Liste bestehender Todos zum Event
- "Aufgabe hinzufuegen" → Inline-Formular: Titel + Prioritaet → `POST /api/todos/` mit `event_id`

**Buttons:** Speichern, Loeschen (bei Bearbeitung), Abbrechen

### 7.5 Wiederkehrende Termine (via Sprachassistent)

Serientermine koennen nur per Sprachbefehl erstellt werden (Backend generiert bis zu 200 Einzeltermine). Kein dediziertes UI-Formular noetig, da der Sprachassistent das handhabt.

---

## 8. Screen: Aufgaben (Todos)

### 8.1 UI-Aufbau

**Header:** "Aufgaben" + Filter-Row

**Filter (VERBESSERUNG: Vollstaendige Filter wie Web):**

| Filter | Typ | Optionen |
|--------|-----|----------|
| Prioritaet | Dropdown | Alle / Hoch / Mittel / Niedrig |
| Mitglied | Dropdown | Alle / [Mitglieder] |
| Erledigte zeigen | Switch/Checkbox | Ein/Aus |

**Quick-Add-Bar (VERBESSERUNG: fehlte in Android):**
- TextField "Neue Aufgabe..."
- Prioritaets-Dropdown (Mittel default)
- "+" Button
- Sendet: `POST /api/todos/` mit `{ title, priority }`

### 8.2 Todo-Liste

Jedes Todo-Item zeigt:
- Checkbox (Toggle: `PATCH /api/todos/{id}/complete`)
- Titel (durchgestrichen wenn erledigt)
- Prioritaets-Badge (rot/gelb/gruen)
- Faelligkeitsdatum (rot wenn ueberfaellig)
- Kategorie-Badge
- Member-Avatare
- Sub-Todo-Zaehler ("2/5")
- Kalender-Icon wenn `requires_multiple` (→ Terminvorschlaege)
- Chevron fuer Details

### 8.3 Todo-Detailansicht / Bearbeitungs-Sheet

**Felder:**

| Feld | Typ | Pflicht |
|------|-----|---------|
| Titel | TextField | Ja |
| Beschreibung | TextField (multiline) | Nein |
| Prioritaet | SegmentedButton (Niedrig/Mittel/Hoch) | Ja |
| Faelligkeitsdatum | DatePicker | Nein |
| Kategorie | Dropdown | Nein |
| Mitglieder | ChipSelector (multi) | Nein |
| Mehrpersonen-Markierung | Switch | Nein |
| Verknuepftes Event | Dropdown (bestehende Events) | Nein |

**Sub-Todos-Sektion:**
- Liste der Unteraufgaben mit Checkbox
- "Unteraufgabe hinzufuegen" → Inline TextField
- `POST /api/todos/` mit `{ title, parent_id }`

**Terminvorschlaege (bei `requires_multiple`):**
- Timeline bestehender Vorschlaege
- "Termin vorschlagen" → DateTimePicker → `POST /api/todos/{id}/proposals`

---

## 9. Screen: Einkauf & Essen (Tabs)

### 9.1 Tab-Struktur

Vier Tabs mit ScrollableTabRow:

| Tab | Inhalt |
|-----|--------|
| **Wochenplan** | 7-Tage-Grid mit Mittag/Abend |
| **Rezepte** | Rezept-Liste mit Suche |
| **Einkaufsliste** | Aktive Liste mit KI-Sort |
| **Vorratskammer** | Bestandsliste mit Alerts |

### 9.2 Wochenplan-Tab

**Header:** `← [KW XX: DD.MM - DD.MM] → [Diese Woche] [Einkaufsliste generieren] [KI-Essensplan]`

**Grid-Layout:**

```
         | Mo    | Di    | Mi    | Do    | Fr    | Sa    | So    |
---------|-------|-------|-------|-------|-------|-------|-------|
Mittag   | [Slot]| [Slot]| [Slot]| [Slot]| [Slot]| [Slot]| [Slot]|
Abend    | [Slot]| [Slot]| [Slot]| [Slot]| [Slot]| [Slot]| [Slot]|
```

Auf Mobile: Horizontal scrollbar, oder vertikale Tagesliste.

**Slot-Card:**
- Leer: "+" Button → AssignSlotSheet
- Gefuellt:
  - Rezeptname
  - Schwierigkeits-Emoji (🟢🟡🔴)
  - Portionen
  - Bild (wenn vorhanden, via Coil)
  - "Gekocht ✓" Badge (wenn `CookingHistory` existiert)
  - Tap → SlotActionSheet (Bearbeiten / Gekocht / Leeren)

**Kochhistorie-Sektion (unterhalb Grid):**
- "Letzte 10 Gerichte" als horizontale Karten
- Long-Press / Drag auf leeren Slot → Schnellzuweisung (VERBESSERUNG)

**Undo-Bar:**
- Nach KI-Essensplan-Bestaetigung: Snackbar "KI-Plan erstellt — Rueckgaengig" (60s Timeout)
- Tap → `POST /api/ai/undo-meal-plan` mit `meal_ids`

### 9.3 AssignSlotSheet

- Rezept-Suchfeld (filtert live)
- Rezept-Liste (Titel + Schwierigkeit + Zubereitungszeit)
- "Schnellrezept erstellen" Button → Titel + Portionen → `POST /api/recipes/`
- Portionen-Picker (1-12, Default 4)
- "Zuweisen" → `PUT /api/meals/plan/{date}/{slot}`

### 9.4 MarkCookedSheet

- Portionen (vorausgefuellt)
- Bewertung: 1-5 Sterne
- Notizen (optional)
- Info-Box: "Vorrat wird automatisch abgezogen"
- → `PATCH /api/meals/plan/{date}/{slot}/done`
- Zeigt Pantry-Deduktionen als Toast/Info

---

## 10. Screen: Familienmitglieder

### 10.1 UI-Aufbau

**Header:** "Familienmitglieder" + "+ Mitglied" Button

**Einladungscode-Sektion (VERBESSERUNG: Neu fuer Android):**
- Karte mit Familien-Name und Einladungscode
- "Code kopieren" Button
- "Code teilen" Button (Android Share Intent)

### 10.2 Mitglieder-Liste

Cards mit:
- Avatar (Emoji in farbigem Kreis)
- Name
- Edit / Delete Icons

### 10.3 MemberFormSheet

**Felder:**

| Feld | Typ | Default |
|------|-----|---------|
| Name | TextField | "" |
| Farbe | ChipSelector (single, 8 Farben) | "#0052CC" |
| Avatar | ChipSelector (single, 12 Emojis) | "👤" |

**Farboptionen:** `#0052CC, #00875A, #FF5630, #FFAB00, #6554C0, #00B8D9, #FF8B00, #36B37E`

**Emoji-Optionen:** `👤 👩 👨 👧 👦 👶 🧓 👵 👴 🐶 🐱 ⭐`

---

## 11. Feature: KI-Essensplanung

> **VERBESSERUNG:** Komplett neu fuer Android. Die Web-App hat dieses Feature, Android bisher nicht.

### 11.1 Flow

```
[KI-Essensplan Button]
  → Lade available-recipes (GET /api/ai/available-recipes)
  → Schritt 1: Konfiguration
     - Welche Woche (Standard: aktuelle)
     - Slot-Grid: Jeder der 14 Slots anklickbar (Toggle)
     - Bereits belegte Slots ausgegraut + markiert
     - Cookidoo einbeziehen (Switch, nur wenn verfuegbar)
     - Portionen (Slider 1-12)
     - Wuensche/Praeferenzen (TextField, optional)
  → "Generieren" Button
  → Schritt 2: KI-Vorschau
     - Loading Spinner ("Claude denkt nach...")
     - POST /api/ai/generate-meal-plan
     - Tabelle mit Vorschlaegen:
       | Tag | Slot | Rezept | Quelle | Schwierigkeit |
     - Quelle-Badge: "Lokal" / "Cookidoo" / "Neu"
     - "Begruendung anzeigen" Button → Popup mit reasoning Text
     - Buttons: "Bestaetigen" / "Neu generieren" / "Zurueck"
  → "Bestaetigen"
     - POST /api/ai/confirm-meal-plan
     - Cookidoo-Rezepte werden auto-importiert
     - Einkaufsliste wird auto-generiert
     - Undo-Bar (60s)
```

### 11.2 Request-Schema

```kotlin
data class GenerateMealPlanRequest(
    val weekStart: String,           // ISO date (Montag)
    val servings: Int = 4,
    val preferences: String = "",    // "vegetarisch, leicht, saisonal"
    val selectedSlots: List<SlotSelection>,  // [{date:"2026-03-23", slot:"dinner"}, ...]
    val includeCookidoo: Boolean = false,
)
```

### 11.3 Response-Schema

```kotlin
data class PreviewMealPlanResponse(
    val suggestions: List<MealSuggestion>,
    val reasoning: String?,
)

data class MealSuggestion(
    val date: String,
    val slot: String,
    val recipeId: Int?,        // null bei Cookidoo/Neu
    val cookidooId: String?,   // null bei lokal
    val recipeTitle: String,
    val servingsPlanned: Int,
    val source: String,        // "local" | "cookidoo" | "new"
    val difficulty: String?,
    val prepTime: Int?,
)
```

---

## 12. Feature: Einkaufsliste + KI-Sortierung

### 12.1 UI-Aufbau

**Header:** "Einkaufsliste" + Fortschritt ("5/12 erledigt") + Aktions-Buttons

**Aktionen:**
- "Sortieren (KI)" Button → `POST /api/shopping/sort`
- "An Knuspr senden" Button (nur wenn Knuspr verfuegbar)
- "Liste leeren" Button (Bestaetigungs-Dialog)

**KI-Sort-Badge:** Wenn sortiert, Banner "Sortiert nach Supermarkt-Gang" anzeigen

### 12.2 Artikel-Darstellung

**Ohne KI-Sortierung (nach Zutatenkategorie):**
```
── Kuehlregal ──
☐ Milch (1l)
☑ Butter (250g)           [durchgestrichen]
── Obst & Gemuese ──
☐ Tomaten (500g)
```

**Mit KI-Sortierung (nach Supermarkt-Sektion):**
```
── 🥬 Obst & Gemuese (Eingang) ──
☐ Tomaten (500g)
── 🧊 Kuehlregal ──
☐ Milch (1l)
── 🏪 Kasse ──
...
```

### 12.3 Interaktionen

- Tap auf Checkbox → `PATCH /api/shopping/items/{id}/check` (Toggle)
- Swipe-to-Delete (nur manuelle Artikel, `source == "manual"`)
- Quick-Add: Name + Kategorie-Dropdown → `POST /api/shopping/items`
- "Generieren": `POST /api/shopping/generate` mit `week_start` der aktuellen Woche

### 12.4 Vorrats-Abgleich

Beim Generieren prueft das Backend automatisch die Vorratskammer:
- Zutaten die komplett im Vorrat sind werden NICHT auf die Liste gesetzt
- Teilweise vorhandene Zutaten: Nur die fehlende Menge
- Der User sieht das Ergebnis ohne extra Interaktion

---

## 13. Feature: Vorratskammer (Pantry)

> **VERBESSERUNG:** Komplett neu fuer Android. Web hat es, Android bisher nicht.

### 13.1 UI-Aufbau

**Alert-Banner (oben):**
- Rot: "3 Artikel laufen bald ab" / "2 Artikel auf niedrigem Bestand"
- Tap → Alert-Liste mit Aktionen:
  - "Zur Einkaufsliste" → `POST /api/pantry/alerts/{id}/add-to-shopping`
  - "Verwerfen" → `POST /api/pantry/alerts/{id}/dismiss`

**Quick-Add-Bar:**
- Name (TextField, Pflicht)
- Menge (NumberField, optional)
- Einheit (TextField, optional)
- Kategorie (Dropdown)
- Ablaufdatum (DatePicker, optional)
- "+" Button

**Artikel-Liste (nach Kategorie gruppiert):**
```
── Kuehlregal ──
🟡 Butter           250g    MHD: Apr 2026
🔴 Milch            1 Stk   MHD: 28.03.2026  [Ablauf-Warnung]
── Trockenware ──
🟢 Mehl             2 kg
🔴 Reis             0.5 kg  [Niedrigbestand]
```

### 13.2 Status-Indikatoren

| Status | Bedingung | Darstellung |
|--------|-----------|-------------|
| Normal | Kein Alert | Gruener Punkt |
| Niedrigbestand | `amount <= min_stock` (Default: 2) | Gelber Punkt + Label |
| Ablauf bald | `expiry_date` innerhalb 7 Tagen | Roter Punkt + Label |
| Aufgebraucht | `amount == 0` | Grauer Punkt + durchgestrichen |

### 13.3 Bearbeitungs-Sheet

Alle Felder wie Quick-Add, plus:
- Mindestbestand (NumberField, optional)
- Loeschen-Button

---

## 14. Feature: Terminvorschlaege (Proposals)

### 14.1 Trigger

Terminvorschlaege sind relevant fuer Todos mit `requires_multiple == true`.

### 14.2 Flow

1. User oeffnet Todo mit `requires_multiple`
2. Sieht bestehende Vorschlaege als Timeline
3. "Termin vorschlagen" → DateTimePicker + optionale Nachricht
4. → `POST /api/todos/{id}/proposals`
5. Andere Familienmitglieder sehen Badge im Header (offene Vorschlaege)
6. Koennen annehmen, ablehnen, oder Gegenvorschlag machen

### 14.3 Pending-Badge

In der TopBar (oder BottomNav): Badge-Zaehler ueber dem Kalender/Todo-Icon
- Periodisch aktualisieren: `GET /api/proposals/pending`
- Badge-Zahl = Anzahl offener Vorschlaege die NICHT vom aktuellen User stammen

### 14.4 Proposal-Dialog

**UI:**
- Liste offener Vorschlaege:
  - Vorgeschlagen von: [Avatar + Name]
  - Datum: [formatiert]
  - Nachricht (optional)
  - Buttons: "Annehmen ✓" / "Ablehnen ✗"
- Bei Ablehnung: Option fuer Gegenvorschlag (neues Datum + Nachricht)

---

## 15. Feature: Cookidoo-Integration

### 15.1 Verfuegbarkeitspruefung

Beim App-Start und beim Oeffnen des Rezept-Tabs:
```
GET /api/cookidoo/status → { available: true/false, reason: "..." }
```
Button nur anzeigen wenn `available == true`.

### 15.2 Cookidoo-Browser

Navigations-Stack:

```
[Einkaufsliste + Sammlungen]
  → [Sammlung: Rezeptliste]
    → [Rezept-Vorschau]
      → [Importieren]
```

**Ebene 1: Hauptseite**
- Einkaufsliste-Sektion (Rezepte aus Cookidoo-Einkaufsliste)
- Sammlungen-Grid (Karten mit Name)
- `GET /api/cookidoo/collections` + `GET /api/cookidoo/shopping-list`

**Ebene 2: Sammlung**
- Rezept-Karten mit Titel + Bild
- `GET /api/cookidoo/collections` (gefiltert)

**Ebene 3: Rezeptvorschau**
- Bild, Titel, Zubereitungszeit, Schwierigkeit
- Zutatenliste
- "Importieren" Button → `POST /api/cookidoo/recipes/{id}/import`
- `GET /api/cookidoo/recipes/{cookidooId}`

### 15.3 Web-URL-Import (VERBESSERUNG: fehlte in Android)

Im Rezept-Import-Dialog:
- Tab "Von URL importieren"
- URL-Eingabefeld
- "Vorschau" → `POST /api/recipes/parse-url` → Vorschau-Karte
- "Importieren" → `POST /api/recipes/` mit vorbefuellten Daten

---

## 16. Feature: Sprachassistent

> **VERBESSERUNG:** Komplett neu fuer Android. Web nutzt Browser Web Speech API; Android hat native SpeechRecognizer.

### 16.1 UI

**Floating Action Button (FAB):**
- Position: Unten rechts, ueber BottomNav
- Zustaende:
  - Idle: 🎤 Icon (grau)
  - Listening: 🎤 Icon (rot, pulsierend)
  - Processing: Spinner

**Voice-Overlay (waehrend Aufnahme):**
- Halbtransparenter Overlay
- Transkriptions-Text (Live-Update)
- "Abbrechen" Button
- Automatisches Ende nach 5s Stille

**Ergebnis-Sheet:**
- Zusammenfassung der ausgefuehrten Aktionen
- Pro Aktion: Typ-Icon + Beschreibung + Erfolg/Fehler-Status
- "OK" Button zum Schliessen

### 16.2 Technische Umsetzung

```kotlin
class VoiceViewModel @Inject constructor(
    private val aiRepository: AiRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(VoiceState())
    val state = _state.asStateFlow()

    fun startListening(context: Context) {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "de-DE")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
        // SpeechRecognizer starten
    }

    fun sendCommand(text: String) {
        viewModelScope.launch {
            _state.update { it.copy(isProcessing = true) }
            val result = aiRepository.voiceCommand(text)
            _state.update { it.copy(isProcessing = false, result = result) }
            // Auto-Refresh der aktiven View
        }
    }
}
```

### 16.3 Unterstuetzte Sprachbefehle

| Befehl-Typ | Beispiel | Backend-Aktion |
|------------|---------|----------------|
| `create_event` | "Am Montag um 14 Uhr Meeting mit Michi" | Event erstellen |
| `create_recurring_event` | "Jeden Mittwoch um 18 Uhr Stammtisch" | Serientermin (bis 200 Events) |
| `create_todo` | "Kaffee vorbereiten fuer das Meeting" | Todo erstellen + optional Event-Link |
| `create_recipe` | "Neues Rezept Kartoffelsuppe, einfach" | Rezept erstellen |
| `set_meal_slot` | "Dienstag Abend Spaghetti" | Wochenplan belegen |
| `add_shopping_item` | "500g Mehl zur Einkaufsliste" | Einkaufsartikel hinzufuegen |
| `add_pantry_items` | "Wir haben Salz, Pfeffer, 20 Dosen Tomaten" | Vorratskammer befuellen |
| `generate_meal_plan` | "Plane diese Woche, was Neues und Bewaehrtes" | KI-Essensplan + Auto-Einkaufsliste |
| `update_event` | "Verschiebe Meeting auf Mittwoch 15 Uhr" | Event bearbeiten |
| `update_todo` | "Prioritaet von Dokument auf hoch" | Todo bearbeiten |
| `complete_todo` | "Kaffee vorbereiten ist erledigt" | Todo abschliessen |
| `delete_event` | "Loesche Basketball Training" | Event loeschen |
| `delete_todo` | "Loesche Todo Dokument ausfuellen" | Todo loeschen |

---

## 17. Offline-Modus & Sync

### 17.1 Architektur

```
Online:  UI ← Room ← API (Room wird nach jedem API-Call aktualisiert)
Offline: UI ← Room ← PendingChange-Queue → API (wenn wieder online)
```

### 17.2 Lese-Operationen

Immer aus Room. Room-Flows sorgen fuer automatische UI-Updates.

```kotlin
// DAO
@Query("SELECT * FROM events WHERE start >= :from AND end <= :to ORDER BY start")
fun observeEventsInRange(from: String, to: String): Flow<List<EventEntity>>

// ViewModel
val events = eventRepository.observeEvents(dateFrom, dateTo)
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
```

### 17.3 Schreib-Operationen

```kotlin
suspend fun createEvent(request: EventCreateRequest) {
    try {
        val response = api.createEvent(request)
        dao.insert(response.toEntity())
    } catch (e: IOException) {
        // Offline: In Queue speichern
        pendingChangeDao.insert(PendingChangeEntity(
            entityType = "event",
            action = "create",
            payload = moshi.adapter(EventCreateRequest::class.java).toJson(request),
            createdAt = System.currentTimeMillis(),
        ))
        // Optimistisch in Room einfuegen (mit temporaerer negativer ID)
        dao.insert(request.toTempEntity(tempId = -(System.currentTimeMillis().toInt())))
    }
}
```

### 17.4 Background-Sync (WorkManager)

```kotlin
class SyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        // 1. Pending Changes abarbeiten
        pendingChangeProcessor.processAll()

        // 2. Kerndaten refreshen
        categoryRepository.refresh()
        memberRepository.refresh()
        eventRepository.refresh(thisMonthRange())
        todoRepository.refresh()
        mealPlanRepository.refresh(thisWeek())
        shoppingRepository.refresh()
        pantryRepository.refresh()

        return Result.success()
    }
}
```

**Scheduling:**
```kotlin
val syncRequest = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
    .setConstraints(Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .build())
    .build()

WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "familienkalender_sync",
    ExistingPeriodicWorkPolicy.KEEP,
    syncRequest,
)
```

### 17.5 Offline-Feedback (VERBESSERUNG)

- Snackbar bei Netzwerkfehler: "Offline — Aenderung wird spaeter synchronisiert"
- Status-Bar-Indikator: "Letzte Synchronisierung: vor 5 Min" in Settings
- Pending-Changes-Zaehler: Badge an Settings-Icon

---

## 18. Navigation & App-Shell

### 18.1 Bottom Navigation

| Icon | Label | Screen | Badge |
|------|-------|--------|-------|
| 📅 | Kalender | CalendarScreen | — |
| ✅ | Aufgaben | TodoScreen | Offene Vorschlaege |
| 🍽️ | Essen | MealsScreen (Tabs) | — |
| 👥 | Familie | MemberScreen | — |

### 18.2 TopAppBar

- Titel: Kontextabhaengig ("Kalender", "Aufgaben", etc.)
- Rechts: Settings-Icon (⚙️) → SettingsScreen

### 18.3 SettingsScreen (VERBESSERUNG: Erweitert)

| Einstellung | Typ | Beschreibung |
|-------------|-----|-------------|
| Server-URL | TextField | Backend-Adresse |
| Dark Mode | Switch | Theme umschalten |
| Familien-Info | Karte | Name, Einladungscode, Teilen-Button |
| User verknuepfen | Dropdown | Mit Familienmitglied verknuepfen |
| Sync-Status | Info | Letzte Sync-Zeit, Pending Changes |
| Abmelden | Button | Token loeschen, zum Login |

### 18.4 Navigation Routes

```kotlin
sealed interface Screen {
    @Serializable data object Login : Screen
    @Serializable data object FamilyOnboarding : Screen
    @Serializable data object Calendar : Screen
    @Serializable data object Todos : Screen
    @Serializable data object Meals : Screen
    @Serializable data object Members : Screen
    @Serializable data object Settings : Screen
}
```

---

## 19. Theming & Design-System

### 19.1 Farbpalette

```kotlin
// Light Theme
val Primary = Color(0xFF0052CC)        // Blau
val OnPrimary = Color.White
val PrimaryContainer = Color(0xFFDEEBFF)
val Secondary = Color(0xFF00875A)      // Gruen
val Error = Color(0xFFDE350B)          // Rot
val Warning = Color(0xFFFF8B00)        // Orange
val Surface = Color.White
val Background = Color(0xFFF4F5F7)
val OnSurface = Color(0xFF172B4D)      // Dunkelgrau
val OnSurfaceVariant = Color(0xFF6B778C)

// Dark Theme
val DarkPrimary = Color(0xFF579DFF)
val DarkSurface = Color(0xFF1D2125)
val DarkBackground = Color(0xFF161A1D)
val DarkOnSurface = Color(0xFFDCDFE4)
```

### 19.2 Kategoriefarben (vom Backend)

Die Kategorien haben farbige Icons/Badges. Default-Farbe: `#0052CC`.

### 19.3 Prioritaetsfarben

| Prioritaet | Farbe | Emoji |
|------------|-------|-------|
| Hoch | `#DE350B` (Rot) | 🔴 |
| Mittel | `#FF8B00` (Orange) | 🟡 |
| Niedrig | `#00875A` (Gruen) | 🟢 |

### 19.4 Schwierigkeits-Anzeige

| Schwierigkeit | Label | Emoji |
|---------------|-------|-------|
| easy | Einfach | 🟢 |
| medium | Mittel | 🟡 |
| hard | Schwer | 🔴 |

---

## 20. Verbesserungen gegenueber Web-App

Diese Verbesserungen sollen direkt in der Android-App umgesetzt werden:

### 20.1 Fehlende Features (Feature-Paritaet)

| Feature | Status in Web | Aktion fuer Android |
|---------|--------------|---------------------|
| KI-Essensplanung | ✅ Vorhanden | **NEU implementieren** (Abschnitt 11) |
| Vorratskammer | ✅ Vorhanden | **NEU implementieren** (Abschnitt 13) |
| Sprachassistent | ✅ Vorhanden | **NEU implementieren** (Abschnitt 16) |
| Rezept-URL-Import | ✅ Vorhanden | **NEU implementieren** (Abschnitt 15.3) |
| Quick-Add Todos | ✅ Vorhanden | **NEU implementieren** (Abschnitt 8.1) |
| Mitglieder-Filter Todos | ✅ Vorhanden | **NEU implementieren** (Abschnitt 8.1) |
| KI-Einkaufslisten-Sortierung | ✅ Vorhanden | **NEU implementieren** (Abschnitt 12) |
| Kochhistorie + Drag&Drop | ✅ Vorhanden | **NEU implementieren** (Abschnitt 9.2) |
| "Schon lange nicht gekocht" Hinweis | ✅ Vorhanden | **NEU implementieren** |
| Schnellrezept bei Slotzuweisung | ✅ Vorhanden | **NEU implementieren** (Abschnitt 9.3) |

### 20.2 UX-Verbesserungen (besser als Web)

| Verbesserung | Beschreibung |
|-------------|-------------|
| **Pull-to-Refresh** | Auf allen Listen-Screens |
| **Toast statt Alert** | Nicht-blockierende Snackbars statt `alert()` |
| **Rezeptsuche/-filter** | Suchfeld + Filter nach Schwierigkeit/Zubereitungszeit |
| **Skeleton Loading** | Placeholder waehrend Daten laden |
| **Kategorie-Verwaltung** | UI fuer CRUD (API existiert, Web/Android hatten bisher kein UI) |
| **Offline-Feedback** | Klare Anzeige von Sync-Status und Pending Changes |
| **Share-Intent** | Einladungscode teilen, Einkaufsliste teilen |
| **Rezeptvorschlaege** | "Selten gekocht"-Vorschlaege in der Rezeptliste anzeigen |
| **Bewertungssterne** | Im Rezeptdetail die durchschnittliche Bewertung aus History anzeigen |

### 20.3 Architektur-Verbesserungen

| Verbesserung | Beschreibung |
|-------------|-------------|
| **Hilt DI** | Saubere Dependency Injection statt manueller Instanziierung |
| **Type-Safe Navigation** | Compile-time sichere Routen statt String-basiert |
| **StateFlow** | Reactive UI-State statt Callback-basiert |
| **Room Caching** | Alle API-Daten lokal gecacht fuer Offline-Zugriff |
| **Error Handling** | Zentrales `NetworkResult<T>` sealed class |

---

## 21. Vollstaendige API-Referenz

### Auth (`/api/auth`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| POST | `/register` | `{username, password}` | `UserResponse` | Neuen User erstellen |
| POST | `/login` | `{username, password}` | `{access_token, token_type}` | JWT erhalten |
| GET | `/me` | — | `UserResponse` | Aktuellen User abfragen |
| PATCH | `/link-member` | `{member_id}` | `UserResponse` | User mit Familienmitglied verknuepfen |
| POST | `/family` | `{name}` | `FamilyResponse` | Familie erstellen (+Default-Kategorien) |
| POST | `/family/join` | `{invite_code}` | `FamilyResponse` | Familie beitreten |
| GET | `/family` | — | `FamilyResponse` | Aktuelle Familie abfragen |

### Events (`/api/events`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/` | — | `List<EventResponse>` | Events filtern (`date_from`, `date_to`, `member_id`, `category_id`) |
| GET | `/{id}` | — | `EventResponse` | Einzelnes Event |
| POST | `/` | `EventCreate` | `EventResponse` | Event erstellen |
| PUT | `/{id}` | `EventUpdate` | `EventResponse` | Event bearbeiten |
| DELETE | `/{id}` | — | 204 | Event loeschen |

### Todos (`/api/todos`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/` | — | `List<TodoResponse>` | Todos filtern (`completed`, `priority`, `member_id`, `category_id`). Nur Root-Todos (kein parent_id). |
| GET | `/{id}` | — | `TodoResponse` | Einzelnes Todo mit Subtodos |
| POST | `/` | `TodoCreate` | `TodoResponse` | Todo erstellen. `parent_id` fuer Sub-Todo. |
| PUT | `/{id}` | `TodoUpdate` | `TodoResponse` | Todo bearbeiten |
| PATCH | `/{id}/complete` | — | `TodoResponse` | Toggle completed (+ completed_at Timestamp) |
| PATCH | `/{id}/link-event` | `{event_id}` | `TodoResponse` | Todo mit Event verknuepfen (null zum Entknuepfen) |
| DELETE | `/{id}` | — | 204 | Todo loeschen (+ Subtodos kaskadierend) |

### Proposals (`/api/proposals` + `/api/todos`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| POST | `/api/todos/{id}/proposals` | `{proposed_date, message?}` | `ProposalDetail` | Terminvorschlag erstellen |
| GET | `/api/todos/{id}/proposals` | — | `List<ProposalDetail>` | Vorschlaege fuer ein Todo |
| POST | `/api/proposals/{id}/respond` | `{response, message?, counter_date?}` | `ProposalDetail` | Annehmen/Ablehnen/Gegenvorschlag |
| GET | `/api/proposals/pending` | — | `List<PendingProposalDetail>` | Offene Vorschlaege (nicht eigene) |

### Recipes (`/api/recipes`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/` | — | `List<RecipeResponse>` | Rezepte (`sort_by`: title/last_cooked_at, `order`: asc/desc) |
| POST | `/` | `RecipeCreate` | `RecipeResponse` | Rezept mit Zutaten erstellen |
| POST | `/parse-url` | `{url}` | `UrlImportPreview` | URL parsen fuer Import-Vorschau |
| GET | `/suggestions` | — | `List<RecipeSuggestion>` | Selten/nie gekochte Rezepte (`limit` 1-50) |
| GET | `/{id}` | — | `RecipeDetailResponse` | Rezeptdetails + History |
| PUT | `/{id}` | `RecipeUpdate` | `RecipeResponse` | Rezept bearbeiten (Zutaten werden ersetzt) |
| DELETE | `/{id}` | — | 204 | Rezept loeschen |
| GET | `/{id}/history` | — | `List<CookingHistoryResponse>` | Kochhistorie des Rezepts |

### Meals (`/api/meals`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/plan` | — | `WeekPlanResponse` | Wochenplan (`week` als ISO-Datum) |
| GET | `/history` | — | `List<CookingHistoryEntry>` | Letzte Gerichte (`limit`) |
| PUT | `/plan/{date}/{slot}` | `{recipe_id, servings_planned}` | `MealSlotResponse` | Slot belegen (upsert) |
| DELETE | `/plan/{date}/{slot}` | — | 204 | Slot leeren |
| PATCH | `/plan/{date}/{slot}/done` | `{servings_cooked?, rating?, notes?}` | `MarkCookedResponse` | Als gekocht markieren. Aktualisiert Recipe-Stats + Pantry-Abzug. Response enthaelt `pantry_deductions`. |

### Shopping (`/api/shopping`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/list` | — | `ShoppingListResponse?` | Aktive Einkaufsliste (null wenn keine) |
| POST | `/generate` | `{week_start}` | `ShoppingListResponse` | Aus Wochenplan generieren (mit Vorrats-Abgleich). Archiviert alte Listen. |
| POST | `/items` | `{name, amount?, unit?, category}` | `ShoppingItemResponse` | Manuellen Artikel hinzufuegen |
| POST | `/clear-all` | — | `{message}` | Alle aktiven Listen archivieren |
| PATCH | `/items/{id}/check` | — | `ShoppingItemResponse` | Toggle checked |
| DELETE | `/items/{id}` | — | 204 | Artikel loeschen |
| POST | `/sort` | — | `ShoppingListResponse` | KI-Sortierung nach Supermarkt-Gang |

### Pantry (`/api/pantry`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/` | — | `List<PantryItemResponse>` | Vorrat (`category`, `search` Filter) |
| POST | `/` | `PantryItemCreate` | `PantryItemResponse` | Artikel hinzufuegen (Merge bei Duplikaten) |
| POST | `/bulk` | `{items: [...]}` | `List<PantryItemResponse>` | Mehrere Artikel auf einmal |
| PATCH | `/{id}` | `PantryItemUpdate` | `PantryItemResponse` | Artikel bearbeiten |
| DELETE | `/{id}` | — | 204 | Artikel loeschen |
| GET | `/alerts` | — | `List<PantryAlertItem>` | Niedrigbestand + Ablauf-Warnungen |
| POST | `/alerts/{id}/add-to-shopping` | — | `{message}` | Alert-Artikel zur Einkaufsliste |
| POST | `/alerts/{id}/dismiss` | — | `{message}` | Alert verwerfen (Menge/Datum loeschen) |

### AI (`/api/ai`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/available-recipes` | — | `dict` | Verfuegbare Rezepte + Slot-Belegung (`week_start` required) |
| POST | `/generate-meal-plan` | `GenerateMealPlanRequest` | `PreviewMealPlanResponse` | KI-Vorschau (speichert NICHT) |
| POST | `/confirm-meal-plan` | `ConfirmMealPlanRequest` | `ConfirmMealPlanResponse` | Plan bestaetigen + speichern + Auto-Import + Auto-Einkaufsliste |
| POST | `/undo-meal-plan` | `{meal_ids: [...]}` | `{message, deleted}` | Plan rueckgaengig machen |
| POST | `/voice-command` | `{text}` | `VoiceCommandResponse` | Sprachbefehl interpretieren + ausfuehren |

### Cookidoo (`/api/cookidoo`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/status` | — | `{available, reason}` | Verfuegbarkeit pruefen |
| GET | `/collections` | — | `List<Collection>` | Sammlungen auflisten |
| GET | `/shopping-list` | — | `List<ShoppingItem>` | Cookidoo-Einkaufsliste |
| GET | `/recipes/{id}` | — | `RecipeDetail` | Rezeptdetails |
| POST | `/recipes/{id}/import` | — | `RecipeResponse` | Rezept importieren |
| GET | `/calendar` | — | `CalendarData` | Cookidoo-Wochenkalender (`week` required) |

### Knuspr (`/api/knuspr`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/products/search` | — | `List<Product>` | Produktsuche (`q` required, min 2 Zeichen) |
| POST | `/cart/add` | `{product_id, quantity}` | `{success}` | Produkt in Warenkorb |
| POST | `/cart/send-list/{id}` | — | `result` | Einkaufsliste an Knuspr senden |
| GET | `/delivery-slots` | — | `List<Slot>` | Lieferslots |
| DELETE | `/cart` | — | `{success}` | Warenkorb leeren |

### Categories (`/api/categories`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/` | — | `List<CategoryResponse>` | Alle Kategorien |
| POST | `/` | `{name, color?, icon?}` | `CategoryResponse` | Kategorie erstellen |
| PUT | `/{id}` | `{name?, color?, icon?}` | `CategoryResponse` | Kategorie bearbeiten |
| DELETE | `/{id}` | — | 204 | Kategorie loeschen |

### Family Members (`/api/family-members`)

| Method | Path | Body | Response | Beschreibung |
|--------|------|------|----------|-------------|
| GET | `/` | — | `List<FamilyMemberResponse>` | Alle Mitglieder |
| POST | `/` | `{name, color?, avatar_emoji?}` | `FamilyMemberResponse` | Mitglied erstellen |
| PUT | `/{id}` | `{name?, color?, avatar_emoji?}` | `FamilyMemberResponse` | Mitglied bearbeiten |
| DELETE | `/{id}` | — | 204 | Mitglied loeschen |

---

## 22. Enum-Definitionen

### Priority
```kotlin
enum class Priority(val value: String, val labelDe: String) {
    LOW("low", "Niedrig"),
    MEDIUM("medium", "Mittel"),
    HIGH("high", "Hoch"),
}
```

### MealSlot
```kotlin
enum class MealSlot(val value: String, val labelDe: String) {
    LUNCH("lunch", "Mittag"),
    DINNER("dinner", "Abend"),
}
```

### Difficulty
```kotlin
enum class Difficulty(val value: String, val labelDe: String) {
    EASY("easy", "Einfach"),
    MEDIUM("medium", "Mittel"),
    HARD("hard", "Schwer"),
}
```

### RecipeSource
```kotlin
enum class RecipeSource(val value: String) {
    MANUAL("manual"),
    COOKIDOO("cookidoo"),
    WEB("web"),
}
```

### IngredientCategory
```kotlin
enum class IngredientCategory(val value: String, val labelDe: String, val icon: String) {
    KUEHLREGAL("kuehlregal", "Kuehlregal", "🧊"),
    OBST_GEMUESE("obst_gemuese", "Obst & Gemuese", "🥬"),
    TROCKENWARE("trockenware", "Trockenware", "🌾"),
    DROGERIE("drogerie", "Drogerie", "🧴"),
    SONSTIGES("sonstiges", "Sonstiges", "📦"),
}
```

### ShoppingItemSource
```kotlin
enum class ShoppingItemSource(val value: String) {
    MANUAL("manual"),
    GENERATED("generated"),
}
```

---

## 23. Implementierungs-Reihenfolge

### Phase 1: Fundament (Woche 1-2)

1. **Projektsetup:** Gradle, Hilt, Room, Retrofit, Navigation, Theme
2. **TokenManager + AuthInterceptor:** Persistente JWT-Verwaltung
3. **Login + Registrierung:** LoginScreen + LoginViewModel
4. **Familien-Onboarding:** FamilyOnboardingScreen
5. **App-Shell:** BottomNavBar + Screen-Routing
6. **Shared Data laden:** Categories + Members beim App-Start

### Phase 2: Kern-Features (Woche 2-4)

6. **Kalender:** MonthGrid + DayDetailSheet + EventForm (CRUD)
7. **Todos:** TodoList + QuickAdd + TodoForm + SubTodos + Toggle
8. **Familienmitglieder:** MemberList + MemberForm (CRUD)
9. **Kategorien:** Verwaltungs-UI in Settings oder eigener Sektion

### Phase 3: Essen & Einkauf (Woche 4-6)

10. **Rezepte:** RecipeList + RecipeDetail + RecipeForm + Zutaten
11. **Wochenplan:** WeekGrid + AssignSlot + MarkCooked + History
12. **Einkaufsliste:** ShoppingList + QuickAdd + Toggle + Generate
13. **Vorratskammer:** PantryList + Alerts + QuickAdd + Edit

### Phase 4: KI & Integration (Woche 6-8)

14. **KI-Essensplanung:** AiMealPlanSheet (Config → Preview → Confirm → Undo)
15. **KI-Einkaufslisten-Sortierung:** AiSortBanner + Section-Rendering
16. **Cookidoo-Browser:** CookidooBrowser + Import + URL-Import
17. **Sprachassistent:** VoiceFab + Overlay + VoiceCommand-API

### Phase 5: Offline & Polish (Woche 8-10)

18. **Room Caching:** Alle Repositories mit Offline-Cache
19. **PendingChange-Queue:** Offline-Schreib-Operationen
20. **SyncWorker:** Periodischer Background-Sync
21. **Pull-to-Refresh:** Auf allen Listen
22. **Skeleton Loading:** Placeholder-Composables
23. **Error Handling:** Zentrales Error-UI
24. **Dark Mode:** Vollstaendige Dark-Theme-Implementierung

### Phase 6: Erweitert (Woche 10-12)

25. **Terminvorschlaege:** Proposal-Flow + Badge
26. **Knuspr-Integration:** Produktsuche + Warenkorb
27. **Share-Intent:** Einladungscode + Einkaufsliste teilen
28. **Rezeptvorschlaege:** "Selten gekocht" Sektion
29. **Benachrichtigungs-Badges:** Offene Vorschlaege, Pantry-Alerts

---

## Anhang A: DTO-Strukturen fuer komplexe Responses

### A.1 AvailableRecipesResponse (GET /api/ai/available-recipes)

```kotlin
data class AvailableRecipesResponse(
    @Json(name = "local_recipe_count") val localRecipeCount: Int,
    @Json(name = "local_recipes") val localRecipes: List<RecipeResponse>,
    @Json(name = "cookidoo_available") val cookidooAvailable: Boolean,
    @Json(name = "cookidoo_recipe_names") val cookidooRecipeNames: List<String>,
    @Json(name = "current_slots") val currentSlots: Map<String, Map<String, MealSlotInfo?>>,
    // currentSlots: { "2026-03-23": { "lunch": {...}, "dinner": null }, ... }
)

data class MealSlotInfo(
    @Json(name = "recipe_id") val recipeId: Int,
    @Json(name = "recipe_title") val recipeTitle: String,
)
```

### A.2 WeekPlanResponse (GET /api/meals/plan)

```kotlin
data class WeekPlanResponse(
    @Json(name = "week_start") val weekStart: String,
    val days: List<DayPlan>,
)

data class DayPlan(
    val date: String,
    val weekday: String,      // "Montag", "Dienstag", etc.
    val lunch: MealSlotResponse?,
    val dinner: MealSlotResponse?,
)

data class MealSlotResponse(
    val id: Int,
    @Json(name = "plan_date") val planDate: String,
    val slot: String,
    @Json(name = "recipe_id") val recipeId: Int,
    @Json(name = "servings_planned") val servingsPlanned: Int,
    val recipe: RecipeResponse,
    @Json(name = "created_at") val createdAt: String,
    @Json(name = "updated_at") val updatedAt: String,
)
```

### A.3 MarkCookedResponse (PATCH /api/meals/plan/{date}/{slot}/done)

```kotlin
data class MarkCookedResponse(
    val id: Int,
    @Json(name = "plan_date") val planDate: String,
    val slot: String,
    @Json(name = "recipe_id") val recipeId: Int,
    @Json(name = "servings_planned") val servingsPlanned: Int,
    val recipe: RecipeResponse,
    @Json(name = "pantry_deductions") val pantryDeductions: List<PantryDeductionItem>,
    @Json(name = "created_at") val createdAt: String,
    @Json(name = "updated_at") val updatedAt: String,
)

data class PantryDeductionItem(
    val name: String,
    @Json(name = "old_amount") val oldAmount: Double,
    @Json(name = "new_amount") val newAmount: Double,
    val depleted: Boolean,
)
```

### A.4 VoiceCommandResponse (POST /api/ai/voice-command)

```kotlin
data class VoiceCommandResponse(
    val summary: String,          // "2 Aktionen ausgefuehrt"
    val actions: List<VoiceCommandAction>,
)

data class VoiceCommandAction(
    val type: String,             // "create_event", "create_todo", etc.
    val ref: String?,             // Referenz-ID fuer verkettete Aktionen
    val params: Map<String, Any>, // Action-spezifische Parameter
    val result: Map<String, Any>?, // Ergebnis nach Ausfuehrung (id, success, error)
)
```

### A.5 EventResponse (vollstaendig)

```kotlin
data class EventResponse(
    val id: Int,
    val title: String,
    val description: String?,
    val start: String,
    val end: String,
    @Json(name = "all_day") val allDay: Boolean,
    val category: CategoryResponse?,
    val members: List<FamilyMemberResponse>,
    val todos: List<EventTodoResponse>,
    @Json(name = "created_at") val createdAt: String,
    @Json(name = "updated_at") val updatedAt: String,
)

data class EventTodoResponse(
    val id: Int,
    val title: String,
    val completed: Boolean,
    val priority: String,
)
```

### A.6 TodoResponse (vollstaendig)

```kotlin
data class TodoResponse(
    val id: Int,
    val title: String,
    val description: String?,
    val priority: String,
    @Json(name = "due_date") val dueDate: String?,
    val completed: Boolean,
    @Json(name = "completed_at") val completedAt: String?,
    val category: CategoryResponse?,
    @Json(name = "event_id") val eventId: Int?,
    @Json(name = "parent_id") val parentId: Int?,
    @Json(name = "requires_multiple") val requiresMultiple: Boolean,
    val members: List<FamilyMemberResponse>,
    val subtodos: List<SubtodoResponse>,
    @Json(name = "created_at") val createdAt: String,
    @Json(name = "updated_at") val updatedAt: String,
)

data class SubtodoResponse(
    val id: Int,
    val title: String,
    val completed: Boolean,
    @Json(name = "completed_at") val completedAt: String?,
    @Json(name = "created_at") val createdAt: String,
)
```

### A.7 RecipeResponse + RecipeDetailResponse

```kotlin
data class RecipeResponse(
    val id: Int,
    val title: String,
    val source: String,
    @Json(name = "cookidoo_id") val cookidooId: String?,
    val servings: Int,
    @Json(name = "prep_time_active_minutes") val prepTimeActiveMinutes: Int?,
    @Json(name = "prep_time_passive_minutes") val prepTimePassiveMinutes: Int?,
    val difficulty: String,
    @Json(name = "last_cooked_at") val lastCookedAt: String?,
    @Json(name = "cook_count") val cookCount: Int,
    val instructions: String?,
    val notes: String?,
    @Json(name = "image_url") val imageUrl: String?,
    @Json(name = "ai_accessible") val aiAccessible: Boolean,
    val ingredients: List<IngredientResponse>,
    @Json(name = "created_at") val createdAt: String,
    @Json(name = "updated_at") val updatedAt: String,
)

data class RecipeDetailResponse(
    // Alle Felder wie RecipeResponse, plus:
    val history: List<CookingHistoryResponse>,
) // Alternativ: RecipeResponse erben oder flach halten

data class IngredientResponse(
    val id: Int,
    val name: String,
    val amount: Double?,
    val unit: String?,
    val category: String,
)

data class CookingHistoryResponse(
    val id: Int,
    @Json(name = "recipe_id") val recipeId: Int,
    @Json(name = "cooked_at") val cookedAt: String,
    @Json(name = "servings_cooked") val servingsCooked: Int,
    val rating: Int?,
    val notes: String?,
    @Json(name = "created_at") val createdAt: String,
)

data class RecipeSuggestion(
    val id: Int,
    val title: String,
    val difficulty: String,
    @Json(name = "prep_time_active_minutes") val prepTimeActiveMinutes: Int?,
    @Json(name = "last_cooked_at") val lastCookedAt: String?,
    @Json(name = "cook_count") val cookCount: Int,
    @Json(name = "days_since_cooked") val daysSinceCooked: Int?,
)
```

### A.8 ShoppingListResponse

```kotlin
data class ShoppingListResponse(
    val id: Int,
    @Json(name = "week_start_date") val weekStartDate: String,
    val status: String,
    @Json(name = "sorted_by_store") val sortedByStore: String?,
    val items: List<ShoppingItemResponse>,
    @Json(name = "created_at") val createdAt: String,
)

data class ShoppingItemResponse(
    val id: Int,
    @Json(name = "shopping_list_id") val shoppingListId: Int,
    val name: String,
    val amount: String?,
    val unit: String?,
    val category: String,
    val checked: Boolean,
    val source: String,
    @Json(name = "recipe_id") val recipeId: Int?,
    @Json(name = "ai_accessible") val aiAccessible: Boolean,
    @Json(name = "sort_order") val sortOrder: Int?,
    @Json(name = "store_section") val storeSection: String?,
    @Json(name = "created_at") val createdAt: String,
    @Json(name = "updated_at") val updatedAt: String,
)
```

### A.9 ProposalDetail + PendingProposalDetail

```kotlin
data class ProposalDetail(
    val id: Int,
    @Json(name = "todo_id") val todoId: Int,
    val proposer: FamilyMemberResponse,
    @Json(name = "proposed_date") val proposedDate: String,
    val message: String?,
    val status: String,
    val responses: List<ProposalResponseDetail>,
    @Json(name = "created_at") val createdAt: String,
)

data class ProposalResponseDetail(
    val id: Int,
    val member: FamilyMemberResponse,
    val response: String,
    @Json(name = "counter_proposal_id") val counterProposalId: Int?,
    val message: String?,
    @Json(name = "created_at") val createdAt: String,
)

data class PendingProposalDetail(
    val id: Int,
    @Json(name = "todo_id") val todoId: Int,
    @Json(name = "todo_title") val todoTitle: String,
    val proposer: FamilyMemberResponse,
    @Json(name = "proposed_date") val proposedDate: String,
    val message: String?,
    val status: String,
    @Json(name = "created_at") val createdAt: String,
)
```

### A.10 Request-DTOs (Create/Update)

```kotlin
data class EventCreateRequest(
    val title: String,
    val description: String? = null,
    val start: String,
    val end: String,
    @Json(name = "all_day") val allDay: Boolean = false,
    @Json(name = "category_id") val categoryId: Int? = null,
    @Json(name = "member_ids") val memberIds: List<Int> = emptyList(),
)

data class EventUpdateRequest(
    val title: String? = null,
    val description: String? = null,
    val start: String? = null,
    val end: String? = null,
    @Json(name = "all_day") val allDay: Boolean? = null,
    @Json(name = "category_id") val categoryId: Int? = null,
    @Json(name = "member_ids") val memberIds: List<Int>? = null,
)

data class TodoCreateRequest(
    val title: String,
    val description: String? = null,
    val priority: String = "medium",
    @Json(name = "due_date") val dueDate: String? = null,
    @Json(name = "category_id") val categoryId: Int? = null,
    @Json(name = "event_id") val eventId: Int? = null,
    @Json(name = "parent_id") val parentId: Int? = null,
    @Json(name = "requires_multiple") val requiresMultiple: Boolean = false,
    @Json(name = "member_ids") val memberIds: List<Int> = emptyList(),
)

data class TodoUpdateRequest(
    val title: String? = null,
    val description: String? = null,
    val priority: String? = null,
    @Json(name = "due_date") val dueDate: String? = null,
    @Json(name = "category_id") val categoryId: Int? = null,
    @Json(name = "event_id") val eventId: Int? = null,
    @Json(name = "requires_multiple") val requiresMultiple: Boolean? = null,
    @Json(name = "member_ids") val memberIds: List<Int>? = null,
)

data class RecipeCreateRequest(
    val title: String,
    val source: String = "manual",
    @Json(name = "cookidoo_id") val cookidooId: String? = null,
    val servings: Int = 4,
    @Json(name = "prep_time_active_minutes") val prepTimeActiveMinutes: Int? = null,
    @Json(name = "prep_time_passive_minutes") val prepTimePassiveMinutes: Int? = null,
    val difficulty: String = "medium",
    val instructions: String? = null,
    val notes: String? = null,
    @Json(name = "image_url") val imageUrl: String? = null,
    @Json(name = "ai_accessible") val aiAccessible: Boolean = true,
    val ingredients: List<IngredientCreateRequest> = emptyList(),
)

data class IngredientCreateRequest(
    val name: String,
    val amount: Double? = null,
    val unit: String? = null,
    val category: String = "sonstiges",
)

data class MealSlotUpdateRequest(
    @Json(name = "recipe_id") val recipeId: Int,
    @Json(name = "servings_planned") val servingsPlanned: Int = 4,
)

data class MarkCookedRequest(
    @Json(name = "servings_cooked") val servingsCooked: Int? = null,
    val rating: Int? = null,
    val notes: String? = null,
)

data class ShoppingItemCreateRequest(
    val name: String,
    val amount: String? = null,
    val unit: String? = null,
    val category: String = "sonstiges",
)

data class PantryItemCreateRequest(
    val name: String,
    val amount: Double? = null,
    val unit: String? = null,
    val category: String = "sonstiges",
    @Json(name = "expiry_date") val expiryDate: String? = null,
    @Json(name = "min_stock") val minStock: Double? = null,
)

data class PantryItemUpdateRequest(
    val name: String? = null,
    val amount: Double? = null,
    val unit: String? = null,
    val category: String? = null,
    @Json(name = "expiry_date") val expiryDate: String? = null,
    @Json(name = "min_stock") val minStock: Double? = null,
)

data class PantryBulkAddRequest(
    val items: List<PantryItemCreateRequest>,
)

data class GenerateShoppingRequest(
    @Json(name = "week_start") val weekStart: String,
)

data class GenerateMealPlanRequest(
    @Json(name = "week_start") val weekStart: String,
    val servings: Int = 4,
    val preferences: String = "",
    @Json(name = "selected_slots") val selectedSlots: List<SlotSelection> = emptyList(),
    @Json(name = "include_cookidoo") val includeCookidoo: Boolean = false,
)

data class SlotSelection(
    val date: String,
    val slot: String,
)

data class ConfirmMealPlanRequest(
    @Json(name = "week_start") val weekStart: String,
    val items: List<MealSuggestion>,
)

data class UndoMealPlanRequest(
    @Json(name = "meal_ids") val mealIds: List<Int>,
)

data class VoiceCommandRequest(
    val text: String,
)

data class SetupRequest(
    val username: String,
    val password: String,
)

data class LoginRequest(
    val username: String,
    val password: String,
)

data class LinkMemberRequest(
    @Json(name = "member_id") val memberId: Int,
)

data class FamilyCreateRequest(
    val name: String,
)

data class FamilyJoinRequest(
    @Json(name = "invite_code") val inviteCode: String,
)

data class ProposalCreateRequest(
    @Json(name = "proposed_date") val proposedDate: String,
    val message: String? = null,
)

data class ProposalRespondRequest(
    val response: String,       // "accepted" | "rejected"
    val message: String? = null,
    @Json(name = "counter_date") val counterDate: String? = null,
)

data class LinkEventRequest(
    @Json(name = "event_id") val eventId: Int?,
)

data class UrlImportRequest(
    val url: String,
)

data class CategoryCreateRequest(
    val name: String,
    val color: String = "#0052CC",
    val icon: String = "📁",
)

data class CategoryUpdateRequest(
    val name: String? = null,
    val color: String? = null,
    val icon: String? = null,
)

data class FamilyMemberCreateRequest(
    val name: String,
    val color: String = "#0052CC",
    @Json(name = "avatar_emoji") val avatarEmoji: String = "👤",
)

data class FamilyMemberUpdateRequest(
    val name: String? = null,
    val color: String? = null,
    @Json(name = "avatar_emoji") val avatarEmoji: String? = null,
)
```

---

## Anhang B: Wichtige Business-Logik-Details

### B.1 Wochenplan-Berechnung

- Woche ist immer Montag bis Sonntag (ISO)
- `monday_of(date)` = `date - timedelta(days=date.weekday())`
- 7 Tage × 2 Slots (lunch, dinner) = 14 Slots pro Woche
- Slot-Eindeutigkeit: `(family_id, plan_date, slot)` ist unique

### B.2 Einkaufslistengenerierung

1. Alle MealPlan-Eintraege der Woche laden
2. Rezepte mit Zutaten laden
3. Zutaten konsolidieren (gleiche Zutat aus mehreren Rezepten → Mengen addieren)
4. Vorratskammer abgleichen (Fuzzy-Matching auf normalisierten Namen):
   - Zutat komplett im Vorrat → NICHT auf Liste
   - Teilweise vorhanden → Nur Differenz
5. Alte aktive Listen archivieren
6. Neue Liste mit konsolidierten Artikeln erstellen

### B.3 Fuzzy Ingredient Matching (Vorrat ↔ Rezept)

Backend-Algorithmus (`normalize_ingredient_name`):
1. Lowercase + Trim
2. Sonderzeichen durch Leerzeichen ersetzen (`,;.-/()`)
3. Whitespace normalisieren
4. Tokens alphabetisch sortieren
5. Deutsche Suffixe kuerzen (`te, ter, tes, ten, em` bei Token > Suffix+3)
6. Ergebnis: "Tomaten gehackt" und "gehackte Tomaten" werden beide zu "gehackt tomat"

### B.4 KI-Essensplan-Prompt-Aufbau

Das Backend baut den Claude-Prompt aus:
- Verfuegbare lokale Rezepte (Titel, Schwierigkeit, Zubereitung, letzte Kochdaten)
- Optionale Cookidoo-Rezeptnamen (aus Collections)
- Slot-Auswahl des Users
- Portionen-Wunsch
- User-Praeferenzen (Freitext)
- Constraint: Keine Wiederholung innerhalb der Woche, Abwechslung bei Schwierigkeit

### B.5 Sprachbefehl-Verarbeitung

1. Text → `POST /api/ai/voice-command`
2. Backend laedt Kontext: Familienmitglieder, (optional) bestehende Events/Todos
3. Claude interpretiert → Strukturiertes JSON mit `actions[]`
4. Jede Action wird sequentiell ausgefuehrt (DB-Operationen)
5. Response: Summary + Action-Liste mit Ergebnissen

### B.6 Multi-Tenancy-Regeln

- Jeder API-Call wird durch `require_family_id` Dependency geprueft
- User ohne `family_id` erhaelt HTTP 403 auf alle Endpunkte ausser Auth
- Alle Queries filtern implizit nach `family_id`
- Get/Update/Delete pruefen zusaetzlich, dass der Datensatz zur Familie gehoert
- Die App muss die `family_id` NICHT mitsenden — das Backend extrahiert sie aus dem JWT/User

---

### B.7 Wochentag-Namen (Deutsch)

Die API liefert deutsche Wochentag-Namen in `WeekPlanResponse.days[].weekday`:
```
"Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"
```

### B.8 Default-Kategorien

Beim Erstellen einer neuen Familie werden automatisch 5 Kategorien geseedet:

| Name | Farbe | Icon |
|------|-------|------|
| Arbeit | `#0052CC` | 💼 |
| Familie | `#00875A` | 👨‍👩‍👧‍👦 |
| Gesundheit | `#FF5630` | ❤️ |
| Einkauf | `#FFAB00` | 🛒 |
| Sonstiges | `#6554C0` | 📁 |

### B.9 Cookidoo-Rezeptimport bei KI-Bestätigung

Wenn der KI-Essensplan Cookidoo-Rezepte enthält (`source == "cookidoo"`):
1. `confirm-meal-plan` importiert sie automatisch in die lokale Rezept-DB
2. Der MealPlan-Eintrag verweist auf die neu importierte lokale `recipe_id`
3. Falls der Import fehlschlägt (Cookidoo offline), wird das Rezept als Schnellrezept angelegt (nur Titel)

### B.10 Einkaufslistengenerierung bei KI-Bestätigung

Wenn `confirm-meal-plan` erfolgreich ist:
1. Backend generiert automatisch eine Einkaufsliste fuer die Woche
2. Response enthält `shopping_list_generated: true/false`
3. Die App sollte bei `true` den User darauf hinweisen (Snackbar: "Einkaufsliste wurde erstellt")

### B.11 Undo-Zeitfenster

- Nach `confirm-meal-plan` erhält die App `meal_ids: [1, 2, 3, ...]`
- Die App zeigt 60 Sekunden lang eine Undo-Bar
- Undo: `POST /api/ai/undo-meal-plan` mit diesen `meal_ids`
- Nach 60s verschwindet die Bar, Undo ist theoretisch trotzdem moeglich (kein serverseitiges Zeitlimit)

### B.12 Token-Format

```json
{
  "sub": "benutzername",
  "exp": 1711500000
}
```
- Algorithmus: HS256
- Lifetime: 24h (1440 Minuten, konfigurierbar)
- Bearer-Schema: `Authorization: Bearer <token>`

---

## Anhang C: Checkliste fuer den implementierenden Agenten

- [ ] Server-URL konfigurierbar (DataStore, Login-Screen + Settings)
- [ ] JWT Token Handling (Speichern, bei jedem Request mitsenden, bei 401 ausloggen)
- [ ] Family-ID wird NICHT von der App gesendet (Backend regelt per JWT)
- [ ] Alle Datums-Strings in ISO 8601 Format
- [ ] Alle JSON-Felder in snake_case (Moshi-Konfiguration)
- [ ] Room Entities fuer alle Modelle (14 Tabellen + 2 CrossRef + 1 PendingChange)
- [ ] Offline-Queue fuer Schreib-Operationen
- [ ] WorkManager fuer Background-Sync (15 Min)
- [ ] Pull-to-Refresh auf allen Listenansichten
- [ ] Dark Mode (Material 3 dynamicDarkColorScheme)
- [ ] Deutsche UI-Texte durchgaengig
- [ ] Snackbar statt blockierender Dialoge fuer Erfolg/Fehler
- [ ] Skeleton Loading waehrend API-Calls
- [ ] 14 Retrofit API-Interfaces (Auth, Event, Todo, Proposal, Recipe, Meal, Shopping, Pantry, AI, Cookidoo, Knuspr, Category, FamilyMember)
- [ ] Voice FAB auf allen Screens sichtbar
- [ ] KI-Essensplanung: 3-Schritt-Flow (Config → Preview → Confirm)
- [ ] Einkaufsliste: KI-Sortierung + Kategorie-Sortierung
- [ ] Vorratskammer: Alerts + Quick-Add
- [ ] Cookidoo-Browser: Navigation-Stack (Home → Sammlung → Rezept → Import)

---

*Dokumentversion: 1.0 — Erstellt am 26.03.2026*
*Basierend auf: Familienkalender Webapp v2.0.0 (75 API-Endpunkte)*
