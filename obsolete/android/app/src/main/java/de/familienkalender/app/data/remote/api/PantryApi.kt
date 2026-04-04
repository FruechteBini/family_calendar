package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface PantryApi {

    @GET("api/pantry/")
    suspend fun getItems(
        @Query("category") category: String? = null,
        @Query("search") search: String? = null
    ): List<PantryItemResponse>

    @POST("api/pantry/")
    suspend fun addItem(@Body item: PantryItemCreate): PantryItemResponse

    @POST("api/pantry/bulk")
    suspend fun addBulk(@Body request: PantryBulkAddRequest): List<PantryItemResponse>

    @PATCH("api/pantry/{id}")
    suspend fun updateItem(@Path("id") id: Int, @Body update: PantryItemUpdate): PantryItemResponse

    @DELETE("api/pantry/{id}")
    suspend fun deleteItem(@Path("id") id: Int)

    @GET("api/pantry/alerts")
    suspend fun getAlerts(): List<PantryAlertItem>

    @POST("api/pantry/alerts/{id}/add-to-shopping")
    suspend fun alertToShopping(@Path("id") id: Int): Map<String, String>

    @POST("api/pantry/alerts/{id}/dismiss")
    suspend fun dismissAlert(@Path("id") id: Int): Map<String, String>
}
