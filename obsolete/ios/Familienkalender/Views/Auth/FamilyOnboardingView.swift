import SwiftUI

struct FamilyOnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var familyName = ""
    @State private var inviteCode = ""
    @State private var errorMessage: String?
    @State private var activeCard: CardType?

    private enum CardType {
        case create, join
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 40)

                headerSection

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.appDanger)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                createFamilyCard

                dividerRow

                joinFamilyCard

                Spacer(minLength: 40)

                logoutButton
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.appPrimary)
                .symbolRenderingMode(.hierarchical)

            Text("Willkommen!")
                .font(.title)
                .fontWeight(.bold)

            Text("Erstelle eine neue Familie oder tritt einer bestehenden bei.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Create Family Card

    private var createFamilyCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appPrimary)
                Text("Familie erstellen")
                    .font(.headline)
                Spacer()
            }

            TextField("Familienname", text: $familyName)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            Button {
                Task { await createFamily() }
            } label: {
                Group {
                    if authManager.isLoading && activeCard == .create {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Erstellen")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .disabled(familyName.trimmingCharacters(in: .whitespaces).isEmpty || authManager.isLoading)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Divider

    private var dividerRow: some View {
        HStack {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            Text("oder")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
    }

    // MARK: - Join Family Card

    private var joinFamilyCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.badge.key.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appSuccess)
                Text("Familie beitreten")
                    .font(.headline)
                Spacer()
            }

            TextField("Einladungscode", text: $inviteCode)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button {
                Task { await joinFamily() }
            } label: {
                Group {
                    if authManager.isLoading && activeCard == .join {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Beitreten")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appSuccess)
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .disabled(inviteCode.trimmingCharacters(in: .whitespaces).isEmpty || authManager.isLoading)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button("Abmelden") {
            authManager.logout()
        }
        .font(.footnote)
        .foregroundStyle(Color.appDanger)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func createFamily() async {
        activeCard = .create
        errorMessage = nil
        do {
            _ = try await authManager.createFamily(name: familyName.trimmingCharacters(in: .whitespaces))
        } catch {
            errorMessage = error.localizedDescription
        }
        activeCard = nil
    }

    private func joinFamily() async {
        activeCard = .join
        errorMessage = nil
        do {
            _ = try await authManager.joinFamily(inviteCode: inviteCode.trimmingCharacters(in: .whitespaces))
        } catch {
            errorMessage = error.localizedDescription
        }
        activeCard = nil
    }
}
