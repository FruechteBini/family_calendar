import Foundation

final class ProposalRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func getPending() async throws -> [PendingProposalDetail] {
        try await api.get(path: "\(Endpoints.Proposals.base)/pending")
    }

    func getForTodo(todoId: Int) async throws -> [ProposalDetail] {
        try await api.get(path: "\(Endpoints.Todos.base)/\(todoId)/proposals")
    }

    func create(todoId: Int, body: ProposalCreate) async throws -> ProposalDetail {
        try await api.post(path: "\(Endpoints.Todos.base)/\(todoId)/proposals", body: body)
    }

    func respond(proposalId: Int, body: ProposalRespondRequest) async throws -> ProposalDetail {
        try await api.post(path: "\(Endpoints.Proposals.base)/\(proposalId)/respond", body: body)
    }
}
