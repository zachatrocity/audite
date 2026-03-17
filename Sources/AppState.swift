import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isRecording: Bool = false

    func toggleRecording() {
        isRecording.toggle()
        // TODO: hook into audio capture/transcription
    }
}
