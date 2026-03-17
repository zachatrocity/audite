# Audite — First Release

A macOS menu-bar app that records meetings and transcribes them locally into Markdown notes for Obsidian.

## Features

- **Fully local transcription** — powered by [FluidAudio](https://github.com/FluidInference/FluidAudio) (Parakeet TDT v3) running on Apple Neural Engine. No audio ever leaves your machine.
- **Menu-bar native** — lives in the status bar with a recording indicator, right-click to quit
- **Obsidian integration** — transcripts saved as `.md` files with YAML frontmatter directly into your vault
- **Apple Calendar integration** — upcoming meetings shown in the popover, click to use as the recording title
- **Prepend date toggle** — useful for recurring meetings (e.g. `2026-03-17 Weekly Standup`)
- **Configurable output** — separate folders for audio recordings and transcript notes, customizable filename templates with `{{date}}` and `{{title}}` tokens
- **Custom app icon**

## Requirements

- macOS 14.0+
- Apple Silicon (M1+) recommended
- ~1 GB disk space for the transcription model (downloaded on first use)

## Getting Started

1. Download and unzip `Audite.zip`
2. Move `Audite.app` to Applications
3. If macOS blocks it: right-click → Open, or run `xattr -cr Audite.app`
4. Click the waveform icon in the menu bar → Settings → Download the transcription model
5. Set your output folders and start recording
