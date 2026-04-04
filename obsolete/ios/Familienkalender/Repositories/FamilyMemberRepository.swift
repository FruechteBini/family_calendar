import Foundation

typealias MemberRepository = FamilyMemberRepository

final class FamilyMemberRepository: Sendable {
    private let api: APIClient

    init(apiClient: APIClient) { self.api = apiClient }

    func list() async throws -> [FamilyMemberResponse] {
        try await api.get(path: "\(Endpoints.FamilyMembers.base)/")
    }

    func create(_ member: FamilyMemberCreate) async throws -> FamilyMemberResponse {
        try await api.post(path: "\(Endpoints.FamilyMembers.base)/", body: member)
    }

    func update(id: Int, _ member: FamilyMemberUpdate) async throws -> FamilyMemberResponse {
        try await api.put(path: "\(Endpoints.FamilyMembers.base)/\(id)", body: member)
    }

    func delete(id: Int) async throws {
        try await api.delete(path: "\(Endpoints.FamilyMembers.base)/\(id)")
    }
}
