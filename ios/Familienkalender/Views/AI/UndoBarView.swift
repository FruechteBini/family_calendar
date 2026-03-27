import SwiftUI
import Combine

struct UndoBarView: View {
    let viewModel: MealPlanViewModel

    @State private var remainingSeconds: Int = 60
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var progressFraction: Double {
        max(0, Double(remainingSeconds) / 60.0)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("KI-Plan rückgängig machen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                GeometryReader { geo in
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(height: 4)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(.white)
                                .frame(width: geo.size.width * progressFraction, height: 4)
                                .animation(.linear(duration: 1), value: remainingSeconds)
                        }
                }
                .frame(height: 4)
            }

            Spacer(minLength: 4)

            Button {
                Task { await viewModel.undoPlan() }
            } label: {
                Text("Rückgängig")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))
            }

            Button {
                viewModel.dismissUndo()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.orange, Color(hex: "#E67E22")],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onAppear { remainingSeconds = 60 }
        .onReceive(timer) { _ in
            guard viewModel.undoMealIds != nil else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
        }
    }
}
