package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "events")
data class EventEntity(
    @PrimaryKey val id: Int,
    val title: String,
    val description: String?,
    val start: String,
    val end: String,
    val allDay: Boolean,
    val categoryId: Int?,
    val categoryName: String?,
    val categoryColor: String?,
    val categoryIcon: String?,
    val createdAt: String,
    val updatedAt: String
)

@Entity(tableName = "event_members", primaryKeys = ["eventId", "memberId"])
data class EventMemberCrossRef(
    val eventId: Int,
    val memberId: Int
)
