import Foundation

@Observable
@MainActor
final class RecipeViewModel {

    // MARK: - State

    var recipes: [RecipeResponse] = []
    var suggestions: [RecipeSuggestion] = []
    var searchText: String = ""
    var sortBy: String = "title"
    var filterDifficulty: Difficulty?
    var filterSource: RecipeSource?
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Computed

    var filteredRecipes: [RecipeResponse] {
        var result = recipes

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.title.lowercased().contains(query) }
        }

        if let diff = filterDifficulty {
            result = result.filter { $0.difficulty == diff.rawValue }
        }

        if let source = filterSource {
            result = result.filter { $0.source == source.rawValue }
        }

        return result
    }

    // MARK: - Dependencies

    private let recipeRepo: RecipeRepository

    init(recipeRepo: RecipeRepository) {
        self.recipeRepo = recipeRepo
    }

    // MARK: - Load

    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        do {
            recipes = try await recipeRepo.list(sortBy: sortBy, order: "asc")
        } catch {
            errorMessage = "Rezepte konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadSuggestions() async {
        do {
            suggestions = try await recipeRepo.suggestions(limit: 10)
        } catch {
            errorMessage = "Vorschlaege konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    // MARK: - CRUD

    func createRecipe(_ body: RecipeCreate) async {
        errorMessage = nil
        do {
            let created = try await recipeRepo.create(body)
            recipes.append(created)
        } catch {
            errorMessage = "Rezept konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }

    func updateRecipe(id: Int, _ body: RecipeUpdate) async {
        errorMessage = nil
        do {
            let updated = try await recipeRepo.update(id: id, body)
            if let idx = recipes.firstIndex(where: { $0.id == id }) {
                recipes[idx] = updated
            }
        } catch {
            errorMessage = "Rezept konnte nicht aktualisiert werden: \(error.localizedDescription)"
        }
    }

    func deleteRecipe(id: Int) async {
        errorMessage = nil
        do {
            try await recipeRepo.delete(id: id)
            recipes.removeAll { $0.id == id }
        } catch {
            errorMessage = "Rezept konnte nicht geloescht werden: \(error.localizedDescription)"
        }
    }

    // MARK: - URL Import

    func parseUrl(url: String) async -> UrlImportPreview? {
        errorMessage = nil
        do {
            return try await recipeRepo.parseUrl(url: url)
        } catch {
            errorMessage = "URL konnte nicht analysiert werden: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - History

    func getHistory(recipeId: Int) async -> [CookingHistoryEntry] {
        do {
            return try await recipeRepo.history(recipeId: recipeId)
        } catch {
            errorMessage = "Kochhistorie konnte nicht geladen werden: \(error.localizedDescription)"
            return []
        }
    }
}
