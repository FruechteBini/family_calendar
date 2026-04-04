import Foundation

final class MealPlanRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func getWeekPlan(week: String) async throws -> WeekPlanResponse {
        let query = [URLQueryItem(name: "week", value: week)]
        return try await api.get(path: "\(Endpoints.Meals.base)/plan", queryItems: query)
    }

    func setSlot(date: String, slot: String, body: MealSlotUpdate) async throws -> MealSlotResponse {
        try await api.put(path: "\(Endpoints.Meals.base)/plan/\(date)/\(slot)", body: body)
    }

    func clearSlot(date: String, slot: String) async throws {
        try await api.delete(path: "\(Endpoints.Meals.base)/plan/\(date)/\(slot)")
    }

    func markCooked(date: String, slot: String, body: MarkCookedRequest) async throws -> MarkCookedResponse {
        try await api.patch(path: "\(Endpoints.Meals.base)/plan/\(date)/\(slot)/done", body: body)
    }

    func getHistory(limit: Int? = nil) async throws -> [CookingHistoryEntry] {
        var query: [URLQueryItem] = []
        if let l = limit { query.append(.init(name: "limit", value: String(l))) }
        return try await api.get(path: "\(Endpoints.Meals.base)/history", queryItems: query.isEmpty ? nil : query)
    }
}
