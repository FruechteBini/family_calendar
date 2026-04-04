import SwiftUI

struct RecipeFormView: View {
    @Bindable var viewModel: RecipeViewModel
    let recipe: RecipeResponse?

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var servings = 4
    @State private var difficulty: Difficulty = .medium
    @State private var prepTimeActive = ""
    @State private var prepTimePassive = ""
    @State private var aiAccessible = true
    @State private var imageUrl = ""
    @State private var instructions = ""
    @State private var notes = ""
    @State private var ingredients: [IngredientRow] = []
    @State private var importUrl = ""
    @State private var isImporting = false
    @State private var isSaving = false
    @State private var showDeleteAlert = false
    @State private var localError: String?

    private var isEditing: Bool { recipe != nil }

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                imageSection
                if !isEditing { urlImportSection }
                ingredientsSection
                instructionsSection
                notesSection
                if isEditing { deleteSection }
            }
            .navigationTitle(isEditing ? "Rezept bearbeiten" : "Neues Rezept")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Speichern" : "Erstellen") {
                        Task { await save() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .fontWeight(.bold)
                }
            }
            .alert("Rezept löschen?", isPresented: $showDeleteAlert) {
                Button("Abbrechen", role: .cancel) {}
                Button("Löschen", role: .destructive) {
                    Task {
                        if let id = recipe?.id {
                            await viewModel.deleteRecipe(id: id)
                        }
                        dismiss()
                    }
                }
            } message: {
                Text("Möchtest du dieses Rezept wirklich löschen?")
            }
            .loadingOverlay(isLoading: isSaving, message: "Wird gespeichert…")
            .onAppear { populateFromRecipe() }
        }
        .interactiveDismissDisabled(isSaving)
    }

    // MARK: - General

    private var generalSection: some View {
        Section("Allgemein") {
            TextField("Titel *", text: $title)
                .textInputAutocapitalization(.words)

            Stepper("Portionen: \(servings)", value: $servings, in: 1...20)

            Picker("Schwierigkeit", selection: $difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { d in
                    Text(d.displayName).tag(d)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Aktive Zeit (Min.)")
                Spacer()
                TextField("–", text: $prepTimeActive)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }

            HStack {
                Text("Passive Zeit (Min.)")
                Spacer()
                TextField("–", text: $prepTimePassive)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }

            Toggle("AI-zugänglich", isOn: $aiAccessible)
        }
    }

    // MARK: - Image

    private var imageSection: some View {
        Section("Bild") {
            TextField("Bild-URL", text: $imageUrl)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        Label("Bild konnte nicht geladen werden", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.appWarning)
                    default:
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    // MARK: - URL Import

    private var urlImportSection: some View {
        Section {
            HStack {
                TextField("Rezept-URL", text: $importUrl)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task { await importFromUrl() }
                } label: {
                    if isImporting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Importieren")
                    }
                }
                .disabled(importUrl.trimmingCharacters(in: .whitespaces).isEmpty || isImporting)
                .buttonStyle(.bordered)
                .tint(.appPrimary)
            }

            if let localError {
                Text(localError)
                    .font(.caption)
                    .foregroundStyle(.appDanger)
            }
        } header: {
            Text("URL-Import")
        } footer: {
            Text("Rezept-URL eingeben, um Titel, Zutaten und Zubereitung automatisch zu übernehmen.")
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        Section {
            ForEach($ingredients) { $row in
                VStack(spacing: 8) {
                    TextField("Zutat *", text: $row.name)

                    HStack(spacing: 8) {
                        TextField("Menge", text: $row.amount)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 70)

                        TextField("Einheit", text: $row.unit)
                            .frame(maxWidth: 70)

                        Picker("", selection: $row.category) {
                            ForEach(IngredientCategory.allCases, id: \.self) { cat in
                                Text("\(cat.icon) \(cat.displayName)").tag(cat)
                            }
                        }
                        .labelsHidden()
                    }
                }
                .padding(.vertical, 2)
            }
            .onDelete(perform: deleteIngredient)

            Button {
                ingredients.append(IngredientRow())
            } label: {
                Label("Zutat hinzufügen", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Zutaten")
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        Section("Zubereitung") {
            TextEditor(text: $instructions)
                .frame(minHeight: 120)
                .overlay(alignment: .topLeading) {
                    if instructions.isEmpty {
                        Text("Zubereitungsschritte beschreiben…")
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        Section("Notizen") {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .overlay(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Optionale Notizen…")
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Rezept löschen", systemImage: "trash")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Actions

    private func populateFromRecipe() {
        guard let r = recipe else { return }
        title = r.title
        servings = r.servings
        difficulty = r.difficultyEnum
        prepTimeActive = r.prepTimeActiveMinutes.map { String($0) } ?? ""
        prepTimePassive = r.prepTimePassiveMinutes.map { String($0) } ?? ""
        aiAccessible = r.aiAccessible
        imageUrl = r.imageUrl ?? ""
        instructions = r.instructions ?? ""
        notes = r.notes ?? ""
        ingredients = r.ingredients.map { ing in
            IngredientRow(
                name: ing.name,
                amount: ing.amount.map { formatAmount($0) } ?? "",
                unit: ing.unit ?? "",
                category: ing.categoryEnum
            )
        }
    }

    private func importFromUrl() async {
        localError = nil
        isImporting = true
        defer { isImporting = false }

        guard let preview = await viewModel.parseUrl(url: importUrl) else {
            localError = viewModel.errorMessage
            return
        }
        if let t = preview.title { title = t }
        if let s = preview.servings { servings = s }
        if let d = preview.difficulty, let diff = Difficulty(rawValue: d) { difficulty = diff }
        if let a = preview.prepTimeActiveMinutes { prepTimeActive = String(a) }
        if let p = preview.prepTimePassiveMinutes { prepTimePassive = String(p) }
        if let img = preview.imageUrl { imageUrl = img }
        if let inst = preview.instructions { instructions = inst }
        if let ings = preview.ingredients, !ings.isEmpty {
            ingredients = ings.map { ic in
                IngredientRow(
                    name: ic.name,
                    amount: ic.amount.map { formatAmount($0) } ?? "",
                    unit: ic.unit ?? "",
                    category: IngredientCategory(apiValue: ic.category) ?? .sonstiges
                )
            }
        }
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let parsedIngredients: [IngredientCreate] = ingredients
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { row in
                IngredientCreate(
                    name: row.name.trimmingCharacters(in: .whitespaces),
                    amount: Double(row.amount.replacingOccurrences(of: ",", with: ".")),
                    unit: row.unit.isEmpty ? nil : row.unit,
                    category: row.category.apiValue
                )
            }

        if isEditing, let id = recipe?.id {
            let body = RecipeUpdate(
                title: trimmedTitle,
                servings: servings,
                prepTimeActiveMinutes: Int(prepTimeActive),
                prepTimePassiveMinutes: Int(prepTimePassive),
                difficulty: difficulty.rawValue,
                instructions: instructions.isEmpty ? nil : instructions,
                notes: notes.isEmpty ? nil : notes,
                imageUrl: imageUrl.isEmpty ? nil : imageUrl,
                aiAccessible: aiAccessible,
                ingredients: parsedIngredients
            )
            await viewModel.updateRecipe(id: id, body)
        } else {
            var body = RecipeCreate(title: trimmedTitle)
            body.servings = servings
            body.difficulty = difficulty.rawValue
            body.prepTimeActiveMinutes = Int(prepTimeActive)
            body.prepTimePassiveMinutes = Int(prepTimePassive)
            body.instructions = instructions.isEmpty ? nil : instructions
            body.notes = notes.isEmpty ? nil : notes
            body.imageUrl = imageUrl.isEmpty ? nil : imageUrl
            body.aiAccessible = aiAccessible
            body.ingredients = parsedIngredients
            if !importUrl.isEmpty {
                body.source = "web"
            }
            await viewModel.createRecipe(body)
        }

        if viewModel.errorMessage == nil {
            dismiss()
        }
    }

    private func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    private func formatAmount(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Ingredient Row Model

struct IngredientRow: Identifiable {
    let id = UUID()
    var name: String = ""
    var amount: String = ""
    var unit: String = ""
    var category: IngredientCategory = .sonstiges
}
