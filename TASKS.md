# Audite — Tasks

## Bugs
_None known — file issues as they come up._

## Features

### Up Next
- [ ] **Global hotkey** — start/stop recording without opening the popover
- [ ] **Launch at login** — option in settings to auto-start on boot
- [ ] **Speaker diarization** — label who said what using FluidAudio's diarization models
- [ ] **Live transcription** — stream text during recording using FluidAudio's streaming ASR

### Later
- [ ] **Meeting detection** — auto-detect when a meeting starts (calendar event begins, conferencing app opens) and prompt to record
- [ ] **Muted audio capture** — capture system/app audio when your mic is muted (e.g. joined a call from a conference room but listening on your laptop)
- [ ] **Import existing recordings** — drag-and-drop or file picker to transcribe pre-recorded audio files (Copilot exports, Zoom recordings, etc.)
- [ ] **Live transcription** _(experimental)_ — stream text during recording using FluidAudio's streaming ASR (Parakeet EOU, English-only)
- [ ] **Export formats** — SRT subtitles, plain text alongside Markdown
- [ ] **Obsidian link in frontmatter** — backlink to related daily note
- [ ] **Model selection** — choose between Parakeet v2 (English-only, higher accuracy) and v3 (multilingual)
- [ ] **Recording history** — list of past recordings with quick access to transcripts

## Done
- [x] Project scaffold (menu bar app + popover + settings)
- [x] Audio capture pipeline (AVAudioEngine, writes .caf files)
- [x] Local transcription engine (FluidAudio Parakeet TDT v3)
- [x] Model download management in settings
- [x] Markdown output with YAML frontmatter (Obsidian-ready)
- [x] Separate audio and transcript output folders
- [x] Inline settings in popover (no separate window)
- [x] Recording timer and status bar icon change
- [x] Meeting title input with Apple Calendar integration
- [x] Prepend date option for recurring meetings
- [x] Entitlements and CI build fixes
