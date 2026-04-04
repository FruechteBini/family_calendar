package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "pantry_items")
data class PantryItemEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val amount: Double?,
    val unit: String?,
    val category: String,
    val expiryDate: String?,
    val minStock: Double?,
    val isLowStock: Boolean,
    val isExpiringSoon: Boolean,
    val createdAt: String,
    val updatedAt: String
)
