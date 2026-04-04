import SwiftUI

struct AssignSlotView: View {
    let date: String
    let slot: String
    let mealPlanVM: MealPlanViewModel
    let recipeVM: RecipeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var servings: Int = 4
    @State private var quickTitle = ""
    @State private var isCreating = false

    private var slotLabel: String {
        slot == "lunch" ? "Mittag" : "Abend"
    }

    private var formattedDate: String {
        guard let d = Date.fromISODate(date) else { return date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMM"
        return formatter.string(from: d)
    }

    private var filteredRecipes: [RecipeResponse] {
        if searchText.isEmpty { return recipeVM.recipes }
        let q = searchText.lowercased()
        return recipeVM.recipes.filter { $0.title.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                slotInfoHeader

                servingsSection

                searchField

                Divider()

                recipeList
            }
            .navigationTitle("Rezept zuweisen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .task { await recipeVM.loadRecipes() }
        }
    }

    // MARK: - Slot Info

    private var slotInfoHeader: some View {
        HStack {
            Image(systemName: slot == "lunch" ? "sun.max.fill" : "moon.fill")
                .foregroundStyle(.appPrimary)
            Text("\(formattedDate) · \(slotLabel)")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Servings

    private var servingsSection: some View {
        HStack {
            Text("Portionen")
                .font(.subheadline)
            Spacer()
            Stepper("\(servings)", value: $servings, in: 1...20)
                .labelsHidden()
            Text("\(servings)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 28)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.appSecondary)
            TextField("Rezept suchen…", text: $searchText)
                .font(.subheadline)
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - List

    private var recipeList: some View {
        List {
            quickRecipeSection

            Section("Rezepte (\(filteredRecipes.count))") {
                ForEach(filteredRecipes) { recipe in
                    recipeRow(recipe)
                }
            }

            if filteredRecipes.isEmpty && !searchText.isEmpty {
                Section {
                    Text("Keine Rezepte gefunden")
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Quick Recipe

    private var quickRecipeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Schnellrezept")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.appSecondary)
                    .textCase(.uppercase)

                HStack(spacing: 10) {
                    TextField("Rezeptname eingeben…", text: $quickTitle)
                        .font(.subheadline)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await createQuickRecipe() }
                    } label: {
                        Text("Erstellen & Zuweisen")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.appPrimary, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(quickTitle.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .opacity(quickTitle.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
            }
        }
    }

    // MARK: - Recipe Row

    private func recipeRow(_ recipe: RecipeResponse) -> some View {
        Button {
            Task {
                await mealPlanVM.assignSlot(
                    date: date, slot: slot,
                    recipeId: recipe.id, servings: servings
                )
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                if let urlString = recipe.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            recipePlaceholder
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    recipePlaceholder
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(recipe.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        DifficultyBadge(difficulty: recipe.difficultyEnum)

                        if let lastCooked = recipe.lastCookedAt,
                           let cookedDate = Date.fromISO(lastCooked) {
                            let days = Calendar.current.dateComponents([.day], from: cookedDate, to: .now).day ?? 0
                            Text(days == 0 ? "Heute" : "Vor \(days) T.")
                                .font(.caption2)
                                .foregroundStyle(.appSecondary)
                        } else {
                            Text("Nie gekocht")
                                .font(.caption2)
                                .foregroundStyle(.appSecondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.appPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    private var recipePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(.systemGray3))
            }
    }

    // MARK: - Quick Create

    private func createQuickRecipe() async {
        let title = quickTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        isCreating = true

        let body = RecipeCreate(title: title, servings: servings)
        let countBefore = recipeVM.recipes.count
        await recipeVM.createRecipe(body)

        if recipeVM.errorMessage == nil,
           recipeVM.recipes.count > countBefore,
           let newRecipe = recipeVM.recipes.last {
            await mealPlanVM.assignSlot(
                date: date, slot: slot,
                recipeId: newRecipe.id, servings: servings
            )
            dismiss()
        }
        isCreating = false
    }
}
