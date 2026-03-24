package de.familienkalender.app.data.repository

import android.util.Log
import com.google.gson.Gson
import de.familienkalender.app.data.local.db.dao.FamilyMemberDao
import de.familienkalender.app.data.local.db.dao.PendingChangeDao
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import de.familienkalender.app.data.local.db.entity.PendingChangeEntity
import de.familienkalender.app.data.remote.api.FamilyMemberApi
import de.familienkalender.app.data.remote.dto.FamilyMemberCreate
import de.familienkalender.app.data.remote.dto.FamilyMemberResponse
import de.familienkalender.app.data.remote.dto.FamilyMemberUpdate
import kotlinx.coroutines.flow.Flow

class FamilyMemberRepository(
    private val api: FamilyMemberApi,
    private val dao: FamilyMemberDao,
    private val pendingChangeDao: PendingChangeDao,
    private val gson: Gson = Gson()
) {

    fun getAll(): Flow<List<FamilyMemberEntity>> = dao.getAll()

    suspend fun refresh() {
        try {
            val remote = api.getMembers()
            dao.deleteAll()
            dao.upsertAll(remote.map { it.toEntity() })
        } catch (e: Exception) {
            Log.w(TAG, "Failed to refresh family members", e)
        }
    }

    suspend fun create(request: FamilyMemberCreate): Result<FamilyMemberEntity> {
        return try {
            val response = api.createMember(request)
            val entity = response.toEntity()
            dao.upsert(entity)
            Result.success(entity)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "family_member",
                    entityId = null,
                    action = "CREATE",
                    endpoint = "api/family-members/",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun update(id: Int, request: FamilyMemberUpdate): Result<FamilyMemberEntity> {
        return try {
            val response = api.updateMember(id, request)
            val entity = response.toEntity()
            dao.upsert(entity)
            Result.success(entity)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "family_member",
                    entityId = id,
                    action = "UPDATE",
                    endpoint = "api/family-members/$id",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun delete(id: Int): Result<Unit> {
        dao.deleteById(id)
        return try {
            api.deleteMember(id)
            Result.success(Unit)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "family_member",
                    entityId = id,
                    action = "DELETE",
                    endpoint = "api/family-members/$id",
                    payload = null
                )
            )
            Result.failure(e)
        }
    }

    companion object {
        private const val TAG = "FamilyMemberRepository"
    }
}

fun FamilyMemberResponse.toEntity() = FamilyMemberEntity(
    id = id,
    name = name,
    color = color,
    avatarEmoji = avatarEmoji,
    createdAt = createdAt
)
