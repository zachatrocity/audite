# Audite — Tasks

Goal: get Audite to a fully functional menu‑bar recorder + transcription app.

## Active
- [x] **Audio capture pipeline** (AVAudioEngine + file writer)
- [ ] **Transcription engine** (Speech framework or Whisper) + live/after‑recording flow
- [ ] **Output formatting & saving** (folder selection + filename template)
- [ ] **Settings UX** (folder picker, template preview, validation)

## Ready
- [ ] **Permissions flow** (microphone + speech recognition)
- [ ] **Calendar integration** (use current event for title/context)
- [ ] **Status UI polish** (recording timer, waveform, error states)

## Later
- [ ] **Auto‑start rules** (hotkey, launch at login)
- [ ] **Export options** (TXT, Markdown, SRT)
- [ ] **Model selection** (local vs cloud)
- [ ] **Diagnostics/logging**

## Done
- [x] Project scaffold (menu bar app + popover + settings)
- [x] Audio capture pipeline (writes CAF files)
