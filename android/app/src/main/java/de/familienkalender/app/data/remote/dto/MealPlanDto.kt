package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class WeekPlanResponse(
    @SerializedName("week_start") val weekStart: String,
    val days: List<DayPlan>
)

data class DayPlan(
    val date: String,
    val weekday: String,
    val lunch: MealSlotResponse?,
    val dinner: MealSlotResponse?
)

data class MealSlotResponse(
    val id: Int,
    @SerializedName("plan_date") val planDate: String,
    val slot: String,
    @SerializedName("recipe_id") val recipeId: Int,
    @SerializedName("servings_planned") val servingsPlanned: Int,
    val recipe: RecipeResponse,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class MealSlotUpdate(
    @SerializedName("recipe_id") val recipeId: Int,
    @SerializedName("servings_planned") val servingsPlanned: Int = 4
)

data class MarkCookedRequest(
    @SerializedName("servings_cooked") val servingsCooked: Int? = null,
    val rating: Int? = null,
    val notes: String? = null
)
