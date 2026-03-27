package de.familienkalender.app.ui.meals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.local.db.entity.PantryItemEntity
import de.familienkalender.app.data.remote.dto.PantryAlertItem
import de.familienkalender.app.data.remote.dto.PantryItemCreate
import de.familienkalender.app.data.remote.dto.PantryItemUpdate
import de.familienkalender.app.data.repository.PantryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class PantryViewModel(
    private val pantryRepository: PantryRepository
) : ViewModel() {

    val items: Flow<List<PantryItemEntity>> = pantryRepository.getAll()

    private val _alerts = MutableStateFlow<List<PantryAlertItem>>(emptyList())
    val alerts: StateFlow<List<PantryAlertItem>> = _alerts

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    fun refresh() {
        viewModelScope.launch {
            _isLoading.value = true
            pantryRepository.refresh()
            refreshAlerts()
            _isLoading.value = false
        }
    }

    private suspend fun refreshAlerts() {
        pantryRepository.getRemoteAlerts().onSuccess { _alerts.value = it }
    }

    fun addItem(create: PantryItemCreate) {
        viewModelScope.launch {
            pantryRepository.addItem(create)
            refreshAlerts()
        }
    }

    fun updateItem(id: Int, update: PantryItemUpdate) {
        viewModelScope.launch {
            pantryRepository.updateItem(id, update)
            refreshAlerts()
        }
    }

    fun deleteItem(id: Int) {
        viewModelScope.launch {
            pantryRepository.deleteItem(id)
            refreshAlerts()
        }
    }

    fun alertToShopping(itemId: Int) {
        viewModelScope.launch {
            pantryRepository.alertToShopping(itemId)
            refreshAlerts()
        }
    }

    fun dismissAlert(itemId: Int) {
        viewModelScope.launch {
            pantryRepository.dismissAlert(itemId)
            refreshAlerts()
        }
    }

    class Factory(
        private val pantryRepository: PantryRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return PantryViewModel(pantryRepository) as T
        }
    }
}
