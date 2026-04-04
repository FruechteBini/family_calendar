import Foundation

struct MealSlotUpdate: Codable {
    let recipeId: Int
    var servingsPlanned: Int = 4
}

struct MarkCookedRequest: Codable {
    let servingsCooked: Int?
    let rating: Int?
    let notes: String?
}

struct PantryDeduction: Codable, Identifiable {
    let pantryItemId: Int
    let name: String
    let deducted: Double
    let unit: String?
    let remaining: Double?
    var id: Int { pantryItemId }
}

struct MarkCookedResponse: Codable {
    let message: String
    let historyId: Int
    let pantryDeductions: [PantryDeduction]?
}

struct MealSlotResponse: Codable, Identifiable {
    let id: Int
    let planDate: String
    let slot: String
    let recipeId: Int
    let servingsPlanned: Int
    let recipe: RecipeResponse
    let createdAt: String
    let updatedAt: String
}

struct DayPlan: Codable, Identifiable {
    let date: String
    let weekday: String
    let lunch: MealSlotResponse?
    let dinner: MealSlotResponse?
    var id: String { date }
}

struct WeekPlanResponse: Codable {
    let weekStart: String
    let days: [DayPlan]
}

struct CookingHistoryEntry: Codable, Identifiable {
    let id: Int
    let recipeId: Int
    let recipeTitle: String
    let recipeDifficulty: String?
    let recipeImageUrl: String?
    let cookedAt: String
    let servingsCooked: Int
    let rating: Int?
}
