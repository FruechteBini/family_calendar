import SwiftUI

struct ServerConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL: String

    init() {
        _serverURL = State(
            initialValue: UserDefaults.standard.string(forKey: "server_url") ?? "http://localhost:8000"
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com:8000", text: $serverURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                } header: {
                    Text("Server-URL")
                } footer: {
                    Text("Die Server-URL wird fuer die Verbindung zum Backend benoetigt.")
                }

                Section {
                    currentURLInfo
                }
            }
            .navigationTitle("Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleaned = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
                        APIClient.setServerURL(cleaned)
                        dismiss()
                    }
                    .disabled(serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var currentURLInfo: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.appPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Aktuelle URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(UserDefaults.standard.string(forKey: "server_url") ?? "http://localhost:8000")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
