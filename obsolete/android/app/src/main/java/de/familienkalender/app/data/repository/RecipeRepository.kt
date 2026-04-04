package de.familienkalender.app.data.repository

import android.util.Log
import com.google.gson.Gson
import de.familienkalender.app.data.local.db.dao.PendingChangeDao
import de.familienkalender.app.data.local.db.dao.RecipeDao
import de.familienkalender.app.data.local.db.dao.RecipeWithIngredients
import de.familienkalender.app.data.local.db.entity.IngredientEntity
import de.familienkalender.app.data.local.db.entity.PendingChangeEntity
import de.familienkalender.app.data.local.db.entity.RecipeEntity
import de.familienkalender.app.data.remote.api.RecipeApi
import de.familienkalender.app.data.remote.dto.*
import kotlinx.coroutines.flow.Flow

class RecipeRepository(
    private val api: RecipeApi,
    private val dao: RecipeDao,
    private val pendingChangeDao: PendingChangeDao,
    private val gson: Gson = Gson()
) {

    fun getAll(): Flow<List<RecipeWithIngredients>> = dao.getAll()

    suspend fun getById(id: Int): RecipeWithIngredients? = dao.getById(id)

    suspend fun refresh() {
        try {
            val remote = api.getRecipes()
            dao.deleteAll()
            dao.deleteAllIngredients()
            dao.upsertAll(remote.map { it.toEntity() })
            remote.forEach { recipe ->
                dao.upsertIngredients(recipe.ingredients.map { it.toEntity(recipe.id) })
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to refresh recipes", e)
        }
    }

    suspend fun getSuggestions(): Result<List<RecipeSuggestion>> {
        return try {
            Result.success(api.getSuggestions())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getDetail(id: Int): Result<RecipeDetailResponse> {
        return try {
            Result.success(api.getRecipe(id))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun create(request: RecipeCreate): Result<RecipeResponse> {
        return try {
            val response = api.createRecipe(request)
            dao.upsert(response.toEntity())
            dao.upsertIngredients(response.ingredients.map { it.toEntity(response.id) })
            Result.success(response)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "recipe",
                    entityId = null,
                    action = "CREATE",
                    endpoint = "api/recipes/",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun update(id: Int, request: RecipeUpdate): Result<RecipeResponse> {
        return try {
            val response = api.updateRecipe(id, request)
            dao.upsert(response.toEntity())
            dao.deleteIngredients(id)
            dao.upsertIngredients(response.ingredients.map { it.toEntity(response.id) })
            Result.success(response)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "recipe",
                    entityId = id,
                    action = "UPDATE",
                    endpoint = "api/recipes/$id",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun delete(id: Int): Result<Unit> {
        dao.deleteIngredients(id)
        dao.deleteById(id)
        return try {
            api.deleteRecipe(id)
            Result.success(Unit)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "recipe",
                    entityId = id,
                    action = "DELETE",
                    endpoint = "api/recipes/$id",
                    payload = null
                )
            )
            Result.failure(e)
        }
    }

    companion object {
        private const val TAG = "RecipeRepository"
    }
}

fun RecipeResponse.toEntity() = RecipeEntity(
    id = id,
    title = title,
    source = source,
    cookidooId = cookidooId,
    servings = servings,
    prepTimeActiveMinutes = prepTimeActiveMinutes,
    prepTimePassiveMinutes = prepTimePassiveMinutes,
    difficulty = difficulty,
    lastCookedAt = lastCookedAt,
    cookCount = cookCount,
    notes = notes,
    imageUrl = imageUrl,
    aiAccessible = aiAccessible,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun IngredientResponse.toEntity(recipeId: Int) = IngredientEntity(
    id = id,
    recipeId = recipeId,
    name = name,
    amount = amount,
    unit = unit,
    category = category
)
