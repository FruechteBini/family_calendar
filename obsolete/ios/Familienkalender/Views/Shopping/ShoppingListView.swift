import SwiftUI

struct ShoppingListView: View {
    let viewModel: ShoppingViewModel
    let weekStart: String

    @State private var newItemName = ""
    @State private var newItemAmount = ""
    @State private var newItemUnit = ""
    @State private var newItemCategory: IngredientCategory = .sonstiges
    @State private var showClearConfirm = false
    @State private var showShareSheet = false
    @State private var showToast = false
    @State private var toastMessage = ""

    private var checkedItems: [ShoppingItemResponse] {
        viewModel.shoppingList?.items.filter(\.checked) ?? []
    }

    private var hasItems: Bool {
        !(viewModel.shoppingList?.items.isEmpty ?? true)
    }

    var body: some View {
        Group {
            if !hasItems && !viewModel.isLoading {
                emptyState
            } else {
                contentView
            }
        }
        .navigationTitle("Einkaufsliste")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        await viewModel.sort()
                        if viewModel.errorMessage == nil {
                            toastMessage = "KI-Sortierung abgeschlossen"
                            showToast = true
                        }
                    }
                } label: {
                    Image(systemName: "wand.and.stars")
                }
                .disabled(viewModel.isSorting || !hasItems)

                ShareLink(item: viewModel.shareText()) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(!hasItems)

                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(!hasItems)
            }
        }
        .confirmationDialog("Liste leeren?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Alle Artikel löschen", role: .destructive) {
                Task { await viewModel.clearAll() }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle Artikel werden unwiderruflich gelöscht.")
        }
        .toast(isShowing: $showToast, message: toastMessage, type: .success)
        .loadingOverlay(isLoading: viewModel.isSorting, message: "KI sortiert Einkaufsliste…")
        .task { await viewModel.loadList() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "cart",
            title: "Keine Einkaufsliste",
            subtitle: "Generiere eine Einkaufsliste aus dem Wochenplan oder füge manuell Artikel hinzu.",
            buttonTitle: "Aus Wochenplan generieren"
        ) {
            Task {
                await viewModel.generate(weekStart: weekStart)
            }
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                progressSection

                quickAddSection
                    .padding(.horizontal, 16)

                if let sortInfo = viewModel.shoppingList?.sortedByStore {
                    sortBadge(sortInfo)
                        .padding(.horizontal, 16)
                }

                ForEach(Array(viewModel.groupedItems.enumerated()), id: \.offset) { _, group in
                    ShoppingCategorySection(
                        sectionName: group.section,
                        icon: group.icon,
                        items: group.items,
                        onCheck: { id in await viewModel.checkItem(id: id) },
                        onDelete: { id in await viewModel.deleteItem(id: id) }
                    )
                    .padding(.horizontal, 16)
                }

                if !checkedItems.isEmpty {
                    checkedSection
                        .padding(.horizontal, 16)
                }

                Color.clear.frame(height: 20)
            }
            .padding(.top, 8)
        }
        .refreshable { await viewModel.loadList() }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 6) {
            let prog = viewModel.progress
            HStack {
                Text("\(prog.checked) von \(prog.total) erledigt")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if prog.total > 0 {
                    Text("\(Int(Double(prog.checked) / Double(prog.total) * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.appPrimary)
                }
            }

            ProgressView(value: Double(prog.checked), total: max(Double(prog.total), 1))
                .tint(prog.checked == prog.total && prog.total > 0 ? .appSuccess : .appPrimary)
                .animation(.spring(duration: 0.3), value: prog.checked)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Add

    private var quickAddSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("Artikel hinzufügen…", text: $newItemName)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await addItem() } }

                TextField("Menge", text: $newItemAmount)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 65)

                TextField("Einheit", text: $newItemUnit)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 65)
            }

            HStack {
                Picker("", selection: $newItemCategory) {
                    ForEach(IngredientCategory.allCases, id: \.self) { cat in
                        Text("\(cat.icon) \(cat.displayName)").tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)

                Spacer()

                Button {
                    Task { await addItem() }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.appPrimary)
                }
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(newItemName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Sort Badge

    private func sortBadge(_ store: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(.appPrimary)

            Text("Sortiert für: \(store)")
                .font(.caption)
                .foregroundStyle(.appPrimary)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(10)
        .background(Color.appPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Checked Items

    private var checkedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.appSuccess)
                Text("Erledigt")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(checkedItems.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ForEach(checkedItems) { item in
                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.checkItem(id: item.id) }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.appSuccess)
                    }
                    .buttonStyle(.plain)

                    Text(item.name)
                        .font(.subheadline)
                        .strikethrough()
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let amount = item.amount, !amount.isEmpty {
                        HStack(spacing: 2) {
                            Text(amount)
                            if let unit = item.unit, !unit.isEmpty {
                                Text(unit)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color(.systemGray3))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .opacity(0.6)
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Add Item

    private func addItem() async {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let body = ShoppingItemCreate(
            name: name,
            amount: newItemAmount.isEmpty ? nil : newItemAmount,
            unit: newItemUnit.isEmpty ? nil : newItemUnit,
            category: newItemCategory.apiValue
        )

        await viewModel.addItem(body)

        if viewModel.errorMessage == nil {
            newItemName = ""
            newItemAmount = ""
            newItemUnit = ""
        }
    }
}
