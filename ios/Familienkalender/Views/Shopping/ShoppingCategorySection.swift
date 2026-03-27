import SwiftUI

struct ShoppingCategorySection: View {
    let sectionName: String
    let icon: String
    let items: [ShoppingItemResponse]
    let onCheck: (Int) async -> Void
    let onDelete: (Int) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            ForEach(items) { item in
                ShoppingItemRow(
                    item: item,
                    onCheck: { Task { await onCheck(item.id) } },
                    onDelete: { Task { await onDelete(item.id) } }
                )
                .padding(.horizontal, 16)

                if item.id != items.last?.id {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.title3)

            Text(sectionName)
                .font(.subheadline)
                .fontWeight(.bold)

            Spacer()

            Text("\(items.count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.appSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(.systemGray5), in: Capsule())
        }
    }
}

// MARK: - Shopping Item Row

struct ShoppingItemRow: View {
    let item: ShoppingItemResponse
    let onCheck: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCheck) {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.checked ? .appSuccess : Color(.systemGray3))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            Text(item.name)
                .font(.subheadline)
                .strikethrough(item.checked)
                .foregroundStyle(item.checked ? .secondary : .primary)

            Spacer()

            if let amount = item.amount, !amount.isEmpty {
                HStack(spacing: 2) {
                    Text(amount)
                    if let unit = item.unit, !unit.isEmpty {
                        Text(unit)
                    }
                }
                .font(.caption)
                .foregroundStyle(.appSecondary)
            }

            if item.source == "manual" {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.appDanger.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onCheck)
    }
}
