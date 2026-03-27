import Foundation

struct CookidooStatusResponse: Codable {
    let available: Bool
}

struct CookidooCollection: Codable, Identifiable {
    let id: String
    let name: String
    let chapters: [CookidooChapter]
}

struct CookidooChapter: Codable, Identifiable {
    let name: String
    let recipes: [CookidooRecipeSummary]
    var id: String { name }
}

struct CookidooRecipeSummary: Codable, Identifiable {
    let cookidooId: String
    let name: String
    var id: String { cookidooId }
}
