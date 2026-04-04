package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.CookingHistoryEntity
import de.familienkalender.app.data.local.db.entity.MealPlanEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface MealPlanDao {

    @Query("SELECT * FROM meal_plan WHERE planDate >= :from AND planDate <= :to ORDER BY planDate, slot")
    fun getForWeek(from: String, to: String): Flow<List<MealPlanEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(mealPlan: MealPlanEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(plans: List<MealPlanEntity>)

    @Query("DELETE FROM meal_plan WHERE planDate = :date AND slot = :slot")
    suspend fun deleteSlot(date: String, slot: String)

    @Query("DELETE FROM meal_plan WHERE planDate >= :from AND planDate <= :to")
    suspend fun deleteForWeek(from: String, to: String)

    @Query("DELETE FROM meal_plan")
    suspend fun deleteAll()

    // Cooking History
    @Query("SELECT * FROM cooking_history WHERE recipeId = :recipeId ORDER BY cookedAt DESC")
    fun getHistoryForRecipe(recipeId: Int): Flow<List<CookingHistoryEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertHistory(history: List<CookingHistoryEntity>)

    @Query("DELETE FROM cooking_history")
    suspend fun deleteAllHistory()
}
