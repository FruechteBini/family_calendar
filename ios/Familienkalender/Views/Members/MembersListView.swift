import SwiftUI

struct MembersListView: View {
    let viewModel: MemberViewModel

    @State private var editMember: FamilyMemberResponse?
    @State private var showCreateSheet = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    @State private var deleteTarget: FamilyMemberResponse?
    @State private var showDeleteConfirm = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        Group {
            if viewModel.members.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "person.2",
                    title: "Keine Familienmitglieder",
                    subtitle: "Füge Familienmitglieder hinzu, um Termine und Aufgaben zuzuweisen.",
                    buttonTitle: "Mitglied hinzufügen"
                ) {
                    showCreateSheet = true
                }
            } else {
                memberGrid
            }
        }
        .navigationTitle("Familienmitglieder")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            MemberFormView(viewModel: viewModel) { message in
                toastMessage = message
                toastType = .success
                showToast = true
            }
        }
        .sheet(item: $editMember) { member in
            MemberFormView(viewModel: viewModel, existing: member) { message in
                toastMessage = message
                toastType = .success
                showToast = true
            }
        }
        .confirmationDialog(
            "Mitglied löschen?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                guard let target = deleteTarget else { return }
                Task {
                    await viewModel.deleteMember(id: target.id)
                    if viewModel.errorMessage == nil {
                        toastMessage = "\(target.name) wurde gelöscht"
                        toastType = .success
                        showToast = true
                    }
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            if let target = deleteTarget {
                Text("\(target.name) wird unwiderruflich entfernt.")
            }
        }
        .toast(isShowing: $showToast, message: toastMessage, type: toastType)
        .loadingOverlay(isLoading: viewModel.isLoading)
        .task { await viewModel.loadMembers() }
    }

    // MARK: - Grid

    private var memberGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.members) { member in
                    memberCard(member)
                        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16))
                        .contextMenu {
                            Button {
                                editMember = member
                            } label: {
                                Label("Bearbeiten", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                deleteTarget = member
                                showDeleteConfirm = true
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            editMember = member
                        }
                }
            }
            .padding(16)
        }
        .refreshable { await viewModel.loadMembers() }
    }

    // MARK: - Card

    private func memberCard(_ member: FamilyMemberResponse) -> some View {
        VStack(spacing: 12) {
            Text(member.avatarEmoji)
                .font(.system(size: 44))
                .frame(width: 80, height: 80)
                .background(Color(hex: member.color).opacity(0.2), in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color(hex: member.color), lineWidth: 3)
                )

            Text(member.name)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)

            Text("Seit \(formattedDate(member.createdAt))")
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Helpers

    private func formattedDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()

        guard let date = iso.date(from: isoString) ?? fallback.date(from: isoString) else {
            return isoString.prefix(10).description
        }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }
}
