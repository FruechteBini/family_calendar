import Foundation

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
}

struct UserResponse: Codable, Identifiable {
    let id: Int
    let username: String
    let familyId: Int?
    let family: FamilyResponse?
    let memberId: Int?
    let member: FamilyMemberResponse?
}

struct LinkMemberRequest: Codable {
    let memberId: Int
}
