import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var lastTranscript: String?
    @Published var lastError: String?

    private let recorder = AudioRecorder()
    private let transcription = TranscriptionEngine()

    func toggleRecording() {
        if isRecording {
            let outputURL = recorder.stopRecording()
            isRecording = false
            startTranscriptionIfNeeded(outputURL)
            return
        }

        do {
            try recorder.startRecording()
            lastError = nil
            isRecording = true
        } catch {
            lastError = error.localizedDescription
            isRecording = false
            NSLog("Audite: failed to start recording: \(error)")
        }
    }

    private func startTranscriptionIfNeeded(_ url: URL?) {
        guard let url else { return }
        isTranscribing = true
        lastTranscript = nil
        lastError = nil

        transcription.transcribeFile(at: url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isTranscribing = false
                switch result {
                case .success(let transcript):
                    self.lastTranscript = transcript
                case .failure(let error):
                    self.lastError = error.localizedDescription
                    NSLog("Audite: transcription failed: \(error)")
                }
            }
        }
    }
}
