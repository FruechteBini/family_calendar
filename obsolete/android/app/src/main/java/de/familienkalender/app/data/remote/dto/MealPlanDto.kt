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

data class MarkCookedResponseDto(
    val id: Int,
    @SerializedName("plan_date") val planDate: String,
    val slot: String,
    @SerializedName("recipe_id") val recipeId: Int,
    @SerializedName("servings_planned") val servingsPlanned: Int,
    val recipe: RecipeResponse,
    @SerializedName("pantry_deductions") val pantryDeductions: List<PantryDeductionItem>,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class CookingHistoryEntry(
    val id: Int,
    @SerializedName("recipe_id") val recipeId: Int,
    @SerializedName("recipe_title") val recipeTitle: String,
    @SerializedName("recipe_difficulty") val recipeDifficulty: String?,
    @SerializedName("recipe_image_url") val recipeImageUrl: String?,
    @SerializedName("cooked_at") val cookedAt: String,
    @SerializedName("servings_cooked") val servingsCooked: Int,
    val rating: Int?
)
