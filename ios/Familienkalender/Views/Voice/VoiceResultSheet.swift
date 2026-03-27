import SwiftUI

struct VoiceResultSheet: View {
    let viewModel: VoiceCommandViewModel

    @Environment(\.dismiss) private var dismiss

    private var isError: Bool {
        viewModel.errorMessage != nil && viewModel.result == nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    if !viewModel.transcript.isEmpty {
                        transcriptSection
                    }

                    if let error = viewModel.errorMessage, viewModel.result == nil {
                        errorSection(error)
                    }

                    if let result = viewModel.result {
                        summarySection(result.summary)

                        if !result.actions.isEmpty {
                            actionsSection(result.actions)
                        }
                    }

                    closeButton
                }
                .padding(20)
            }
            .navigationTitle("Sprachbefehl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.appSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Text(isError ? "⚠️" : "🎤")
                .font(.system(size: 32))

            Text(isError ? "Fehler" : "Sprachbefehl ausgeführt")
                .font(.title3)
                .fontWeight(.bold)
        }
    }

    // MARK: - Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Eingabe")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.appSecondary)
                .textCase(.uppercase)

            Text("„\(viewModel.transcript)"")
                .font(.body)
                .italic()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Error

    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.appDanger)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appDanger.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Summary

    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Zusammenfassung")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.appSecondary)
                .textCase(.uppercase)

            Text(summary)
                .font(.body)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSuccess.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Actions

    private func actionsSection(_ actions: [VoiceCommandAction]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aktionen")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.appSecondary)
                .textCase(.uppercase)

            ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                actionRow(action)
            }
        }
    }

    private func actionRow(_ action: VoiceCommandAction) -> some View {
        let info = actionInfo(for: action.type)
        let isSuccess = action.ref != nil || action.result != nil

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(isSuccess ? .appSuccess : .appDanger)

                Text(info.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }

            if let detail = actionDetailText(action) {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .padding(.leading, 30)
            }

            if action.type == "generate_meal_plan", let result = action.result {
                mealPlanDetail(result)
                    .padding(.leading, 30)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Meal Plan Detail

    private func mealPlanDetail(_ result: [String: AnyCodableValue]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let reasoning = result["reasoning"]?.stringValue {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "brain")
                        .font(.caption)
                        .foregroundStyle(.appPrimary)
                    Text(reasoning)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .background(Color.appPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }

            if case .array(let meals) = result["meals"] {
                ForEach(Array(meals.enumerated()), id: \.offset) { _, meal in
                    if case .dictionary(let dict) = meal {
                        mealRow(dict)
                    }
                }
            }
        }
    }

    private func mealRow(_ dict: [String: AnyCodableValue]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.caption2)
                .foregroundStyle(.appPrimary)
                .frame(width: 16)

            if let date = dict["date"]?.stringValue {
                Text(date)
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .leading)
            }

            if let slot = dict["slot"]?.stringValue {
                Text(slot == "lunch" ? "Mittag" : "Abend")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .frame(width: 50, alignment: .leading)
            }

            if let title = dict["title"]?.stringValue {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Close

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Schließen")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
        }
        .buttonStyle(.borderedProminent)
        .tint(.appPrimary)
        .controlSize(.large)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.top, 8)
    }

    // MARK: - Action Label Mapping

    private struct ActionTypeInfo {
        let label: String
        let icon: String
    }

    private func actionInfo(for type: String) -> ActionTypeInfo {
        switch type {
        case "create_event":
            return ActionTypeInfo(label: "Termin erstellt", icon: "calendar.badge.plus")
        case "create_recurring_event":
            return ActionTypeInfo(label: "Serientermin erstellt", icon: "calendar.badge.clock")
        case "create_todo":
            return ActionTypeInfo(label: "Aufgabe erstellt", icon: "checklist")
        case "create_recipe":
            return ActionTypeInfo(label: "Rezept erstellt", icon: "fork.knife")
        case "set_meal_slot":
            return ActionTypeInfo(label: "Essensplan belegt", icon: "calendar.day.timeline.left")
        case "generate_meal_plan":
            return ActionTypeInfo(label: "Essensplan erstellt", icon: "sparkles")
        case "add_shopping_item":
            return ActionTypeInfo(label: "Einkaufsartikel hinzugefügt", icon: "cart.badge.plus")
        case "add_pantry_items":
            return ActionTypeInfo(label: "Vorrat aktualisiert", icon: "shippingbox")
        case "complete_todo":
            return ActionTypeInfo(label: "Aufgabe erledigt", icon: "checkmark.circle")
        case "mark_cooked":
            return ActionTypeInfo(label: "Als gekocht markiert", icon: "flame")
        case "update_event":
            return ActionTypeInfo(label: "Termin bearbeitet", icon: "calendar.badge.exclamationmark")
        case "update_todo":
            return ActionTypeInfo(label: "Aufgabe bearbeitet", icon: "pencil.circle")
        case "delete_event":
            return ActionTypeInfo(label: "Termin gelöscht", icon: "calendar.badge.minus")
        case "delete_todo":
            return ActionTypeInfo(label: "Aufgabe gelöscht", icon: "trash")
        default:
            return ActionTypeInfo(label: type, icon: "questionmark.circle")
        }
    }

    // MARK: - Action Detail Text

    private func actionDetailText(_ action: VoiceCommandAction) -> String? {
        guard let result = action.result else {
            if let ref = action.ref {
                return "Ref: \(ref)"
            }
            return nil
        }

        var parts: [String] = []

        if let title = result["title"]?.stringValue {
            parts.append(title)
        }
        if let name = result["name"]?.stringValue, !parts.contains(name) {
            parts.append(name)
        }
        if let date = result["date"]?.stringValue {
            parts.append(date)
        }
        if let time = result["start_time"]?.stringValue {
            parts.append(time)
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
