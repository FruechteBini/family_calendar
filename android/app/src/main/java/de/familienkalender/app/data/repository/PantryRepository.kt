package de.familienkalender.app.data.repository

import android.util.Log
import de.familienkalender.app.data.local.db.dao.PantryDao
import de.familienkalender.app.data.local.db.entity.PantryItemEntity
import de.familienkalender.app.data.remote.api.PantryApi
import de.familienkalender.app.data.remote.dto.*
import kotlinx.coroutines.flow.Flow

class PantryRepository(
    private val api: PantryApi,
    private val dao: PantryDao
) {

    fun getAll(): Flow<List<PantryItemEntity>> = dao.getAll()

    fun getAlerts(): Flow<List<PantryItemEntity>> = dao.getAlerts()

    suspend fun refresh() {
        try {
            val items = api.getItems()
            dao.deleteAll()
            dao.upsertAll(items.map { it.toEntity() })
        } catch (e: Exception) {
            Log.w(TAG, "Failed to refresh pantry", e)
        }
    }

    suspend fun addItem(request: PantryItemCreate): Result<PantryItemResponse> {
        return try {
            val response = api.addItem(request)
            dao.upsert(response.toEntity())
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun addBulk(items: List<PantryItemCreate>): Result<List<PantryItemResponse>> {
        return try {
            val response = api.addBulk(PantryBulkAddRequest(items))
            dao.upsertAll(response.map { it.toEntity() })
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateItem(id: Int, update: PantryItemUpdate): Result<PantryItemResponse> {
        return try {
            val response = api.updateItem(id, update)
            dao.upsert(response.toEntity())
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteItem(id: Int): Result<Unit> {
        dao.deleteById(id)
        return try {
            api.deleteItem(id)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getRemoteAlerts(): Result<List<PantryAlertItem>> {
        return try {
            Result.success(api.getAlerts())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun alertToShopping(itemId: Int): Result<String> {
        return try {
            val response = api.alertToShopping(itemId)
            refresh()
            Result.success(response["message"] ?: "OK")
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun dismissAlert(itemId: Int): Result<String> {
        return try {
            val response = api.dismissAlert(itemId)
            refresh()
            Result.success(response["message"] ?: "OK")
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    companion object {
        private const val TAG = "PantryRepository"
    }
}

fun PantryItemResponse.toEntity() = PantryItemEntity(
    id = id,
    name = name,
    amount = amount,
    unit = unit,
    category = category,
    expiryDate = expiryDate,
    minStock = minStock,
    isLowStock = isLowStock,
    isExpiringSoon = isExpiringSoon,
    createdAt = createdAt,
    updatedAt = updatedAt
)
