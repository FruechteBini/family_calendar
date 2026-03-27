package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface ShoppingApi {

    @GET("api/shopping/list")
    suspend fun getShoppingList(): ShoppingListResponse?

    @POST("api/shopping/generate")
    suspend fun generateList(@Body request: GenerateRequest): ShoppingListResponse

    @POST("api/shopping/items")
    suspend fun addItem(@Body item: ShoppingItemCreate): ShoppingItemResponse

    @POST("api/shopping/clear-all")
    suspend fun clearAll(): Map<String, String>

    @PATCH("api/shopping/items/{id}/check")
    suspend fun checkItem(@Path("id") id: Int): ShoppingItemResponse

    @DELETE("api/shopping/items/{id}")
    suspend fun deleteItem(@Path("id") id: Int)

    @POST("api/shopping/sort")
    suspend fun aiSort(): ShoppingListResponse
}
