import Foundation

enum RecipeSource: String, Codable {
    case manual, cookidoo, web

    var displayName: String {
        switch self {
        case .manual: "Manuell"
        case .cookidoo: "Cookidoo"
        case .web: "Web"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard

    var displayName: String {
        switch self {
        case .easy: "Einfach"
        case .medium: "Mittel"
        case .hard: "Aufwendig"
        }
    }

    var color: String {
        switch self {
        case .easy: "#00875A"
        case .medium: "#FF8B00"
        case .hard: "#DE350B"
        }
    }
}

enum IngredientCategory: String, Codable, CaseIterable {
    case kuehlregal
    case obstGemuese
    case trockenware
    case drogerie
    case sonstiges

    var displayName: String {
        switch self {
        case .kuehlregal: "Kuehlregal"
        case .obstGemuese: "Obst & Gemuese"
        case .trockenware: "Trockenware"
        case .drogerie: "Drogerie"
        case .sonstiges: "Sonstiges"
        }
    }

    var icon: String {
        switch self {
        case .kuehlregal: "🧊"
        case .obstGemuese: "🍇"
        case .trockenware: "🍞"
        case .drogerie: "🧴"
        case .sonstiges: "📦"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "kuehlregal": self = .kuehlregal
        case "obst_gemuese": self = .obstGemuese
        case "trockenware": self = .trockenware
        case "drogerie": self = .drogerie
        case "sonstiges": self = .sonstiges
        default: self = .sonstiges
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .kuehlregal: try container.encode("kuehlregal")
        case .obstGemuese: try container.encode("obst_gemuese")
        case .trockenware: try container.encode("trockenware")
        case .drogerie: try container.encode("drogerie")
        case .sonstiges: try container.encode("sonstiges")
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "kuehlregal": self = .kuehlregal
        case "obst_gemuese": self = .obstGemuese
        case "trockenware": self = .trockenware
        case "drogerie": self = .drogerie
        case "sonstiges": self = .sonstiges
        default: return nil
        }
    }

    var apiValue: String {
        switch self {
        case .kuehlregal: return "kuehlregal"
        case .obstGemuese: return "obst_gemuese"
        case .trockenware: return "trockenware"
        case .drogerie: return "drogerie"
        case .sonstiges: return "sonstiges"
        }
    }
}

struct IngredientCreate: Codable {
    let name: String
    let amount: Double?
    let unit: String?
    var category: String = "sonstiges"
}

struct IngredientResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let amount: Double?
    let unit: String?
    let category: String

    var categoryEnum: IngredientCategory {
        IngredientCategory(apiValue: category) ?? .sonstiges
    }
}

struct RecipeCreate: Codable {
    let title: String
    var source: String = "manual"
    var cookidooId: String?
    var servings: Int = 4
    var prepTimeActiveMinutes: Int?
    var prepTimePassiveMinutes: Int?
    var difficulty: String = "medium"
    var instructions: String?
    var notes: String?
    var imageUrl: String?
    var aiAccessible: Bool = true
    var ingredients: [IngredientCreate] = []
}

struct RecipeUpdate: Codable {
    var title: String?
    var servings: Int?
    var prepTimeActiveMinutes: Int?
    var prepTimePassiveMinutes: Int?
    var difficulty: String?
    var instructions: String?
    var notes: String?
    var imageUrl: String?
    var aiAccessible: Bool?
    var ingredients: [IngredientCreate]?
}

struct RecipeResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let source: String
    let cookidooId: String?
    let servings: Int
    let prepTimeActiveMinutes: Int?
    let prepTimePassiveMinutes: Int?
    let difficulty: String
    let lastCookedAt: String?
    let cookCount: Int
    let instructions: String?
    let notes: String?
    let imageUrl: String?
    let aiAccessible: Bool
    let ingredients: [IngredientResponse]
    let createdAt: String
    let updatedAt: String

    var difficultyEnum: Difficulty {
        Difficulty(rawValue: difficulty) ?? .medium
    }

    var sourceEnum: RecipeSource {
        RecipeSource(rawValue: source) ?? .manual
    }

    var formattedPrepTime: String? {
        let active = prepTimeActiveMinutes ?? 0
        let passive = prepTimePassiveMinutes ?? 0
        if active == 0 && passive == 0 { return nil }
        if passive == 0 { return "\(active) Min." }
        return "\(active) Min. aktiv, \(passive) Min. passiv"
    }
}

struct RecipeSuggestion: Codable, Identifiable {
    let id: Int
    let title: String
    let difficulty: String
    let prepTimeActiveMinutes: Int?
    let lastCookedAt: String?
    let cookCount: Int
    let daysSinceCooked: Int?
}

struct UrlParseRequest: Codable {
    let url: String
}

struct UrlImportPreview: Codable {
    let title: String?
    let servings: Int?
    let prepTimeActiveMinutes: Int?
    let prepTimePassiveMinutes: Int?
    let difficulty: String?
    let instructions: String?
    let imageUrl: String?
    let ingredients: [IngredientCreate]?
}
