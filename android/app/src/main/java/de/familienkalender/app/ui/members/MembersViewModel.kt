package de.familienkalender.app.ui.members

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import de.familienkalender.app.data.remote.dto.FamilyMemberCreate
import de.familienkalender.app.data.remote.dto.FamilyMemberUpdate
import de.familienkalender.app.data.repository.FamilyMemberRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class MembersViewModel(
    private val repository: FamilyMemberRepository
) : ViewModel() {

    val members: StateFlow<List<FamilyMemberEntity>> = repository.getAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch { repository.refresh() }
    }

    fun create(request: FamilyMemberCreate) {
        viewModelScope.launch { repository.create(request) }
    }

    fun update(id: Int, request: FamilyMemberUpdate) {
        viewModelScope.launch { repository.update(id, request) }
    }

    fun delete(id: Int) {
        viewModelScope.launch { repository.delete(id) }
    }

    class Factory(private val repository: FamilyMemberRepository) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return MembersViewModel(repository) as T
        }
    }
}
