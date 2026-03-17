# Audite v0.0.5

## New Features

- **File upload for pre-recorded meetings** — Upload .caf, .mp3, .m4a, or .wav files via drag & drop or file picker to transcribe existing recordings
- **Paragraph formatting** — Transcriptions are now broken into readable paragraphs using pause detection and sentence grouping, instead of a wall of text
- **Experimental speaker detection** — Optional speaker diarization powered by FluidAudio's offline pipeline. Identifies who said what in multi-speaker meetings. Disabled by default — enable in Settings (requires additional model download)
- **Update checker** — Settings now shows a notification when a newer version is available on GitHub
- **Clear button** — Dismiss the last recording result with a single click
- **Filename improvements** — Fixed double-date issue with "Prepend date", removed confusing time digits from default filenames, added "Include time" toggle

## Bug Fixes

- Fixed settings pane getting cut off in the popover
- Main view and settings now scroll when content exceeds popover height
