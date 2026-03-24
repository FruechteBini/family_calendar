package de.familienkalender.app

import android.app.Application
import de.familienkalender.app.data.local.db.AppDatabase
import de.familienkalender.app.data.local.prefs.TokenManager
import de.familienkalender.app.data.remote.RetrofitClient
import de.familienkalender.app.data.repository.*
import de.familienkalender.app.sync.SyncWorker

class FamilienkalenderApp : Application() {

    lateinit var tokenManager: TokenManager
    lateinit var retrofitClient: RetrofitClient
    lateinit var database: AppDatabase

    // Repositories
    lateinit var authRepository: AuthRepository
    lateinit var memberRepository: FamilyMemberRepository
    lateinit var categoryRepository: CategoryRepository
    lateinit var eventRepository: EventRepository
    lateinit var todoRepository: TodoRepository
    lateinit var recipeRepository: RecipeRepository
    lateinit var mealPlanRepository: MealPlanRepository
    lateinit var shoppingRepository: ShoppingRepository

    override fun onCreate() {
        super.onCreate()

        tokenManager = TokenManager(this)
        retrofitClient = RetrofitClient(tokenManager)
        database = AppDatabase.getInstance(this)

        val pendingChangeDao = database.pendingChangeDao()

        authRepository = AuthRepository(retrofitClient.authApi, tokenManager)
        memberRepository = FamilyMemberRepository(
            retrofitClient.familyMemberApi, database.familyMemberDao(), pendingChangeDao
        )
        categoryRepository = CategoryRepository(
            retrofitClient.categoryApi, database.categoryDao(), pendingChangeDao
        )
        eventRepository = EventRepository(
            retrofitClient.eventApi, database.eventDao(), pendingChangeDao
        )
        todoRepository = TodoRepository(
            retrofitClient.todoApi, database.todoDao(), pendingChangeDao
        )
        recipeRepository = RecipeRepository(
            retrofitClient.recipeApi, database.recipeDao(), pendingChangeDao
        )
        mealPlanRepository = MealPlanRepository(
            retrofitClient.mealApi, database.mealPlanDao(), database.recipeDao()
        )
        shoppingRepository = ShoppingRepository(
            retrofitClient.shoppingApi, database.shoppingDao()
        )

        // Start periodic background sync
        SyncWorker.enqueuePeriodicSync(this)
    }
}
