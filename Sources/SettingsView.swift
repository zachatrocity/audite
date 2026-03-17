import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("audioFolder") private var audioFolder: String = ""
    @AppStorage("outputFolder") private var outputFolder: String = ""
    @AppStorage("filenameTemplate") private var filenameTemplate: String = "{{date}} {{title}}"
    @AppStorage("includeTime") private var includeTime: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                modelSection
                Divider()
                audioFolderSection
                Divider()
                obsidianFolderSection
                Divider()
                filenameSection
            }
        }
    }

    // MARK: - Model

    @ViewBuilder
    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transcription Model")
                .font(.caption.bold())

            HStack(spacing: 8) {
                switch appState.transcription.modelState {
                case .notDownloaded:
                    Circle().fill(.orange).frame(width: 6, height: 6)
                    Text("Parakeet TDT v3 — not downloaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Download") {
                        appState.transcription.downloadModel()
                    }
                    .controlSize(.small)

                case .downloading:
                    ProgressView()
                        .controlSize(.small)
                    Text("Downloading model...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()

                case .ready:
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("Parakeet TDT v3 — ready")
                        .font(.caption)
                    Spacer()

                case .error(let msg):
                    Circle().fill(.red).frame(width: 6, height: 6)
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                    Spacer()
                    Button("Retry") {
                        appState.transcription.downloadModel()
                    }
                    .controlSize(.small)
                }
            }

            Text("Runs fully on-device via Apple Neural Engine. ~1 GB download.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Audio Folder

    @ViewBuilder
    private var audioFolderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recordings Folder")
                .font(.caption.bold())

            HStack(spacing: 6) {
                Text(audioFolder.isEmpty ? "~/Documents/Audite/Recordings" : abbreviatePath(audioFolder))
                    .font(.caption)
                    .foregroundColor(audioFolder.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Choose...") {
                    pickFolder { audioFolder = $0 }
                }
                .controlSize(.small)
            }

            Text("Where audio .caf files are saved.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Obsidian Folder

    @ViewBuilder
    private var obsidianFolderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Obsidian Output Folder")
                .font(.caption.bold())

            HStack(spacing: 6) {
                Text(outputFolder.isEmpty ? "~/Documents/Audite" : abbreviatePath(outputFolder))
                    .font(.caption)
                    .foregroundColor(outputFolder.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Choose...") {
                    pickFolder { outputFolder = $0 }
                }
                .controlSize(.small)
            }

            Text("Where .md transcript notes are saved. Point to your Obsidian vault.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Filename

    @ViewBuilder
    private var filenameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Filename Template")
                .font(.caption.bold())

            TextField("{{date}} {{title}}", text: $filenameTemplate)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            Toggle("Include time in {{date}}", isOn: $includeTime)
                .toggleStyle(.checkbox)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("Tokens: {{date}}, {{title}} — used for both audio and transcript files.")
                .font(.caption2)
                .foregroundColor(.secondary)

            if !filenameTemplate.isEmpty {
                Text("Preview: \(previewFilename()).caf / .md")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Helpers

    private func pickFolder(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        // Detach from popover so the panel gets full focus
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { response in
            if response == .OK {
                completion(panel.url?.path ?? "")
            }
        }
    }

    private func previewFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = includeTime ? "yyyy-MM-dd HHmmss" : "yyyy-MM-dd"
        return filenameTemplate
            .replacingOccurrences(of: "{{date}}", with: formatter.string(from: Date()))
            .replacingOccurrences(of: "{{title}}", with: "Recording")
    }

    private func abbreviatePath(_ path: String) -> String {
        if let home = ProcessInfo.processInfo.environment["HOME"], path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
