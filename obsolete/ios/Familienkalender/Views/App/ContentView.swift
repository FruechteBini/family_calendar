import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                loadingView
            } else if !authManager.isAuthenticated {
                LoginView()
            } else if authManager.currentUser?.familyId == nil {
                FamilyOnboardingView()
            } else if authManager.currentUser?.memberId == nil {
                MemberLinkView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.currentUser?.familyId)
        .task {
            await authManager.checkAuth()
            isCheckingAuth = false
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Laden...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
