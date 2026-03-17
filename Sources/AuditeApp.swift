import SwiftUI

@main
struct AuditeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    init() {
        // Inject state into AppDelegate so it can wire the status bar.
        AppDelegate.shared.appState = appState
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
