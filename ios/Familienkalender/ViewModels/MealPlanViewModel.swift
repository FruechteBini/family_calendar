import Foundation

@Observable
@MainActor
final class MealPlanViewModel {

    // MARK: - State

    var weekPlan: WeekPlanResponse?
    var currentWeekStart: Date
    var cookingHistory: [CookingHistoryEntry] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var undoMealIds: [Int]?

    @ObservationIgnored
    private var undoTimer: Timer?

    // MARK: - Dependencies

    private let mealPlanRepo: MealPlanRepository

    init(mealPlanRepo: MealPlanRepository) {
        self.mealPlanRepo = mealPlanRepo
        self.currentWeekStart = Date().mondayOfWeek
    }

    // MARK: - Load

    func loadWeek() async {
        isLoading = true
        errorMessage = nil
        do {
            weekPlan = try await mealPlanRepo.getWeekPlan(week: currentWeekStart.isoDateString)
        } catch {
            errorMessage = "Wochenplan konnte nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func navigateWeek(by offset: Int) {
        let cal = Calendar.current
        if let newWeek = cal.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) {
            currentWeekStart = newWeek.mondayOfWeek
        }
    }

    // MARK: - Slot Management

    func assignSlot(date: String, slot: String, recipeId: Int, servings: Int) async {
        errorMessage = nil
        let body = MealSlotUpdate(recipeId: recipeId, servingsPlanned: servings)
        do {
            _ = try await mealPlanRepo.setSlot(date: date, slot: slot, body: body)
            await loadWeek()
        } catch {
            errorMessage = "Slot konnte nicht belegt werden: \(error.localizedDescription)"
        }
    }

    func clearSlot(date: String, slot: String) async {
        errorMessage = nil
        do {
            try await mealPlanRepo.clearSlot(date: date, slot: slot)
            await loadWeek()
        } catch {
            errorMessage = "Slot konnte nicht geleert werden: \(error.localizedDescription)"
        }
    }

    func markCooked(date: String, slot: String, servings: Int?, rating: Int?, notes: String?) async -> MarkCookedResponse? {
        errorMessage = nil
        let body = MarkCookedRequest(servingsCooked: servings, rating: rating, notes: notes)
        do {
            let response = try await mealPlanRepo.markCooked(date: date, slot: slot, body: body)
            await loadWeek()
            return response
        } catch {
            errorMessage = "Konnte nicht als gekocht markiert werden: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - History

    func loadHistory(limit: Int = 20) async {
        do {
            cookingHistory = try await mealPlanRepo.getHistory(limit: limit)
        } catch {
            errorMessage = "Kochhistorie konnte nicht geladen werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Undo

    func startUndoTimer(mealIds: [Int]) {
        undoTimer?.invalidate()
        undoMealIds = mealIds
        undoTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.dismissUndo()
            }
        }
    }

    func undoPlan() async {
        guard let ids = undoMealIds else { return }
        errorMessage = nil
        do {
            let request = UndoMealPlanRequest(mealIds: ids)
            try await mealPlanRepo.undoPlan(request)
            dismissUndo()
            await loadWeek()
        } catch {
            errorMessage = "Rueckgaengig machen fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    func dismissUndo() {
        undoTimer?.invalidate()
        undoTimer = nil
        undoMealIds = nil
    }
}
