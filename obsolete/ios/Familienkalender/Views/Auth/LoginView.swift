import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var username = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    @State private var showServerConfig = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    headerSection

                    formSection

                    Spacer(minLength: 40)

                    serverButton
                }
                .padding(.horizontal, 32)
            }

            gearButton
        }
        .sheet(isPresented: $showServerConfig) {
            ServerConfigView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(Color.appPrimary)
                .symbolRenderingMode(.hierarchical)

            Text("Familienkalender")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)

            Text("Dein Familienplaner")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            Picker("Modus", selection: $isRegistering) {
                Text("Anmelden").tag(false)
                Text("Registrieren").tag(true)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("Benutzername", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    SecureField("Passwort", text: $password)
                        .textContentType(isRegistering ? .newPassword : .password)
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.appDanger)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            Button {
                Task { await performAuth() }
            } label: {
                Group {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isRegistering ? "Registrieren" : "Anmelden")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 22)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(username.isEmpty || password.isEmpty || authManager.isLoading)
        }
    }

    // MARK: - Server Button

    private var serverButton: some View {
        Button {
            showServerConfig = true
        } label: {
            Label("Server-Einstellungen", systemImage: "server.rack")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Gear Icon (top right)

    private var gearButton: some View {
        Button {
            showServerConfig = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .padding(.top, 16)
        .padding(.trailing, 16)
    }

    // MARK: - Auth Action

    private func performAuth() async {
        errorMessage = nil
        do {
            if isRegistering {
                try await authManager.register(username: username, password: password)
                try await authManager.login(username: username, password: password)
            } else {
                try await authManager.login(username: username, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
