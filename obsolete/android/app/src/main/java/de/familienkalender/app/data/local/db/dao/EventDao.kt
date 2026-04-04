package de.familienkalender.app.data.local.db.dao

import androidx.room.*
import de.familienkalender.app.data.local.db.entity.EventEntity
import de.familienkalender.app.data.local.db.entity.EventMemberCrossRef
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import kotlinx.coroutines.flow.Flow

data class EventWithMembers(
    @Embedded val event: EventEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "id",
        associateBy = Junction(
            EventMemberCrossRef::class,
            parentColumn = "eventId",
            entityColumn = "memberId"
        )
    )
    val members: List<FamilyMemberEntity>
)

@Dao
interface EventDao {

    @Transaction
    @Query("SELECT * FROM events WHERE start >= :from AND start <= :to ORDER BY start")
    fun getEventsBetween(from: String, to: String): Flow<List<EventWithMembers>>

    @Transaction
    @Query("SELECT * FROM events ORDER BY start")
    fun getAll(): Flow<List<EventWithMembers>>

    @Transaction
    @Query("SELECT * FROM events WHERE id = :id")
    suspend fun getById(id: Int): EventWithMembers?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(event: EventEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(events: List<EventEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMemberRefs(refs: List<EventMemberCrossRef>)

    @Query("DELETE FROM event_members WHERE eventId = :eventId")
    suspend fun deleteMemberRefs(eventId: Int)

    @Query("DELETE FROM events WHERE id = :id")
    suspend fun deleteById(id: Int)

    @Query("DELETE FROM events")
    suspend fun deleteAll()

    @Query("DELETE FROM event_members")
    suspend fun deleteAllMemberRefs()
}
