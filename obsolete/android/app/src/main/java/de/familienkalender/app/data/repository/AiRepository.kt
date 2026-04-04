package de.familienkalender.app.data.repository

import de.familienkalender.app.data.remote.api.AiApi
import de.familienkalender.app.data.remote.dto.*

class AiRepository(
    private val api: AiApi
) {

    suspend fun getAvailableRecipes(weekStart: String): Result<AvailableRecipesResponse> {
        return try {
            Result.success(api.getAvailableRecipes(weekStart))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun generateMealPlan(request: GenerateMealPlanRequest): Result<PreviewMealPlanResponse> {
        return try {
            Result.success(api.generateMealPlan(request))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun confirmMealPlan(request: ConfirmMealPlanRequest): Result<ConfirmMealPlanResponse> {
        return try {
            Result.success(api.confirmMealPlan(request))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun undoMealPlan(mealIds: List<Int>): Result<Map<String, Any>> {
        return try {
            Result.success(api.undoMealPlan(UndoMealPlanRequest(mealIds)))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun voiceCommand(text: String): Result<VoiceCommandResponse> {
        return try {
            Result.success(api.voiceCommand(VoiceCommandRequest(text)))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
