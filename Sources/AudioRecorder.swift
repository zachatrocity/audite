import Foundation
import AVFoundation

final class AudioRecorder {
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var isRecording = false

    func startRecording(title: String = "") throws {
        guard !isRecording else { return }
        try ensureMicrophoneAccess()

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        let outputURL = try makeOutputURL(title: title)

        audioFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
        self.outputURL = outputURL

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                NSLog("Audite: failed to write audio buffer: \(error)")
            }
        }

        engine.prepare()
        try engine.start()
        isRecording = true
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        engine.reset()
        audioFile = nil
        isRecording = false
        let finishedURL = outputURL
        outputURL = nil
        return finishedURL
    }

    private func ensureMicrophoneAccess() throws {
        let semaphore = DispatchSemaphore(value: 0)
        var granted = false

        AVCaptureDevice.requestAccess(for: .audio) { allowed in
            granted = allowed
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 10)

        if !granted {
            throw NSError(domain: "Audite", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Microphone access not granted"
            ])
        }
    }

    private func makeOutputURL(title: String) throws -> URL {
        let defaults = UserDefaults.standard
        let audioFolder = defaults.string(forKey: "audioFolder") ?? ""
        let filenameTemplate = defaults.string(forKey: "filenameTemplate") ?? "{{date}} {{title}}"

        let baseURL: URL
        if audioFolder.isEmpty {
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Audite/Recordings", isDirectory: true)
        } else {
            baseURL = URL(fileURLWithPath: audioFolder, isDirectory: true)
        }

        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        let includeTime = defaults.bool(forKey: "includeTime")
        let formatter = DateFormatter()
        formatter.dateFormat = includeTime ? "yyyy-MM-dd HHmmss" : "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        let resolvedTitle = title.isEmpty ? "Recording" : title
        let titleHasDate = resolvedTitle.hasPrefix(dateString)

        var filename = filenameTemplate
            .replacingOccurrences(of: "{{date}}", with: titleHasDate ? "" : dateString)
            .replacingOccurrences(of: "{{title}}", with: resolvedTitle)
            .trimmingCharacters(in: .whitespaces)

        filename = filename
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        if filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filename = dateString
        }

        return baseURL.appendingPathComponent(filename).appendingPathExtension("caf")
    }
}
