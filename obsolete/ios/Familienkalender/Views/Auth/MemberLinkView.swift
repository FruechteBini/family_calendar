import SwiftUI

struct MemberLinkView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AppDependencies.self) private var deps
    @State private var members: [FamilyMemberResponse] = []
    @State private var selectedMemberId: Int?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            headerSection

            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if members.isEmpty {
                emptyState
            } else {
                memberGrid
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.appDanger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            actionButtons
        }
        .padding(.horizontal, 24)
        .task {
            await loadMembers()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(Color.appPrimary)
                .symbolRenderingMode(.hierarchical)

            Text("Wer bist du?")
                .font(.title)
                .fontWeight(.bold)

            Text("Verknuepfe dich mit deinem Familienmitglied")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Keine Familienmitglieder vorhanden")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Ueberspringe diesen Schritt und erstelle spaeter Familienmitglieder.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
    }

    // MARK: - Member Grid

    private var memberGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(members) { member in
                    MemberCard(
                        member: member,
                        isSelected: selectedMemberId == member.id
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedMemberId == member.id {
                                selectedMemberId = nil
                            } else {
                                selectedMemberId = member.id
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await confirmLink() }
            } label: {
                Group {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Bestaetigen")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(selectedMemberId == nil || authManager.isLoading)

            Button("Ueberspringen") {
                Task { await authManager.checkAuth() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Actions

    private func loadMembers() async {
        isLoading = true
        errorMessage = nil
        do {
            members = try await deps.memberRepository.list()
        } catch {
            errorMessage = "Mitglieder konnten nicht geladen werden: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func confirmLink() async {
        guard let memberId = selectedMemberId else { return }
        errorMessage = nil
        do {
            try await authManager.linkMember(memberId: memberId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Member Card

private struct MemberCard: View {
    let member: FamilyMemberResponse
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(member.avatarEmoji)
                .font(.system(size: 40))

            Text(member.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.appPrimary.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2.5)
        )
    }
}
