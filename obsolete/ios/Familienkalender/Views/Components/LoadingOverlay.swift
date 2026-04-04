import SwiftUI

struct LoadingOverlay: View {
    var message: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.appPrimary)

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Laden…")
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.overlay {
            if isLoading {
                LoadingOverlay(message: message)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
}

#Preview {
    Text("Hintergrund-Inhalt")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .loadingOverlay(isLoading: true, message: "Wird geladen…")
}
