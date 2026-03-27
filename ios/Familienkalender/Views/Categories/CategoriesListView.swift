import SwiftUI

struct CategoriesListView: View {
    let viewModel: CategoryViewModel

    @State private var editCategory: CategoryResponse?
    @State private var showCreateSheet = false
    @State private var deleteTarget: CategoryResponse?
    @State private var showDeleteConfirm = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success

    var body: some View {
        Group {
            if viewModel.categories.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "folder",
                    title: "Keine Kategorien",
                    subtitle: "Erstelle Kategorien, um Termine und Aufgaben zu organisieren.",
                    buttonTitle: "Kategorie erstellen"
                ) {
                    showCreateSheet = true
                }
            } else {
                categoryList
            }
        }
        .navigationTitle("Kategorien")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CategoryFormView(viewModel: viewModel) { message in
                toastMessage = message
                toastType = .success
                showToast = true
            }
        }
        .sheet(item: $editCategory) { category in
            CategoryFormView(viewModel: viewModel, existing: category) { message in
                toastMessage = message
                toastType = .success
                showToast = true
            }
        }
        .confirmationDialog(
            "Kategorie löschen?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                guard let target = deleteTarget else { return }
                Task {
                    await viewModel.deleteCategory(id: target.id)
                    if viewModel.errorMessage == nil {
                        toastMessage = "\(target.name) wurde gelöscht"
                        toastType = .success
                        showToast = true
                    }
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            if let target = deleteTarget {
                Text("Kategorie „\(target.name)" wird unwiderruflich entfernt.")
            }
        }
        .toast(isShowing: $showToast, message: toastMessage, type: toastType)
        .loadingOverlay(isLoading: viewModel.isLoading)
        .task { await viewModel.loadCategories() }
    }

    // MARK: - List

    private var categoryList: some View {
        List {
            ForEach(viewModel.categories) { category in
                categoryRow(category)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editCategory = category
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTarget = category
                            showDeleteConfirm = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }

                        Button {
                            editCategory = category
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        .tint(.appPrimary)
                    }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.loadCategories() }
    }

    // MARK: - Row

    private func categoryRow(_ category: CategoryResponse) -> some View {
        HStack(spacing: 14) {
            Text(category.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(hex: category.color).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            Text(category.name)
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            Circle()
                .fill(Color(hex: category.color))
                .frame(width: 14, height: 14)
        }
        .padding(.vertical, 4)
    }
}
