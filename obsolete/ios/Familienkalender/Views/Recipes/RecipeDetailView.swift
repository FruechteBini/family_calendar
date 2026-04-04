import SwiftUI

struct RecipeDetailView: View {
    let recipe: RecipeResponse
    @Bindable var viewModel: RecipeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showEditForm = false
    @State private var showDeleteAlert = false
    @State private var history: [CookingHistoryEntry] = []
    @State private var historyLoaded = false

    private var groupedIngredients: [(IngredientCategory, [IngredientResponse])] {
        let groups = Dictionary(grouping: recipe.ingredients) { $0.categoryEnum }
        return IngredientCategory.allCases.compactMap { cat in
            guard let items = groups[cat], !items.isEmpty else { return nil }
            return (cat, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerImage
                contentSection
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditForm = true
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            RecipeFormView(viewModel: viewModel, recipe: recipe)
        }
        .alert("Rezept löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                Task {
                    await viewModel.deleteRecipe(id: recipe.id)
                    dismiss()
                }
            }
        } message: {
            Text("Möchtest du „\(recipe.title)" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .task {
            guard !historyLoaded else { return }
            history = await viewModel.getHistory(recipeId: recipe.id)
            historyLoaded = true
        }
    }

    // MARK: - Header Image

    private var headerImage: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = recipe.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16 / 9, contentMode: .fill)
                    case .failure:
                        imagePlaceholder
                    default:
                        imagePlaceholder
                            .overlay { ProgressView().tint(.white) }
                    }
                }
                .frame(height: 220)
                .clipped()
            } else {
                imagePlaceholder
            }

            LinearGradient(
                colors: [.black.opacity(0.5), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
        }
        .frame(height: 220)
        .clipped()
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 220)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(.systemGray3))
            }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(recipe.title)
                    .font(.title2)
                    .fontWeight(.bold)

                infoRow
            }

            if !recipe.ingredients.isEmpty {
                ingredientsSection
            }

            if let instructions = recipe.instructions, !instructions.isEmpty {
                instructionsSection(instructions)
            }

            if let notes = recipe.notes, !notes.isEmpty {
                notesSection(notes)
            }

            historySection
        }
        .padding(20)
    }

    // MARK: - Info Row

    private var infoRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                DifficultyBadge(difficulty: recipe.difficultyEnum)

                infoPill(icon: "fork.knife", text: "\(recipe.servings) Portionen")

                if let prepTime = recipe.formattedPrepTime {
                    infoPill(icon: "clock", text: prepTime)
                }

                if recipe.sourceEnum != .manual {
                    Text(recipe.sourceEnum.displayName)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            recipe.sourceEnum == .cookidoo ? Color(hex: "#36B37E") : .appPrimary,
                            in: Capsule()
                        )
                }
            }
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6), in: Capsule())
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Zutaten")

            ForEach(groupedIngredients, id: \.0) { category, ingredients in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(category.icon)
                            .font(.subheadline)
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 4)

                    ForEach(ingredients) { ingredient in
                        HStack(spacing: 0) {
                            Circle()
                                .fill(.appPrimary.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .padding(.trailing, 10)

                            if let amount = ingredient.amount {
                                Text(formatAmount(amount))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 50, alignment: .trailing)
                                    .padding(.trailing, 4)
                            }

                            if let unit = ingredient.unit, !unit.isEmpty {
                                Text(unit)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .leading)
                            }

                            Text(ingredient.name)
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func formatAmount(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Instructions

    private func instructionsSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Zubereitung")

            Text(text)
                .font(.subheadline)
                .lineSpacing(4)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Notes

    private func notesSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Notizen")

            Text(text)
                .font(.subheadline)
                .lineSpacing(3)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Kochhistorie")

            if !historyLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else if history.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .foregroundStyle(.appSecondary)
                    Text("Noch nie gekocht")
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(history) { entry in
                    historyRow(entry)
                }
            }
        }
    }

    private func historyRow(_ entry: CookingHistoryEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.caption)
                .foregroundStyle(.appWarning)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(formatHistoryDate(entry.cookedAt))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(entry.servingsCooked) Portionen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let rating = entry.rating, rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(star <= rating ? .appWarning : Color(.systemGray4))
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    private func formatHistoryDate(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        let date = isoFormatter.date(from: iso) ?? fallbackFormatter.date(from: iso)
        guard let date else { return iso }

        let display = DateFormatter()
        display.locale = Locale(identifier: "de_DE")
        display.dateStyle = .medium
        return display.string(from: date)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
    }
}
