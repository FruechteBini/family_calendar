import SwiftUI

struct PantryView: View {
    let viewModel: PantryViewModel

    @State private var quickName = ""
    @State private var quickAmount = ""
    @State private var quickUnit = ""
    @State private var quickCategory: IngredientCategory = .sonstiges
    @State private var editItem: PantryItemResponse?
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        Group {
            if viewModel.items.isEmpty && viewModel.alerts.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "Vorratskammer ist leer",
                    subtitle: "Füge Artikel hinzu, um deinen Vorrat im Blick zu behalten."
                )
            } else {
                contentList
            }
        }
        .navigationTitle("Vorratskammer")
        .loadingOverlay(isLoading: viewModel.isLoading)
        .toast(isShowing: $showToast, message: toastMessage, type: .success)
        .sheet(item: $editItem) { item in
            PantryFormView(existingItem: item, viewModel: viewModel)
        }
        .task { await viewModel.refresh() }
    }

    // MARK: - Content

    private var contentList: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsHeader

                if !viewModel.alerts.isEmpty {
                    PantryAlertsView(
                        alerts: viewModel.alerts,
                        onAddToShopping: { id in
                            await viewModel.addAlertToShopping(id: id)
                            toastMessage = "Zur Einkaufsliste hinzugefügt"
                            showToast = true
                        },
                        onDismiss: { id in
                            await viewModel.dismissAlert(id: id)
                        }
                    )
                    .padding(.horizontal, 16)
                }

                quickAddBar
                    .padding(.horizontal, 16)

                ForEach(viewModel.groupedItems, id: \.category) { group in
                    categorySection(group.category, items: group.items)
                }

                Color.clear.frame(height: 20)
            }
            .padding(.top, 8)
        }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Stats

    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatPill(
                icon: "shippingbox.fill",
                value: "\(viewModel.items.count)",
                label: "Artikel",
                color: .appPrimary
            )

            if !viewModel.alerts.isEmpty {
                StatPill(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(viewModel.alerts.count)",
                    label: viewModel.alerts.count == 1 ? "Warnung" : "Warnungen",
                    color: .appWarning
                )
            }

            let lowStock = viewModel.items.filter(\.isLowStock).count
            if lowStock > 0 {
                StatPill(
                    icon: "arrow.down.circle.fill",
                    value: "\(lowStock)",
                    label: "Niedrig",
                    color: .appDanger
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Add

    private var quickAddBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("Artikel hinzufügen…", text: $quickName)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)

                TextField("Menge", text: $quickAmount)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 70)

                TextField("Einheit", text: $quickUnit)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
            }

            HStack(spacing: 8) {
                Picker("Kategorie", selection: $quickCategory) {
                    ForEach(IngredientCategory.allCases, id: \.self) { cat in
                        Text("\(cat.icon) \(cat.displayName)").tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)

                Spacer()

                Button {
                    Task { await quickAdd() }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.appPrimary)
                }
                .disabled(quickName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(quickName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Category Section

    private func categorySection(_ category: IngredientCategory, items: [PantryItemResponse]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(category.icon)
                    .font(.title3)
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(items.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ForEach(items) { item in
                PantryItemRow(item: item)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteItem(id: item.id) }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }

                        Button {
                            editItem = item
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        .tint(.appPrimary)
                    }

                if item.id != items.last?.id {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Add Action

    private func quickAdd() async {
        let name = quickName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let parsedAmount = Double(quickAmount.replacingOccurrences(of: ",", with: "."))
        let body = PantryItemCreate(
            name: name,
            amount: parsedAmount,
            unit: quickUnit.isEmpty ? nil : quickUnit,
            category: quickCategory.apiValue
        )
        await viewModel.createItem(body)

        if viewModel.errorMessage == nil {
            quickName = ""
            quickAmount = ""
            quickUnit = ""
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}
