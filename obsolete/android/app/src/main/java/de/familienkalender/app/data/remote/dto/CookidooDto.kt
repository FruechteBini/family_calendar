package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class CookidooStatus(val available: Boolean, val reason: String? = null)

data class CookidooRecipeBrief(
    @SerializedName("cookidoo_id") val cookidooId: String,
    val name: String,
    @SerializedName("total_time") val totalTime: Int?,
    val thumbnail: String?,
    val url: String?,
    val ingredients: List<CookidooIngredient> = emptyList()
)

data class CookidooIngredient(
    val id: String,
    val name: String,
    val description: String?
)

data class CookidooChapter(
    val name: String,
    val recipes: List<CookidooRecipeBrief>
)

data class CookidooCollection(
    val id: String,
    val name: String,
    val description: String?,
    val chapters: List<CookidooChapter>
)

data class CookidooRecipeDetail(
    @SerializedName("cookidoo_id") val cookidooId: String,
    val name: String,
    @SerializedName("serving_size") val servingSize: Int?,
    @SerializedName("total_time") val totalTime: Int?,
    @SerializedName("active_time") val activeTime: Int?,
    val difficulty: String?,
    val image: String?,
    val url: String?,
    val ingredients: List<CookidooIngredient>,
    val categories: List<String>
)
