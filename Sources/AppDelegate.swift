import Cocoa
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard statusBar == nil else { return }
        statusBar = StatusBarController(appState)
        appState.transcription.loadModelIfCached()
        appState.calendar.requestAccess()
    }
}
