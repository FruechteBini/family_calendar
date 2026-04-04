package de.familienkalender.app.data.remote.dto

data class CategoryResponse(
    val id: Int,
    val name: String,
    val color: String,
    val icon: String
)

data class CategoryCreate(
    val name: String,
    val color: String = "#0052CC",
    val icon: String = "\uD83D\uDCC1"
)

data class CategoryUpdate(
    val name: String? = null,
    val color: String? = null,
    val icon: String? = null
)
