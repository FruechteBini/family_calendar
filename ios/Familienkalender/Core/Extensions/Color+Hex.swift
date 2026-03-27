import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let length = cleaned.count
        switch length {
        case 6:
            self.init(
                red: Double((rgb >> 16) & 0xFF) / 255.0,
                green: Double((rgb >> 8) & 0xFF) / 255.0,
                blue: Double(rgb & 0xFF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb >> 24) & 0xFF) / 255.0,
                green: Double((rgb >> 16) & 0xFF) / 255.0,
                blue: Double((rgb >> 8) & 0xFF) / 255.0,
                opacity: Double(rgb & 0xFF) / 255.0
            )
        default:
            self.init(red: 0, green: 0, blue: 0)
        }
    }

    static let appPrimary = Color(hex: "#0052CC")
    static let appSuccess = Color(hex: "#00875A")
    static let appDanger = Color(hex: "#DE350B")
    static let appWarning = Color(hex: "#FF8B00")
    static let appSecondary = Color(hex: "#6B778C")
}
