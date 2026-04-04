package de.familienkalender.app.data.remote

import de.familienkalender.app.data.local.prefs.TokenManager
import okhttp3.Interceptor
import okhttp3.Response

class AuthInterceptor(private val tokenManager: TokenManager) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()

        // Skip auth header for login/register endpoints
        val path = original.url.encodedPath
        if (path.endsWith("/auth/login") || path.endsWith("/auth/register")) {
            return chain.proceed(original)
        }

        val token = tokenManager.token ?: return chain.proceed(original)

        val request = original.newBuilder()
            .header("Authorization", "Bearer $token")
            .build()

        return chain.proceed(request)
    }
}
