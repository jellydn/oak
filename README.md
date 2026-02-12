# Oak

A lightweight macOS focus companion designed for deep work.

## Vision

Oak helps users start focused work in seconds with a calm, minimal interface that stays out of the way.

## MVP Scope

- Notch-first focus companion UI
- Fixed Pomodoro presets: `25/5` and `50/10`
- Session controls: start, pause, resume
- Ambient sounds: rain, forest, cafe, brown noise, lo-fi
- Minimal local tracking: daily focus minutes, completed work sessions, 7-day streak

## Out of Scope (Current MVP)

- macOS Focus/notification automation
- Custom timer durations
- Team/shared sessions
- Cross-device sync
- CLI integration
- Paid monetization flow (MVP is free for now)

## Technical Baseline

- Platform: macOS 13+ (Apple Silicon target)
- Language/UI: Swift + SwiftUI
- Audio: AVFoundation
- Persistence: local storage (Core Data or equivalent)

## Project Structure

- `tasks/` Product docs and planning artifacts
- `doc/adr/` Architecture Decision Records
- `scripts/ralph/` PRD-to-Ralph support scripts
