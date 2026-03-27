import SwiftUI

struct PantryAlertsView: View {
    let alerts: [PantryAlertItem]
    let onAddToShopping: (Int) async -> Void
    let onDismiss: (Int) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.appWarning)
                Text("Vorrat prüfen")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Spacer()

                Text("\(alerts.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.appWarning, in: Capsule())
            }

            ForEach(alerts) { alert in
                alertRow(alert)
            }
        }
        .padding(14)
        .background(Color.appWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.appWarning.opacity(0.25), lineWidth: 1)
        )
    }

    private func alertRow(_ alert: PantryAlertItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(alert.reasonText)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    Task { await onAddToShopping(alert.id) }
                } label: {
                    Text("Einkaufsliste")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.appPrimary, in: Capsule())
                }

                Button {
                    Task { await onDismiss(alert.id) }
                } label: {
                    Text("Vorhanden")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.appSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray6), in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
