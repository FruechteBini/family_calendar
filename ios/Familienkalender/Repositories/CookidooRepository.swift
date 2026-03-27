import Foundation

final class CookidooRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func checkStatus() async throws -> CookidooStatusResponse {
        try await api.get(path: "\(Endpoints.Cookidoo.base)/status")
    }

    func getCollections() async throws -> [CookidooCollection] {
        try await api.get(path: "\(Endpoints.Cookidoo.base)/collections")
    }

    func getShoppingList() async throws -> [CookidooRecipeSummary] {
        try await api.get(path: "\(Endpoints.Cookidoo.base)/shopping-list")
    }

    func getRecipe(id: String) async throws -> RecipeResponse {
        try await api.get(path: "\(Endpoints.Cookidoo.base)/recipes/\(id)")
    }

    func importRecipe(id: String) async throws -> RecipeResponse {
        try await api.post(path: "\(Endpoints.Cookidoo.base)/recipes/\(id)/import")
    }
}
