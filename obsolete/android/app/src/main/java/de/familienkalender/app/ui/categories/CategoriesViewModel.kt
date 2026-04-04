package de.familienkalender.app.ui.categories

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.local.db.entity.CategoryEntity
import de.familienkalender.app.data.repository.CategoryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class CategoriesViewModel(
    private val categoryRepository: CategoryRepository
) : ViewModel() {

    val categories: Flow<List<CategoryEntity>> = categoryRepository.getAll()

    fun refresh() {
        viewModelScope.launch { categoryRepository.refresh() }
    }

    fun create(name: String, color: String) {
        viewModelScope.launch {
            categoryRepository.create(
                de.familienkalender.app.data.remote.dto.CategoryCreate(name = name, color = color)
            )
        }
    }

    fun update(id: Int, name: String, color: String) {
        viewModelScope.launch {
            categoryRepository.update(id,
                de.familienkalender.app.data.remote.dto.CategoryUpdate(name = name, color = color)
            )
        }
    }

    fun delete(id: Int) {
        viewModelScope.launch { categoryRepository.delete(id) }
    }

    class Factory(
        private val categoryRepository: CategoryRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return CategoriesViewModel(categoryRepository) as T
        }
    }
}
