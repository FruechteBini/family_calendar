package de.familienkalender.app.data.repository

import de.familienkalender.app.data.local.prefs.TokenManager
import de.familienkalender.app.data.remote.api.AuthApi
import de.familienkalender.app.data.remote.dto.LinkMemberRequest
import de.familienkalender.app.data.remote.dto.LoginRequest
import de.familienkalender.app.data.remote.dto.SetupRequest
import de.familienkalender.app.data.remote.dto.UserResponse

class AuthRepository(
    private val api: AuthApi,
    private val tokenManager: TokenManager
) {

    suspend fun login(username: String, password: String): Result<UserResponse> {
        return try {
            val tokenResponse = api.login(LoginRequest(username, password))
            tokenManager.token = tokenResponse.accessToken
            tokenManager.username = username

            val user = api.getMe()
            tokenManager.userId = user.id
            user.memberId?.let { tokenManager.memberId = it }

            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun register(username: String, password: String): Result<UserResponse> {
        return try {
            val user = api.register(SetupRequest(username, password))
            // After registration, login to get token
            login(username, password)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getMe(): Result<UserResponse> {
        return try {
            val user = api.getMe()
            tokenManager.userId = user.id
            tokenManager.username = user.username
            user.memberId?.let { tokenManager.memberId = it }
            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun linkMember(memberId: Int): Result<UserResponse> {
        return try {
            val user = api.linkMember(LinkMemberRequest(memberId))
            tokenManager.memberId = memberId
            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun logout() {
        tokenManager.clear()
    }

    val isLoggedIn: Boolean get() = tokenManager.isLoggedIn
}
