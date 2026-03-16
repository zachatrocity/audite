import Cocoa
import SwiftUI

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(_ appState: AppState) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Audite")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover.contentSize = NSSize(width: 320, height: 220)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView().environmentObject(appState))
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
