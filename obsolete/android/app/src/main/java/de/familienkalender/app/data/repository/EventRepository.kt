package de.familienkalender.app.data.repository

import android.util.Log
import com.google.gson.Gson
import de.familienkalender.app.data.local.db.dao.EventDao
import de.familienkalender.app.data.local.db.dao.EventWithMembers
import de.familienkalender.app.data.local.db.dao.PendingChangeDao
import de.familienkalender.app.data.local.db.entity.EventEntity
import de.familienkalender.app.data.local.db.entity.EventMemberCrossRef
import de.familienkalender.app.data.local.db.entity.PendingChangeEntity
import de.familienkalender.app.data.remote.api.EventApi
import de.familienkalender.app.data.remote.dto.EventCreate
import de.familienkalender.app.data.remote.dto.EventResponse
import de.familienkalender.app.data.remote.dto.EventUpdate
import kotlinx.coroutines.flow.Flow

class EventRepository(
    private val api: EventApi,
    private val dao: EventDao,
    private val pendingChangeDao: PendingChangeDao,
    private val gson: Gson = Gson()
) {

    fun getEventsBetween(from: String, to: String): Flow<List<EventWithMembers>> =
        dao.getEventsBetween(from, to)

    fun getAll(): Flow<List<EventWithMembers>> = dao.getAll()

    suspend fun refresh(dateFrom: String? = null, dateTo: String? = null) {
        try {
            val remote = api.getEvents(dateFrom = dateFrom, dateTo = dateTo)
            if (dateFrom == null && dateTo == null) {
                dao.deleteAll()
                dao.deleteAllMemberRefs()
            }
            dao.upsertAll(remote.map { it.toEntity() })
            remote.forEach { event ->
                dao.deleteMemberRefs(event.id)
                dao.insertMemberRefs(event.members.map {
                    EventMemberCrossRef(event.id, it.id)
                })
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to refresh events", e)
        }
    }

    suspend fun create(request: EventCreate): Result<EventResponse> {
        return try {
            val response = api.createEvent(request)
            dao.upsert(response.toEntity())
            dao.insertMemberRefs(response.members.map {
                EventMemberCrossRef(response.id, it.id)
            })
            Result.success(response)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "event",
                    entityId = null,
                    action = "CREATE",
                    endpoint = "api/events/",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun update(id: Int, request: EventUpdate): Result<EventResponse> {
        return try {
            val response = api.updateEvent(id, request)
            dao.upsert(response.toEntity())
            dao.deleteMemberRefs(id)
            dao.insertMemberRefs(response.members.map {
                EventMemberCrossRef(response.id, it.id)
            })
            Result.success(response)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "event",
                    entityId = id,
                    action = "UPDATE",
                    endpoint = "api/events/$id",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun delete(id: Int): Result<Unit> {
        dao.deleteMemberRefs(id)
        dao.deleteById(id)
        return try {
            api.deleteEvent(id)
            Result.success(Unit)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "event",
                    entityId = id,
                    action = "DELETE",
                    endpoint = "api/events/$id",
                    payload = null
                )
            )
            Result.failure(e)
        }
    }

    companion object {
        private const val TAG = "EventRepository"
    }
}

fun EventResponse.toEntity() = EventEntity(
    id = id,
    title = title,
    description = description,
    start = start,
    end = end,
    allDay = allDay,
    categoryId = category?.id,
    categoryName = category?.name,
    categoryColor = category?.color,
    categoryIcon = category?.icon,
    createdAt = createdAt,
    updatedAt = updatedAt
)
