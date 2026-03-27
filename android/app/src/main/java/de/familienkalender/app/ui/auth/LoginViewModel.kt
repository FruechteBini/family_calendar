package de.familienkalender.app.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.local.prefs.TokenManager
import de.familienkalender.app.data.remote.RetrofitClient
import de.familienkalender.app.data.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class LoginUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val isLoggedIn: Boolean = false,
    val hasFamilyId: Boolean = false,
    val serverUrl: String = ""
)

class LoginViewModel(
    private val authRepository: AuthRepository,
    private val tokenManager: TokenManager,
    private val retrofitClient: RetrofitClient
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginUiState(serverUrl = tokenManager.serverUrl))
    val uiState: StateFlow<LoginUiState> = _uiState

    fun updateServerUrl(url: String) {
        tokenManager.serverUrl = url
        retrofitClient.invalidate()
        _uiState.value = _uiState.value.copy(serverUrl = url)
    }

    fun login(username: String, password: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            authRepository.login(username, password).fold(
                onSuccess = { user ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        isLoggedIn = true,
                        hasFamilyId = user.familyId != null
                    )
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Anmeldung fehlgeschlagen"
                    )
                }
            )
        }
    }

    fun register(username: String, password: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            authRepository.register(username, password).fold(
                onSuccess = { user ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        isLoggedIn = true,
                        hasFamilyId = user.familyId != null
                    )
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Registrierung fehlgeschlagen"
                    )
                }
            )
        }
    }

    fun checkExistingToken() {
        if (tokenManager.isLoggedIn) {
            viewModelScope.launch {
                _uiState.value = _uiState.value.copy(isLoading = true)
                authRepository.getMe().fold(
                    onSuccess = { user ->
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            isLoggedIn = true,
                            hasFamilyId = user.familyId != null
                        )
                    },
                    onFailure = {
                        tokenManager.clear()
                        _uiState.value = _uiState.value.copy(isLoading = false)
                    }
                )
            }
        }
    }

    class Factory(
        private val authRepository: AuthRepository,
        private val tokenManager: TokenManager,
        private val retrofitClient: RetrofitClient
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return LoginViewModel(authRepository, tokenManager, retrofitClient) as T
        }
    }
}
