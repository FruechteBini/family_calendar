import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.appSecondary.opacity(0.6))
                .padding(.bottom, 4)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let buttonTitle, let onAction {
                Button(action: onAction) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview("With Button") {
    EmptyStateView(
        icon: "calendar.badge.plus",
        title: "Keine Termine",
        subtitle: "Du hast noch keine Termine angelegt. Erstelle jetzt deinen ersten Termin.",
        buttonTitle: "Termin erstellen"
    ) {
        print("Tapped")
    }
}

#Preview("Without Button") {
    EmptyStateView(
        icon: "checkmark.circle",
        title: "Alles erledigt!",
        subtitle: "Keine offenen Aufgaben vorhanden."
    )
}
