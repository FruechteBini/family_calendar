package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class EventResponse(
    val id: Int,
    val title: String,
    val description: String?,
    val start: String,
    val end: String,
    @SerializedName("all_day") val allDay: Boolean,
    val category: CategoryResponse?,
    val members: List<FamilyMemberResponse>,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class EventCreate(
    val title: String,
    val description: String? = null,
    val start: String,
    val end: String,
    @SerializedName("all_day") val allDay: Boolean = false,
    @SerializedName("category_id") val categoryId: Int? = null,
    @SerializedName("member_ids") val memberIds: List<Int> = emptyList()
)

data class EventUpdate(
    val title: String? = null,
    val description: String? = null,
    val start: String? = null,
    val end: String? = null,
    @SerializedName("all_day") val allDay: Boolean? = null,
    @SerializedName("category_id") val categoryId: Int? = null,
    @SerializedName("member_ids") val memberIds: List<Int>? = null
)

fun EventCreate.toUpdate() = EventUpdate(
    title = title,
    description = description,
    start = start,
    end = end,
    allDay = allDay,
    categoryId = categoryId,
    memberIds = memberIds
)
