import SwiftUI

struct RecipeListView: View {
    @Bindable var viewModel: RecipeViewModel

    @State private var showAddForm = false
    @State private var columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.filteredRecipes.isEmpty && !viewModel.isLoading {
                    if viewModel.searchText.isEmpty && viewModel.filterDifficulty == nil && viewModel.filterSource == nil {
                        EmptyStateView(
                            icon: "book.closed",
                            title: "Keine Rezepte",
                            subtitle: "Erstelle dein erstes Rezept oder importiere eines per URL.",
                            buttonTitle: "Rezept erstellen"
                        ) {
                            showAddForm = true
                        }
                    } else {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "Keine Treffer",
                            subtitle: "Kein Rezept passt zu deinen Filtern. Passe die Suche oder Filter an."
                        )
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            filterChips
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(viewModel.filteredRecipes) { recipe in
                                    RecipeCardView(recipe: recipe, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    .refreshable {
                        await viewModel.loadRecipes()
                    }
                }
            }
            .navigationTitle("Rezepte")
            .searchable(text: $viewModel.searchText, prompt: "Rezept suchen…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddForm) {
                RecipeFormView(viewModel: viewModel, recipe: nil)
            }
            .loadingOverlay(isLoading: viewModel.isLoading, message: "Rezepte laden…")
            .task {
                if viewModel.recipes.isEmpty {
                    await viewModel.loadRecipes()
                }
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Schwierigkeit:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    chipButton(
                        title: "Alle",
                        isSelected: viewModel.filterDifficulty == nil
                    ) {
                        viewModel.filterDifficulty = nil
                    }

                    ForEach(Difficulty.allCases, id: \.self) { diff in
                        chipButton(
                            title: diff.displayName,
                            isSelected: viewModel.filterDifficulty == diff,
                            activeColor: Color(hex: diff.color)
                        ) {
                            viewModel.filterDifficulty = viewModel.filterDifficulty == diff ? nil : diff
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Quelle:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    chipButton(
                        title: "Alle",
                        isSelected: viewModel.filterSource == nil
                    ) {
                        viewModel.filterSource = nil
                    }

                    ForEach([RecipeSource.manual, .cookidoo, .web], id: \.self) { src in
                        chipButton(
                            title: src.displayName,
                            isSelected: viewModel.filterSource == src
                        ) {
                            viewModel.filterSource = viewModel.filterSource == src ? nil : src
                        }
                    }
                }
            }
        }
    }

    private func chipButton(
        title: String,
        isSelected: Bool,
        activeColor: Color = .appPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? activeColor.opacity(0.15) : Color(.systemGray6),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? activeColor : .primary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? activeColor.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            Button {
                viewModel.sortBy = "title"
                Task { await viewModel.loadRecipes() }
            } label: {
                Label("Nach Titel", systemImage: viewModel.sortBy == "title" ? "checkmark" : "")
            }
            Button {
                viewModel.sortBy = "last_cooked"
                Task { await viewModel.loadRecipes() }
            } label: {
                Label("Zuletzt gekocht", systemImage: viewModel.sortBy == "last_cooked" ? "checkmark" : "")
            }
            Button {
                viewModel.sortBy = "cook_count"
                Task { await viewModel.loadRecipes() }
            } label: {
                Label("Häufigkeit", systemImage: viewModel.sortBy == "cook_count" ? "checkmark" : "")
            }
            Button {
                viewModel.sortBy = "prep_time"
                Task { await viewModel.loadRecipes() }
            } label: {
                Label("Zubereitungszeit", systemImage: viewModel.sortBy == "prep_time" ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}
