import Foundation

@Observable
@MainActor
final class CookidooViewModel {

    // MARK: - State

    var isAvailable: Bool = false
    var collections: [CookidooCollection] = []
    var shoppingListRecipes: [CookidooRecipeSummary] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var isImporting: Bool = false

    // MARK: - Dependencies

    private let cookidooRepo: CookidooRepository

    init(cookidooRepo: CookidooRepository) {
        self.cookidooRepo = cookidooRepo
    }

    // MARK: - Status

    func checkStatus() async {
        do {
            let status = try await cookidooRepo.checkStatus()
            isAvailable = status.available
        } catch {
            isAvailable = false
        }
    }

    // MARK: - Load

    func loadCollections() async {
        isLoading = true
        errorMessage = nil
        do {
            collections = try await cookidooRepo.getCollections()
        } catch {
            errorMessage = "Cookidoo-Sammlungen konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadShoppingList() async {
        isLoading = true
        errorMessage = nil
        do {
            shoppingListRecipes = try await cookidooRepo.getShoppingList()
        } catch {
            errorMessage = "Cookidoo-Einkaufsliste konnte nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Import

    func importRecipe(id: String) async -> RecipeResponse? {
        isImporting = true
        errorMessage = nil
        do {
            let recipe = try await cookidooRepo.importRecipe(id: id)
            isImporting = false
            return recipe
        } catch {
            errorMessage = "Rezept konnte nicht importiert werden: \(error.localizedDescription)"
            isImporting = false
            return nil
        }
    }
}
