import Foundation

@Observable
@MainActor
final class CategoryViewModel {

    // MARK: - State

    var categories: [CategoryResponse] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let categoryRepo: CategoryRepository

    init(categoryRepo: CategoryRepository) {
        self.categoryRepo = categoryRepo
    }

    // MARK: - Load

    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        do {
            categories = try await categoryRepo.list()
        } catch {
            errorMessage = "Kategorien konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - CRUD

    func createCategory(_ body: CategoryCreate) async {
        errorMessage = nil
        do {
            let created = try await categoryRepo.create(body)
            categories.append(created)
        } catch {
            errorMessage = "Kategorie konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }

    func updateCategory(id: Int, _ body: CategoryUpdate) async {
        errorMessage = nil
        do {
            let updated = try await categoryRepo.update(id: id, body)
            if let idx = categories.firstIndex(where: { $0.id == id }) {
                categories[idx] = updated
            }
        } catch {
            errorMessage = "Kategorie konnte nicht aktualisiert werden: \(error.localizedDescription)"
        }
    }

    func deleteCategory(id: Int) async {
        errorMessage = nil
        do {
            try await categoryRepo.delete(id: id)
            categories.removeAll { $0.id == id }
        } catch {
            errorMessage = "Kategorie konnte nicht geloescht werden: \(error.localizedDescription)"
        }
    }
}
