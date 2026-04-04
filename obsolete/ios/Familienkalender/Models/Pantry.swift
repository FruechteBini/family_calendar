import Foundation

struct PantryItemCreate: Codable {
    let name: String
    var amount: Double?
    var unit: String?
    var category: String = "sonstiges"
    var expiryDate: String?
    var minStock: Double?
}

struct PantryItemUpdate: Codable {
    var name: String?
    var amount: Double?
    var unit: String?
    var category: String?
    var expiryDate: String?
    var minStock: Double?
}

struct PantryBulkAddRequest: Codable {
    let items: [PantryItemCreate]
}

struct PantryItemResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let amount: Double?
    let unit: String?
    let category: String
    let expiryDate: String?
    let minStock: Double?
    let isLowStock: Bool
    let isExpiringSoon: Bool
    let createdAt: String
    let updatedAt: String

    var categoryEnum: IngredientCategory {
        IngredientCategory(apiValue: category) ?? .sonstiges
    }

    var isDepleted: Bool {
        isLowStock && (amount ?? 1) <= 0
    }

    var formattedAmount: String? {
        guard let amount = amount else { return nil }
        let formatted = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", amount)
            : String(format: "%.1f", amount)
        if let unit = unit, !unit.isEmpty {
            return "\(formatted) \(unit)"
        }
        return formatted
    }

    var formattedExpiry: String? {
        guard let expiryDate = expiryDate,
              let date = Date.fromISODate(expiryDate) else { return nil }
        let cal = Calendar.current
        let day = cal.component(.day, from: date)
        if day == 1 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateFormat = "MMMM yyyy"
            return "ca. \(formatter.string(from: date))"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMM yyyy"
        return formatter.string(from: date)
    }
}

struct PantryAlertItem: Codable, Identifiable {
    let id: Int
    let name: String
    let amount: Double?
    let unit: String?
    let reason: String
    let expiryDate: String?

    var reasonText: String {
        if reason == "low_stock" {
            if let amount = amount {
                let formatted = amount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", amount)
                    : String(format: "%.1f", amount)
                let unitStr = unit.map { " \($0)" } ?? ""
                return "Nur noch \(formatted)\(unitStr) vorhanden"
            }
            return "Niedrig"
        } else {
            guard let expiryDate = expiryDate,
                  let date = Date.fromISODate(expiryDate) else { return "Laeuft bald ab" }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateFormat = "d. MMM yyyy"
            return "Laeuft ab: \(formatter.string(from: date))"
        }
    }
}
