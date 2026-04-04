package de.familienkalender.app.data.local.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import de.familienkalender.app.data.local.db.dao.*
import de.familienkalender.app.data.local.db.entity.*

@Database(
    entities = [
        FamilyMemberEntity::class,
        CategoryEntity::class,
        EventEntity::class,
        EventMemberCrossRef::class,
        TodoEntity::class,
        TodoMemberCrossRef::class,
        SubtodoEntity::class,
        RecipeEntity::class,
        IngredientEntity::class,
        MealPlanEntity::class,
        CookingHistoryEntity::class,
        ShoppingListEntity::class,
        ShoppingItemEntity::class,
        PantryItemEntity::class,
        PendingChangeEntity::class
    ],
    version = 2,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun familyMemberDao(): FamilyMemberDao
    abstract fun categoryDao(): CategoryDao
    abstract fun eventDao(): EventDao
    abstract fun todoDao(): TodoDao
    abstract fun recipeDao(): RecipeDao
    abstract fun mealPlanDao(): MealPlanDao
    abstract fun shoppingDao(): ShoppingDao
    abstract fun pantryDao(): PantryDao
    abstract fun pendingChangeDao(): PendingChangeDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "familienkalender.db"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
