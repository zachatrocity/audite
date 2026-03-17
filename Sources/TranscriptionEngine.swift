import Foundation
import FluidAudio

/// Wraps AsrManager so it can cross isolation boundaries.
/// Safe because we only ever call transcribe sequentially from AppState.
private final class SendableAsrManager: @unchecked Sendable {
    let manager: AsrManager
    init(_ manager: AsrManager) { self.manager = manager }
}

@MainActor
final class TranscriptionEngine: ObservableObject {
    @Published var modelState: ModelState = .notDownloaded
    @Published var downloadProgress: Double = 0

    private var asrManager: SendableAsrManager?
    private var models: AsrModels?

    enum ModelState: Equatable {
        case notDownloaded
        case downloading
        case ready
        case error(String)
    }

    enum TranscriptionError: LocalizedError {
        case modelNotReady
        case transcriptionFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotReady:
                return "Transcription model not downloaded. Open Settings to download."
            case .transcriptionFailed(let msg):
                return "Transcription failed: \(msg)"
            }
        }
    }

    func downloadModel() {
        guard modelState != .downloading else { return }
        modelState = .downloading
        downloadProgress = 0

        Task {
            do {
                let loadedModels = try await AsrModels.downloadAndLoad(version: .v3)
                self.models = loadedModels

                let manager = AsrManager(config: .default)
                try await manager.initialize(models: loadedModels)
                self.asrManager = SendableAsrManager(manager)

                self.modelState = .ready
                self.downloadProgress = 1.0
                NSLog("Audite: model downloaded and ready")
            } catch {
                self.modelState = .error(error.localizedDescription)
                NSLog("Audite: model download failed: \(error)")
            }
        }
    }

    func loadModelIfCached() {
        Task {
            do {
                let loadedModels = try await AsrModels.downloadAndLoad(version: .v3)
                self.models = loadedModels

                let manager = AsrManager(config: .default)
                try await manager.initialize(models: loadedModels)
                self.asrManager = SendableAsrManager(manager)

                self.modelState = .ready
                NSLog("Audite: model loaded from cache")
            } catch {
                self.modelState = .notDownloaded
            }
        }
    }

    func transcribeFile(at url: URL) async throws -> String {
        guard let wrapper = asrManager else {
            throw TranscriptionError.modelNotReady
        }

        let result = try await Task.detached {
            try await wrapper.manager.transcribe(url, source: .system)
        }.value

        return result.text
    }
}
