import Foundation

enum Priority: String, Codable, CaseIterable {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low: "Niedrig"
        case .medium: "Mittel"
        case .high: "Hoch"
        }
    }

    var color: String {
        switch self {
        case .low: "#6B778C"
        case .medium: "#FF8B00"
        case .high: "#DE350B"
        }
    }
}

struct TodoCreate: Codable {
    let title: String
    var description: String?
    var priority: String = "medium"
    var dueDate: String?
    var categoryId: Int?
    var eventId: Int?
    var parentId: Int?
    var requiresMultiple: Bool = false
    var memberIds: [Int] = []
}

struct TodoUpdate: Codable {
    var title: String?
    var description: String?
    var priority: String?
    var dueDate: String?
    var categoryId: Int?
    var eventId: Int?
    var requiresMultiple: Bool?
    var memberIds: [Int]?
}

struct SubtodoResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let completed: Bool
    let completedAt: String?
    let createdAt: String
}

struct TodoResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let priority: String
    let dueDate: String?
    let completed: Bool
    let completedAt: String?
    let category: CategoryResponse?
    let eventId: Int?
    let parentId: Int?
    let requiresMultiple: Bool
    let members: [FamilyMemberResponse]
    let subtodos: [SubtodoResponse]
    let createdAt: String
    let updatedAt: String

    var priorityEnum: Priority {
        Priority(rawValue: priority) ?? .medium
    }
}
