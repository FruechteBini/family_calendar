import Foundation

final class AIRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func getAvailableRecipes(weekStart: String) async throws -> AvailableRecipesResponse {
        let query = [URLQueryItem(name: "week_start", value: weekStart)]
        return try await api.get(path: "\(Endpoints.AI.base)/available-recipes", queryItems: query)
    }

    func generateMealPlan(_ request: GenerateMealPlanRequest) async throws -> PreviewMealPlanResponse {
        try await api.post(path: "\(Endpoints.AI.base)/generate-meal-plan", body: request)
    }

    func confirmMealPlan(_ request: ConfirmMealPlanRequest) async throws -> ConfirmMealPlanResponse {
        try await api.post(path: "\(Endpoints.AI.base)/confirm-meal-plan", body: request)
    }

    func undoMealPlan(_ request: UndoMealPlanRequest) async throws -> [String: AnyCodableValue] {
        try await api.post(path: "\(Endpoints.AI.base)/undo-meal-plan", body: request)
    }

    func voiceCommand(text: String) async throws -> VoiceCommandResponse {
        let body = VoiceCommandRequest(text: text)
        return try await api.post(path: "\(Endpoints.AI.base)/voice-command", body: body)
    }
}
