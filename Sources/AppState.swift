import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var lastTranscript: String?
    @Published var lastError: String?
    @Published var lastSavedURL: URL?
    @Published var recordingStartDate: Date?
    @Published var meetingTitle: String = ""

    let transcription = TranscriptionEngine()
    let calendar = CalendarManager()
    private let recorder = AudioRecorder()

    func toggleRecording() {
        if isRecording {
            let outputURL = recorder.stopRecording()
            isRecording = false
            recordingStartDate = nil
            startTranscriptionIfNeeded(outputURL)
            return
        }

        do {
            try recorder.startRecording(title: meetingTitle)
            lastError = nil
            lastTranscript = nil
            lastSavedURL = nil
            isRecording = true
            recordingStartDate = Date()
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

        Task {
            do {
                let transcript = try await transcription.transcribeFile(at: url)
                self.isTranscribing = false
                self.lastTranscript = transcript
                self.saveTranscript(transcript, audioURL: url)
            } catch {
                self.isTranscribing = false
                self.lastError = error.localizedDescription
                NSLog("Audite: transcription failed: \(error)")
            }
        }
    }

    private func saveTranscript(_ transcript: String, audioURL: URL) {
        let defaults = UserDefaults.standard
        let outputFolder = defaults.string(forKey: "outputFolder") ?? ""
        let filenameTemplate = defaults.string(forKey: "filenameTemplate") ?? "{{date}} {{title}}"
        let title = meetingTitle.isEmpty ? "Recording" : meetingTitle

        let baseURL: URL
        if outputFolder.isEmpty {
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Audite", isDirectory: true)
        } else {
            baseURL = URL(fileURLWithPath: outputFolder, isDirectory: true)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HHmmss"
        let dateString = formatter.string(from: Date())

        let isoFormatter = ISO8601DateFormatter()
        let isoDate = isoFormatter.string(from: Date())

        var filename = filenameTemplate
            .replacingOccurrences(of: "{{date}}", with: dateString)
            .replacingOccurrences(of: "{{title}}", with: title)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        if filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filename = dateString
        }

        let mdURL = baseURL.appendingPathComponent(filename).appendingPathExtension("md")

        let markdown = """
        ---
        date: \(isoDate)
        type: meeting-transcript
        audio: \(audioURL.lastPathComponent)
        ---

        # \(filename)

        \(transcript)
        """

        do {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            try markdown.write(to: mdURL, atomically: true, encoding: .utf8)
            lastSavedURL = mdURL
            NSLog("Audite: saved transcript to \(mdURL.path)")
        } catch {
            lastError = "Failed to save transcript: \(error.localizedDescription)"
            NSLog("Audite: failed to save transcript: \(error)")
        }
    }
}
