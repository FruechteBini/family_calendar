import Foundation

final class CategoryRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func list() async throws -> [CategoryResponse] {
        try await api.get(path: "\(Endpoints.Categories.base)/")
    }

    func create(_ category: CategoryCreate) async throws -> CategoryResponse {
        try await api.post(path: "\(Endpoints.Categories.base)/", body: category)
    }

    func update(id: Int, _ category: CategoryUpdate) async throws -> CategoryResponse {
        try await api.put(path: "\(Endpoints.Categories.base)/\(id)", body: category)
    }

    func delete(id: Int) async throws {
        try await api.delete(path: "\(Endpoints.Categories.base)/\(id)")
    }
}
