import SwiftUI

struct MemberFormView: View {
    let viewModel: MemberViewModel
    var existing: FamilyMemberResponse?
    var onSuccess: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: String = "#0052CC"
    @State private var selectedEmoji: String = "👨"
    @State private var customEmoji: String = ""
    @State private var showDeleteConfirm = false
    @State private var isSaving = false

    private var isEditing: Bool { existing != nil }

    private static let colorOptions: [String] = [
        "#0052CC", "#00875A", "#DE350B", "#FF8B00", "#6B778C",
        "#8777D9", "#E91E63", "#00BCD4", "#4CAF50", "#FF5722"
    ]

    private static let emojiOptions: [String] = [
        "👨", "👩", "👦", "👧", "👶", "🧑",
        "👴", "👵", "🐶", "🐱", "🦊", "🐻"
    ]

    private var displayEmoji: String {
        if !customEmoji.isEmpty { return String(customEmoji.prefix(1)) }
        return selectedEmoji
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                nameSection
                colorSection
                emojiSection
                customEmojiSection

                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(isEditing ? "Mitglied bearbeiten" : "Neues Mitglied")
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
                "Mitglied löschen?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Endgültig löschen", role: .destructive) {
                    Task { await delete() }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("\(name) wird unwiderruflich entfernt. Zugehörige Zuweisungen gehen verloren.")
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
                    Text(displayEmoji)
                        .font(.system(size: 52))
                        .frame(width: 96, height: 96)
                        .background(Color(hex: selectedColor).opacity(0.2), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: selectedColor), lineWidth: 3)
                        )
                        .animation(.spring(duration: 0.3), value: selectedColor)
                        .animation(.spring(duration: 0.3), value: displayEmoji)

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
            TextField("Name eingeben", text: $name)
                .textContentType(.name)
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
                            .accessibilityLabel("Farbe \(hex)")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Emoji

    private var emojiSection: some View {
        Section("Emoji") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(Self.emojiOptions, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                        .background(
                            selectedEmoji == emoji && customEmoji.isEmpty
                                ? Color(hex: selectedColor).opacity(0.2)
                                : Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selectedEmoji == emoji && customEmoji.isEmpty
                                        ? Color(hex: selectedColor)
                                        : .clear,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.2)) {
                                selectedEmoji = emoji
                                customEmoji = ""
                            }
                        }
                }
            }
        }
    }

    // MARK: - Custom Emoji

    private var customEmojiSection: some View {
        Section("Eigenes Emoji") {
            HStack {
                TextField("Emoji eingeben (z.B. 🎸)", text: $customEmoji)
                    .onChange(of: customEmoji) { _, newValue in
                        if newValue.count > 1 {
                            customEmoji = String(newValue.suffix(1))
                        }
                    }

                if !customEmoji.isEmpty {
                    Button {
                        customEmoji = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.appSecondary)
                    }
                    .buttonStyle(.plain)
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
                    Label("Mitglied löschen", systemImage: "trash")
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
        let emoji = existing.avatarEmoji
        if Self.emojiOptions.contains(emoji) {
            selectedEmoji = emoji
            customEmoji = ""
        } else {
            customEmoji = emoji
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        let emoji = displayEmoji

        if let existing {
            let body = FamilyMemberUpdate(
                name: trimmedName,
                color: selectedColor,
                avatarEmoji: emoji
            )
            await viewModel.updateMember(id: existing.id, body)
            if viewModel.errorMessage == nil {
                onSuccess?("\(trimmedName) wurde aktualisiert")
                dismiss()
            }
        } else {
            let body = FamilyMemberCreate(
                name: trimmedName,
                color: selectedColor,
                avatarEmoji: emoji
            )
            await viewModel.createMember(body)
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
        await viewModel.deleteMember(id: existing.id)
        if viewModel.errorMessage == nil {
            onSuccess?("\(existing.name) wurde gelöscht")
            dismiss()
        }
        isSaving = false
    }
}
