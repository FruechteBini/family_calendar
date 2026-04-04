package de.familienkalender.app.data.repository

import de.familienkalender.app.data.local.prefs.TokenManager
import de.familienkalender.app.data.remote.api.AuthApi
import de.familienkalender.app.data.remote.dto.*

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
            user.familyId?.let { tokenManager.familyId = it }

            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun register(username: String, password: String): Result<UserResponse> {
        return try {
            api.register(SetupRequest(username, password))
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
            user.familyId?.let { tokenManager.familyId = it }
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

    suspend fun createFamily(name: String): Result<FamilyResponse> {
        return try {
            val family = api.createFamily(FamilyCreateRequest(name))
            tokenManager.familyId = family.id
            Result.success(family)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun joinFamily(inviteCode: String): Result<FamilyResponse> {
        return try {
            val family = api.joinFamily(FamilyJoinRequest(inviteCode))
            tokenManager.familyId = family.id
            Result.success(family)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getFamily(): Result<FamilyResponse> {
        return try {
            Result.success(api.getFamily())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun logout() {
        tokenManager.clear()
    }

    val isLoggedIn: Boolean get() = tokenManager.isLoggedIn
    val hasFamilyId: Boolean get() = tokenManager.familyId != null && tokenManager.familyId != 0
}
