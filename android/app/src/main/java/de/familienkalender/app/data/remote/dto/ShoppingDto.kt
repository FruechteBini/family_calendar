package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class ShoppingListResponse(
    val id: Int,
    @SerializedName("week_start_date") val weekStartDate: String,
    val status: String,
    val items: List<ShoppingItemResponse>,
    @SerializedName("created_at") val createdAt: String
)

data class ShoppingItemResponse(
    val id: Int,
    @SerializedName("shopping_list_id") val shoppingListId: Int,
    val name: String,
    val amount: String?,
    val unit: String?,
    val category: String,
    val checked: Boolean,
    val source: String,
    @SerializedName("recipe_id") val recipeId: Int?,
    @SerializedName("ai_accessible") val aiAccessible: Boolean,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class ShoppingItemCreate(
    val name: String,
    val amount: String? = null,
    val unit: String? = null,
    val category: String = "sonstiges"
)

data class GenerateRequest(
    @SerializedName("week_start") val weekStart: String
)
