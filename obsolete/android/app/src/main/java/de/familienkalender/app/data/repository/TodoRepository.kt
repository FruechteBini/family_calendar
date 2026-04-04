package de.familienkalender.app.data.repository

import android.util.Log
import com.google.gson.Gson
import de.familienkalender.app.data.local.db.dao.PendingChangeDao
import de.familienkalender.app.data.local.db.dao.TodoDao
import de.familienkalender.app.data.local.db.dao.TodoWithDetails
import de.familienkalender.app.data.local.db.entity.*
import de.familienkalender.app.data.remote.api.TodoApi
import de.familienkalender.app.data.remote.dto.*
import kotlinx.coroutines.flow.Flow

class TodoRepository(
    private val api: TodoApi,
    private val dao: TodoDao,
    private val pendingChangeDao: PendingChangeDao,
    private val gson: Gson = Gson()
) {

    fun getAll(): Flow<List<TodoWithDetails>> = dao.getAll()

    fun getSubtodos(parentId: Int): Flow<List<SubtodoEntity>> = dao.getSubtodos(parentId)

    suspend fun refresh() {
        try {
            val remote = api.getTodos()
            dao.deleteAll()
            dao.deleteAllMemberRefs()
            dao.deleteAllSubtodos()
            dao.upsertAll(remote.map { it.toEntity() })
            remote.forEach { todo ->
                dao.insertMemberRefs(todo.members.map {
                    TodoMemberCrossRef(todo.id, it.id)
                })
                dao.upsertSubtodos(todo.subtodos.map { it.toEntity(todo.id) })
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to refresh todos", e)
        }
    }

    suspend fun create(request: TodoCreate): Result<TodoResponse> {
        val now = java.time.LocalDateTime.now().toString()
        val tempId = -(System.currentTimeMillis() / 1000).toInt().coerceAtMost(-1)
        dao.upsert(
            TodoEntity(
                id = tempId,
                title = request.title,
                description = request.description,
                priority = request.priority,
                dueDate = request.dueDate,
                completed = false,
                completedAt = null,
                categoryId = request.categoryId,
                categoryName = null,
                categoryColor = null,
                categoryIcon = null,
                eventId = request.eventId,
                parentId = request.parentId,
                requiresMultiple = request.requiresMultiple,
                createdAt = now,
                updatedAt = now
            )
        )
        if (request.memberIds.isNotEmpty()) {
            dao.insertMemberRefs(request.memberIds.map { TodoMemberCrossRef(tempId, it) })
        }
        return try {
            val response = api.createTodo(request)
            dao.deleteMemberRefs(tempId)
            dao.deleteById(tempId)
            saveToLocal(response)
            Result.success(response)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "todo",
                    entityId = null,
                    action = "CREATE",
                    endpoint = "api/todos/",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun update(id: Int, request: TodoUpdate): Result<TodoResponse> {
        return try {
            val response = api.updateTodo(id, request)
            saveToLocal(response)
            Result.success(response)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "todo",
                    entityId = id,
                    action = "UPDATE",
                    endpoint = "api/todos/$id",
                    payload = gson.toJson(request)
                )
            )
            Result.failure(e)
        }
    }

    suspend fun toggleComplete(id: Int): Result<TodoResponse> {
        return try {
            val response = api.completeTodo(id)
            saveToLocal(response)
            Result.success(response)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "todo",
                    entityId = id,
                    action = "PATCH",
                    endpoint = "api/todos/$id/complete",
                    payload = null
                )
            )
            Result.failure(e)
        }
    }

    suspend fun delete(id: Int): Result<Unit> {
        dao.deleteMemberRefs(id)
        dao.deleteSubtodos(id)
        dao.deleteById(id)
        return try {
            api.deleteTodo(id)
            Result.success(Unit)
        } catch (e: Exception) {
            pendingChangeDao.insert(
                PendingChangeEntity(
                    entityType = "todo",
                    entityId = id,
                    action = "DELETE",
                    endpoint = "api/todos/$id",
                    payload = null
                )
            )
            Result.failure(e)
        }
    }

    suspend fun getProposals(todoId: Int): List<ProposalResponse> {
        return try {
            api.getProposals(todoId)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to load proposals for todo $todoId", e)
            emptyList()
        }
    }

    suspend fun proposeDate(todoId: Int, request: ProposalCreate): Result<ProposalResponse> {
        return try {
            Result.success(api.createProposal(todoId, request))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getPendingProposals(): List<PendingProposalDetail> {
        return try {
            api.getPendingProposals()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to load pending proposals", e)
            emptyList()
        }
    }

    suspend fun respondToProposal(proposalId: Int, request: ProposalRespondRequest): Result<ProposalResponse> {
        return try {
            Result.success(api.respondToProposal(proposalId, request))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun saveToLocal(response: TodoResponse) {
        dao.upsert(response.toEntity())
        dao.deleteMemberRefs(response.id)
        dao.insertMemberRefs(response.members.map {
            TodoMemberCrossRef(response.id, it.id)
        })
        dao.deleteSubtodos(response.id)
        dao.upsertSubtodos(response.subtodos.map { it.toEntity(response.id) })
    }

    companion object {
        private const val TAG = "TodoRepository"
    }
}

fun TodoResponse.toEntity() = TodoEntity(
    id = id,
    title = title,
    description = description,
    priority = priority,
    dueDate = dueDate,
    completed = completed,
    completedAt = completedAt,
    categoryId = category?.id,
    categoryName = category?.name,
    categoryColor = category?.color,
    categoryIcon = category?.icon,
    eventId = eventId,
    parentId = parentId,
    requiresMultiple = requiresMultiple,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun SubtodoResponse.toEntity(parentId: Int) = SubtodoEntity(
    id = id,
    parentId = parentId,
    title = title,
    completed = completed,
    completedAt = completedAt,
    createdAt = createdAt
)
