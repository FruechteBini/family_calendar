import SwiftUI

struct PantryFormView: View {
    let existingItem: PantryItemResponse?
    let viewModel: PantryViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var amount: String
    @State private var unit: String
    @State private var category: IngredientCategory
    @State private var hasExpiry: Bool
    @State private var expiryDate: Date
    @State private var minStockText: String
    @State private var isSaving = false

    init(existingItem: PantryItemResponse? = nil, viewModel: PantryViewModel) {
        self.existingItem = existingItem
        self.viewModel = viewModel

        let item = existingItem
        self._name = State(initialValue: item?.name ?? "")
        self._amount = State(initialValue: {
            guard let a = item?.amount else { return "" }
            return a.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", a)
                : String(format: "%.1f", a)
        }())
        self._unit = State(initialValue: item?.unit ?? "")
        self._category = State(initialValue: item?.categoryEnum ?? .sonstiges)
        self._hasExpiry = State(initialValue: item?.expiryDate != nil)
        self._expiryDate = State(initialValue: {
            if let exp = item?.expiryDate, let d = Date.fromISODate(exp) { return d }
            return Date().adding(days: 30)
        }())
        self._minStockText = State(initialValue: {
            guard let ms = item?.minStock else { return "" }
            return ms.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", ms)
                : String(format: "%.1f", ms)
        }())
    }

    private var isEditing: Bool { existingItem != nil }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                quantitySection
                categorySection
                expirySection
                minStockSection
            }
            .navigationTitle(isEditing ? "Artikel bearbeiten" : "Neuer Artikel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Bezeichnung") {
            TextField("z.B. Mehl, Milch, Eier…", text: $name)
                .font(.body)
        }
    }

    private var quantitySection: some View {
        Section("Menge") {
            HStack(spacing: 12) {
                TextField("Menge", text: $amount)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 100)

                Divider()

                TextField("Einheit (g, ml, Stk…)", text: $unit)
            }
        }
    }

    private var categorySection: some View {
        Section("Kategorie") {
            Picker("Kategorie", selection: $category) {
                ForEach(IngredientCategory.allCases, id: \.self) { cat in
                    HStack {
                        Text(cat.icon)
                        Text(cat.displayName)
                    }
                    .tag(cat)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var expirySection: some View {
        Section("Mindesthaltbarkeit") {
            Toggle("MHD angeben", isOn: $hasExpiry.animation())

            if hasExpiry {
                DatePicker(
                    "Ablaufdatum",
                    selection: $expiryDate,
                    displayedComponents: .date
                )
                .environment(\.locale, Locale(identifier: "de_DE"))
            }
        }
    }

    private var minStockSection: some View {
        Section {
            TextField("Standard: 2", text: $minStockText)
                .keyboardType(.decimalPad)
        } header: {
            Text("Mindestbestand")
        } footer: {
            Text("Du wirst gewarnt, wenn der Bestand unter diesen Wert fällt.")
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let parsedAmount = Double(amount.replacingOccurrences(of: ",", with: "."))
        let parsedMinStock = Double(minStockText.replacingOccurrences(of: ",", with: "."))
        let expiryString = hasExpiry ? expiryDate.isoDateString : nil

        if let existing = existingItem {
            let body = PantryItemUpdate(
                name: trimmedName,
                amount: parsedAmount,
                unit: unit.isEmpty ? nil : unit,
                category: category.apiValue,
                expiryDate: expiryString,
                minStock: parsedMinStock
            )
            await viewModel.updateItem(id: existing.id, body)
        } else {
            let body = PantryItemCreate(
                name: trimmedName,
                amount: parsedAmount,
                unit: unit.isEmpty ? nil : unit,
                category: category.apiValue,
                expiryDate: expiryString,
                minStock: parsedMinStock
            )
            await viewModel.createItem(body)
        }

        isSaving = false
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
