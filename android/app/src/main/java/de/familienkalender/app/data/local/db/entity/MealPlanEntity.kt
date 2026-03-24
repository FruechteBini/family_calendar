package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "meal_plan")
data class MealPlanEntity(
    @PrimaryKey val id: Int,
    val planDate: String,
    val slot: String,
    val recipeId: Int,
    val servingsPlanned: Int,
    val createdAt: String,
    val updatedAt: String
)

@Entity(tableName = "cooking_history")
data class CookingHistoryEntity(
    @PrimaryKey val id: Int,
    val recipeId: Int,
    val cookedAt: String,
    val servingsCooked: Int,
    val rating: Int?,
    val notes: String?,
    val createdAt: String
)
