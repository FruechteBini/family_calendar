import Foundation

final class EventRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func list(dateFrom: String? = nil, dateTo: String? = nil, memberId: Int? = nil, categoryId: Int? = nil) async throws -> [EventResponse] {
        var query: [URLQueryItem] = []
        if let d = dateFrom { query.append(.init(name: "date_from", value: d)) }
        if let d = dateTo { query.append(.init(name: "date_to", value: d)) }
        if let m = memberId { query.append(.init(name: "member_id", value: String(m))) }
        if let c = categoryId { query.append(.init(name: "category_id", value: String(c))) }
        return try await api.get(path: "\(Endpoints.Events.base)/", queryItems: query.isEmpty ? nil : query)
    }

    func get(id: Int) async throws -> EventResponse {
        try await api.get(path: "\(Endpoints.Events.base)/\(id)")
    }

    func create(_ event: EventCreate) async throws -> EventResponse {
        try await api.post(path: "\(Endpoints.Events.base)/", body: event)
    }

    func update(id: Int, _ event: EventUpdate) async throws -> EventResponse {
        try await api.put(path: "\(Endpoints.Events.base)/\(id)", body: event)
    }

    func delete(id: Int) async throws {
        try await api.delete(path: "\(Endpoints.Events.base)/\(id)")
    }
}
