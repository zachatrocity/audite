import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var lastError: String?

    private let recorder = AudioRecorder()

    func toggleRecording() {
        if isRecording {
            recorder.stopRecording()
            isRecording = false
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
}
