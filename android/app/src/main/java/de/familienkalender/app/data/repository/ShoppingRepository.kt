package de.familienkalender.app.data.repository

import android.util.Log
import de.familienkalender.app.data.local.db.dao.ShoppingDao
import de.familienkalender.app.data.local.db.dao.ShoppingListWithItems
import de.familienkalender.app.data.local.db.entity.ShoppingItemEntity
import de.familienkalender.app.data.local.db.entity.ShoppingListEntity
import de.familienkalender.app.data.remote.api.ShoppingApi
import de.familienkalender.app.data.remote.dto.*
import kotlinx.coroutines.flow.Flow

class ShoppingRepository(
    private val api: ShoppingApi,
    private val dao: ShoppingDao
) {

    fun getActiveList(): Flow<ShoppingListWithItems?> = dao.getActiveList()

    suspend fun refresh() {
        try {
            val response = api.getShoppingList()
            dao.deleteAllItems()
            dao.deleteAllLists()
            if (response != null) {
                dao.upsertList(response.toEntity())
                dao.upsertItems(response.items.map { it.toEntity() })
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to refresh shopping list", e)
        }
    }

    suspend fun generate(weekStart: String): Result<ShoppingListResponse> {
        return try {
            val response = api.generateList(GenerateRequest(weekStart))
            dao.deleteAllItems()
            dao.deleteAllLists()
            dao.upsertList(response.toEntity())
            dao.upsertItems(response.items.map { it.toEntity() })
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun addItem(request: ShoppingItemCreate): Result<ShoppingItemResponse> {
        return try {
            val response = api.addItem(request)
            dao.upsertItem(response.toEntity())
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun checkItem(id: Int): Result<ShoppingItemResponse> {
        return try {
            val response = api.checkItem(id)
            dao.upsertItem(response.toEntity())
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteItem(id: Int): Result<Unit> {
        dao.deleteItem(id)
        return try {
            api.deleteItem(id)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    companion object {
        private const val TAG = "ShoppingRepository"
    }
}

fun ShoppingListResponse.toEntity() = ShoppingListEntity(
    id = id,
    weekStartDate = weekStartDate,
    status = status,
    createdAt = createdAt
)

fun ShoppingItemResponse.toEntity() = ShoppingItemEntity(
    id = id,
    shoppingListId = shoppingListId,
    name = name,
    amount = amount,
    unit = unit,
    category = category,
    checked = checked,
    source = source,
    recipeId = recipeId,
    aiAccessible = aiAccessible,
    createdAt = createdAt,
    updatedAt = updatedAt
)
