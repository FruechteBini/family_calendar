import SwiftUI

struct SlotCellView: View {
    let label: String
    let icon: String
    let slot: MealSlotResponse?
    let onAssign: () -> Void
    let onMarkCooked: () -> Void
    let onClear: () -> Void

    var body: some View {
        Group {
            if let slot {
                filledCell(slot)
            } else {
                emptyCell
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 72)
    }

    // MARK: - Empty

    private var emptyCell: some View {
        Button(action: onAssign) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.appSecondary.opacity(0.6))

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.appPrimary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 72)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Color(.systemGray4))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filled

    private func filledCell(_ meal: MealSlotResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.appSecondary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)

                Spacer()

                if meal.servingsPlanned > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "person.2")
                            .font(.system(size: 8))
                        Text("\(meal.servingsPlanned)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.appSecondary)
                }
            }

            HStack(spacing: 8) {
                if let urlString = meal.recipe.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            recipeImagePlaceholder
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.recipe.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    DifficultyBadge(difficulty: meal.recipe.difficultyEnum)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button {
                onMarkCooked()
            } label: {
                Label("Als gekocht markieren", systemImage: "checkmark.circle")
            }

            Button(role: .destructive) {
                onClear()
            } label: {
                Label("Slot leeren", systemImage: "xmark.circle")
            }
        }
    }

    private var recipeImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.systemGray3))
            }
    }
}
