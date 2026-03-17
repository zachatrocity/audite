import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Text(appState.isRecording ? "Recording…" : (appState.isTranscribing ? "Transcribing…" : "Idle"))
                .font(.headline)

            if let error = appState.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            if let transcript = appState.lastTranscript {
                ScrollView {
                    Text(transcript)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
            }

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
