import Foundation

final class TodoRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func list(completed: Bool? = nil, priority: String? = nil, memberId: Int? = nil, categoryId: Int? = nil) async throws -> [TodoResponse] {
        var query: [URLQueryItem] = []
        if let c = completed { query.append(.init(name: "completed", value: String(c))) }
        if let p = priority { query.append(.init(name: "priority", value: p)) }
        if let m = memberId { query.append(.init(name: "member_id", value: String(m))) }
        if let c = categoryId { query.append(.init(name: "category_id", value: String(c))) }
        return try await api.get(path: "\(Endpoints.Todos.base)/", queryItems: query.isEmpty ? nil : query)
    }

    func get(id: Int) async throws -> TodoResponse {
        try await api.get(path: "\(Endpoints.Todos.base)/\(id)")
    }

    func create(_ todo: TodoCreate) async throws -> TodoResponse {
        try await api.post(path: "\(Endpoints.Todos.base)/", body: todo)
    }

    func update(id: Int, _ todo: TodoUpdate) async throws -> TodoResponse {
        try await api.put(path: "\(Endpoints.Todos.base)/\(id)", body: todo)
    }

    func complete(id: Int) async throws -> TodoResponse {
        try await api.patch(path: "\(Endpoints.Todos.base)/\(id)/complete")
    }

    func linkEvent(todoId: Int, eventId: Int) async throws -> TodoResponse {
        let body = ["event_id": eventId]
        return try await api.patch(path: "\(Endpoints.Todos.base)/\(todoId)/link-event", body: body)
    }

    func delete(id: Int) async throws {
        try await api.delete(path: "\(Endpoints.Todos.base)/\(id)")
    }
}
