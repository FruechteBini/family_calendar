import Foundation

@Observable
@MainActor
final class ProposalViewModel {

    // MARK: - State

    var pendingProposals: [PendingProposalDetail] = []
    var todoProposals: [ProposalDetail] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let proposalRepo: ProposalRepository

    init(proposalRepo: ProposalRepository) {
        self.proposalRepo = proposalRepo
    }

    // MARK: - Load

    func loadPending() async {
        isLoading = true
        errorMessage = nil
        do {
            pendingProposals = try await proposalRepo.getPending()
        } catch {
            errorMessage = "Offene Vorschlaege konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadForTodo(todoId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            todoProposals = try await proposalRepo.getForTodo(todoId: todoId)
        } catch {
            errorMessage = "Vorschlaege konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Actions

    func createProposal(todoId: Int, date: String, message: String?) async {
        errorMessage = nil
        let body = ProposalCreate(proposedDate: date, message: message)
        do {
            let created = try await proposalRepo.create(todoId: todoId, body: body)
            todoProposals.append(created)
        } catch {
            errorMessage = "Vorschlag konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }

    func respond(proposalId: Int, response: String, message: String?, counterDate: String?) async {
        errorMessage = nil
        let body = ProposalRespondRequest(
            response: response,
            message: message,
            counterDate: counterDate
        )
        do {
            let updated = try await proposalRepo.respond(proposalId: proposalId, body: body)
            if let idx = todoProposals.firstIndex(where: { $0.id == proposalId }) {
                todoProposals[idx] = updated
            }
            if let idx = pendingProposals.firstIndex(where: { $0.id == proposalId }) {
                pendingProposals.remove(at: idx)
            }
        } catch {
            errorMessage = "Antwort konnte nicht gesendet werden: \(error.localizedDescription)"
        }
    }
}
