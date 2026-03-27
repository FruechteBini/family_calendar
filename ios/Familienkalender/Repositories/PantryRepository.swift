import Foundation

final class PantryRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func list(category: String? = nil, search: String? = nil) async throws -> [PantryItemResponse] {
        var query: [URLQueryItem] = []
        if let c = category { query.append(.init(name: "category", value: c)) }
        if let s = search { query.append(.init(name: "search", value: s)) }
        return try await api.get(path: "\(Endpoints.Pantry.base)/", queryItems: query.isEmpty ? nil : query)
    }

    func create(_ item: PantryItemCreate) async throws -> PantryItemResponse {
        try await api.post(path: "\(Endpoints.Pantry.base)/", body: item)
    }

    func bulkAdd(_ request: PantryBulkAddRequest) async throws -> [PantryItemResponse] {
        try await api.post(path: "\(Endpoints.Pantry.base)/bulk", body: request)
    }

    func update(id: Int, _ item: PantryItemUpdate) async throws -> PantryItemResponse {
        try await api.patch(path: "\(Endpoints.Pantry.base)/\(id)", body: item)
    }

    func delete(id: Int) async throws {
        try await api.delete(path: "\(Endpoints.Pantry.base)/\(id)")
    }

    func getAlerts() async throws -> [PantryAlertItem] {
        try await api.get(path: "\(Endpoints.Pantry.base)/alerts")
    }

    func addAlertToShopping(id: Int) async throws -> [String: String] {
        try await api.post(path: "\(Endpoints.Pantry.base)/alerts/\(id)/add-to-shopping")
    }

    func dismissAlert(id: Int) async throws -> [String: String] {
        try await api.post(path: "\(Endpoints.Pantry.base)/alerts/\(id)/dismiss")
    }
}
