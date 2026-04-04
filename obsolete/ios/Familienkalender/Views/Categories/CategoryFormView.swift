import SwiftUI

struct CategoryFormView: View {
    let viewModel: CategoryViewModel
    var existing: CategoryResponse?
    var onSuccess: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: String = "#0052CC"
    @State private var icon: String = "📁"
    @State private var showDeleteConfirm = false
    @State private var isSaving = false

    private var isEditing: Bool { existing != nil }

    private static let colorOptions: [String] = [
        "#0052CC", "#00875A", "#DE350B", "#FF8B00", "#6B778C",
        "#8777D9", "#E91E63", "#00BCD4", "#4CAF50", "#FF5722"
    ]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                nameSection
                colorSection
                iconSection

                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(isEditing ? "Kategorie bearbeiten" : "Neue Kategorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Speichern" : "Erstellen") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave || isSaving)
                }
            }
            .confirmationDialog(
                "Kategorie löschen?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Endgültig löschen", role: .destructive) {
                    Task { await delete() }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Die Kategorie „\(name)" wird unwiderruflich entfernt.")
            }
            .onAppear { populateFields() }
            .loadingOverlay(isLoading: isSaving)
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Text(icon.isEmpty ? "📁" : String(icon.prefix(1)))
                        .font(.system(size: 44))
                        .frame(width: 80, height: 80)
                        .background(Color(hex: selectedColor).opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: selectedColor), lineWidth: 2.5)
                        )
                        .animation(.spring(duration: 0.3), value: selectedColor)
                        .animation(.spring(duration: 0.3), value: icon)

                    if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(name)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        Section("Name") {
            TextField("Kategorie-Name eingeben", text: $name)
                .autocorrectionDisabled()
        }
    }

    // MARK: - Color

    private var colorSection: some View {
        Section("Farbe") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Self.colorOptions, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 40, height: 40)
                            .overlay {
                                if selectedColor == hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .shadow(color: selectedColor == hex ? Color(hex: hex).opacity(0.5) : .clear, radius: 4, y: 2)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.2)) {
                                    selectedColor = hex
                                }
                            }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        Section("Icon (Emoji)") {
            HStack {
                TextField("Emoji eingeben (z.B. 🏠)", text: $icon)
                    .onChange(of: icon) { _, newValue in
                        if newValue.count > 1 {
                            icon = String(newValue.suffix(1))
                        }
                    }

                if !icon.isEmpty {
                    Text(icon)
                        .font(.title2)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: selectedColor).opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Label("Kategorie löschen", systemImage: "trash")
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Actions

    private func populateFields() {
        guard let existing else { return }
        name = existing.name
        selectedColor = existing.color
        icon = existing.icon
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        let finalIcon = icon.isEmpty ? "📁" : String(icon.prefix(1))

        if let existing {
            let body = CategoryUpdate(
                name: trimmedName,
                color: selectedColor,
                icon: finalIcon
            )
            await viewModel.updateCategory(id: existing.id, body)
            if viewModel.errorMessage == nil {
                onSuccess?("\(trimmedName) wurde aktualisiert")
                dismiss()
            }
        } else {
            let body = CategoryCreate(
                name: trimmedName,
                color: selectedColor,
                icon: finalIcon
            )
            await viewModel.createCategory(body)
            if viewModel.errorMessage == nil {
                onSuccess?("\(trimmedName) wurde erstellt")
                dismiss()
            }
        }
        isSaving = false
    }

    private func delete() async {
        guard let existing else { return }
        isSaving = true
        await viewModel.deleteCategory(id: existing.id)
        if viewModel.errorMessage == nil {
            onSuccess?("\(existing.name) wurde gelöscht")
            dismiss()
        }
        isSaving = false
    }
}
