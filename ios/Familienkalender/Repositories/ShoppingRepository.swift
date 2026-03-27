import Foundation

final class ShoppingRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func getList() async throws -> ShoppingListResponse? {
        do {
            return try await api.get(path: "\(Endpoints.Shopping.base)/list") as ShoppingListResponse
        } catch let error as APIError {
            if case .notFound = error { return nil }
            throw error
        }
    }

    func generate(weekStart: String) async throws -> ShoppingListResponse {
        let body = GenerateShoppingRequest(weekStart: weekStart)
        return try await api.post(path: "\(Endpoints.Shopping.base)/generate", body: body)
    }

    func addItem(_ item: ShoppingItemCreate) async throws -> ShoppingItemResponse {
        try await api.post(path: "\(Endpoints.Shopping.base)/items", body: item)
    }

    func checkItem(id: Int) async throws -> ShoppingItemResponse {
        try await api.patch(path: "\(Endpoints.Shopping.base)/items/\(id)/check")
    }

    func deleteItem(id: Int) async throws {
        try await api.delete(path: "\(Endpoints.Shopping.base)/items/\(id)")
    }

    func sort() async throws -> ShoppingListResponse {
        try await api.post(path: "\(Endpoints.Shopping.base)/sort")
    }

    func clearAll() async throws -> [String: AnyCodableValue] {
        try await api.post(path: "\(Endpoints.Shopping.base)/clear-all")
    }
}
