package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface FamilyMemberApi {

    @GET("api/family-members/")
    suspend fun getMembers(): List<FamilyMemberResponse>

    @POST("api/family-members/")
    suspend fun createMember(@Body member: FamilyMemberCreate): FamilyMemberResponse

    @PUT("api/family-members/{id}")
    suspend fun updateMember(@Path("id") id: Int, @Body member: FamilyMemberUpdate): FamilyMemberResponse

    @DELETE("api/family-members/{id}")
    suspend fun deleteMember(@Path("id") id: Int)
}
