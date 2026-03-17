import SwiftUI

@main
struct AuditeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar app — all UI lives in the popover via StatusBarController.
        // A Scene is required by the App protocol; use an empty Settings scene.
        Settings { EmptyView() }
    }
}
