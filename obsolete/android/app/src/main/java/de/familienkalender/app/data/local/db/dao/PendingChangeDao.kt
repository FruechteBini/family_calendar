package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.PendingChangeEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PendingChangeDao {

    @Query("SELECT * FROM pending_changes ORDER BY createdAt ASC")
    suspend fun getAll(): List<PendingChangeEntity>

    @Query("SELECT COUNT(*) FROM pending_changes")
    fun getCount(): Flow<Int>

    @Insert
    suspend fun insert(change: PendingChangeEntity): Long

    @Query("DELETE FROM pending_changes WHERE id = :id")
    suspend fun deleteById(id: Long)

    @Query("DELETE FROM pending_changes")
    suspend fun deleteAll()
}
