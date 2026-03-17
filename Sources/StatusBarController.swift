import Cocoa
import SwiftUI
import Combine

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var contextMenu: NSMenu?
    private var cancellables: Set<AnyCancellable> = []

    init(_ appState: AppState) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Audite")
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit Audite", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        self.contextMenu = menu

        popover.contentSize = NSSize(width: 320, height: 280)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView().environmentObject(appState))

        appState.$isRecording.sink { [weak self] isRecording in
            guard let self else { return }
            let name = isRecording ? "record.circle.fill" : "waveform.circle"
            self.statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "Audite")
            self.updatePopoverBehavior(appState)
        }.store(in: &cancellables)

        appState.$showingSettings.sink { [weak self] _ in
            guard let self else { return }
            self.updatePopoverBehavior(appState)
        }.store(in: &cancellables)
    }

    private func updatePopoverBehavior(_ appState: AppState) {
        let pinOpen = appState.isRecording || appState.showingSettings
        popover.behavior = pinOpen ? .applicationDefined : .transient
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            popover.performClose(sender)
            statusItem.menu = contextMenu
            button.performClick(nil)
            statusItem.menu = nil
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
