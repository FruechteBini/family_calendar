import SwiftUI

// MARK: - Pending Proposals View

struct PendingProposalsView: View {
    @Bindable var proposalVM: ProposalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var counterProposalId: Int?
    @State private var counterDate = Date()
    @State private var counterMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if proposalVM.pendingProposals.isEmpty && !proposalVM.isLoading {
                    EmptyStateView(
                        icon: "hand.thumbsup",
                        title: "Keine offenen Vorschläge",
                        subtitle: "Es liegen keine Terminvorschläge vor, die deine Aufmerksamkeit benötigen."
                    )
                } else {
                    List {
                        ForEach(proposalVM.pendingProposals) { proposal in
                            PendingProposalRow(
                                proposal: proposal,
                                counterProposalId: $counterProposalId,
                                counterDate: $counterDate,
                                counterMessage: $counterMessage,
                                onAccept: { await accept(proposal) },
                                onReject: { await reject(proposal) },
                                onCounter: { await counter(proposal) }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Offene Vorschläge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .loadingOverlay(isLoading: proposalVM.isLoading, message: "Laden…")
            .task {
                await proposalVM.loadPending()
            }
        }
    }

    private func accept(_ proposal: PendingProposalDetail) async {
        await proposalVM.respond(
            proposalId: proposal.id,
            response: "accepted",
            message: nil,
            counterDate: nil
        )
    }

    private func reject(_ proposal: PendingProposalDetail) async {
        await proposalVM.respond(
            proposalId: proposal.id,
            response: "rejected",
            message: nil,
            counterDate: nil
        )
    }

    private func counter(_ proposal: PendingProposalDetail) async {
        await proposalVM.respond(
            proposalId: proposal.id,
            response: "counter",
            message: counterMessage.isEmpty ? nil : counterMessage,
            counterDate: counterDate.isoDateString
        )
        counterProposalId = nil
        counterMessage = ""
    }
}

// MARK: - Pending Proposal Row

private struct PendingProposalRow: View {
    let proposal: PendingProposalDetail
    @Binding var counterProposalId: Int?
    @Binding var counterDate: Date
    @Binding var counterMessage: String
    var onAccept: () async -> Void
    var onReject: () async -> Void
    var onCounter: () async -> Void

    private var proposedDate: String {
        if let date = Date.fromISODate(proposal.proposedDate) {
            return "\(date.germanWeekday), \(date.germanDayMonth)"
        }
        return proposal.proposedDate
    }

    private var showCounter: Bool { counterProposalId == proposal.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(proposal.todoTitle)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 8) {
                Text(proposal.proposer.avatarEmoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(proposal.proposer.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Vorschlag: \(proposedDate)")
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
            }

            if let message = proposal.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 10) {
                Button {
                    Task { await onAccept() }
                } label: {
                    Label("Annehmen", systemImage: "checkmark")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appSuccess)

                Button {
                    Task { await onReject() }
                } label: {
                    Label("Ablehnen", systemImage: "xmark")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appDanger)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        counterProposalId = showCounter ? nil : proposal.id
                    }
                } label: {
                    Label("Gegenvorschlag", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
            }

            if showCounter {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    Text("Gegenvorschlag")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    DatePicker(
                        "Datum",
                        selection: $counterDate,
                        displayedComponents: [.date]
                    )
                    .environment(\.locale, Locale(identifier: "de_DE"))

                    TextField("Nachricht (optional)", text: $counterMessage, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...3)

                    Button {
                        Task { await onCounter() }
                    } label: {
                        Text("Gegenvorschlag senden")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appPrimary)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Proposal Timeline View

struct ProposalTimelineView: View {
    @Bindable var proposalVM: ProposalViewModel
    let todoId: Int

    var body: some View {
        Group {
            if proposalVM.todoProposals.isEmpty && !proposalVM.isLoading {
                Text("Keine Terminvorschläge vorhanden")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(proposalVM.todoProposals.sorted(by: { $0.createdAt < $1.createdAt })) { proposal in
                        ProposalTimelineItem(proposal: proposal)

                        if proposal.id != proposalVM.todoProposals.last?.id {
                            timelineConnector
                        }
                    }
                }
            }
        }
        .task {
            await proposalVM.loadForTodo(todoId: todoId)
        }
    }

    private var timelineConnector: some View {
        HStack {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 2, height: 20)
                .padding(.leading, 11)
            Spacer()
        }
    }
}

// MARK: - Timeline Item

private struct ProposalTimelineItem: View {
    let proposal: ProposalDetail

    private var statusColor: Color {
        switch proposal.status {
        case "pending": .appPrimary
        case "accepted": .appSuccess
        case "rejected": .appDanger
        default: .appSecondary
        }
    }

    private var statusLabel: String {
        switch proposal.status {
        case "pending": "Offen"
        case "accepted": "Angenommen"
        case "rejected": "Abgelehnt"
        case "superseded": "Ersetzt"
        default: proposal.status.capitalized
        }
    }

    private var proposedDateFormatted: String {
        if let date = Date.fromISODate(proposal.proposedDate) {
            return "\(date.germanWeekday), \(date.germanDayMonth)"
        }
        return proposal.proposedDate
    }

    private var createdAtFormatted: String {
        if let date = Date.fromISO(proposal.createdAt) {
            return date.germanDateString
        }
        return ""
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 24, height: 24)
                .overlay {
                    statusIcon
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(proposal.proposer.avatarEmoji)
                    Text(proposal.proposer.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(statusLabel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor, in: RoundedRectangle(cornerRadius: 4))
                }

                HStack(spacing: 12) {
                    Label(proposedDateFormatted, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.appSecondary)

                    if !createdAtFormatted.isEmpty {
                        Text(createdAtFormatted)
                            .font(.caption)
                            .foregroundStyle(.appSecondary.opacity(0.7))
                    }
                }

                if let message = proposal.message, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 6))
                }

                if !proposal.responses.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(proposal.responses) { response in
                            ProposalResponseRow(response: response)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch proposal.status {
        case "pending":
            Image(systemName: "clock")
        case "accepted":
            Image(systemName: "checkmark")
        case "rejected":
            Image(systemName: "xmark")
        default:
            Image(systemName: "arrow.triangle.2.circlepath")
        }
    }
}

// MARK: - Response Row

private struct ProposalResponseRow: View {
    let response: ProposalResponseDetail

    private var responseColor: Color {
        switch response.response {
        case "accepted": .appSuccess
        case "rejected": .appDanger
        default: .appPrimary
        }
    }

    private var responseLabel: String {
        switch response.response {
        case "accepted": "Angenommen"
        case "rejected": "Abgelehnt"
        case "counter": "Gegenvorschlag"
        default: response.response.capitalized
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(response.member.avatarEmoji)
                .font(.caption)
            Text(response.member.name)
                .font(.caption)
                .fontWeight(.medium)
            Text("–")
                .font(.caption)
                .foregroundStyle(.appSecondary)
            Text(responseLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(responseColor)

            if let message = response.message, !message.isEmpty {
                Text("„\(message)"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
