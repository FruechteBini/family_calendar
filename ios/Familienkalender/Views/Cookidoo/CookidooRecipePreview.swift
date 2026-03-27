import SwiftUI

struct CookidooRecipePreview: View {
    let recipe: CookidooRecipeSummary
    let viewModel: CookidooViewModel
    var onImported: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var importSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                headerSection

                importButton

                Spacer()

                closeButton
            }
            .padding(24)
            .navigationTitle("Rezeptvorschau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.appSecondary)
                    }
                }
            }
            .loadingOverlay(isLoading: viewModel.isImporting, message: "Rezept wird importiert…")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.appPrimary)
                .symbolRenderingMode(.hierarchical)

            Text(recipe.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.caption)
                Text("Cookidoo")
                    .font(.caption)
            }
            .foregroundStyle(.appSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6), in: Capsule())
        }
    }

    // MARK: - Import Button

    private var importButton: some View {
        Group {
            if importSuccess {
                Label("Erfolgreich importiert", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .padding(.vertical, 12)
                    .background(.appSuccess, in: RoundedRectangle(cornerRadius: 14))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    Task { await performImport() }
                } label: {
                    Label("Importieren", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(viewModel.isImporting)
            }
        }
        .animation(.spring(duration: 0.3), value: importSuccess)
    }

    // MARK: - Close

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Schließen")
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Import Action

    private func performImport() async {
        let imported = await viewModel.importRecipe(id: recipe.cookidooId)
        if imported != nil {
            importSuccess = true
            onImported?("„\(recipe.name)" wurde importiert")
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        }
    }
}
