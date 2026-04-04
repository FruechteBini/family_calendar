package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface RecipeApi {

    @GET("api/recipes/")
    suspend fun getRecipes(
        @Query("sort_by") sortBy: String? = null,
        @Query("order") order: String? = null
    ): List<RecipeResponse>

    @GET("api/recipes/suggestions")
    suspend fun getSuggestions(@Query("limit") limit: Int = 10): List<RecipeSuggestion>

    @GET("api/recipes/{id}")
    suspend fun getRecipe(@Path("id") id: Int): RecipeDetailResponse

    @POST("api/recipes/")
    suspend fun createRecipe(@Body recipe: RecipeCreate): RecipeResponse

    @PUT("api/recipes/{id}")
    suspend fun updateRecipe(@Path("id") id: Int, @Body recipe: RecipeUpdate): RecipeResponse

    @GET("api/recipes/{id}/history")
    suspend fun getHistory(@Path("id") id: Int): List<CookingHistoryResponse>

    @DELETE("api/recipes/{id}")
    suspend fun deleteRecipe(@Path("id") id: Int)

    @POST("api/recipes/parse-url")
    suspend fun parseUrl(@Body request: ParseUrlRequest): RecipeResponse
}
