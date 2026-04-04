package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface TodoApi {

    @GET("api/todos/")
    suspend fun getTodos(
        @Query("completed") completed: Boolean? = null,
        @Query("priority") priority: String? = null,
        @Query("member_id") memberId: Int? = null,
        @Query("category_id") categoryId: Int? = null
    ): List<TodoResponse>

    @GET("api/todos/{id}")
    suspend fun getTodo(@Path("id") id: Int): TodoResponse

    @POST("api/todos/")
    suspend fun createTodo(@Body todo: TodoCreate): TodoResponse

    @PUT("api/todos/{id}")
    suspend fun updateTodo(@Path("id") id: Int, @Body todo: TodoUpdate): TodoResponse

    @PATCH("api/todos/{id}/complete")
    suspend fun completeTodo(@Path("id") id: Int): TodoResponse

    @PATCH("api/todos/{id}/link-event")
    suspend fun linkEvent(@Path("id") id: Int, @Body request: LinkEventRequest): TodoResponse

    @DELETE("api/todos/{id}")
    suspend fun deleteTodo(@Path("id") id: Int)

    @GET("api/todos/{id}/proposals")
    suspend fun getProposals(@Path("id") id: Int): List<ProposalResponse>

    @POST("api/todos/{id}/proposals")
    suspend fun createProposal(@Path("id") id: Int, @Body request: ProposalCreate): ProposalResponse

    @GET("api/proposals/pending")
    suspend fun getPendingProposals(): List<PendingProposalDetail>

    @POST("api/proposals/{id}/respond")
    suspend fun respondToProposal(@Path("id") id: Int, @Body request: ProposalRespondRequest): ProposalResponse
}
