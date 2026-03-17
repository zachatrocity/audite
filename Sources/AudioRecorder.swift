import Foundation
import AVFoundation

final class AudioRecorder {
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var isRecording = false

    func startRecording() throws {
        guard !isRecording else { return }
        try ensureMicrophoneAccess()

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        let outputURL = try makeOutputURL()

        audioFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)

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

    func stopRecording() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        isRecording = false
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

    private func makeOutputURL() throws -> URL {
        let defaults = UserDefaults.standard
        let outputFolder = defaults.string(forKey: "outputFolder") ?? ""
        let filenameTemplate = defaults.string(forKey: "filenameTemplate") ?? "{{date}} {{title}}"

        let baseURL: URL
        if outputFolder.isEmpty {
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Audite", isDirectory: true)
        } else {
            baseURL = URL(fileURLWithPath: outputFolder, isDirectory: true)
        }

        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HHmmss"
        let dateString = formatter.string(from: Date())

        var filename = filenameTemplate
            .replacingOccurrences(of: "{{date}}", with: dateString)
            .replacingOccurrences(of: "{{title}}", with: "Recording")

        filename = filename
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        if filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filename = dateString
        }

        return baseURL.appendingPathComponent(filename).appendingPathExtension("caf")
    }
}
