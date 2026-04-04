package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class RecipeResponse(
    val id: Int,
    val title: String,
    val source: String,
    @SerializedName("cookidoo_id") val cookidooId: String?,
    val servings: Int,
    @SerializedName("prep_time_active_minutes") val prepTimeActiveMinutes: Int?,
    @SerializedName("prep_time_passive_minutes") val prepTimePassiveMinutes: Int?,
    val difficulty: String,
    @SerializedName("last_cooked_at") val lastCookedAt: String?,
    @SerializedName("cook_count") val cookCount: Int,
    val notes: String?,
    @SerializedName("image_url") val imageUrl: String?,
    @SerializedName("ai_accessible") val aiAccessible: Boolean,
    val ingredients: List<IngredientResponse>,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class IngredientResponse(
    val id: Int,
    val name: String,
    val amount: Float?,
    val unit: String?,
    val category: String
)

data class RecipeCreate(
    val title: String,
    val source: String = "manual",
    @SerializedName("cookidoo_id") val cookidooId: String? = null,
    val servings: Int = 4,
    @SerializedName("prep_time_active_minutes") val prepTimeActiveMinutes: Int? = null,
    @SerializedName("prep_time_passive_minutes") val prepTimePassiveMinutes: Int? = null,
    val difficulty: String = "medium",
    val notes: String? = null,
    @SerializedName("image_url") val imageUrl: String? = null,
    @SerializedName("ai_accessible") val aiAccessible: Boolean = true,
    val ingredients: List<IngredientCreate> = emptyList()
)

data class IngredientCreate(
    val name: String,
    val amount: Float? = null,
    val unit: String? = null,
    val category: String = "sonstiges"
)

data class RecipeUpdate(
    val title: String? = null,
    val servings: Int? = null,
    @SerializedName("prep_time_active_minutes") val prepTimeActiveMinutes: Int? = null,
    @SerializedName("prep_time_passive_minutes") val prepTimePassiveMinutes: Int? = null,
    val difficulty: String? = null,
    val notes: String? = null,
    @SerializedName("image_url") val imageUrl: String? = null,
    @SerializedName("ai_accessible") val aiAccessible: Boolean? = null,
    val ingredients: List<IngredientCreate>? = null
)

data class CookingHistoryResponse(
    val id: Int,
    @SerializedName("recipe_id") val recipeId: Int,
    @SerializedName("cooked_at") val cookedAt: String,
    @SerializedName("servings_cooked") val servingsCooked: Int,
    val rating: Int?,
    val notes: String?,
    @SerializedName("created_at") val createdAt: String
)

data class RecipeDetailResponse(
    val id: Int,
    val title: String,
    val source: String,
    @SerializedName("cookidoo_id") val cookidooId: String?,
    val servings: Int,
    @SerializedName("prep_time_active_minutes") val prepTimeActiveMinutes: Int?,
    @SerializedName("prep_time_passive_minutes") val prepTimePassiveMinutes: Int?,
    val difficulty: String,
    @SerializedName("last_cooked_at") val lastCookedAt: String?,
    @SerializedName("cook_count") val cookCount: Int,
    val notes: String?,
    @SerializedName("image_url") val imageUrl: String?,
    @SerializedName("ai_accessible") val aiAccessible: Boolean,
    val ingredients: List<IngredientResponse>,
    val history: List<CookingHistoryResponse>,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class RecipeSuggestion(
    val id: Int,
    val title: String,
    val difficulty: String,
    @SerializedName("prep_time_active_minutes") val prepTimeActiveMinutes: Int?,
    @SerializedName("last_cooked_at") val lastCookedAt: String?,
    @SerializedName("cook_count") val cookCount: Int,
    @SerializedName("days_since_cooked") val daysSinceCooked: Int?
)

data class ParseUrlRequest(val url: String)
