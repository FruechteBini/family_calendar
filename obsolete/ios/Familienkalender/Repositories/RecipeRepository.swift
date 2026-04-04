import Foundation

final class RecipeRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func list(sortBy: String? = nil, order: String? = nil) async throws -> [RecipeResponse] {
        var query: [URLQueryItem] = []
        if let s = sortBy { query.append(.init(name: "sort_by", value: s)) }
        if let o = order { query.append(.init(name: "order", value: o)) }
        return try await api.get(path: "\(Endpoints.Recipes.base)/", queryItems: query.isEmpty ? nil : query)
    }

    func get(id: Int) async throws -> RecipeResponse {
        try await api.get(path: "\(Endpoints.Recipes.base)/\(id)")
    }

    func create(_ recipe: RecipeCreate) async throws -> RecipeResponse {
        try await api.post(path: "\(Endpoints.Recipes.base)/", body: recipe)
    }

    func update(id: Int, _ recipe: RecipeUpdate) async throws -> RecipeResponse {
        try await api.put(path: "\(Endpoints.Recipes.base)/\(id)", body: recipe)
    }

    func delete(id: Int) async throws {
        try await api.delete(path: "\(Endpoints.Recipes.base)/\(id)")
    }

    func suggestions(limit: Int? = nil) async throws -> [RecipeSuggestion] {
        var query: [URLQueryItem] = []
        if let l = limit { query.append(.init(name: "limit", value: String(l))) }
        return try await api.get(path: "\(Endpoints.Recipes.base)/suggestions", queryItems: query.isEmpty ? nil : query)
    }

    func history(recipeId: Int) async throws -> [CookingHistoryEntry] {
        try await api.get(path: "\(Endpoints.Recipes.base)/\(recipeId)/history")
    }

    func parseUrl(url urlString: String) async throws -> UrlImportPreview {
        let body = UrlParseRequest(url: urlString)
        return try await api.post(path: "\(Endpoints.Recipes.base)/parse-url", body: body)
    }
}
