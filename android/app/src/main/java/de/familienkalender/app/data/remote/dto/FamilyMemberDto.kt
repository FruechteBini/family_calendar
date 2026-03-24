package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class FamilyMemberResponse(
    val id: Int,
    val name: String,
    val color: String,
    @SerializedName("avatar_emoji") val avatarEmoji: String,
    @SerializedName("created_at") val createdAt: String
)

data class FamilyMemberCreate(
    val name: String,
    val color: String = "#0052CC",
    @SerializedName("avatar_emoji") val avatarEmoji: String = "\uD83D\uDC64"
)

data class FamilyMemberUpdate(
    val name: String? = null,
    val color: String? = null,
    @SerializedName("avatar_emoji") val avatarEmoji: String? = null
)
