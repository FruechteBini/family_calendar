package de.familienkalender.app.ui.calendar

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.local.db.dao.EventWithMembers
import de.familienkalender.app.data.local.db.entity.CategoryEntity
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import de.familienkalender.app.data.remote.dto.EventCreate
import de.familienkalender.app.data.remote.dto.EventUpdate
import de.familienkalender.app.data.remote.dto.TodoCreate
import de.familienkalender.app.data.repository.CategoryRepository
import de.familienkalender.app.data.repository.EventRepository
import de.familienkalender.app.data.repository.FamilyMemberRepository
import de.familienkalender.app.data.repository.TodoRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

enum class CalendarViewMode(val label: String) {
    Day("Tag"),
    ThreeDays("3 Tage"),
    Week("Woche"),
    Month("Monat")
}

class CalendarViewModel(
    private val eventRepository: EventRepository,
    private val categoryRepository: CategoryRepository,
    private val memberRepository: FamilyMemberRepository,
    private val todoRepository: TodoRepository
) : ViewModel() {

    companion object {
        private const val TAG = "CalendarViewModel"
    }

    private val _currentMonth = MutableStateFlow(YearMonth.now())
    val currentMonth: StateFlow<YearMonth> = _currentMonth

    private val _selectedDate = MutableStateFlow<LocalDate?>(LocalDate.now())
    val selectedDate: StateFlow<LocalDate?> = _selectedDate

    private val _viewMode = MutableStateFlow(CalendarViewMode.Month)
    val viewMode: StateFlow<CalendarViewMode> = _viewMode

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    val events: StateFlow<List<EventWithMembers>> = _currentMonth.flatMapLatest { month ->
        val from = month.atDay(1).format(DateTimeFormatter.ISO_LOCAL_DATE) + "T00:00:00"
        val to = month.atEndOfMonth().format(DateTimeFormatter.ISO_LOCAL_DATE) + "T23:59:59"
        eventRepository.getEventsBetween(from, to)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val categories: StateFlow<List<CategoryEntity>> = categoryRepository.getAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val members: StateFlow<List<FamilyMemberEntity>> = memberRepository.getAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _isRefreshing.value = true
            try {
                val month = _currentMonth.value
                val from = month.atDay(1).format(DateTimeFormatter.ISO_LOCAL_DATE) + "T00:00:00"
                val to = month.atEndOfMonth().format(DateTimeFormatter.ISO_LOCAL_DATE) + "T23:59:59"
                eventRepository.refresh(dateFrom = from, dateTo = to)
                categoryRepository.refresh()
                memberRepository.refresh()
            } catch (e: Exception) {
                Log.w(TAG, "Failed to refresh calendar", e)
                _error.value = "Offline – Daten konnten nicht aktualisiert werden"
            }
            _isRefreshing.value = false
        }
    }

    fun setViewMode(mode: CalendarViewMode) {
        _viewMode.value = mode
        if (_selectedDate.value == null) _selectedDate.value = LocalDate.now()
    }

    fun navigateBack() {
        when (_viewMode.value) {
            CalendarViewMode.Month -> previousMonth()
            CalendarViewMode.Week -> shiftDate(-7)
            CalendarViewMode.ThreeDays -> shiftDate(-3)
            CalendarViewMode.Day -> shiftDate(-1)
        }
    }

    fun navigateForward() {
        when (_viewMode.value) {
            CalendarViewMode.Month -> nextMonth()
            CalendarViewMode.Week -> shiftDate(7)
            CalendarViewMode.ThreeDays -> shiftDate(3)
            CalendarViewMode.Day -> shiftDate(1)
        }
    }

    private fun shiftDate(days: Long) {
        val base = _selectedDate.value ?: LocalDate.now()
        val next = base.plusDays(days)
        _selectedDate.value = next
        val month = YearMonth.from(next)
        if (month != _currentMonth.value) {
            _currentMonth.value = month
            refresh()
        }
    }

    fun previousMonth() {
        _currentMonth.value = _currentMonth.value.minusMonths(1)
        _selectedDate.value = null
        refresh()
    }

    fun nextMonth() {
        _currentMonth.value = _currentMonth.value.plusMonths(1)
        _selectedDate.value = null
        refresh()
    }

    fun goToToday() {
        _currentMonth.value = YearMonth.now()
        _selectedDate.value = LocalDate.now()
        refresh()
    }

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
        val month = YearMonth.from(date)
        if (month != _currentMonth.value) {
            _currentMonth.value = month
            refresh()
        }
    }

    fun createEvent(request: EventCreate, todoTitles: List<String> = emptyList()) {
        viewModelScope.launch {
            val result = eventRepository.create(request)
            result.onSuccess { eventResponse ->
                _error.value = null
                if (todoTitles.isNotEmpty()) {
                    val dueDate = request.start.take(10)
                    todoTitles.filter { it.isNotBlank() }.forEach { title ->
                        todoRepository.create(TodoCreate(title = title, dueDate = dueDate, eventId = eventResponse.id))
                    }
                }
            }
            result.onFailure {
                _error.value = "Offline – Termin wird bei Verbindung erstellt"
            }
        }
    }

    fun addTodosToEvent(eventId: Int, dueDate: String, todoTitles: List<String>) {
        viewModelScope.launch {
            todoTitles.filter { it.isNotBlank() }.forEach { title ->
                todoRepository.create(TodoCreate(title = title, dueDate = dueDate, eventId = eventId))
            }
        }
    }

    fun updateEvent(id: Int, request: EventUpdate) {
        viewModelScope.launch {
            val result = eventRepository.update(id, request)
            result.onSuccess { _error.value = null }
            result.onFailure { _error.value = "Offline – Änderung wird synchronisiert" }
        }
    }

    fun deleteEvent(id: Int) {
        viewModelScope.launch {
            eventRepository.delete(id)
        }
    }

    class Factory(
        private val eventRepository: EventRepository,
        private val categoryRepository: CategoryRepository,
        private val memberRepository: FamilyMemberRepository,
        private val todoRepository: TodoRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return CalendarViewModel(eventRepository, categoryRepository, memberRepository, todoRepository) as T
        }
    }
}
