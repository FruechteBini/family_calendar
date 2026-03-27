package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface MealApi {

    @GET("api/meals/plan")
    suspend fun getWeekPlan(@Query("week") week: String? = null): WeekPlanResponse

    @GET("api/meals/history")
    suspend fun getHistory(@Query("limit") limit: Int = 10): List<CookingHistoryEntry>

    @PUT("api/meals/plan/{date}/{slot}")
    suspend fun setMealSlot(
        @Path("date") date: String,
        @Path("slot") slot: String,
        @Body update: MealSlotUpdate
    ): MealSlotResponse

    @DELETE("api/meals/plan/{date}/{slot}")
    suspend fun clearMealSlot(
        @Path("date") date: String,
        @Path("slot") slot: String
    )

    @PATCH("api/meals/plan/{date}/{slot}/done")
    suspend fun markAsCooked(
        @Path("date") date: String,
        @Path("slot") slot: String,
        @Body request: MarkCookedRequest
    ): MarkCookedResponseDto
}
