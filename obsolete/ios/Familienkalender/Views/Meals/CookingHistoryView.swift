import SwiftUI

struct CookingHistoryView: View {
    let viewModel: MealPlanViewModel

    var body: some View {
        Group {
            if viewModel.cookingHistory.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "Noch keine Einträge",
                    subtitle: "Sobald du Gerichte als gekocht markierst, erscheinen sie hier."
                )
            } else {
                historyList
            }
        }
        .navigationTitle("Kochhistorie")
        .loadingOverlay(isLoading: viewModel.isLoading)
        .task { await viewModel.loadHistory(limit: 50) }
    }

    private var historyList: some View {
        List(viewModel.cookingHistory) { entry in
            historyRow(entry)
        }
        .listStyle(.insetGrouped)
    }

    private func historyRow(_ entry: CookingHistoryEntry) -> some View {
        HStack(spacing: 12) {
            recipeImage(entry)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.recipeTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let diff = entry.recipeDifficulty,
                       let difficulty = Difficulty(rawValue: diff) {
                        DifficultyBadge(difficulty: difficulty)
                    }

                    HStack(spacing: 3) {
                        Image(systemName: "person.2")
                            .font(.system(size: 10))
                        Text("\(entry.servingsCooked)")
                            .font(.caption)
                    }
                    .foregroundStyle(.appSecondary)
                }

                Text(formattedDate(entry.cookedAt))
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }

            Spacer()

            if let rating = entry.rating, rating > 0 {
                ratingView(rating)
            }
        }
        .padding(.vertical, 4)
    }

    private func recipeImage(_ entry: CookingHistoryEntry) -> some View {
        Group {
            if let urlString = entry.recipeImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(.systemGray3))
            }
    }

    private func ratingView(_ rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(star <= rating ? .yellow : Color(.systemGray4))
            }
        }
    }

    private func formattedDate(_ isoString: String) -> String {
        guard let date = Date.fromISO(isoString) else {
            if let d = Date.fromISODate(String(isoString.prefix(10))) {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "de_DE")
                formatter.dateFormat = "d. MMMM yyyy"
                return formatter.string(from: d)
            }
            return isoString
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
