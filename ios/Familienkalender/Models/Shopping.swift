import Foundation

struct ShoppingItemCreate: Codable {
    let name: String
    var amount: String?
    var unit: String?
    var category: String = "sonstiges"
}

struct ShoppingItemResponse: Codable, Identifiable {
    let id: Int
    let shoppingListId: Int
    let name: String
    let amount: String?
    let unit: String?
    let category: String
    let checked: Bool
    let source: String
    let recipeId: Int?
    let aiAccessible: Bool
    let sortOrder: Int?
    let storeSection: String?
    let createdAt: String
    let updatedAt: String
}

struct ShoppingListResponse: Codable, Identifiable {
    let id: Int
    let weekStartDate: String
    let status: String
    let sortedByStore: String?
    let items: [ShoppingItemResponse]
    let createdAt: String
}

struct GenerateShoppingRequest: Codable {
    let weekStart: String
}
