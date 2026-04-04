package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class SlotSelection(
    val date: String,
    val slot: String
)

data class GenerateMealPlanRequest(
    @SerializedName("week_start") val weekStart: String,
    val servings: Int = 4,
    val preferences: String = "",
    @SerializedName("selected_slots") val selectedSlots: List<SlotSelection> = emptyList(),
    @SerializedName("include_cookidoo") val includeCookidoo: Boolean = false
)

data class MealSuggestion(
    val date: String,
    val slot: String,
    @SerializedName("recipe_id") val recipeId: Int?,
    @SerializedName("cookidoo_id") val cookidooId: String?,
    @SerializedName("recipe_title") val recipeTitle: String,
    @SerializedName("servings_planned") val servingsPlanned: Int,
    val source: String,
    val difficulty: String?,
    @SerializedName("prep_time") val prepTime: Int?
)

data class PreviewMealPlanResponse(
    val suggestions: List<MealSuggestion>,
    val reasoning: String?
)

data class ConfirmMealPlanRequest(
    @SerializedName("week_start") val weekStart: String,
    val items: List<MealSuggestion>
)

data class ConfirmMealPlanResponse(
    val message: String,
    @SerializedName("meals_created") val mealsCreated: Int,
    @SerializedName("meal_ids") val mealIds: List<Int>,
    @SerializedName("shopping_list_generated") val shoppingListGenerated: Boolean
)

data class UndoMealPlanRequest(
    @SerializedName("meal_ids") val mealIds: List<Int>
)

data class AvailableRecipesResponse(
    @SerializedName("local_recipe_count") val localRecipeCount: Int,
    @SerializedName("local_recipes") val localRecipes: List<RecipeResponse>,
    @SerializedName("cookidoo_available") val cookidooAvailable: Boolean,
    @SerializedName("cookidoo_recipe_names") val cookidooRecipeNames: List<String>,
    @SerializedName("current_slots") val currentSlots: Map<String, Map<String, SlotInfo?>>
)

data class SlotInfo(
    @SerializedName("recipe_id") val recipeId: Int,
    @SerializedName("recipe_title") val recipeTitle: String
)

data class VoiceCommandRequest(val text: String)

data class VoiceCommandAction(
    val type: String,
    val ref: String?,
    val params: Map<String, Any>,
    val result: Map<String, Any>?
)

data class VoiceCommandResponse(
    val summary: String,
    val actions: List<VoiceCommandAction>
)
