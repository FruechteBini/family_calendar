package de.familienkalender.app.data.remote.dto

import com.google.gson.annotations.SerializedName

data class TodoResponse(
    val id: Int,
    val title: String,
    val description: String?,
    val priority: String,
    @SerializedName("due_date") val dueDate: String?,
    val completed: Boolean,
    @SerializedName("completed_at") val completedAt: String?,
    val category: CategoryResponse?,
    @SerializedName("event_id") val eventId: Int?,
    @SerializedName("parent_id") val parentId: Int?,
    @SerializedName("requires_multiple") val requiresMultiple: Boolean,
    val members: List<FamilyMemberResponse>,
    val subtodos: List<SubtodoResponse>,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String
)

data class SubtodoResponse(
    val id: Int,
    val title: String,
    val completed: Boolean,
    @SerializedName("completed_at") val completedAt: String?,
    @SerializedName("created_at") val createdAt: String
)

data class TodoCreate(
    val title: String,
    val description: String? = null,
    val priority: String = "medium",
    @SerializedName("due_date") val dueDate: String? = null,
    @SerializedName("category_id") val categoryId: Int? = null,
    @SerializedName("event_id") val eventId: Int? = null,
    @SerializedName("parent_id") val parentId: Int? = null,
    @SerializedName("requires_multiple") val requiresMultiple: Boolean = false,
    @SerializedName("member_ids") val memberIds: List<Int> = emptyList()
)

data class TodoUpdate(
    val title: String? = null,
    val description: String? = null,
    val priority: String? = null,
    @SerializedName("due_date") val dueDate: String? = null,
    @SerializedName("category_id") val categoryId: Int? = null,
    @SerializedName("event_id") val eventId: Int? = null,
    @SerializedName("requires_multiple") val requiresMultiple: Boolean? = null,
    @SerializedName("member_ids") val memberIds: List<Int>? = null
)

data class LinkEventRequest(
    @SerializedName("event_id") val eventId: Int?
)
