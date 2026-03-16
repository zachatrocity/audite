import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Text(appState.isRecording ? "Recording…" : "Idle")
                .font(.headline)

            Button(appState.isRecording ? "Stop" : "Start") {
                appState.toggleRecording()
            }
            .keyboardShortcut(.space, modifiers: [])

            Divider()

            Button("Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .padding()
    }
}
