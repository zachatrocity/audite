import Foundation
import FluidAudio

/// Wraps AsrManager so it can cross isolation boundaries.
/// Safe because we only ever call transcribe sequentially from AppState.
private final class SendableAsrManager: @unchecked Sendable {
    let manager: AsrManager
    init(_ manager: AsrManager) { self.manager = manager }
}

private final class SendableDiarizer: @unchecked Sendable {
    let manager: OfflineDiarizerManager
    init(_ manager: OfflineDiarizerManager) { self.manager = manager }
}

@MainActor
final class TranscriptionEngine: ObservableObject {
    @Published var modelState: ModelState = .notDownloaded
    @Published var diarizationState: ModelState = .notDownloaded
    @Published var downloadProgress: Double = 0

    private var asrManager: SendableAsrManager?
    private var diarizer: SendableDiarizer?
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

    // MARK: - ASR Model

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

    // MARK: - Diarization Model

    func downloadDiarizationModel() {
        guard diarizationState != .downloading else { return }
        diarizationState = .downloading

        Task {
            do {
                let manager = OfflineDiarizerManager(config: .default)
                try await manager.prepareModels()
                self.diarizer = SendableDiarizer(manager)
                self.diarizationState = .ready
                NSLog("Audite: diarization model downloaded and ready")
            } catch {
                self.diarizationState = .error(error.localizedDescription)
                NSLog("Audite: diarization model download failed: \(error)")
            }
        }
    }

    func loadDiarizationModelIfCached() {
        Task {
            do {
                let manager = OfflineDiarizerManager(config: .default)
                try await manager.prepareModels()
                self.diarizer = SendableDiarizer(manager)
                self.diarizationState = .ready
                NSLog("Audite: diarization model loaded from cache")
            } catch {
                self.diarizationState = .notDownloaded
            }
        }
    }

    // MARK: - Transcription

    func transcribeFile(at url: URL) async throws -> String {
        guard let wrapper = asrManager else {
            throw TranscriptionError.modelNotReady
        }

        let speakerDetection = UserDefaults.standard.bool(forKey: "speakerDetection")
        let diarizerWrapper = speakerDetection ? diarizer : nil

        let result = try await Task.detached {
            try await wrapper.manager.transcribe(url, source: .system)
        }.value

        // If speaker detection is enabled and diarization is available, merge with speakers
        if let diarizerWrapper, let tokenTimings = result.tokenTimings, !tokenTimings.isEmpty {
            let diarizationResult = try await Task.detached {
                try await diarizerWrapper.manager.process(url)
            }.value

            return Self.mergeTranscriptWithSpeakers(
                tokenTimings: tokenTimings,
                speakerSegments: diarizationResult.segments
            )
        }

        // Otherwise, use pause-based paragraphing
        if let tokenTimings = result.tokenTimings, !tokenTimings.isEmpty {
            return Self.paragraphByPauses(tokenTimings: tokenTimings)
        }

        return result.text
    }

    // MARK: - Pause-based Paragraphing

    /// Splits transcript into paragraphs using pauses between tokens.
    /// Uses a two-tier approach:
    /// - Large pauses (1.5s+) always create a paragraph break
    /// - Medium pauses (0.5s+) create a break if we're at a sentence boundary (., ?, !)
    /// Falls back to sentence-based paragraphing (~3-4 sentences per paragraph) if no pauses are detected.
    private static func paragraphByPauses(tokenTimings: [TokenTiming]) -> String {
        var paragraphs: [String] = []
        var current = ""
        var pauseBreakCount = 0

        let largePause: TimeInterval = 1.5
        let mediumPause: TimeInterval = 0.4

        for (i, token) in tokenTimings.enumerated() {
            let cleanText = token.token.replacingOccurrences(of: "\u{2581}", with: " ")

            if i > 0 {
                let gap = token.startTime - tokenTimings[i - 1].endTime

                let atSentenceEnd = current.hasSuffix(".") || current.hasSuffix("?") || current.hasSuffix("!")

                if gap >= largePause || (gap >= mediumPause && atSentenceEnd) {
                    let trimmed = current.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        paragraphs.append(trimmed)
                        pauseBreakCount += 1
                    }
                    current = ""
                }
            }

            current += cleanText
        }

        let trimmed = current.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            paragraphs.append(trimmed)
        }

        // If pause detection didn't produce meaningful breaks, fall back to sentence grouping
        if paragraphs.count <= 1, let text = paragraphs.first {
            return groupBySentences(text, sentencesPerParagraph: 4)
        }

        return paragraphs.joined(separator: "\n\n")
    }

    /// Groups text into paragraphs of N sentences each as a fallback.
    private static func groupBySentences(_ text: String, sentencesPerParagraph: Int) -> String {
        var paragraphs: [String] = []
        var current = ""
        var sentenceCount = 0

        for char in text {
            current.append(char)
            if char == "." || char == "?" || char == "!" {
                sentenceCount += 1
                if sentenceCount >= sentencesPerParagraph {
                    let trimmed = current.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        paragraphs.append(trimmed)
                    }
                    current = ""
                    sentenceCount = 0
                }
            }
        }

        let trimmed = current.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            if let last = paragraphs.last {
                // Merge trailing fragment into last paragraph
                paragraphs[paragraphs.count - 1] = last + " " + trimmed
            } else {
                paragraphs.append(trimmed)
            }
        }

        return paragraphs.joined(separator: "\n\n")
    }

    // MARK: - Speaker Merge Logic (Experimental)

    /// Assigns each token to a speaker based on diarization segments,
    /// then groups consecutive tokens by speaker into paragraphs.
    private static func mergeTranscriptWithSpeakers(
        tokenTimings: [TokenTiming],
        speakerSegments: [TimedSpeakerSegment]
    ) -> String {
        guard !tokenTimings.isEmpty, !speakerSegments.isEmpty else {
            // Fallback to plain text if no segments
            return tokenTimings.map {
                $0.token.replacingOccurrences(of: "\u{2581}", with: " ")
            }.joined().trimmingCharacters(in: .whitespaces)
        }

        struct AttributedToken {
            let text: String
            let speaker: String
        }

        let sortedSegments = speakerSegments.sorted { $0.startTimeSeconds < $1.startTimeSeconds }

        // Assign each token to a speaker
        let attributed: [AttributedToken] = tokenTimings.map { token in
            let tokenMid = Float((token.startTime + token.endTime) / 2.0)

            // Find the speaker segment that contains this token's midpoint
            if let match = sortedSegments.first(where: { seg in
                tokenMid >= seg.startTimeSeconds && tokenMid <= seg.endTimeSeconds
            }) {
                let cleanText = token.token.replacingOccurrences(of: "\u{2581}", with: " ")
                return AttributedToken(text: cleanText, speaker: match.speakerId)
            }

            // Token falls in a gap — assign to the nearest segment
            let nearest = sortedSegments.min(by: { a, b in
                let distA = min(abs(tokenMid - a.startTimeSeconds), abs(tokenMid - a.endTimeSeconds))
                let distB = min(abs(tokenMid - b.startTimeSeconds), abs(tokenMid - b.endTimeSeconds))
                return distA < distB
            })!

            let cleanText = token.token.replacingOccurrences(of: "\u{2581}", with: " ")
            return AttributedToken(text: cleanText, speaker: nearest.speakerId)
        }

        // Group consecutive tokens by speaker into paragraphs
        var paragraphs: [(speaker: String, text: String)] = []
        var currentSpeaker = ""
        var currentText = ""

        for token in attributed {
            if token.speaker != currentSpeaker {
                if !currentText.isEmpty {
                    paragraphs.append((speaker: currentSpeaker, text: currentText.trimmingCharacters(in: .whitespaces)))
                }
                currentSpeaker = token.speaker
                currentText = token.text
            } else {
                currentText += token.text
            }
        }

        if !currentText.isEmpty {
            paragraphs.append((speaker: currentSpeaker, text: currentText.trimmingCharacters(in: .whitespaces)))
        }

        // Merge short paragraphs (< 3 words) into the surrounding speaker's paragraph
        // This eliminates false speaker switches on filler words like "yeah", "um", etc.
        var merged: [(speaker: String, text: String)] = []
        for para in paragraphs {
            let wordCount = para.text.split(separator: " ").count
            if wordCount < 3, let last = merged.last, merged.count >= 1 {
                // Check if the next paragraph (if any) is the same speaker as the previous
                // Short blip — absorb into the previous paragraph
                merged[merged.count - 1] = (speaker: last.speaker, text: last.text + " " + para.text)
            } else {
                merged.append(para)
            }
        }

        // Second pass: merge consecutive same-speaker paragraphs created by the above
        var final: [(speaker: String, text: String)] = []
        for para in merged {
            if let last = final.last, last.speaker == para.speaker {
                final[final.count - 1] = (speaker: last.speaker, text: last.text + " " + para.text)
            } else {
                final.append(para)
            }
        }

        // Rename speakers to friendly labels (Speaker 1, Speaker 2, ...)
        var speakerNames: [String: String] = [:]
        var nextSpeakerNum = 1
        for para in final {
            if speakerNames[para.speaker] == nil {
                speakerNames[para.speaker] = "Speaker \(nextSpeakerNum)"
                nextSpeakerNum += 1
            }
        }

        return final
            .map { "**\(speakerNames[$0.speaker] ?? $0.speaker):** \($0.text)" }
            .joined(separator: "\n\n")
    }
}
