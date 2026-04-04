package de.familienkalender.app.data.repository

import android.util.Log
import com.google.gson.Gson
import de.familienkalender.app.data.local.db.dao.CategoryDao
import de.familienkalender.app.data.local.db.dao.PendingChangeDao
import de.familienkalender.app.data.local.db.entity.CategoryEntity
import de.familienkalender.app.data.local.db.entity.PendingChangeEntity
import de.familienkalender.app.data.remote.api.CategoryApi
import de.familienkalender.app.data.remote.dto.CategoryCreate
import de.familienkalender.app.data.remote.dto.CategoryResponse
import de.familienkalender.app.data.remote.dto.CategoryUpdate
import kotlinx.coroutines.flow.Flow

class CategoryRepository(
    private val api: CategoryApi,
    private val dao: CategoryDao,
    private val pendingChangeDao: PendingChangeDao,
    private val gson: Gson = Gson()
) {

    fun getAll(): Flow<List<CategoryEntity>> = dao.getAll()

    suspend fun refresh() {
        try {
            val remote = api.getCategories()
            dao.deleteAll()
            dao.upsertAll(remote.map { it.toEntity() })
        } catch (e: Exception) {
            Log.w(TAG, "Failed to refresh categories", e)
        }
    }

    suspend fun create(request: CategoryCreate): Result<CategoryEntity> {
        return try {
            val response = api.createCategory(request)
            val entity = response.toEntity()
            dao.upsert(entity)
            Result.success(entity)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "category",
                    entityId = null,
                    action = "CREATE",
                    endpoint = "api/categories/",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun update(id: Int, request: CategoryUpdate): Result<CategoryEntity> {
        return try {
            val response = api.updateCategory(id, request)
            val entity = response.toEntity()
            dao.upsert(entity)
            Result.success(entity)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "category",
                    entityId = id,
                    action = "UPDATE",
                    endpoint = "api/categories/$id",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun delete(id: Int): Result<Unit> {
        dao.deleteById(id)
        return try {
            api.deleteCategory(id)
            Result.success(Unit)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "category",
                    entityId = id,
                    action = "DELETE",
                    endpoint = "api/categories/$id",
                    payload = null
                )
            )
            Result.failure(e)
        }
    }

    companion object {
        private const val TAG = "CategoryRepository"
    }
}

fun CategoryResponse.toEntity() = CategoryEntity(
    id = id,
    name = name,
    color = color,
    icon = icon
)
