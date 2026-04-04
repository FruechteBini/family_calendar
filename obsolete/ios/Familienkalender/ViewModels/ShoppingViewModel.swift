import Foundation

@Observable
@MainActor
final class ShoppingViewModel {

    // MARK: - State

    var shoppingList: ShoppingListResponse?
    var isLoading: Bool = false
    var errorMessage: String?
    var isSorting: Bool = false

    // MARK: - Computed

    var progress: (checked: Int, total: Int) {
        guard let items = shoppingList?.items else { return (0, 0) }
        let checked = items.filter(\.checked).count
        return (checked: checked, total: items.count)
    }

    var groupedItems: [(section: String, icon: String, items: [ShoppingItemResponse])] {
        guard let items = shoppingList?.items else { return [] }
        let unchecked = items.filter { !$0.checked }

        let isSorted = shoppingList?.sortedByStore != nil

        var groups: [String: [ShoppingItemResponse]] = [:]
        for item in unchecked {
            let key = isSorted ? (item.storeSection ?? "Sonstiges") : (item.category)
            groups[key, default: []].append(item)
        }

        let sectionOrder = [
            "kuehlregal", "obst_gemuese", "trockenware", "drogerie", "sonstiges"
        ]

        return groups.sorted { lhs, rhs in
            let li = sectionOrder.firstIndex(of: lhs.key) ?? sectionOrder.count
            let ri = sectionOrder.firstIndex(of: rhs.key) ?? sectionOrder.count
            if li != ri { return li < ri }
            return lhs.key < rhs.key
        }.map { key, items in
            let cat = IngredientCategory(apiValue: key)
            let displayName = cat?.displayName ?? key
            let icon = cat?.icon ?? "📦"
            return (section: displayName, icon: icon, items: items)
        }
    }

    // MARK: - Dependencies

    private let shoppingRepo: ShoppingRepository

    init(shoppingRepo: ShoppingRepository) {
        self.shoppingRepo = shoppingRepo
    }

    // MARK: - Load

    func loadList() async {
        isLoading = true
        errorMessage = nil
        do {
            shoppingList = try await shoppingRepo.getList()
        } catch {
            errorMessage = "Einkaufsliste konnte nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func generate(weekStart: String) async {
        isLoading = true
        errorMessage = nil
        do {
            shoppingList = try await shoppingRepo.generate(weekStart: weekStart)
        } catch {
            errorMessage = "Einkaufsliste konnte nicht generiert werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Item Actions

    func addItem(_ body: ShoppingItemCreate) async {
        errorMessage = nil
        do {
            _ = try await shoppingRepo.addItem(body)
            await loadList()
        } catch {
            errorMessage = "Artikel konnte nicht hinzugefuegt werden: \(error.localizedDescription)"
        }
    }

    func checkItem(id: Int) async {
        errorMessage = nil
        do {
            _ = try await shoppingRepo.checkItem(id: id)
            if let idx = shoppingList?.items.firstIndex(where: { $0.id == id }) {
                await loadList()
            }
        } catch {
            errorMessage = "Artikel konnte nicht abgehakt werden: \(error.localizedDescription)"
        }
    }

    func deleteItem(id: Int) async {
        errorMessage = nil
        do {
            try await shoppingRepo.deleteItem(id: id)
            shoppingList?.items.removeAll { $0.id == id }
        } catch {
            errorMessage = "Artikel konnte nicht geloescht werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Sort & Clear

    func sort() async {
        isSorting = true
        errorMessage = nil
        do {
            shoppingList = try await shoppingRepo.sort()
        } catch {
            errorMessage = "KI-Sortierung fehlgeschlagen: \(error.localizedDescription)"
        }
        isSorting = false
    }

    func clearAll() async {
        errorMessage = nil
        do {
            try await shoppingRepo.clearAll()
            shoppingList?.items.removeAll()
        } catch {
            errorMessage = "Liste konnte nicht geleert werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Share

    func shareText() -> String {
        guard let items = shoppingList?.items else { return "" }
        let unchecked = items.filter { !$0.checked }
        if unchecked.isEmpty { return "Einkaufsliste ist leer." }

        var lines: [String] = ["Einkaufsliste:", ""]
        for item in unchecked {
            var line = "- \(item.name)"
            if let amount = item.amount, !amount.isEmpty {
                line += " (\(amount)"
                if let unit = item.unit, !unit.isEmpty {
                    line += " \(unit)"
                }
                line += ")"
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}
