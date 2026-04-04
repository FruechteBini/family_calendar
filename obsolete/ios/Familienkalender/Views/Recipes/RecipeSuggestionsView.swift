import SwiftUI

struct RecipeSuggestionsView: View {
    @Bindable var viewModel: RecipeViewModel

    var body: some View {
        Group {
            if viewModel.suggestions.isEmpty {
                EmptyStateView(
                    icon: "sparkles",
                    title: "Keine Vorschläge",
                    subtitle: "Alle Rezepte werden regelmäßig gekocht!"
                )
            } else {
                List(viewModel.suggestions) { suggestion in
                    NavigationLink {
                        if let recipe = viewModel.recipes.first(where: { $0.id == suggestion.id }) {
                            RecipeDetailView(recipe: recipe, viewModel: viewModel)
                        } else {
                            recipeNotLoadedView(for: suggestion)
                        }
                    } label: {
                        suggestionRow(suggestion)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Rezeptvorschläge")
        .task {
            await viewModel.loadSuggestions()
            if viewModel.recipes.isEmpty {
                await viewModel.loadRecipes()
            }
        }
    }

    // MARK: - Suggestion Row

    private func suggestionRow(_ suggestion: RecipeSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion.title)
                .font(.body)
                .fontWeight(.bold)
                .lineLimit(2)

            HStack(spacing: 10) {
                if let diff = Difficulty(rawValue: suggestion.difficulty) {
                    DifficultyBadge(difficulty: diff)
                }

                if let minutes = suggestion.prepTimeActiveMinutes {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(minutes) Min.")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                cookCountBadge(suggestion.cookCount)
            }

            Text(cookedAgoText(suggestion))
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .padding(.vertical, 4)
    }

    private func cookCountBadge(_ count: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.caption2)
            Text("\(count)×")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(count == 0 ? .appSecondary : .appWarning)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            (count == 0 ? Color.appSecondary : Color.appWarning).opacity(0.12),
            in: Capsule()
        )
    }

    private func cookedAgoText(_ suggestion: RecipeSuggestion) -> String {
        if let days = suggestion.daysSinceCooked {
            if days == 0 { return "Heute gekocht" }
            if days == 1 { return "Gestern gekocht" }
            return "Zuletzt vor \(days) Tagen gekocht"
        }
        return "Noch nie gekocht"
    }

    private func recipeNotLoadedView(for suggestion: RecipeSuggestion) -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Rezept wird geladen…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(suggestion.title)
    }
}
