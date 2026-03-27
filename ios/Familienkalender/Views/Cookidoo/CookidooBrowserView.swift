import SwiftUI

struct CookidooBrowserView: View {
    let viewModel: CookidooViewModel

    @State private var selectedTab = 0
    @State private var expandedCollections: Set<String> = []
    @State private var expandedChapters: Set<String> = []
    @State private var previewRecipe: CookidooRecipeSummary?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isAvailable && !viewModel.isLoading {
                    unavailableView
                } else {
                    contentView
                }
            }
            .navigationTitle("Cookidoo")
            .loadingOverlay(isLoading: viewModel.isLoading)
            .toast(isShowing: $showToast, message: toastMessage, type: toastType)
            .sheet(item: $previewRecipe) { recipe in
                CookidooRecipePreview(
                    recipe: recipe,
                    viewModel: viewModel
                ) { message in
                    toastMessage = message
                    toastType = .success
                    showToast = true
                }
            }
            .task {
                await viewModel.checkStatus()
                if viewModel.isAvailable {
                    async let cols: () = viewModel.loadCollections()
                    async let shop: () = viewModel.loadShoppingList()
                    _ = await (cols, shop)
                }
            }
        }
    }

    // MARK: - Unavailable

    private var unavailableView: some View {
        EmptyStateView(
            icon: "book.closed",
            title: "Cookidoo nicht verfügbar",
            subtitle: "Bitte Server-Konfiguration prüfen. Cookidoo-Zugangsdaten müssen auf dem Server hinterlegt sein."
        )
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(spacing: 0) {
            Picker("Ansicht", selection: $selectedTab) {
                Text("Sammlungen").tag(0)
                Text("Einkaufsliste").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if selectedTab == 0 {
                collectionsTab
            } else {
                shoppingListTab
            }
        }
    }

    // MARK: - Collections Tab

    private var collectionsTab: some View {
        Group {
            if viewModel.collections.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "books.vertical",
                    title: "Keine Sammlungen",
                    subtitle: "Erstelle Sammlungen in der Cookidoo-App, um sie hier zu sehen."
                )
            } else {
                collectionsList
            }
        }
    }

    private var collectionsList: some View {
        List {
            ForEach(viewModel.collections) { collection in
                Section {
                    collectionHeader(collection)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3)) {
                                toggleSet(&expandedCollections, id: collection.id)
                            }
                        }

                    if expandedCollections.contains(collection.id) {
                        ForEach(collection.chapters) { chapter in
                            chapterSection(chapter, collectionId: collection.id)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadCollections()
        }
    }

    private func collectionHeader(_ collection: CookidooCollection) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.title3)
                .foregroundStyle(.appPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.body)
                    .fontWeight(.semibold)

                Text("\(collection.chapters.count) Kapitel")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }

            Spacer()

            Image(systemName: expandedCollections.contains(collection.id) ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
    }

    private func chapterSection(_ chapter: CookidooChapter, collectionId: String) -> some View {
        let chapterKey = "\(collectionId)_\(chapter.id)"

        return Group {
            HStack(spacing: 10) {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundStyle(.appWarning)

                Text(chapter.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(chapter.recipes.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5), in: Capsule())

                Image(systemName: expandedChapters.contains(chapterKey) ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
            .padding(.leading, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    toggleSet(&expandedChapters, id: chapterKey)
                }
            }

            if expandedChapters.contains(chapterKey) {
                ForEach(chapter.recipes) { recipe in
                    recipeRow(recipe)
                        .padding(.leading, 32)
                }
            }
        }
    }

    // MARK: - Shopping List Tab

    private var shoppingListTab: some View {
        Group {
            if viewModel.shoppingListRecipes.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "cart",
                    title: "Keine Rezepte",
                    subtitle: "Füge Rezepte zur Cookidoo-Einkaufsliste hinzu, um sie hier zu sehen."
                )
            } else {
                shoppingRecipesList
            }
        }
    }

    private var shoppingRecipesList: some View {
        List {
            ForEach(viewModel.shoppingListRecipes) { recipe in
                recipeRow(recipe)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadShoppingList()
        }
    }

    // MARK: - Recipe Row

    private func recipeRow(_ recipe: CookidooRecipeSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.subheadline)
                .foregroundStyle(.appPrimary)
                .frame(width: 24)

            Text(recipe.name)
                .font(.subheadline)
                .lineLimit(2)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.appSecondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            previewRecipe = recipe
        }
    }

    // MARK: - Helpers

    private func toggleSet<T: Hashable>(_ set: inout Set<T>, id: T) {
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
    }
}
