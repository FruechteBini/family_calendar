package de.familienkalender.app.data.remote

import com.google.gson.GsonBuilder
import de.familienkalender.app.data.local.prefs.TokenManager
import de.familienkalender.app.data.remote.api.*
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit

class RetrofitClient(private val tokenManager: TokenManager) {

    private val gson = GsonBuilder()
        .setDateFormat("yyyy-MM-dd'T'HH:mm:ss")
        .create()

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    val okHttpClient: OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(AuthInterceptor(tokenManager))
        .addInterceptor(loggingInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    @Volatile private var cachedRetrofit: Retrofit? = null
    @Volatile private var cachedBaseUrl: String? = null
    private val apiCache = ConcurrentHashMap<Class<*>, Any>()

    @Synchronized
    private fun getRetrofit(): Retrofit {
        val currentUrl = tokenManager.serverUrl
        if (cachedRetrofit != null && cachedBaseUrl == currentUrl) {
            return cachedRetrofit!!
        }
        val baseUrl = if (currentUrl.endsWith("/")) currentUrl else "$currentUrl/"
        val retrofit = Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
        cachedRetrofit = retrofit
        cachedBaseUrl = currentUrl
        apiCache.clear()
        return retrofit
    }

    fun invalidate() {
        synchronized(this) {
            cachedRetrofit = null
            cachedBaseUrl = null
            apiCache.clear()
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun <T> getApi(clazz: Class<T>): T =
        apiCache.getOrPut(clazz) { getRetrofit().create(clazz) } as T

    val authApi: AuthApi get() = getApi(AuthApi::class.java)
    val eventApi: EventApi get() = getApi(EventApi::class.java)
    val todoApi: TodoApi get() = getApi(TodoApi::class.java)
    val categoryApi: CategoryApi get() = getApi(CategoryApi::class.java)
    val familyMemberApi: FamilyMemberApi get() = getApi(FamilyMemberApi::class.java)
    val recipeApi: RecipeApi get() = getApi(RecipeApi::class.java)
    val mealApi: MealApi get() = getApi(MealApi::class.java)
    val shoppingApi: ShoppingApi get() = getApi(ShoppingApi::class.java)
    val cookidooApi: CookidooApi get() = getApi(CookidooApi::class.java)
}
