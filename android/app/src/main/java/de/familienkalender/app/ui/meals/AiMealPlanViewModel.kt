package de.familienkalender.app.ui.meals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.remote.dto.*
import de.familienkalender.app.data.repository.AiRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

enum class AiStep { LOADING, CONFIG, GENERATING, PREVIEW, ERROR }

data class AiMealPlanUiState(
    val step: AiStep = AiStep.LOADING,
    val weekStart: String = "",
    val availableDates: List<String> = emptyList(),
    val occupiedSlots: Set<String> = emptySet(),
    val selectedSlots: Set<String> = emptySet(),
    val cookidooAvailable: Boolean = false,
    val includeCookidoo: Boolean = false,
    val servings: Int = 4,
    val preferences: String = "",
    val preview: PreviewMealPlanResponse? = null,
    val isConfirming: Boolean = false,
    val error: String? = null
)

class AiMealPlanViewModel(
    private val aiRepository: AiRepository,
    private val weekStart: String
) : ViewModel() {

    private val _uiState = MutableStateFlow(AiMealPlanUiState(weekStart = weekStart))
    val uiState: StateFlow<AiMealPlanUiState> = _uiState

    init {
        loadAvailableRecipes()
    }

    private fun loadAvailableRecipes() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(step = AiStep.LOADING)
            aiRepository.getAvailableRecipes(weekStart).fold(
                onSuccess = { response ->
                    val monday = LocalDate.parse(weekStart)
                    val dates = (0..6).map { monday.plusDays(it.toLong()).format(DateTimeFormatter.ISO_DATE) }
                    val occupied = mutableSetOf<String>()
                    response.currentSlots.forEach { (date, slots) ->
                        slots.forEach { (slot, info) ->
                            if (info != null) occupied.add("$date|$slot")
                        }
                    }
                    val emptySlots = dates.flatMap { d ->
                        listOf("lunch", "dinner").mapNotNull { s ->
                            val id = "$d|$s"
                            if (!occupied.contains(id)) id else null
                        }
                    }.toSet()

                    _uiState.value = _uiState.value.copy(
                        step = AiStep.CONFIG,
                        availableDates = dates,
                        occupiedSlots = occupied,
                        selectedSlots = emptySlots,
                        cookidooAvailable = response.cookidooAvailable
                    )
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(step = AiStep.ERROR, error = e.message)
                }
            )
        }
    }

    fun toggleSlot(slotId: String) {
        val current = _uiState.value.selectedSlots.toMutableSet()
        if (current.contains(slotId)) current.remove(slotId) else current.add(slotId)
        _uiState.value = _uiState.value.copy(selectedSlots = current)
    }

    fun setIncludeCookidoo(v: Boolean) { _uiState.value = _uiState.value.copy(includeCookidoo = v) }
    fun setServings(v: Int) { _uiState.value = _uiState.value.copy(servings = v) }
    fun setPreferences(v: String) { _uiState.value = _uiState.value.copy(preferences = v) }

    fun generate() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(step = AiStep.GENERATING)
            val slots = _uiState.value.selectedSlots.map { id ->
                val parts = id.split("|")
                SlotSelection(parts[0], parts[1])
            }
            val request = GenerateMealPlanRequest(
                weekStart = weekStart,
                servings = _uiState.value.servings,
                preferences = _uiState.value.preferences,
                selectedSlots = slots,
                includeCookidoo = _uiState.value.includeCookidoo
            )
            aiRepository.generateMealPlan(request).fold(
                onSuccess = { preview ->
                    _uiState.value = _uiState.value.copy(step = AiStep.PREVIEW, preview = preview)
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(step = AiStep.ERROR, error = e.message)
                }
            )
        }
    }

    fun confirm(onConfirmed: (List<Int>) -> Unit) {
        viewModelScope.launch {
            val preview = _uiState.value.preview ?: return@launch
            _uiState.value = _uiState.value.copy(isConfirming = true)
            val request = ConfirmMealPlanRequest(weekStart = weekStart, items = preview.suggestions)
            aiRepository.confirmMealPlan(request).fold(
                onSuccess = { response ->
                    _uiState.value = _uiState.value.copy(isConfirming = false)
                    onConfirmed(response.mealIds)
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(isConfirming = false, step = AiStep.ERROR, error = e.message)
                }
            )
        }
    }

    fun backToConfig() {
        _uiState.value = _uiState.value.copy(step = AiStep.CONFIG, error = null)
    }

    class Factory(
        private val aiRepository: AiRepository,
        private val weekStart: String
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return AiMealPlanViewModel(aiRepository, weekStart) as T
        }
    }
}
