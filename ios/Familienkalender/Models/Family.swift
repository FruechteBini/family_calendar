import Foundation

struct FamilyCreate: Codable {
    let name: String
}

struct FamilyJoin: Codable {
    let inviteCode: String
}

struct FamilyResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let inviteCode: String
    let createdAt: String
}
