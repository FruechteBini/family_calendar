import SwiftUI

struct AIConfigStepView: View {
    @Bindable var viewModel: AIMealPlanViewModel
    let weekStart: String

    private var weekNumber: Int {
        guard let d = Date.fromISODate(weekStart) else { return 0 }
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        return cal.component(.weekOfYear, from: d)
    }

    private var dateRangeText: String {
        guard let start = Date.fromISODate(weekStart) else { return weekStart }
        let end = start.adding(days: 6)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "d. MMM"
        let yearFmt = DateFormatter()
        yearFmt.dateFormat = "yyyy"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end)) \(yearFmt.string(from: end))"
    }

    private let weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                weekInfoCard
                slotGrid
                settingsCard
                generateButton
            }
            .padding(16)
        }
    }

    // MARK: - Week Info

    private var weekInfoCard: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(.appPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("KW \(weekNumber)")
                    .font(.headline)
                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }

            Spacer()

            if let recipes = viewModel.availableRecipes {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(recipes.localCount) Rezepte")
                        .font(.caption)
                        .fontWeight(.medium)

                    if recipes.cookidooAvailable {
                        Text("+ \(recipes.cookidooCount) Cookidoo")
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Slot Grid

    private var slotGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Slots auswählen")
                .font(.subheadline)
                .fontWeight(.bold)

            Text("Wähle die Slots, für die KI-Vorschläge generiert werden sollen.")
                .font(.caption)
                .foregroundStyle(.appSecondary)

            gridHeader

            if let available = viewModel.availableRecipes {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let dateStr = dateForDayIndex(dayIndex)
                    gridRow(
                        dayIndex: dayIndex,
                        dateStr: dateStr,
                        filledSlots: available.filledSlots,
                        emptySlots: available.emptySlots
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var gridHeader: some View {
        HStack {
            Text("Tag")
                .frame(width: 40, alignment: .leading)
            Spacer()
            Text("Mittag")
                .frame(maxWidth: .infinity)
            Text("Abend")
                .frame(maxWidth: .infinity)
        }
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundStyle(.appSecondary)
        .textCase(.uppercase)
    }

    private func gridRow(dayIndex: Int, dateStr: String, filledSlots: [FilledSlotInfo], emptySlots: [EmptySlotInfo]) -> some View {
        HStack {
            Text(weekdays[dayIndex])
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 40, alignment: .leading)

            Spacer()

            slotCell(dateStr: dateStr, slot: "lunch", filledSlots: filledSlots, emptySlots: emptySlots)
                .frame(maxWidth: .infinity)

            slotCell(dateStr: dateStr, slot: "dinner", filledSlots: filledSlots, emptySlots: emptySlots)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func slotCell(dateStr: String, slot: String, filledSlots: [FilledSlotInfo], emptySlots: [EmptySlotInfo]) -> some View {
        let key = "\(dateStr)_\(slot)"
        let filled = filledSlots.first { $0.date == dateStr && $0.slot == slot }
        let isEmpty = emptySlots.contains { $0.date == dateStr && $0.slot == slot }

        if let filled {
            Text(filled.recipeTitle)
                .font(.system(size: 10))
                .lineLimit(1)
                .foregroundStyle(.appSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
        } else if isEmpty {
            let isSelected = viewModel.selectedSlots.contains(key)
            Button {
                if isSelected {
                    viewModel.selectedSlots.remove(key)
                } else {
                    viewModel.selectedSlots.insert(key)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark" : "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        isSelected ? Color.appPrimary : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Color.appPrimary : Color(.systemGray4), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        } else {
            Color(.systemGray6)
                .frame(height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Settings

    private var settingsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "person.2")
                    .foregroundStyle(.appPrimary)
                Text("Portionen")
                    .font(.subheadline)
                Spacer()
                Stepper("\(viewModel.servings)", value: $viewModel.servings, in: 1...12)
                    .labelsHidden()
                Text("\(viewModel.servings)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 28)
            }

            Divider()

            if viewModel.availableRecipes?.cookidooAvailable == true {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.appPrimary)
                    Toggle("Cookidoo-Rezepte einbeziehen", isOn: $viewModel.includeCookidoo)
                        .font(.subheadline)
                }

                Divider()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundStyle(.appPrimary)
                    Text("Wünsche & Vorlieben")
                        .font(.subheadline)
                }

                TextField("z.B. vegetarisch, schnelle Gerichte, italienisch…", text: $viewModel.preferences, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Generate

    private var generateButton: some View {
        Button {
            Task { await viewModel.generatePlan(weekStart: weekStart) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Plan generieren")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.appPrimary, Color(hex: "#0065FF")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .shadow(color: .appPrimary.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(viewModel.selectedSlots.isEmpty || viewModel.isLoading)
        .opacity(viewModel.selectedSlots.isEmpty ? 0.5 : 1)
    }

    // MARK: - Helpers

    private func dateForDayIndex(_ index: Int) -> String {
        guard let start = Date.fromISODate(weekStart) else { return "" }
        return start.adding(days: index).isoDateString
    }
}
