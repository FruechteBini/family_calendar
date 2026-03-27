import SwiftUI

struct TodoFormView: View {
    @Bindable var viewModel: TodoViewModel
    var editingTodo: TodoResponse?

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var priority: Priority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedCategoryId: Int?
    @State private var selectedMemberIds: Set<Int> = []
    @State private var requiresMultiple = false
    @State private var newSubtodoTitle = ""
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var localError: String?

    private var isEditing: Bool { editingTodo != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titel *", text: $title)
                    TextField("Beschreibung (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Priorität") {
                    Picker("Priorität", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Fälligkeitsdatum") {
                    Toggle("Fälligkeitsdatum setzen", isOn: $hasDueDate.animation(.easeInOut(duration: 0.2)))

                    if hasDueDate {
                        DatePicker(
                            "Fällig am",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                        .environment(\.locale, Locale(identifier: "de_DE"))
                    }
                }

                Section("Kategorie") {
                    CategoryPicker(
                        categories: viewModel.categories,
                        selectedCategoryId: $selectedCategoryId
                    )
                }

                if !viewModel.members.isEmpty {
                    Section("Zugewiesen an") {
                        MemberChipRow(
                            members: viewModel.members,
                            selectedIds: $selectedMemberIds
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))

                        if selectedMemberIds.count > 1 {
                            Toggle("Mehrere Personen erforderlich", isOn: $requiresMultiple)
                        }
                    }
                }

                if isEditing, let todo = editingTodo {
                    Section("Unteraufgaben") {
                        if todo.subtodos.isEmpty {
                            Text("Keine Unteraufgaben vorhanden")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(todo.subtodos) { subtodo in
                                HStack(spacing: 10) {
                                    Image(systemName: subtodo.completed ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(subtodo.completed ? .appSuccess : .appSecondary)
                                    Text(subtodo.title)
                                        .strikethrough(subtodo.completed)
                                        .foregroundStyle(subtodo.completed ? .secondary : .primary)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            TextField("Neue Unteraufgabe…", text: $newSubtodoTitle)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                                .onSubmit { addSubtodo() }

                            Button {
                                addSubtodo()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.appPrimary)
                            }
                            .disabled(newSubtodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }

                if let error = localError ?? viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.appDanger)
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Aufgabe löschen", systemImage: "trash")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Aufgabe bearbeiten" : "Neue Aufgabe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Speichern" : "Erstellen") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isSaving)
                }
            }
            .alert("Aufgabe löschen?", isPresented: $showDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) {}
                Button("Löschen", role: .destructive) {
                    Task { await deleteTodo() }
                }
            } message: {
                Text("Möchtest du diese Aufgabe wirklich löschen? Alle Unteraufgaben werden ebenfalls gelöscht.")
            }
            .disabled(isSaving)
            .interactiveDismissDisabled(isSaving)
            .onAppear(perform: prefill)
        }
    }

    // MARK: - Prefill

    private func prefill() {
        guard let todo = editingTodo else { return }
        title = todo.title
        description = todo.description ?? ""
        priority = todo.priorityEnum
        if let dueDateStr = todo.dueDate, let date = Date.fromISODate(dueDateStr) {
            hasDueDate = true
            dueDate = date
        }
        selectedCategoryId = todo.category?.id
        selectedMemberIds = Set(todo.members.map(\.id))
        requiresMultiple = todo.requiresMultiple
    }

    // MARK: - Save

    private func save() async {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            localError = "Bitte gib einen Titel ein."
            return
        }
        localError = nil
        isSaving = true

        let dueDateStr = hasDueDate ? dueDate.isoDateString : nil

        if let todo = editingTodo {
            let body = TodoUpdate(
                title: trimmed,
                description: description.isEmpty ? nil : description,
                priority: priority.rawValue,
                dueDate: dueDateStr,
                categoryId: selectedCategoryId,
                requiresMultiple: requiresMultiple,
                memberIds: Array(selectedMemberIds)
            )
            await viewModel.updateTodo(id: todo.id, body)
        } else {
            let body = TodoCreate(
                title: trimmed,
                description: description.isEmpty ? nil : description,
                priority: priority.rawValue,
                dueDate: dueDateStr,
                categoryId: selectedCategoryId,
                requiresMultiple: requiresMultiple,
                memberIds: Array(selectedMemberIds)
            )
            await viewModel.createTodo(body)
        }

        isSaving = false
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }

    // MARK: - Subtodo

    private func addSubtodo() {
        let trimmed = newSubtodoTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let todo = editingTodo else { return }
        newSubtodoTitle = ""
        Task { await viewModel.createSubtodo(parentId: todo.id, title: trimmed) }
    }

    // MARK: - Delete

    private func deleteTodo() async {
        guard let todo = editingTodo else { return }
        isSaving = true
        await viewModel.deleteTodo(id: todo.id)
        isSaving = false
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
