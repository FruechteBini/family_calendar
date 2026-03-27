import SwiftUI

struct MarkCookedSheet: View {
    let date: String
    let slot: String
    let mealSlot: MealSlotResponse
    let viewModel: MealPlanViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var servings: Int
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var deductions: [PantryDeduction] = []
    @State private var showDeductions = false

    init(date: String, slot: String, mealSlot: MealSlotResponse, viewModel: MealPlanViewModel) {
        self.date = date
        self.slot = slot
        self.mealSlot = mealSlot
        self.viewModel = viewModel
        self._servings = State(initialValue: mealSlot.servingsPlanned)
    }

    var body: some View {
        NavigationStack {
            Group {
                if showDeductions {
                    deductionsView
                } else {
                    formView
                }
            }
            .navigationTitle("Als gekocht markieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        ScrollView {
            VStack(spacing: 24) {
                recipeHeader
                servingsField
                ratingField
                notesField
                confirmButton
            }
            .padding(20)
        }
    }

    private var recipeHeader: some View {
        HStack(spacing: 14) {
            if let urlString = mealSlot.recipe.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        imagePlaceholder
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                imagePlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mealSlot.recipe.title)
                    .font(.headline)

                DifficultyBadge(difficulty: mealSlot.recipe.difficultyEnum)

                if let prep = mealSlot.recipe.formattedPrepTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(prep)
                            .font(.caption)
                    }
                    .foregroundStyle(.appSecondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(Color(.systemGray3))
            }
    }

    // MARK: - Servings

    private var servingsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Portionen")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                Stepper("\(servings) Portionen", value: $servings, in: 1...20)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Rating

    private var ratingField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bewertung")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            rating = rating == star ? 0 : star
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= rating ? .yellow : Color(.systemGray3))
                            .symbolEffect(.bounce, value: rating)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if rating > 0 {
                    Text("\(rating)/5")
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Notes

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notizen")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField("Optionale Anmerkungen…", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .font(.subheadline)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Confirm

    private var confirmButton: some View {
        Button {
            Task { await markCooked() }
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("Bestätigen")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(.appSuccess, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSaving)
    }

    // MARK: - Deductions View

    private var deductionsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.appSuccess)

            Text("Erfolgreich als gekocht markiert!")
                .font(.headline)

            if !deductions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "shippingbox")
                            .foregroundStyle(.appPrimary)
                        Text("Vorrat aktualisiert")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    ForEach(deductions) { deduction in
                        HStack {
                            Text(deduction.name)
                                .font(.subheadline)
                            Spacer()

                            let amount = deduction.deducted.truncatingRemainder(dividingBy: 1) == 0
                                ? String(format: "%.0f", deduction.deducted)
                                : String(format: "%.1f", deduction.deducted)
                            let unit = deduction.unit ?? ""
                            Text("-\(amount) \(unit)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.appWarning)

                            if let remaining = deduction.remaining {
                                let rem = remaining.truncatingRemainder(dividingBy: 1) == 0
                                    ? String(format: "%.0f", remaining)
                                    : String(format: "%.1f", remaining)
                                Text("→ \(rem) \(unit)")
                                    .font(.caption)
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Fertig")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(.appPrimary, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Action

    private func markCooked() async {
        isSaving = true
        let result = await viewModel.markCooked(
            date: date,
            slot: slot,
            servings: servings,
            rating: rating > 0 ? rating : nil,
            notes: notes.isEmpty ? nil : notes
        )
        isSaving = false

        if let result {
            if let d = result.pantryDeductions, !d.isEmpty {
                deductions = d
                withAnimation { showDeductions = true }
            } else {
                dismiss()
            }
        }
    }
}
