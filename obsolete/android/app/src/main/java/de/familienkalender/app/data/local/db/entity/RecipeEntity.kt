package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "recipes")
data class RecipeEntity(
    @PrimaryKey val id: Int,
    val title: String,
    val source: String,
    val cookidooId: String?,
    val servings: Int,
    val prepTimeActiveMinutes: Int?,
    val prepTimePassiveMinutes: Int?,
    val difficulty: String,
    val lastCookedAt: String?,
    val cookCount: Int,
    val notes: String?,
    val imageUrl: String?,
    val aiAccessible: Boolean,
    val createdAt: String,
    val updatedAt: String
)

@Entity(tableName = "ingredients")
data class IngredientEntity(
    @PrimaryKey val id: Int,
    val recipeId: Int,
    val name: String,
    val amount: Float?,
    val unit: String?,
    val category: String
)
