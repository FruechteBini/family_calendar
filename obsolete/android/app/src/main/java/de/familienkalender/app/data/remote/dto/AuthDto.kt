package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class LoginRequest(
    val username: String,
    val password: String
)

data class SetupRequest(
    val username: String,
    val password: String
)

data class TokenResponse(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("token_type") val tokenType: String
)

data class LinkMemberRequest(
    @SerializedName("member_id") val memberId: Int
)

data class UserResponse(
    val id: Int,
    val username: String,
    @SerializedName("family_id") val familyId: Int?,
    val family: FamilyResponse?,
    @SerializedName("member_id") val memberId: Int?,
    val member: FamilyMemberResponse?
)

data class FamilyCreateRequest(val name: String)

data class FamilyJoinRequest(
    @SerializedName("invite_code") val inviteCode: String
)

data class FamilyResponse(
    val id: Int,
    val name: String,
    @SerializedName("invite_code") val inviteCode: String,
    @SerializedName("created_at") val createdAt: String
)
