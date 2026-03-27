import Foundation

struct EventCreate: Codable {
    let title: String
    let description: String?
    let start: String
    let end: String
    var allDay: Bool = false
    let categoryId: Int?
    var memberIds: [Int] = []
}

struct EventUpdate: Codable {
    var title: String?
    var description: String?
    var start: String?
    var end: String?
    var allDay: Bool?
    var categoryId: Int?
    var memberIds: [Int]?
}

struct EventResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let start: String
    let end: String
    let allDay: Bool
    let category: CategoryResponse?
    let members: [FamilyMemberResponse]
    let todos: [EventTodoResponse]?
    let createdAt: String
    let updatedAt: String
}

struct EventTodoResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let completed: Bool
    let priority: String
}
