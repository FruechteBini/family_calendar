import Foundation

struct CategoryCreate: Codable {
    let name: String
    var color: String = "#0052CC"
    var icon: String = "📁"
}

struct CategoryUpdate: Codable {
    var name: String?
    var color: String?
    var icon: String?
}

struct CategoryResponse: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String
    let icon: String
}
