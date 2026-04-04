package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey val id: Int,
    val title: String,
    val description: String?,
    val priority: String,
    val dueDate: String?,
    val completed: Boolean,
    val completedAt: String?,
    val categoryId: Int?,
    val categoryName: String?,
    val categoryColor: String?,
    val categoryIcon: String?,
    val eventId: Int?,
    val parentId: Int?,
    val requiresMultiple: Boolean,
    val createdAt: String,
    val updatedAt: String
)

@Entity(tableName = "todo_members", primaryKeys = ["todoId", "memberId"])
data class TodoMemberCrossRef(
    val todoId: Int,
    val memberId: Int
)

@Entity(tableName = "subtodos")
data class SubtodoEntity(
    @PrimaryKey val id: Int,
    val parentId: Int,
    val title: String,
    val completed: Boolean,
    val completedAt: String?,
    val createdAt: String
)
