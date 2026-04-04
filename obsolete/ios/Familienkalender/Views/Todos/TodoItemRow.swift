import SwiftUI

struct TodoItemRow: View {
    let todo: TodoResponse
    @Bindable var viewModel: TodoViewModel
    var onEdit: () -> Void

    @State private var showSubtodos = false
    @State private var newSubtodoTitle = ""

    private var isOverdue: Bool {
        guard let dueDateStr = todo.dueDate,
              let dueDate = Date.fromISODate(dueDateStr) else { return false }
        return dueDate.startOfDay < Date().startOfDay && !todo.completed
    }

    private var dueDateText: String? {
        guard let dueDateStr = todo.dueDate,
              let dueDate = Date.fromISODate(dueDateStr) else { return nil }
        return dueDate.germanDateString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainRow
                .contentShape(Rectangle())
                .onTapGesture { onEdit() }

            if !todo.subtodos.isEmpty || showSubtodos {
                subtodoSection
                    .padding(.leading, 36)
                    .padding(.top, 6)
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                Task { await viewModel.completeTodo(id: todo.id) }
            } label: {
                Image(systemName: todo.completed ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(.appSuccess)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task { await viewModel.deleteTodo(id: todo.id) }
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                Task { await viewModel.completeTodo(id: todo.id) }
            } label: {
                Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.completed ? .appSuccess : .appSecondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(todo.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(todo.completed)
                        .foregroundStyle(todo.completed ? .secondary : .primary)
                        .lineLimit(2)

                    if todo.requiresMultiple {
                        Text("👥")
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    if let dueDateText {
                        Label(dueDateText, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(isOverdue ? .appDanger : .appSecondary)
                            .fontWeight(isOverdue ? .semibold : .regular)
                    }

                    if !todo.subtodos.isEmpty {
                        let done = todo.subtodos.filter(\.completed).count
                        Label("\(done)/\(todo.subtodos.count)", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    if let cat = todo.category {
                        Text(cat.icon)
                            .font(.caption)
                    }
                    PriorityBadge(priority: todo.priorityEnum)
                }

                if !todo.members.isEmpty {
                    HStack(spacing: -4) {
                        ForEach(todo.members.prefix(3)) { member in
                            Text(member.avatarEmoji)
                                .font(.system(size: 12))
                                .frame(width: 20, height: 20)
                                .background(Color(hex: member.color).opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subtodos

    private var subtodoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !todo.subtodos.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSubtodos.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showSubtodos ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                        Text("\(todo.subtodos.count) Unteraufgaben")
                            .font(.caption)
                    }
                    .foregroundStyle(.appSecondary)
                }
                .buttonStyle(.plain)
            }

            if showSubtodos || todo.subtodos.isEmpty {
                ForEach(todo.subtodos) { subtodo in
                    HStack(spacing: 8) {
                        Image(systemName: subtodo.completed ? "checkmark.circle.fill" : "circle")
                            .font(.subheadline)
                            .foregroundStyle(subtodo.completed ? .appSuccess : .appSecondary)

                        Text(subtodo.title)
                            .font(.subheadline)
                            .strikethrough(subtodo.completed)
                            .foregroundStyle(subtodo.completed ? .secondary : .primary)
                    }
                    .padding(.vertical, 2)
                }

                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundStyle(.appPrimary)

                    TextField("Sub-Aufgabe hinzufügen", text: $newSubtodoTitle)
                        .font(.subheadline)
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .onSubmit { addSubtodo() }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func addSubtodo() {
        let trimmed = newSubtodoTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        newSubtodoTitle = ""
        Task { await viewModel.createSubtodo(parentId: todo.id, title: trimmed) }
    }
}
