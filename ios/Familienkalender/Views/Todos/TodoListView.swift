import SwiftUI

struct TodoListView: View {
    @Bindable var viewModel: TodoViewModel
    @State private var quickAddTitle = ""
    @State private var quickAddPriority: Priority = .medium
    @State private var showingNewTodo = false
    @State private var editingTodo: TodoResponse?
    @State private var showFilterOptions = false

    private var hasActiveFilters: Bool {
        viewModel.filterPriority != nil
        || viewModel.filterMemberId != nil
        || viewModel.filterCategoryId != nil
        || viewModel.showCompleted
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                quickAddBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))

                if viewModel.groupedTodos.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "Keine Aufgaben",
                        subtitle: "Erstelle deine erste Aufgabe über das Textfeld oben oder den + Button.",
                        buttonTitle: "Aufgabe erstellen"
                    ) {
                        showingNewTodo = true
                    }
                } else {
                    List {
                        ForEach(viewModel.groupedTodos, id: \.section) { group in
                            Section {
                                ForEach(group.items) { todo in
                                    TodoItemRow(
                                        todo: todo,
                                        viewModel: viewModel,
                                        onEdit: { editingTodo = todo }
                                    )
                                }
                            } header: {
                                sectionHeader(group.section)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .refreshable {
                await viewModel.loadTodos()
            }
            .navigationTitle("Aufgaben")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Menu {
                            filterMenu
                        } label: {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundStyle(hasActiveFilters ? .appPrimary : .primary)
                        }

                        Button {
                            showingNewTodo = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewTodo) {
                TodoFormView(viewModel: viewModel)
            }
            .sheet(item: $editingTodo) { todo in
                TodoFormView(viewModel: viewModel, editingTodo: todo)
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.appDanger, in: RoundedRectangle(cornerRadius: 10))
                            .padding()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: viewModel.errorMessage)
                    .onTapGesture { viewModel.errorMessage = nil }
                }
            }
            .loadingOverlay(isLoading: viewModel.isLoading, message: "Aufgaben laden…")
            .task {
                async let todos: () = viewModel.loadTodos()
                async let shared: () = viewModel.loadSharedData()
                _ = await (todos, shared)
            }
        }
    }

    // MARK: - Quick Add

    private var quickAddBar: some View {
        HStack(spacing: 8) {
            TextField("Neue Aufgabe…", text: $quickAddTitle)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit { quickAdd() }

            Menu {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Button {
                        quickAddPriority = priority
                    } label: {
                        HStack {
                            Text(priority.displayName)
                            if priority == quickAddPriority {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                PriorityBadge(priority: quickAddPriority)
            }

            Button {
                quickAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.appPrimary)
            }
            .disabled(quickAddTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func quickAdd() {
        let trimmed = quickAddTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let body = TodoCreate(title: trimmed, priority: quickAddPriority.rawValue)
        quickAddTitle = ""
        Task { await viewModel.createTodo(body) }
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private var filterMenu: some View {
        Section("Priorität") {
            Button {
                viewModel.filterPriority = nil
                Task { await viewModel.loadTodos() }
            } label: {
                HStack {
                    Text("Alle")
                    if viewModel.filterPriority == nil { Image(systemName: "checkmark") }
                }
            }
            ForEach(Priority.allCases, id: \.self) { priority in
                Button {
                    viewModel.filterPriority = priority
                    Task { await viewModel.loadTodos() }
                } label: {
                    HStack {
                        Text(priority.displayName)
                        if viewModel.filterPriority == priority { Image(systemName: "checkmark") }
                    }
                }
            }
        }

        if !viewModel.members.isEmpty {
            Section("Mitglied") {
                Button {
                    viewModel.filterMemberId = nil
                    Task { await viewModel.loadTodos() }
                } label: {
                    HStack {
                        Text("Alle")
                        if viewModel.filterMemberId == nil { Image(systemName: "checkmark") }
                    }
                }
                ForEach(viewModel.members) { member in
                    Button {
                        viewModel.filterMemberId = member.id
                        Task { await viewModel.loadTodos() }
                    } label: {
                        HStack {
                            Text("\(member.avatarEmoji) \(member.name)")
                            if viewModel.filterMemberId == member.id { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
        }

        if !viewModel.categories.isEmpty {
            Section("Kategorie") {
                Button {
                    viewModel.filterCategoryId = nil
                    Task { await viewModel.loadTodos() }
                } label: {
                    HStack {
                        Text("Alle")
                        if viewModel.filterCategoryId == nil { Image(systemName: "checkmark") }
                    }
                }
                ForEach(viewModel.categories) { category in
                    Button {
                        viewModel.filterCategoryId = category.id
                        Task { await viewModel.loadTodos() }
                    } label: {
                        HStack {
                            Text("\(category.icon) \(category.name)")
                            if viewModel.filterCategoryId == category.id { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
        }

        Section {
            Toggle(isOn: Binding(
                get: { viewModel.showCompleted },
                set: { newValue in
                    viewModel.showCompleted = newValue
                    Task { await viewModel.loadTodos() }
                }
            )) {
                Text("Erledigte anzeigen")
            }
        }

        if hasActiveFilters {
            Section {
                Button(role: .destructive) {
                    viewModel.filterPriority = nil
                    viewModel.filterMemberId = nil
                    viewModel.filterCategoryId = nil
                    viewModel.showCompleted = false
                    Task { await viewModel.loadTodos() }
                } label: {
                    Label("Filter zurücksetzen", systemImage: "xmark.circle")
                }
            }
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ section: TodoViewModel.TodoSection) -> some View {
        HStack(spacing: 6) {
            switch section {
            case .overdue:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.appDanger)
                Text("Überfällig")
                    .foregroundStyle(.appDanger)
                    .fontWeight(.bold)
            case .today:
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.appWarning)
                Text("Heute")
                    .fontWeight(.semibold)
            case .thisWeek:
                Image(systemName: "calendar")
                    .foregroundStyle(.appPrimary)
                Text("Diese Woche")
                    .fontWeight(.semibold)
            case .later:
                Image(systemName: "clock")
                    .foregroundStyle(.appSecondary)
                Text("Später")
                    .fontWeight(.semibold)
            case .noDueDate:
                Image(systemName: "tray")
                    .foregroundStyle(.appSecondary)
                Text("Ohne Datum")
                    .fontWeight(.semibold)
            }
        }
        .font(.subheadline)
        .textCase(nil)
    }
}
