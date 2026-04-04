package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface EventApi {

    @GET("api/events/")
    suspend fun getEvents(
        @Query("date_from") dateFrom: String? = null,
        @Query("date_to") dateTo: String? = null,
        @Query("member_id") memberId: Int? = null,
        @Query("category_id") categoryId: Int? = null
    ): List<EventResponse>

    @GET("api/events/{id}")
    suspend fun getEvent(@Path("id") id: Int): EventResponse

    @POST("api/events/")
    suspend fun createEvent(@Body event: EventCreate): EventResponse

    @PUT("api/events/{id}")
    suspend fun updateEvent(@Path("id") id: Int, @Body event: EventUpdate): EventResponse

    @DELETE("api/events/{id}")
    suspend fun deleteEvent(@Path("id") id: Int)
}
