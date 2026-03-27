package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface KnusprApi {

    @GET("api/knuspr/products/search")
    suspend fun searchProducts(@Query("q") query: String): List<KnusprProduct>

    @POST("api/knuspr/cart/add")
    suspend fun addToCart(@Body request: AddToCartRequest): Map<String, Boolean>

    @POST("api/knuspr/cart/send-list/{id}")
    suspend fun sendListToCart(@Path("id") shoppingListId: Int): Map<String, Any>

    @GET("api/knuspr/delivery-slots")
    suspend fun getDeliverySlots(): List<KnusprDeliverySlot>

    @DELETE("api/knuspr/cart")
    suspend fun clearCart(): Map<String, Boolean>
}
