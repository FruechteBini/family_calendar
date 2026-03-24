package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface FamilyMemberDao {

    @Query("SELECT * FROM family_members ORDER BY name")
    fun getAll(): Flow<List<FamilyMemberEntity>>

    @Query("SELECT * FROM family_members WHERE id = :id")
    suspend fun getById(id: Int): FamilyMemberEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(members: List<FamilyMemberEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(member: FamilyMemberEntity)

    @Query("DELETE FROM family_members WHERE id = :id")
    suspend fun deleteById(id: Int)

    @Query("DELETE FROM family_members")
    suspend fun deleteAll()
}
