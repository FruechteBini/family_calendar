package de.familienkalender.app.data.repository

import de.familienkalender.app.data.local.db.dao.MealPlanDao
import de.familienkalender.app.data.local.db.dao.RecipeDao
import de.familienkalender.app.data.local.db.entity.MealPlanEntity
import de.familienkalender.app.data.remote.api.MealApi
import de.familienkalender.app.data.remote.dto.*
import kotlinx.coroutines.flow.Flow

class MealPlanRepository(
    private val api: MealApi,
    private val dao: MealPlanDao,
    private val recipeDao: RecipeDao
) {

    fun getForWeek(from: String, to: String): Flow<List<MealPlanEntity>> =
        dao.getForWeek(from, to)

    // Returns the full WeekPlanResponse from API (used by UI for recipe details)
    suspend fun refreshWeek(week: String? = null): Result<WeekPlanResponse> {
        return try {
            val response = api.getWeekPlan(week)
            val from = response.weekStart
            val to = response.days.lastOrNull()?.date ?: from
            dao.deleteForWeek(from, to)

            response.days.forEach { day ->
                day.lunch?.let { slot ->
                    dao.upsert(slot.toEntity())
                    recipeDao.upsert(slot.recipe.toEntity())
                    recipeDao.deleteIngredients(slot.recipe.id)
                    recipeDao.upsertIngredients(slot.recipe.ingredients.map { it.toEntity(slot.recipe.id) })
                }
                day.dinner?.let { slot ->
                    dao.upsert(slot.toEntity())
                    recipeDao.upsert(slot.recipe.toEntity())
                    recipeDao.deleteIngredients(slot.recipe.id)
                    recipeDao.upsertIngredients(slot.recipe.ingredients.map { it.toEntity(slot.recipe.id) })
                }
            }
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun setSlot(date: String, slot: String, update: MealSlotUpdate): Result<MealSlotResponse> {
        return try {
            val response = api.setMealSlot(date, slot, update)
            dao.upsert(response.toEntity())
            recipeDao.upsert(response.recipe.toEntity())
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun clearSlot(date: String, slot: String): Result<Unit> {
        return try {
            api.clearMealSlot(date, slot)
            dao.deleteSlot(date, slot)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun markAsCooked(date: String, slot: String, request: MarkCookedRequest): Result<MealSlotResponse> {
        return try {
            val response = api.markAsCooked(date, slot, request)
            dao.upsert(response.toEntity())
            recipeDao.upsert(response.recipe.toEntity())
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

fun MealSlotResponse.toEntity() = MealPlanEntity(
    id = id,
    planDate = planDate,
    slot = slot,
    recipeId = recipeId,
    servingsPlanned = servingsPlanned,
    createdAt = createdAt,
    updatedAt = updatedAt
)
