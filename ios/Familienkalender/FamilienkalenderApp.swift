import SwiftUI

@main
struct FamilienkalenderApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dependencies)
                .environment(dependencies.authManager)
        }
    }
}
