import Foundation

@Observable
@MainActor
final class PantryViewModel {

    // MARK: - State

    var items: [PantryItemResponse] = []
    var alerts: [PantryAlertItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Computed

    private static let categoryOrder: [String] = [
        "kuehlregal", "obst_gemuese", "trockenware", "drogerie", "sonstiges"
    ]

    var groupedItems: [(category: IngredientCategory, items: [PantryItemResponse])] {
        var groups: [String: [PantryItemResponse]] = [:]
        for item in items {
            groups[item.category, default: []].append(item)
        }

        return Self.categoryOrder.compactMap { key in
            guard let catItems = groups[key], !catItems.isEmpty,
                  let cat = IngredientCategory(apiValue: key) else { return nil }
            return (category: cat, items: catItems)
        }
    }

    // MARK: - Dependencies

    private let pantryRepo: PantryRepository

    init(pantryRepo: PantryRepository) {
        self.pantryRepo = pantryRepo
    }

    // MARK: - Load

    func loadItems() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await pantryRepo.list(category: nil, search: nil)
        } catch {
            errorMessage = "Vorrat konnte nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadAlerts() async {
        do {
            alerts = try await pantryRepo.getAlerts()
        } catch {
            errorMessage = "Warnungen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            async let loadedItems = pantryRepo.list(category: nil, search: nil)
            async let loadedAlerts = pantryRepo.getAlerts()
            items = try await loadedItems
            alerts = try await loadedAlerts
        } catch {
            errorMessage = "Vorrat konnte nicht aktualisiert werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - CRUD

    func createItem(_ body: PantryItemCreate) async {
        errorMessage = nil
        do {
            let created = try await pantryRepo.create(body)
            items.append(created)
        } catch {
            errorMessage = "Artikel konnte nicht hinzugefuegt werden: \(error.localizedDescription)"
        }
    }

    func updateItem(id: Int, _ body: PantryItemUpdate) async {
        errorMessage = nil
        do {
            let updated = try await pantryRepo.update(id: id, body)
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx] = updated
            }
        } catch {
            errorMessage = "Artikel konnte nicht aktualisiert werden: \(error.localizedDescription)"
        }
    }

    func deleteItem(id: Int) async {
        errorMessage = nil
        do {
            try await pantryRepo.delete(id: id)
            items.removeAll { $0.id == id }
        } catch {
            errorMessage = "Artikel konnte nicht geloescht werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Alert Actions

    func addAlertToShopping(id: Int) async {
        errorMessage = nil
        do {
            try await pantryRepo.addAlertToShopping(id: id)
            alerts.removeAll { $0.id == id }
        } catch {
            errorMessage = "Konnte nicht zur Einkaufsliste hinzugefuegt werden: \(error.localizedDescription)"
        }
    }

    func dismissAlert(id: Int) async {
        errorMessage = nil
        do {
            try await pantryRepo.dismissAlert(id: id)
            alerts.removeAll { $0.id == id }
        } catch {
            errorMessage = "Warnung konnte nicht verworfen werden: \(error.localizedDescription)"
        }
    }
}
