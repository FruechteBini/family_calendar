package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface AuthApi {

    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): TokenResponse

    @POST("api/auth/register")
    suspend fun register(@Body request: SetupRequest): UserResponse

    @GET("api/auth/me")
    suspend fun getMe(): UserResponse

    @PATCH("api/auth/link-member")
    suspend fun linkMember(@Body request: LinkMemberRequest): UserResponse

    @POST("api/auth/family")
    suspend fun createFamily(@Body request: FamilyCreateRequest): FamilyResponse

    @POST("api/auth/family/join")
    suspend fun joinFamily(@Body request: FamilyJoinRequest): FamilyResponse

    @GET("api/auth/family")
    suspend fun getFamily(): FamilyResponse
}
