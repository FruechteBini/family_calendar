import SwiftUI

struct FamilyInfoView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showCopiedToast = false

    private var family: FamilyResponse? {
        authManager.currentUser?.family
    }

    var body: some View {
        List {
            if let family {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.bottom, 4)

                        Text(family.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section("Einladungscode") {
                    HStack {
                        Text(family.inviteCode)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = family.inviteCode
                            withAnimation {
                                showCopiedToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedToast = false
                                }
                            }
                        } label: {
                            Image(systemName: showCopiedToast ? "checkmark" : "doc.on.doc")
                                .foregroundStyle(showCopiedToast ? Color.appSuccess : Color.appPrimary)
                        }
                    }

                    if showCopiedToast {
                        Text("In Zwischenablage kopiert!")
                            .font(.caption)
                            .foregroundStyle(Color.appSuccess)
                            .transition(.opacity)
                    }

                    ShareLink(
                        "Einladungscode teilen",
                        item: "Tritt unserer Familie im Familienkalender bei! Code: \(family.inviteCode)"
                    )
                }

                Section("Details") {
                    HStack {
                        Text("Erstellt am")
                        Spacer()
                        Text(formattedDate(family.createdAt))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Familien-ID")
                        Spacer()
                        Text("\(family.id)")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Keine Familie",
                    systemImage: "house.slash",
                    description: Text("Du bist keiner Familie zugeordnet.")
                )
            }
        }
        .navigationTitle("Familie")
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.locale = Locale(identifier: "de_DE")
            display.dateStyle = .long
            display.timeStyle = .none
            return display.string(from: date)
        }

        let fallback = ISO8601DateFormatter()
        if let date = fallback.date(from: isoString) {
            let display = DateFormatter()
            display.locale = Locale(identifier: "de_DE")
            display.dateStyle = .long
            display.timeStyle = .none
            return display.string(from: date)
        }

        return String(isoString.prefix(10))
    }
}
