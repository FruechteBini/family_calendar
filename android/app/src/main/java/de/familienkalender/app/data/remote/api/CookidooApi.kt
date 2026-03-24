package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface CookidooApi {

    @GET("api/cookidoo/status")
    suspend fun getStatus(): CookidooStatus

    @GET("api/cookidoo/collections")
    suspend fun getCollections(): List<CookidooCollection>

    @GET("api/cookidoo/shopping-list")
    suspend fun getShoppingList(): List<CookidooRecipeBrief>

    @GET("api/cookidoo/recipes/{cookidoo_id}")
    suspend fun getRecipeDetail(@Path("cookidoo_id") cookidooId: String): CookidooRecipeDetail

    @POST("api/cookidoo/recipes/{cookidoo_id}/import")
    suspend fun importRecipe(@Path("cookidoo_id") cookidooId: String): RecipeResponse
}
