import SwiftUI

struct RecipeCardView: View {
    let recipe: RecipeResponse
    let viewModel: RecipeViewModel

    private var daysSinceCooked: String {
        guard let lastCooked = recipe.lastCookedAt else {
            return "Noch nie gekocht"
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if let date = formatter.date(from: String(lastCooked.prefix(10))) {
            let days = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
            if days == 0 { return "Heute gekocht" }
            if days == 1 { return "Gestern gekocht" }
            return "Vor \(days) Tagen gekocht"
        }
        return "Zuletzt gekocht"
    }

    var body: some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe, viewModel: viewModel)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                imageSection
                infoSection
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Image

    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            if let urlString = recipe.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(4 / 3, contentMode: .fill)
                    case .failure:
                        placeholderImage
                    default:
                        placeholderImage
                            .overlay { ProgressView().tint(.appSecondary) }
                    }
                }
                .frame(height: 120)
                .clipped()
            } else {
                placeholderImage
            }

            if recipe.sourceEnum != .manual {
                sourceBadge
                    .padding(6)
            }
        }
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 120)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(.systemGray3))
            }
    }

    private var sourceBadge: some View {
        Text(recipe.sourceEnum.displayName)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                recipe.sourceEnum == .cookidoo ? Color(hex: "#36B37E") : .appPrimary,
                in: Capsule()
            )
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipe.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                DifficultyBadge(difficulty: recipe.difficultyEnum)

                if let prepTime = recipe.formattedPrepTime {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(prepTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(daysSinceCooked)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
        }
        .padding(10)
    }
}
