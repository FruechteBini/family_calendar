import SwiftUI

struct PantryItemRow: View {
    let item: PantryItemResponse

    private var statusColor: Color {
        if item.isDepleted { return .appDanger }
        if item.isLowStock { return .appWarning }
        return .appSuccess
    }

    private var statusIcon: String {
        if item.isDepleted { return "exclamationmark.circle.fill" }
        if item.isLowStock { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let formatted = item.formattedAmount {
                        Text(formatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Menge unbekannt")
                            .font(.caption)
                            .foregroundStyle(Color(.systemGray3))
                            .italic()
                    }

                    if let minStock = item.minStock {
                        let formatted = minStock.truncatingRemainder(dividingBy: 1) == 0
                            ? String(format: "%.0f", minStock)
                            : String(format: "%.1f", minStock)
                        Text("Min: \(formatted)")
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color(.systemGray6), in: Capsule())
                    }
                }
            }

            Spacer()

            if let expiry = item.formattedExpiry {
                HStack(spacing: 3) {
                    Image(systemName: item.isExpiringSoon ? "exclamationmark.triangle.fill" : "calendar")
                        .font(.system(size: 10))
                    Text(expiry)
                        .font(.caption2)
                }
                .foregroundStyle(item.isExpiringSoon ? .appWarning : .appSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (item.isExpiringSoon ? Color.appWarning : Color(.systemGray5)).opacity(0.15),
                    in: Capsule()
                )
            }
        }
        .padding(.vertical, 4)
    }
}
