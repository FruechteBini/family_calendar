import Foundation

@Observable
@MainActor
final class TodoViewModel {

    // MARK: - Section grouping

    enum TodoSection: String, CaseIterable {
        case overdue = "Ueberfaellig"
        case today = "Heute"
        case thisWeek = "Diese Woche"
        case later = "Spaeter"
        case noDueDate = "Ohne Faelligkeitsdatum"
    }

    // MARK: - State

    var todos: [TodoResponse] = []
    var isLoading: Bool = false
    var errorMessage: String?

    var filterPriority: Priority?
    var filterMemberId: Int?
    var filterCategoryId: Int?
    var showCompleted: Bool = false

    var categories: [CategoryResponse] = []
    var members: [FamilyMemberResponse] = []

    // MARK: - Computed

    var groupedTodos: [(section: TodoSection, items: [TodoResponse])] {
        let cal = Calendar.current
        let now = Date()
        let todayStart = cal.startOfDay(for: now)
        let weekEnd = cal.date(byAdding: .day, value: 7, to: todayStart)!

        let topLevel = todos.filter { $0.parentId == nil }

        var overdue: [TodoResponse] = []
        var today: [TodoResponse] = []
        var thisWeek: [TodoResponse] = []
        var later: [TodoResponse] = []
        var noDueDate: [TodoResponse] = []

        for todo in topLevel {
            guard let dueDateStr = todo.dueDate,
                  let dueDate = Date.fromISODate(dueDateStr) else {
                noDueDate.append(todo)
                continue
            }
            let due = cal.startOfDay(for: dueDate)
            if due < todayStart && !todo.completed {
                overdue.append(todo)
            } else if cal.isDate(due, inSameDayAs: todayStart) {
                today.append(todo)
            } else if due < weekEnd {
                thisWeek.append(todo)
            } else {
                later.append(todo)
            }
        }

        return TodoSection.allCases.compactMap { section in
            let items: [TodoResponse]
            switch section {
            case .overdue: items = overdue
            case .today: items = today
            case .thisWeek: items = thisWeek
            case .later: items = later
            case .noDueDate: items = noDueDate
            }
            return items.isEmpty ? nil : (section: section, items: items)
        }
    }

    // MARK: - Dependencies

    private let todoRepo: TodoRepository
    private let categoryRepo: CategoryRepository
    private let memberRepo: MemberRepository

    init(todoRepo: TodoRepository, categoryRepo: CategoryRepository, memberRepo: MemberRepository) {
        self.todoRepo = todoRepo
        self.categoryRepo = categoryRepo
        self.memberRepo = memberRepo
    }

    // MARK: - Load

    func loadTodos() async {
        isLoading = true
        errorMessage = nil
        do {
            todos = try await todoRepo.list(
                completed: showCompleted ? true : nil,
                priority: filterPriority?.rawValue,
                memberId: filterMemberId,
                categoryId: filterCategoryId
            )
        } catch {
            errorMessage = "Aufgaben konnten nicht geladen werden: \(error.localizedDescription)"
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

    func createTodo(_ body: TodoCreate) async {
        errorMessage = nil
        do {
            let created = try await todoRepo.create(body)
            todos.append(created)
        } catch {
            errorMessage = "Aufgabe konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }

    func updateTodo(id: Int, _ body: TodoUpdate) async {
        errorMessage = nil
        do {
            let updated = try await todoRepo.update(id: id, body)
            if let idx = todos.firstIndex(where: { $0.id == id }) {
                todos[idx] = updated
            }
        } catch {
            errorMessage = "Aufgabe konnte nicht aktualisiert werden: \(error.localizedDescription)"
        }
    }

    func completeTodo(id: Int) async {
        errorMessage = nil
        do {
            let updated = try await todoRepo.complete(id: id)
            if let idx = todos.firstIndex(where: { $0.id == id }) {
                todos[idx] = updated
            }
        } catch {
            errorMessage = "Status konnte nicht geaendert werden: \(error.localizedDescription)"
        }
    }

    func deleteTodo(id: Int) async {
        errorMessage = nil
        do {
            try await todoRepo.delete(id: id)
            todos.removeAll { $0.id == id }
        } catch {
            errorMessage = "Aufgabe konnte nicht geloescht werden: \(error.localizedDescription)"
        }
    }

    func createSubtodo(parentId: Int, title: String) async {
        errorMessage = nil
        let body = TodoCreate(title: title, parentId: parentId)
        do {
            _ = try await todoRepo.create(body)
            await loadTodos()
        } catch {
            errorMessage = "Unteraufgabe konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }
}
