package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.PantryItemEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PantryDao {

    @Query("SELECT * FROM pantry_items ORDER BY category, name")
    fun getAll(): Flow<List<PantryItemEntity>>

    @Query("SELECT * FROM pantry_items WHERE category = :category ORDER BY name")
    fun getByCategory(category: String): Flow<List<PantryItemEntity>>

    @Query("SELECT * FROM pantry_items WHERE isLowStock = 1 OR isExpiringSoon = 1")
    fun getAlerts(): Flow<List<PantryItemEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(item: PantryItemEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(items: List<PantryItemEntity>)

    @Query("DELETE FROM pantry_items WHERE id = :id")
    suspend fun deleteById(id: Int)

    @Query("DELETE FROM pantry_items")
    suspend fun deleteAll()
}
