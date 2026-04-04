package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "shopping_lists")
data class ShoppingListEntity(
    @PrimaryKey val id: Int,
    val weekStartDate: String,
    val status: String,
    val sortedByStore: String?,
    val createdAt: String
)

@Entity(tableName = "shopping_items")
data class ShoppingItemEntity(
    @PrimaryKey val id: Int,
    val shoppingListId: Int,
    val name: String,
    val amount: String?,
    val unit: String?,
    val category: String,
    val checked: Boolean,
    val source: String,
    val recipeId: Int?,
    val aiAccessible: Boolean,
    val sortOrder: Int?,
    val storeSection: String?,
    val createdAt: String,
    val updatedAt: String
)
