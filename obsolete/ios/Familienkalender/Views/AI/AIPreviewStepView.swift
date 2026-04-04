import SwiftUI

struct AIPreviewStepView: View {
    let viewModel: AIMealPlanViewModel
    let mealPlanVM: MealPlanViewModel
    let weekStart: String
    let onDismiss: () -> Void

    @State private var showReasoning = false

    private let weekdayMap: [String: String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE"
        var map: [String: String] = [:]
        let refDate = Date().mondayOfWeek
        for i in 0..<7 {
            let d = refDate.adding(days: i)
            map[d.isoDateString] = formatter.string(from: d)
        }
        return map
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerBadge
                suggestionsList

                if let reasoning = viewModel.preview?.reasoning, !reasoning.isEmpty {
                    reasoningSection(reasoning)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.appDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                actionButtons
            }
            .padding(16)
        }
    }

    // MARK: - Header

    private var headerBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.appPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("KI-Vorschläge")
                    .font(.headline)

                let count = viewModel.preview?.suggestions.count ?? 0
                Text("\(count) Gerichte vorgeschlagen")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.appPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Suggestions

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            tableHeader

            if let suggestions = viewModel.preview?.suggestions {
                ForEach(suggestions) { suggestion in
                    suggestionRow(suggestion)

                    if suggestion.id != suggestions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var tableHeader: some View {
        HStack {
            Text("Tag")
                .frame(width: 70, alignment: .leading)
            Text("Slot")
                .frame(width: 50)
            Text("Rezept")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Quelle")
                .frame(width: 70)
        }
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundStyle(.appSecondary)
        .textCase(.uppercase)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .clipShape(
            UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
        )
    }

    private func suggestionRow(_ suggestion: MealSuggestion) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text(weekdayName(suggestion.date))
                    .font(.caption)
                    .fontWeight(.medium)
                Text(shortDate(suggestion.date))
                    .font(.system(size: 9))
                    .foregroundStyle(.appSecondary)
            }
            .frame(width: 70, alignment: .leading)

            Text(suggestion.slot == "lunch" ? "Mittag" : "Abend")
                .font(.caption)
                .foregroundStyle(.appSecondary)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.recipeTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let diff = suggestion.difficulty, let d = Difficulty(rawValue: diff) {
                        DifficultyBadge(difficulty: d)
                    }

                    if let prep = suggestion.prepTime, prep > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                            Text("\(prep) Min.")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(.appSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            sourceBadge(suggestion.source)
                .frame(width: 70)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func sourceBadge(_ source: String) -> some View {
        Text(source == "cookidoo" ? "Cookidoo" : "Lokal")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                source == "cookidoo" ? Color(hex: "#36B37E") : .appPrimary,
                in: Capsule()
            )
    }

    // MARK: - Reasoning

    private func reasoningSection(_ reasoning: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    showReasoning.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.appPrimary)
                    Text("KI-Begründung")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showReasoning ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
            }
            .buttonStyle(.plain)

            if showReasoning {
                Text(reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    if let result = await viewModel.confirmPlan(weekStart: weekStart) {
                        mealPlanVM.startUndoTimer(mealIds: result.mealIds)
                        onDismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Bestätigen")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(.appSuccess, in: RoundedRectangle(cornerRadius: 14))
            }

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.generatePlan(weekStart: weekStart) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Neu generieren")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.appPrimary)
                    .background(Color.appPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.step = .config
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.appSecondary)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Helpers

    private func weekdayName(_ dateStr: String) -> String {
        guard let date = Date.fromISODate(dateStr) else { return "" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "EEEE"
        return fmt.string(from: date)
    }

    private func shortDate(_ dateStr: String) -> String {
        guard let date = Date.fromISODate(dateStr) else { return dateStr }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "dd.MM."
        return fmt.string(from: date)
    }
}
