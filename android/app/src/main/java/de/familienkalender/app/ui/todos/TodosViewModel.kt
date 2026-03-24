package de.familienkalender.app.ui.todos

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.local.db.dao.TodoWithDetails
import de.familienkalender.app.data.local.db.entity.CategoryEntity
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import de.familienkalender.app.data.local.db.entity.SubtodoEntity
import de.familienkalender.app.data.remote.dto.PendingProposalDetail
import de.familienkalender.app.data.remote.dto.ProposalCreate
import de.familienkalender.app.data.remote.dto.ProposalRespondRequest
import de.familienkalender.app.data.remote.dto.ProposalResponse
import de.familienkalender.app.data.remote.dto.TodoCreate
import de.familienkalender.app.data.remote.dto.TodoUpdate
import de.familienkalender.app.data.repository.CategoryRepository
import de.familienkalender.app.data.repository.FamilyMemberRepository
import de.familienkalender.app.data.repository.TodoRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class TodoFilter(
    val priority: String? = null,
    val completed: Boolean? = false, // default: show open
    val memberId: Int? = null,
    val categoryId: Int? = null
)

class TodosViewModel(
    private val todoRepository: TodoRepository,
    private val categoryRepository: CategoryRepository,
    private val memberRepository: FamilyMemberRepository
) : ViewModel() {

    private val _filter = MutableStateFlow(TodoFilter())
    val filter: StateFlow<TodoFilter> = _filter

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing

    val allTodos: StateFlow<List<TodoWithDetails>> = todoRepository.getAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val filteredTodos: StateFlow<List<TodoWithDetails>> = combine(allTodos, _filter) { todos, filter ->
        todos.filter { todo ->
            (filter.priority == null || todo.todo.priority == filter.priority) &&
            (filter.completed == null || todo.todo.completed == filter.completed) &&
            (filter.memberId == null || todo.members.any { it.id == filter.memberId }) &&
            (filter.categoryId == null || todo.todo.categoryId == filter.categoryId)
        }
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
            todoRepository.refresh()
            categoryRepository.refresh()
            memberRepository.refresh()
            _pendingProposals.value = todoRepository.getPendingProposals()
            _isRefreshing.value = false
        }
    }

    fun setFilter(filter: TodoFilter) {
        _filter.value = filter
    }

    fun togglePriority(priority: String) {
        _filter.value = _filter.value.copy(
            priority = if (_filter.value.priority == priority) null else priority
        )
    }

    fun toggleShowCompleted() {
        _filter.value = _filter.value.copy(
            completed = if (_filter.value.completed == false) null else false
        )
    }

    fun createTodo(request: TodoCreate) {
        viewModelScope.launch { todoRepository.create(request) }
    }

    fun updateTodo(id: Int, request: TodoUpdate) {
        viewModelScope.launch { todoRepository.update(id, request) }
    }

    fun toggleComplete(id: Int) {
        viewModelScope.launch { todoRepository.toggleComplete(id) }
    }

    fun deleteTodo(id: Int) {
        viewModelScope.launch { todoRepository.delete(id) }
    }

    fun getSubtodos(parentId: Int): Flow<List<SubtodoEntity>> = todoRepository.getSubtodos(parentId)

    fun addSubTodo(parentId: Int, title: String) {
        viewModelScope.launch {
            todoRepository.create(TodoCreate(title = title, parentId = parentId))
        }
    }

    private val _pendingProposals = MutableStateFlow<List<PendingProposalDetail>>(emptyList())
    val pendingProposals: StateFlow<List<PendingProposalDetail>> = _pendingProposals

    suspend fun getProposals(todoId: Int): List<ProposalResponse> {
        return todoRepository.getProposals(todoId)
    }

    fun proposeDate(todoId: Int, proposedDate: String, message: String?) {
        viewModelScope.launch {
            todoRepository.proposeDate(todoId, ProposalCreate(proposedDate = proposedDate, message = message))
        }
    }

    fun refreshPendingProposals() {
        viewModelScope.launch {
            _pendingProposals.value = todoRepository.getPendingProposals()
        }
    }

    fun respondToProposal(
        proposalId: Int,
        response: String,
        message: String? = null,
        counterDate: String? = null,
        onDone: () -> Unit = {}
    ) {
        viewModelScope.launch {
            todoRepository.respondToProposal(
                proposalId,
                ProposalRespondRequest(response = response, message = message, counterDate = counterDate)
            )
            refreshPendingProposals()
            onDone()
        }
    }

    class Factory(
        private val todoRepository: TodoRepository,
        private val categoryRepository: CategoryRepository,
        private val memberRepository: FamilyMemberRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return TodosViewModel(todoRepository, categoryRepository, memberRepository) as T
        }
    }
}
