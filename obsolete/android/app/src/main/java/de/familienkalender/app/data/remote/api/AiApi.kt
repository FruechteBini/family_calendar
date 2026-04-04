package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface AiApi {

    @GET("api/ai/available-recipes")
    suspend fun getAvailableRecipes(@Query("week_start") weekStart: String): AvailableRecipesResponse

    @POST("api/ai/generate-meal-plan")
    suspend fun generateMealPlan(@Body request: GenerateMealPlanRequest): PreviewMealPlanResponse

    @POST("api/ai/confirm-meal-plan")
    suspend fun confirmMealPlan(@Body request: ConfirmMealPlanRequest): ConfirmMealPlanResponse

    @POST("api/ai/undo-meal-plan")
    suspend fun undoMealPlan(@Body request: UndoMealPlanRequest): Map<String, Any>

    @POST("api/ai/voice-command")
    suspend fun voiceCommand(@Body request: VoiceCommandRequest): VoiceCommandResponse
}
