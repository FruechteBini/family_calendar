package de.familienkalender.app.data.local.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "family_members")
data class FamilyMemberEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val color: String,
    val avatarEmoji: String,
    val createdAt: String
)
