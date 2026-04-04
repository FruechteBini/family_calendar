import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showServerConfig = false

    private var serverURL: String {
        UserDefaults.standard.string(forKey: "server_url") ?? "http://localhost:8000"
    }

    var body: some View {
        List {
            Section("Server") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server-URL")
                            .font(.subheadline)
                        Text(serverURL)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Aendern") {
                        showServerConfig = true
                    }
                    .font(.subheadline)
                }
            }

            Section("Konto") {
                if let user = authManager.currentUser {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(.body)
                                if let member = user.member {
                                    Text("Verknuepft mit: \(member.name) \(member.avatarEmoji)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }

                Button(role: .destructive) {
                    authManager.logout()
                } label: {
                    Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            Section("App") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Einstellungen")
        .sheet(isPresented: $showServerConfig) {
            ServerConfigView()
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
