import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    var appState: AppState!
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard statusBar == nil else { return }
        statusBar = StatusBarController(appState)
    }
}
