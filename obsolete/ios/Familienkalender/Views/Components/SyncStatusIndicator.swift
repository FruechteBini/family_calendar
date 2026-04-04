import SwiftUI

enum SyncStatus {
    case synced
    case syncing
    case offline

    var iconName: String {
        switch self {
        case .synced: "checkmark.circle.fill"
        case .syncing: "arrow.triangle.2.circlepath"
        case .offline: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .synced: .appSuccess
        case .syncing: .appWarning
        case .offline: .appDanger
        }
    }

    var label: String {
        switch self {
        case .synced: "Synchronisiert"
        case .syncing: "Wird synchronisiert"
        case .offline: "Offline"
        }
    }
}

struct SyncStatusIndicator: View {
    let status: SyncStatus
    var showLabel: Bool = false

    @State private var isRotating = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption)
                .foregroundStyle(status.color)
                .rotationEffect(.degrees(status == .syncing && isRotating ? 360 : 0))
                .animation(
                    status == .syncing
                        ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                        : .default,
                    value: isRotating
                )

            if showLabel {
                Text(status.label)
                    .font(.caption2)
                    .foregroundStyle(status.color)
            }
        }
        .onChange(of: status) { _, newValue in
            isRotating = newValue == .syncing
        }
        .onAppear {
            isRotating = status == .syncing
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.label)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            SyncStatusIndicator(status: .synced)
            SyncStatusIndicator(status: .syncing)
            SyncStatusIndicator(status: .offline)
        }

        HStack(spacing: 20) {
            SyncStatusIndicator(status: .synced, showLabel: true)
            SyncStatusIndicator(status: .syncing, showLabel: true)
            SyncStatusIndicator(status: .offline, showLabel: true)
        }
    }
    .padding()
}
