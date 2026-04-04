import Foundation

@Observable
@MainActor
final class CalendarViewModel {

    // MARK: - State

    var events: [EventResponse] = []
    var selectedDate: Date = Date()
    var currentMonth: Date = Date()
    var isLoading: Bool = false
    var errorMessage: String?

    var categories: [CategoryResponse] = []
    var members: [FamilyMemberResponse] = []

    // MARK: - Dependencies

    private let eventRepo: EventRepository
    private let categoryRepo: CategoryRepository
    private let memberRepo: MemberRepository

    init(eventRepo: EventRepository, categoryRepo: CategoryRepository, memberRepo: MemberRepository) {
        self.eventRepo = eventRepo
        self.categoryRepo = categoryRepo
        self.memberRepo = memberRepo
    }

    // MARK: - Load

    func loadEvents() async {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: currentMonth),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)),
              let lastDay = cal.date(byAdding: .day, value: range.count - 1, to: firstDay) else { return }

        isLoading = true
        errorMessage = nil
        do {
            events = try await eventRepo.list(
                dateFrom: firstDay.isoDateString,
                dateTo: lastDay.isoDateString,
                memberId: nil,
                categoryId: nil
            )
        } catch {
            errorMessage = "Termine konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadSharedData() async {
        do {
            async let cats = categoryRepo.list()
            async let mems = memberRepo.list()
            categories = try await cats
            members = try await mems
        } catch {
            errorMessage = "Stammdaten konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    // MARK: - CRUD

    func createEvent(_ body: EventCreate) async {
        errorMessage = nil
        do {
            let created = try await eventRepo.create(body)
            events.append(created)
        } catch {
            errorMessage = "Termin konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }

    func updateEvent(id: Int, _ body: EventUpdate) async {
        errorMessage = nil
        do {
            let updated = try await eventRepo.update(id: id, body)
            if let idx = events.firstIndex(where: { $0.id == id }) {
                events[idx] = updated
            }
        } catch {
            errorMessage = "Termin konnte nicht aktualisiert werden: \(error.localizedDescription)"
        }
    }

    func deleteEvent(id: Int) async {
        errorMessage = nil
        do {
            try await eventRepo.delete(id: id)
            events.removeAll { $0.id == id }
        } catch {
            errorMessage = "Termin konnte nicht geloescht werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    func eventsForDate(_ date: Date) -> [EventResponse] {
        let target = date.isoDateString
        return events.filter { event in
            guard let eventStart = Date.fromISODate(String(event.start.prefix(10))),
                  let eventEnd = Date.fromISODate(String(event.end.prefix(10))) else {
                return String(event.start.prefix(10)) == target
            }
            let targetDate = date.startOfDay
            return targetDate >= eventStart.startOfDay && targetDate <= eventEnd.startOfDay
        }
    }

    func navigateMonth(by offset: Int) {
        let cal = Calendar.current
        if let newMonth = cal.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}
