import Foundation

struct SlotSelection: Codable {
    let date: String
    let slot: String
}

struct GenerateMealPlanRequest: Codable {
    let weekStart: String
    var servings: Int = 4
    var preferences: String = ""
    var selectedSlots: [SlotSelection] = []
    var includeCookidoo: Bool = false
}

struct MealSuggestion: Codable, Identifiable {
    let date: String
    let slot: String
    let recipeId: Int?
    let cookidooId: String?
    let recipeTitle: String
    let servingsPlanned: Int
    let source: String
    let difficulty: String?
    let prepTime: Int?
    var id: String { "\(date)_\(slot)" }
}

struct PreviewMealPlanResponse: Codable {
    let suggestions: [MealSuggestion]
    let reasoning: String?
}

struct ConfirmMealPlanRequest: Codable {
    let weekStart: String
    let items: [MealSuggestion]
}

struct ConfirmMealPlanResponse: Codable {
    let message: String
    let mealsCreated: Int
    let mealIds: [Int]
    let shoppingListGenerated: Bool
}

struct UndoMealPlanRequest: Codable {
    let mealIds: [Int]
}

struct AvailableRecipesResponse: Codable {
    let localCount: Int
    let localRecipes: [LocalRecipeInfo]
    let cookidooAvailable: Bool
    let cookidooCount: Int
    let filledSlots: [FilledSlotInfo]
    let emptySlots: [EmptySlotInfo]
}

struct LocalRecipeInfo: Codable, Identifiable {
    let id: Int
    let title: String
    let difficulty: String
}

struct FilledSlotInfo: Codable {
    let date: String
    let day: String
    let slot: String
    let label: String
    let recipeTitle: String
}

struct EmptySlotInfo: Codable {
    let date: String
    let day: String
    let slot: String
    let label: String
}
