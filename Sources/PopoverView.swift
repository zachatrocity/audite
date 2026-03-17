import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var appState: AppState
    @State private var elapsed: TimeInterval = 0
    @AppStorage("prependDate") private var prependDate: Bool = true
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            if appState.showingSettings {
                settingsContent
            } else {
                mainContent
            }

            Divider()

            HStack {
                Button(appState.showingSettings ? "Back" : "Settings") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.showingSettings.toggle()
                    }
                }
                .buttonStyle(.link)
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.link)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            appState.calendar.fetchUpcoming()
        }
        .onReceive(timer) { _ in
            if let start = appState.recordingStartDate {
                elapsed = Date().timeIntervalSince(start)
            } else {
                elapsed = 0
            }
        }
    }

    // MARK: - Main

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
        VStack(spacing: 12) {
        HStack(spacing: 8) {
            if appState.isRecording {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Recording")
                    .font(.headline)
                Spacer()
                Text(formatElapsed(elapsed))
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.secondary)
            } else if appState.isTranscribing {
                ProgressView()
                    .controlSize(.small)
                Text("Transcribing...")
                    .font(.headline)
                Spacer()
            } else {
                Image(systemName: "waveform.circle")
                    .foregroundColor(.secondary)
                Text("Ready")
                    .font(.headline)
                Spacer()
            }
        }

        if !appState.isRecording && !appState.isTranscribing {
            TextField("Meeting name (optional)", text: $appState.meetingTitle)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            if !appState.calendar.upcomingEvents.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Upcoming")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(appState.calendar.upcomingEvents) { event in
                                Button {
                                    if prependDate {
                                        let df = DateFormatter()
                                        df.dateFormat = "yyyy-MM-dd"
                                        appState.meetingTitle = "\(df.string(from: Date())) \(event.title)"
                                    } else {
                                        appState.meetingTitle = event.title
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if event.isHappeningNow {
                                            Circle().fill(.green).frame(width: 5, height: 5)
                                        }
                                        Text(event.title)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Text(event.timeString)
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.caption)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(
                                    appState.meetingTitle.hasSuffix(event.title)
                                        ? Color.accentColor.opacity(0.1)
                                        : Color.clear
                                )
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxHeight: 90)

                    Toggle("Prepend date", isOn: $prependDate)
                        .toggleStyle(.checkbox)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.top, 4)
            }
        } else if appState.isRecording && !appState.meetingTitle.isEmpty {
            Text(appState.meetingTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }

        if appState.transcription.modelState == .notDownloaded {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Model not downloaded.")
                    .font(.caption)
                Button("Settings") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.showingSettings = true
                    }
                }
                .font(.caption)
                .buttonStyle(.link)
            }
        }

        if let error = appState.lastError {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }

        if let savedURL = appState.lastSavedURL {
            HStack(spacing: 4) {
                Button {
                    NSWorkspace.shared.open(savedURL)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                        Text("Open in Obsidian")
                    }
                    .font(.caption)
                }
                .buttonStyle(.link)

                Spacer()

                Text(savedURL.deletingPathExtension().lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.secondary)
                    .font(.caption)

                Button {
                    appState.lastSavedURL = nil
                    appState.lastTranscript = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }

        Button {
            appState.toggleRecording()
        } label: {
            HStack {
                Image(systemName: appState.isRecording ? "stop.circle.fill" : "record.circle")
                Text(appState.isRecording ? "Stop Recording" : "Start Recording")
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .keyboardShortcut(.space, modifiers: [])
        .disabled(appState.isTranscribing || appState.transcription.modelState != .ready)
        } // VStack
        } // ScrollView
    }

    // MARK: - Settings

    @ViewBuilder
    private var settingsContent: some View {
        SettingsView()
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
