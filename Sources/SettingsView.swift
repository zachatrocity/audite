import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("outputFolder") private var outputFolder: String = ""
    @AppStorage("filenameTemplate") private var filenameTemplate: String = "{{date}} {{title}}"
    @AppStorage("calendarEnabled") private var calendarEnabled: Bool = true

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 6) {
                Text("Output Folder")
                    .font(.headline)

                HStack(spacing: 8) {
                    TextField("Default: Documents/Audite", text: $outputFolder)
                    Button("Choose…") {
                        pickOutputFolder()
                    }
                }

                if !outputFolder.isEmpty {
                    Text(outputFolder)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Filename Template")
                    .font(.headline)

                TextField("{{date}} {{title}}", text: $filenameTemplate)
                    .textFieldStyle(.roundedBorder)

                Text("Available tokens: {{date}}, {{title}}")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Toggle("Apple Calendar Integration", isOn: $calendarEnabled)
        }
        .padding()
        .frame(width: 460)
    }

    private func pickOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        if panel.runModal() == .OK {
            outputFolder = panel.url?.path ?? ""
        }
    }
}
