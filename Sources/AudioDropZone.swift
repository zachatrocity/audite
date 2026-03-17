import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct AudioDropZone: View {
    let onFileSelected: (URL) -> Void
    @State private var isTargeted = false

    private static let supportedExtensions: Set<String> = ["caf", "mp3", "m4a", "wav", "aiff", "aif"]

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 24))
                .foregroundColor(isTargeted ? .accentColor : .secondary)

            Text("Drop audio file here")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("or")
                .font(.caption2)
                .foregroundColor(.secondary)

            Button("Choose File...") {
                pickFile()
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [6])
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  Self.supportedExtensions.contains(url.pathExtension.lowercased()) else { return }

            DispatchQueue.main.async {
                onFileSelected(url)
            }
        }
        return true
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "caf")!,
            .mp3,
            .mpeg4Audio,
            .wav,
            .aiff,
        ]
        panel.prompt = "Transcribe"

        NSApp.activate(ignoringOtherApps: true)
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onFileSelected(url)
            }
        }
    }
}
