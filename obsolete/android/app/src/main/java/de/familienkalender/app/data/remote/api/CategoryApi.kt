package de.familienkalender.app.data.remote.api

import de.familienkalender.app.data.remote.dto.*
import retrofit2.http.*

interface CategoryApi {

    @GET("api/categories/")
    suspend fun getCategories(): List<CategoryResponse>

    @POST("api/categories/")
    suspend fun createCategory(@Body category: CategoryCreate): CategoryResponse

    @PUT("api/categories/{id}")
    suspend fun updateCategory(@Path("id") id: Int, @Body category: CategoryUpdate): CategoryResponse

    @DELETE("api/categories/{id}")
    suspend fun deleteCategory(@Path("id") id: Int)
}
