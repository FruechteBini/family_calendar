package de.familienkalender.app.ui.meals

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.local.db.dao.RecipeWithIngredients
import de.familienkalender.app.data.local.db.dao.ShoppingListWithItems
import de.familienkalender.app.data.remote.api.CookidooApi
import de.familienkalender.app.data.remote.dto.*
import de.familienkalender.app.data.repository.MealPlanRepository
import de.familienkalender.app.data.repository.RecipeRepository
import de.familienkalender.app.data.repository.ShoppingRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters

class MealsViewModel(
    private val mealPlanRepository: MealPlanRepository,
    private val recipeRepository: RecipeRepository,
    private val shoppingRepository: ShoppingRepository,
    private val cookidooApi: CookidooApi
) : ViewModel() {

    companion object {
        private const val TAG = "MealsViewModel"
    }

    private val _currentWeekStart = MutableStateFlow(
        LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
    )
    val currentWeekStart: StateFlow<LocalDate> = _currentWeekStart

    private val _weekPlan = MutableStateFlow<WeekPlanResponse?>(null)
    val weekPlan: StateFlow<WeekPlanResponse?> = _weekPlan

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing

    val recipes: StateFlow<List<RecipeWithIngredients>> = recipeRepository.getAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val shoppingList: StateFlow<ShoppingListWithItems?> = shoppingRepository.getActiveList()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // ── Cookidoo ──────────────────────────────────────────────────
    private val _cookidooAvailable = MutableStateFlow(false)
    val cookidooAvailable: StateFlow<Boolean> = _cookidooAvailable

    private val _cookidooCollections = MutableStateFlow<List<CookidooCollection>>(emptyList())
    val cookidooCollections: StateFlow<List<CookidooCollection>> = _cookidooCollections

    private val _cookidooShoppingList = MutableStateFlow<List<CookidooRecipeBrief>>(emptyList())
    val cookidooShoppingList: StateFlow<List<CookidooRecipeBrief>> = _cookidooShoppingList

    private val _cookidooLoading = MutableStateFlow(false)
    val cookidooLoading: StateFlow<Boolean> = _cookidooLoading

    private val _cookidooImportStatus = MutableStateFlow<Map<String, String>>(emptyMap())
    val cookidooImportStatus: StateFlow<Map<String, String>> = _cookidooImportStatus

    init {
        refreshAll()
        checkCookidooAvailability()
    }

    private fun checkCookidooAvailability() {
        viewModelScope.launch {
            try {
                val status = cookidooApi.getStatus()
                _cookidooAvailable.value = status.available
            } catch (e: Exception) {
                Log.w(TAG, "Failed to check Cookidoo availability", e)
                _cookidooAvailable.value = false
            }
        }
    }

    fun loadCookidoo() {
        viewModelScope.launch {
            _cookidooLoading.value = true
            try {
                _cookidooCollections.value = cookidooApi.getCollections()
                _cookidooShoppingList.value = cookidooApi.getShoppingList()
            } catch (e: Exception) {
                Log.w(TAG, "Failed to load Cookidoo data", e)
            }
            _cookidooLoading.value = false
        }
    }

    fun loadCookidooDetail(cookidooId: String, onResult: (CookidooRecipeDetail) -> Unit) {
        viewModelScope.launch {
            _cookidooLoading.value = true
            try {
                val detail = cookidooApi.getRecipeDetail(cookidooId)
                onResult(detail)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to load Cookidoo detail for $cookidooId", e)
            }
            _cookidooLoading.value = false
        }
    }

    fun importFromCookidoo(cookidooId: String) {
        viewModelScope.launch {
            _cookidooImportStatus.value = _cookidooImportStatus.value + (cookidooId to "loading")
            try {
                cookidooApi.importRecipe(cookidooId)
                recipeRepository.refresh()
                _cookidooImportStatus.value = _cookidooImportStatus.value + (cookidooId to "done")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to import Cookidoo recipe $cookidooId", e)
                _cookidooImportStatus.value = _cookidooImportStatus.value - cookidooId
            }
        }
    }

    // ── Recipe CRUD ───────────────────────────────────────────────

    fun refreshAll() {
        viewModelScope.launch {
            _isRefreshing.value = true
            val weekStr = _currentWeekStart.value.format(DateTimeFormatter.ISO_LOCAL_DATE)
            val result = mealPlanRepository.refreshWeek(weekStr)
            result.onSuccess { _weekPlan.value = it }
            result.onFailure { Log.w(TAG, "Failed to refresh week plan", it) }
            recipeRepository.refresh()
            shoppingRepository.refresh()
            _isRefreshing.value = false
        }
    }

    fun previousWeek() {
        _currentWeekStart.value = _currentWeekStart.value.minusWeeks(1)
        refreshAll()
    }

    fun nextWeek() {
        _currentWeekStart.value = _currentWeekStart.value.plusWeeks(1)
        refreshAll()
    }

    fun goToThisWeek() {
        _currentWeekStart.value = LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        refreshAll()
    }

    fun setMealSlot(date: String, slot: String, recipeId: Int, servings: Int = 4) {
        viewModelScope.launch {
            mealPlanRepository.setSlot(date, slot, MealSlotUpdate(recipeId, servings))
            refreshAll()
        }
    }

    fun clearMealSlot(date: String, slot: String) {
        viewModelScope.launch {
            mealPlanRepository.clearSlot(date, slot)
            refreshAll()
        }
    }

    fun markAsCooked(date: String, slot: String, rating: Int? = null, notes: String? = null) {
        viewModelScope.launch {
            mealPlanRepository.markAsCooked(date, slot, MarkCookedRequest(rating = rating, notes = notes))
            refreshAll()
        }
    }

    fun createRecipe(request: RecipeCreate) {
        viewModelScope.launch { recipeRepository.create(request) }
    }

    fun updateRecipe(id: Int, request: RecipeUpdate) {
        viewModelScope.launch { recipeRepository.update(id, request) }
    }

    fun deleteRecipe(id: Int) {
        viewModelScope.launch { recipeRepository.delete(id) }
    }

    fun generateShoppingList() {
        viewModelScope.launch {
            val weekStr = _currentWeekStart.value.format(DateTimeFormatter.ISO_LOCAL_DATE)
            shoppingRepository.generate(weekStr)
        }
    }

    fun addShoppingItem(request: ShoppingItemCreate) {
        viewModelScope.launch { shoppingRepository.addItem(request) }
    }

    fun checkShoppingItem(id: Int) {
        viewModelScope.launch { shoppingRepository.checkItem(id) }
    }

    fun deleteShoppingItem(id: Int) {
        viewModelScope.launch { shoppingRepository.deleteItem(id) }
    }

    class Factory(
        private val mealPlanRepository: MealPlanRepository,
        private val recipeRepository: RecipeRepository,
        private val shoppingRepository: ShoppingRepository,
        private val cookidooApi: CookidooApi
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return MealsViewModel(mealPlanRepository, recipeRepository, shoppingRepository, cookidooApi) as T
        }
    }
}
