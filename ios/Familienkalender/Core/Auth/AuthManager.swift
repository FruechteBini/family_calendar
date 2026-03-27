import Foundation
import Observation

// MARK: - Auth-Related Models

struct UserResponse: Codable, Sendable, Identifiable {
    let id: Int
    let username: String
    let familyId: Int?
    let family: FamilyResponse?
    let memberId: Int?
    let member: FamilyMemberResponse?
}

struct FamilyResponse: Codable, Sendable, Identifiable {
    let id: Int
    let name: String
    let inviteCode: String
    let createdAt: String
}

struct FamilyMemberResponse: Codable, Sendable, Identifiable {
    let id: Int
    let name: String
    let color: String
    let avatarEmoji: String
    let createdAt: String
}

struct RegisterRequest: Codable, Sendable {
    let username: String
    let password: String
}

struct FamilyCreateRequest: Codable, Sendable {
    let name: String
}

struct FamilyJoinRequest: Codable, Sendable {
    let inviteCode: String
}

struct LinkMemberRequest: Codable, Sendable {
    let memberId: Int
}

// MARK: - AuthManager

@Observable
@MainActor
final class AuthManager {
    var isAuthenticated = false
    var currentUser: UserResponse?
    var isLoading = false

    private let apiClient: APIClient
    private let keychainManager: KeychainManager

    init(apiClient: APIClient, keychainManager: KeychainManager) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager

        if keychainManager.loadToken() != nil {
            isAuthenticated = true
        }
    }

    func login(username: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let tokenResponse = try await apiClient.login(username: username, password: password)
        keychainManager.saveToken(tokenResponse.accessToken)
        isAuthenticated = true

        try await fetchCurrentUser()
    }

    func register(username: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let _: UserResponse = try await apiClient.post(
            path: Endpoints.Auth.register,
            body: RegisterRequest(username: username, password: password)
        )
    }

    func logout() {
        keychainManager.deleteToken()
        currentUser = nil
        isAuthenticated = false
    }

    func checkAuth() async {
        guard keychainManager.loadToken() != nil else {
            isAuthenticated = false
            return
        }

        do {
            try await fetchCurrentUser()
            isAuthenticated = true
        } catch {
            if error is APIError, case .unauthorized = error as! APIError {
                logout()
            }
        }
    }

    func createFamily(name: String) async throws -> FamilyResponse {
        isLoading = true
        defer { isLoading = false }

        let family: FamilyResponse = try await apiClient.post(
            path: Endpoints.Auth.family,
            body: FamilyCreateRequest(name: name)
        )

        try await fetchCurrentUser()
        return family
    }

    func joinFamily(inviteCode: String) async throws -> FamilyResponse {
        isLoading = true
        defer { isLoading = false }

        let family: FamilyResponse = try await apiClient.post(
            path: Endpoints.Auth.familyJoin,
            body: FamilyJoinRequest(inviteCode: inviteCode)
        )

        try await fetchCurrentUser()
        return family
    }

    func linkMember(memberId: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        let user: UserResponse = try await apiClient.patch(
            path: Endpoints.Auth.linkMember,
            body: LinkMemberRequest(memberId: memberId)
        )
        currentUser = user
    }

    private func fetchCurrentUser() async throws {
        let user: UserResponse = try await apiClient.get(path: Endpoints.Auth.me)
        currentUser = user
    }
}
