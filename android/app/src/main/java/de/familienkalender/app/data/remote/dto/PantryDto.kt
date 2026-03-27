package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class PantryItemResponse(
    val id: Int,
    val name: String,
    val amount: Double?,
    val unit: String?,
    val category: String,
    @SerializedName("expiry_date") val expiryDate: String?,
    @SerializedName("min_stock") val minStock: Double?,
    @SerializedName("is_low_stock") val isLowStock: Boolean,
    @SerializedName("is_expiring_soon") val isExpiringSoon: Boolean,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class PantryItemCreate(
    val name: String,
    val amount: Double? = null,
    val unit: String? = null,
    val category: String = "sonstiges",
    @SerializedName("expiry_date") val expiryDate: String? = null,
    @SerializedName("min_stock") val minStock: Double? = null
)

data class PantryItemUpdate(
    val name: String? = null,
    val amount: Double? = null,
    val unit: String? = null,
    val category: String? = null,
    @SerializedName("expiry_date") val expiryDate: String? = null,
    @SerializedName("min_stock") val minStock: Double? = null
)

data class PantryBulkAddRequest(
    val items: List<PantryItemCreate>
)

data class PantryAlertItem(
    val id: Int,
    val name: String,
    val amount: Double?,
    val unit: String?,
    val reason: String,
    @SerializedName("expiry_date") val expiryDate: String?
)

data class PantryDeductionItem(
    val name: String,
    @SerializedName("old_amount") val oldAmount: Double,
    @SerializedName("new_amount") val newAmount: Double,
    val depleted: Boolean
)
