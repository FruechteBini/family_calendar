import SwiftUI

struct AIMealPlanWizard: View {
    let viewModel: AIMealPlanViewModel
    let mealPlanVM: MealPlanViewModel
    let weekStart: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .config:
                    AIConfigStepView(
                        viewModel: viewModel,
                        weekStart: weekStart
                    )

                case .loading:
                    loadingState("KI generiert Vorschläge…")

                case .preview:
                    AIPreviewStepView(
                        viewModel: viewModel,
                        mealPlanVM: mealPlanVM,
                        weekStart: weekStart,
                        onDismiss: { dismiss() }
                    )

                case .confirming:
                    loadingState("Plan wird bestätigt…")

                case .done:
                    Color.clear
                        .onAppear { dismiss() }
                }
            }
            .navigationTitle("KI-Essensplanung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        viewModel.reset()
                        dismiss()
                    }
                }
            }
            .task { await viewModel.loadAvailableRecipes(weekStart: weekStart) }
        }
    }

    private func loadingState(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView()
                .controlSize(.large)
                .tint(.appPrimary)

            Text(message)
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Das kann einen Moment dauern…")
                .font(.subheadline)
                .foregroundStyle(.appSecondary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.appDanger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
