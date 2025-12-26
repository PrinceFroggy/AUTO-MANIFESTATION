import SwiftUI

@main
struct AutoManifestApp: App {
    @StateObject private var auto = AutomationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            AutoManifestView()
                .environmentObject(auto)
                .task {
                    await auto.bootstrap()
                }
        }
    }
}
