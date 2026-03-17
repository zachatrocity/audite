import Foundation
import Speech

final class TranscriptionEngine {
    private let recognizer = SFSpeechRecognizer()

    func transcribeFile(at url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        requestSpeechAccess { [weak self] accessGranted in
            guard let self else { return }
            guard accessGranted else {
                completion(.failure(TranscriptionError.permissionDenied))
                return
            }

            guard let recognizer = self.recognizer, recognizer.isAvailable else {
                completion(.failure(TranscriptionError.recognizerUnavailable))
                return
            }

            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false

            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                if let result, result.isFinal {
                    completion(.success(result.bestTranscription.formattedString))
                }
            }
        }
    }

    private func requestSpeechAccess(completion: @escaping (Bool) -> Void) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                completion(status == .authorized)
            }
        @unknown default:
            completion(false)
        }
    }

    enum TranscriptionError: LocalizedError {
        case permissionDenied
        case recognizerUnavailable

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Speech recognition permission not granted"
            case .recognizerUnavailable:
                return "Speech recognizer is unavailable"
            }
        }
    }
}
