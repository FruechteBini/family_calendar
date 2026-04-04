package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.*
import kotlinx.coroutines.flow.Flow

data class TodoWithDetails(
    @Embedded val todo: TodoEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "id",
        associateBy = Junction(
            TodoMemberCrossRef::class,
            parentColumn = "todoId",
            entityColumn = "memberId"
        )
    )
    val members: List<FamilyMemberEntity>
)

@Dao
interface TodoDao {

    @Transaction
    @Query("SELECT * FROM todos WHERE parentId IS NULL ORDER BY dueDate, createdAt")
    fun getAll(): Flow<List<TodoWithDetails>>

    @Transaction
    @Query("SELECT * FROM todos WHERE id = :id")
    suspend fun getById(id: Int): TodoWithDetails?

    @Query("SELECT * FROM subtodos WHERE parentId = :parentId ORDER BY createdAt")
    fun getSubtodos(parentId: Int): Flow<List<SubtodoEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(todo: TodoEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(todos: List<TodoEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSubtodos(subtodos: List<SubtodoEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMemberRefs(refs: List<TodoMemberCrossRef>)

    @Query("DELETE FROM todo_members WHERE todoId = :todoId")
    suspend fun deleteMemberRefs(todoId: Int)

    @Query("DELETE FROM subtodos WHERE parentId = :parentId")
    suspend fun deleteSubtodos(parentId: Int)

    @Query("DELETE FROM todos WHERE id = :id")
    suspend fun deleteById(id: Int)

    @Query("DELETE FROM todos")
    suspend fun deleteAll()

    @Query("DELETE FROM todo_members")
    suspend fun deleteAllMemberRefs()

    @Query("DELETE FROM subtodos")
    suspend fun deleteAllSubtodos()
}
