import Foundation

@Observable
@MainActor
final class AIMealPlanViewModel {

    // MARK: - Wizard Steps

    enum WizardStep {
        case config, loading, preview, confirming, done
    }

    // MARK: - State

    var availableRecipes: AvailableRecipesResponse?
    var selectedSlots: Set<String> = []
    var servings: Int = 4
    var preferences: String = ""
    var includeCookidoo: Bool = false
    var preview: PreviewMealPlanResponse?
    var confirmResult: ConfirmMealPlanResponse?
    var step: WizardStep = .config
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let aiRepo: AIRepository

    init(aiRepo: AIRepository) {
        self.aiRepo = aiRepo
    }

    // MARK: - Slot key helpers

    private func slotKey(date: String, slot: String) -> String {
        "\(date)_\(slot)"
    }

    // MARK: - Load

    func loadAvailableRecipes(weekStart: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await aiRepo.getAvailableRecipes(weekStart: weekStart)
            availableRecipes = response

            selectedSlots.removeAll()
            for emptySlot in response.emptySlots {
                selectedSlots.insert(slotKey(date: emptySlot.date, slot: emptySlot.slot))
            }
        } catch {
            errorMessage = "Verfuegbare Rezepte konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Generate

    func generatePlan(weekStart: String) async {
        step = .loading
        errorMessage = nil

        let slots: [SlotSelection] = selectedSlots.compactMap { key in
            let parts = key.split(separator: "_", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            return SlotSelection(date: String(parts[0]), slot: String(parts[1]))
        }

        let request = GenerateMealPlanRequest(
            weekStart: weekStart,
            servings: servings,
            preferences: preferences,
            selectedSlots: slots,
            includeCookidoo: includeCookidoo
        )

        do {
            preview = try await aiRepo.generateMealPlan(request)
            step = .preview
        } catch {
            errorMessage = "KI-Plan konnte nicht generiert werden: \(error.localizedDescription)"
            step = .config
        }
    }

    // MARK: - Confirm

    func confirmPlan(weekStart: String) async -> ConfirmMealPlanResponse? {
        guard let preview = preview else { return nil }
        step = .confirming
        errorMessage = nil

        let request = ConfirmMealPlanRequest(
            weekStart: weekStart,
            items: preview.suggestions
        )

        do {
            let result = try await aiRepo.confirmMealPlan(request)
            confirmResult = result
            step = .done
            return result
        } catch {
            errorMessage = "Plan konnte nicht bestaetigt werden: \(error.localizedDescription)"
            step = .preview
            return nil
        }
    }

    // MARK: - Reset

    func reset() {
        step = .config
        preview = nil
        confirmResult = nil
        errorMessage = nil
        preferences = ""
    }
}
