import Foundation

struct FamilyMemberCreate: Codable {
    let name: String
    var color: String = "#0052CC"
    var avatarEmoji: String = "👤"
}

struct FamilyMemberUpdate: Codable {
    var name: String?
    var color: String?
    var avatarEmoji: String?
}

struct FamilyMemberResponse: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String
    let avatarEmoji: String
    let createdAt: String
}
