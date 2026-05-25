# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Domain glossary (`CONTEXT.md`) — formal definitions for Session State, Preset, Round, Display Target, and other core terms
- Codebase map documents in `.planning/codebase/` — STACK.md, ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, INTEGRATIONS.md, CONCERNS.md
- ADR-0003 — decision record for the glossary and codebase map approach
- `.prettierrc` — markdown formatting defaults

## [0.5.30] - 2026-05-25

### Changed

- Documented session timeline feature in README and docs site

## [0.5.29] - 2026-05-25

### Changed

- Updated GitHub Actions dependencies

## [0.5.28] - 2026-05-25

### Added

- Detailed session timeline view showing each focus session and break from today with start/end times and durations (#114)

## [0.5.27] - 2026-04-18

### Fixed

- Daily progress not resetting when app runs across midnight

## [0.5.26] - 2026-03-20

### Changed

- Made `AudioManager` injectable in `FocusSessionViewModel` for testability
- Simplified `AudioManagerTests` and updated persistence tests

### Added

- `MockAudioManager` for test dependency injection

### Removed

- Untestable `@State` property tests

## [0.5.25] - 2026-03-20

### Fixed

- Always save selected audio track on change

## [0.5.24] - 2026-03-14

### Changed

- Refreshed codebase analysis documents

## [0.5.23] - 2026-03-14

### Added

- Test coverage for `NotchCompanionView` UI behavior (layout, session state rendering)

## [0.5.22] - 2026-03-14

### Added

- Test coverage for `AudioManager`

## [0.5.21] - 2026-03-13

### Changed

- Restructured `sessionView` to group by session state for better code organization

## [0.5.20] - 2026-03-09

### Fixed

- Prevented race conditions in auto-release CI workflow

## [0.5.19] - 2026-03-09

### Added

- Ambient audio now pauses when a focus session is paused and resumes when resumed

### Changed

- Updated various dependencies via Renovate

## [0.5.17] - 2026-03-07

### Added

- `renovate.json` for automated dependency management

## [0.5.16] - 2026-02-18

### Added

- VoiceOver and accessibility support for `NotchCompanionView` controls

## [0.5.15] - 2026-02-16

### Added

- Auto-start next interval with 10-second countdown after session completion
- Audio track persistence across sessions

## [0.5.14] - 2026-02-16

### Added

- Troubleshooting documentation for Gatekeeper warnings on first launch

## [0.5.13] - 2026-02-16

### Fixed

- Minor bug fixes and stability improvements

## [0.5.12] - 2026-02-16

### Added

- Preset selection (25/5 ↔ 50/10) directly in the notch UI

## [0.5.11] - 2026-02-15

### Added

- "Dismiss on click outside" modifier for popovers

## [0.5.10] - 2026-02-15

### Changed

- Replaced singleton dependency pattern with constructor-based dependency injection for services

## [0.5.9] - 2026-02-15

### Changed

- Continued dependency injection refactoring (removed singleton accessors from services)

## [0.5.8] - 2026-02-15

### Changed

- Updated Swift version to 6.2 in SwiftFormat configuration

## [0.5.7] - 2026-02-15

### Changed

- Default "Always on top" setting changed from off to on

## [0.5.6] - 2026-02-15

### Changed

- Updated demo GIF in README

## [0.5.5] - 2026-02-15

### Added

- Support section to settings menu with author links and donation options

## [0.5.4] - 2026-02-15

### Changed

- Minor internal improvements

## [0.5.3] - 2026-02-15

### Changed

- Streamlined `AGENTS.md` formatting and content

## [0.5.2] - 2026-02-15

### Changed

- Reuse `AVAudioEngine` instance across track changes for smoother audio transitions

## [0.5.1] - 2026-02-15

### Fixed

- Resolved three production concerns (specific details in commit `cc8c9ca`)

## [0.5.0] - 2026-02-15

### Added

- Initial public release of Oak — macOS focus companion with notch-first UI
- Notch companion UI with expand/collapse interaction
- Pomodoro presets: 25/5 and 50/10
- Session state machine: idle → running → paused → completed
- Ambient audio: rain, forest, cafe, brown noise, lo-fi
- Local progress tracking with daily focus minutes and session counts
- 7-day streak calculation
- Confetti animation on session completion
- Notification on session completion
- Sparkle auto-update framework integration
- Circular progress ring display mode
- Countdown display mode (number and circle ring)
- Inside notch / below notch layout options
- Countdown display mode selection
- Always on top window behavior

[Unreleased]: https://github.com/jellydn/oak/compare/v0.5.30...HEAD
[0.5.30]: https://github.com/jellydn/oak/compare/v0.5.29...v0.5.30
[0.5.29]: https://github.com/jellydn/oak/compare/v0.5.28...v0.5.29
[0.5.28]: https://github.com/jellydn/oak/compare/v0.5.27...v0.5.28
[0.5.27]: https://github.com/jellydn/oak/compare/v0.5.26...v0.5.27
[0.5.26]: https://github.com/jellydn/oak/compare/v0.5.25...v0.5.26
[0.5.25]: https://github.com/jellydn/oak/compare/v0.5.24...v0.5.25
[0.5.24]: https://github.com/jellydn/oak/compare/v0.5.23...v0.5.24
[0.5.23]: https://github.com/jellydn/oak/compare/v0.5.22...v0.5.23
[0.5.22]: https://github.com/jellydn/oak/compare/v0.5.21...v0.5.22
[0.5.21]: https://github.com/jellydn/oak/compare/v0.5.20...v0.5.21
[0.5.20]: https://github.com/jellydn/oak/compare/v0.5.19...v0.5.20
[0.5.19]: https://github.com/jellydn/oak/compare/v0.5.17...v0.5.19
[0.5.17]: https://github.com/jellydn/oak/compare/v0.5.16...v0.5.17
[0.5.16]: https://github.com/jellydn/oak/compare/v0.5.15...v0.5.16
[0.5.15]: https://github.com/jellydn/oak/compare/v0.5.14...v0.5.15
[0.5.14]: https://github.com/jellydn/oak/compare/v0.5.13...v0.5.14
[0.5.13]: https://github.com/jellydn/oak/compare/v0.5.12...v0.5.13
[0.5.12]: https://github.com/jellydn/oak/compare/v0.5.11...v0.5.12
[0.5.11]: https://github.com/jellydn/oak/compare/v0.5.10...v0.5.11
[0.5.10]: https://github.com/jellydn/oak/compare/v0.5.9...v0.5.10
[0.5.9]: https://github.com/jellydn/oak/compare/v0.5.8...v0.5.9
[0.5.8]: https://github.com/jellydn/oak/compare/v0.5.7...v0.5.8
[0.5.7]: https://github.com/jellydn/oak/compare/v0.5.6...v0.5.7
[0.5.6]: https://github.com/jellydn/oak/compare/v0.5.5...v0.5.6
[0.5.5]: https://github.com/jellydn/oak/compare/v0.5.4...v0.5.5
[0.5.4]: https://github.com/jellydn/oak/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/jellydn/oak/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/jellydn/oak/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/jellydn/oak/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/jellydn/oak/releases/tag/v0.5.0
