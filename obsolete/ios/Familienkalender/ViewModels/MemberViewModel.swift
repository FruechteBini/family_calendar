import Foundation

@Observable
@MainActor
final class MemberViewModel {

    // MARK: - State

    var members: [FamilyMemberResponse] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let memberRepo: MemberRepository

    init(memberRepo: MemberRepository) {
        self.memberRepo = memberRepo
    }

    // MARK: - Load

    func loadMembers() async {
        isLoading = true
        errorMessage = nil
        do {
            members = try await memberRepo.list()
        } catch {
            errorMessage = "Familienmitglieder konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - CRUD

    func createMember(_ body: FamilyMemberCreate) async {
        errorMessage = nil
        do {
            let created = try await memberRepo.create(body)
            members.append(created)
        } catch {
            errorMessage = "Mitglied konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }

    func updateMember(id: Int, _ body: FamilyMemberUpdate) async {
        errorMessage = nil
        do {
            let updated = try await memberRepo.update(id: id, body)
            if let idx = members.firstIndex(where: { $0.id == id }) {
                members[idx] = updated
            }
        } catch {
            errorMessage = "Mitglied konnte nicht aktualisiert werden: \(error.localizedDescription)"
        }
    }

    func deleteMember(id: Int) async {
        errorMessage = nil
        do {
            try await memberRepo.delete(id: id)
            members.removeAll { $0.id == id }
        } catch {
            errorMessage = "Mitglied konnte nicht geloescht werden: \(error.localizedDescription)"
        }
    }
}
