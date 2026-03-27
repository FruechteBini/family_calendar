import SwiftUI

struct EventFormView: View {
    @Bindable var viewModel: CalendarViewModel
    var editingEvent: EventResponse?
    var initialDate: Date?

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var allDay = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedCategoryId: Int?
    @State private var selectedMemberIds: Set<Int> = []
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var localError: String?

    private var isEditing: Bool { editingEvent != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titel *", text: $title)
                        .font(.body)
                    TextField("Beschreibung (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Toggle("Ganztägig", isOn: $allDay)

                    DatePicker(
                        "Beginn",
                        selection: $startDate,
                        displayedComponents: allDay ? [.date] : [.date, .hourAndMinute]
                    )
                    .environment(\.locale, Locale(identifier: "de_DE"))

                    DatePicker(
                        "Ende",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: allDay ? [.date] : [.date, .hourAndMinute]
                    )
                    .environment(\.locale, Locale(identifier: "de_DE"))
                }

                Section("Kategorie") {
                    CategoryPicker(
                        categories: viewModel.categories,
                        selectedCategoryId: $selectedCategoryId
                    )
                }

                if !viewModel.members.isEmpty {
                    Section("Teilnehmer") {
                        MemberChipRow(
                            members: viewModel.members,
                            selectedIds: $selectedMemberIds
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
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
                                Label("Termin löschen", systemImage: "trash")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Termin bearbeiten" : "Neuer Termin")
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
            .alert("Termin löschen?", isPresented: $showDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) {}
                Button("Löschen", role: .destructive) {
                    Task { await deleteEvent() }
                }
            } message: {
                Text("Möchtest du diesen Termin wirklich löschen? Dies kann nicht rückgängig gemacht werden.")
            }
            .disabled(isSaving)
            .interactiveDismissDisabled(isSaving)
            .onAppear(perform: prefill)
        }
    }

    // MARK: - Prefill

    private func prefill() {
        if let event = editingEvent {
            title = event.title
            description = event.description ?? ""
            allDay = event.allDay

            if let s = Date.fromISO(event.start) { startDate = s }
            else if let s = Date.fromISODate(event.start) { startDate = s }

            if let e = Date.fromISO(event.end) { endDate = e }
            else if let e = Date.fromISODate(event.end) { endDate = e }

            selectedCategoryId = event.category?.id
            selectedMemberIds = Set(event.members.map(\.id))
        } else if let date = initialDate {
            let cal = Calendar.current
            startDate = cal.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
            endDate = cal.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
        }
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

        let startStr = allDay ? startDate.isoDateString : startDate.isoDateTimeString
        let endStr = allDay ? endDate.isoDateString : endDate.isoDateTimeString

        if let event = editingEvent {
            let body = EventUpdate(
                title: trimmed,
                description: description.isEmpty ? nil : description,
                start: startStr,
                end: endStr,
                allDay: allDay,
                categoryId: selectedCategoryId,
                memberIds: Array(selectedMemberIds)
            )
            await viewModel.updateEvent(id: event.id, body)
        } else {
            let body = EventCreate(
                title: trimmed,
                description: description.isEmpty ? nil : description,
                start: startStr,
                end: endStr,
                allDay: allDay,
                categoryId: selectedCategoryId,
                memberIds: Array(selectedMemberIds)
            )
            await viewModel.createEvent(body)
        }

        isSaving = false
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }

    // MARK: - Delete

    private func deleteEvent() async {
        guard let event = editingEvent else { return }
        isSaving = true
        await viewModel.deleteEvent(id: event.id)
        isSaving = false
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
