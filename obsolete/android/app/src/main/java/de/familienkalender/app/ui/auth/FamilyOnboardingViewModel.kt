package de.familienkalender.app.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class FamilyOnboardingState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val familyJoined: Boolean = false
)

class FamilyOnboardingViewModel(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(FamilyOnboardingState())
    val uiState: StateFlow<FamilyOnboardingState> = _uiState

    fun createFamily(name: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            authRepository.createFamily(name).fold(
                onSuccess = {
                    _uiState.value = _uiState.value.copy(isLoading = false, familyJoined = true)
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Familie konnte nicht erstellt werden"
                    )
                }
            )
        }
    }

    fun joinFamily(inviteCode: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            authRepository.joinFamily(inviteCode).fold(
                onSuccess = {
                    _uiState.value = _uiState.value.copy(isLoading = false, familyJoined = true)
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Beitreten fehlgeschlagen. Ist der Code korrekt?"
                    )
                }
            )
        }
    }

    class Factory(
        private val authRepository: AuthRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return FamilyOnboardingViewModel(authRepository) as T
        }
    }
}
