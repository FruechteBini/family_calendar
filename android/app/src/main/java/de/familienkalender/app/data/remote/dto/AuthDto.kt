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
    @SerializedName("member_id") val memberId: Int?,
    val member: FamilyMemberResponse?
)
