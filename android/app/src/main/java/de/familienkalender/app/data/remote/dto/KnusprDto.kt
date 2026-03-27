package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class KnusprProduct(
    val id: String,
    val name: String,
    val price: Double?,
    @SerializedName("image_url") val imageUrl: String?,
    val unit: String?
)

data class AddToCartRequest(
    @SerializedName("product_id") val productId: String,
    val quantity: Int = 1
)

data class KnusprDeliverySlot(
    val id: String,
    val date: String,
    @SerializedName("time_from") val timeFrom: String,
    @SerializedName("time_to") val timeTo: String,
    val available: Boolean
)
