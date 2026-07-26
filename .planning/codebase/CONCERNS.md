# Technical Concerns

## Resolved (Recent PRs)

| Concern | Resolution | PR |
| --- | --- | --- |
| Large `FocusSessionViewModel` (was 415 lines) | Extracted `SessionTimerService` (108 lines) + `SessionStateMachine` | #130, #133 |
| `AudioManager` too large (374 lines) | Extracted `NoiseGenerator.swift` | #129 |
| `PresetSettingsStore` monolithic | Split into `SessionDurationConfig`, `DisplayConfig`, `BehaviorConfig` | #132 |
| Thin test files (Confetti, ClickOutside, Smoke) | Added meaningful assertions | #131 |
| NotchCompanionView fragmented (4 files) | Merged extensions from 4→3 files | #135 |
| Duplicated window positioning logic | Extracted `WindowPositioning` enum | #137 |
| `SettingsMenuView` large (was ~390 lines) | Extracted `PresetEditorView` | #138 |
| Keyboard shortcuts missing | Added `KeyboardShortcutService` — Space/Escape | #142 |
| No progress data export | Added JSON/CSV export, JSON import | #141 |

## Active Concerns

### 1. Test Suite Performance

- **Issue**: Full test suite times out at 600 seconds on CI; `build-and-test` checks are frequently cancelled
- **Location**: All test files under `Tests/OakTests/`
- **Impact**: CI feedback loop is unreliable; PRs show `UNSTABLE` merge state due to cancelled checks
- **Recommendation**: Profile tests with Instruments, identify slowest tests, optimize or split test target

### 2. Large File: NotchCompanionView (351 lines)

- **Location**: `Views/NotchCompanionView.swift`
- **Concern**: Below 500-line warn threshold but contains controls, layout, completion animation, and popover handling in one struct
- **Recommendation**: Extract popover presentation logic or completion animation into separate components

### 3. Large File: AudioManager (328 lines)

- **Location**: `Services/AudioManager.swift`
- **Concern**: Still contains noise generation, track management, playback control, and volume logic after NoiseGenerator extraction
- **Recommendation**: Consider extracting audio track management or playback strategies

### 4. Large File: SettingsMenuView (341 lines)

- **Location**: `Views/SettingsMenuView.swift`
- **Concern**: Accumulated Display, Session Presets, Notifications, Keyboard, Data, Updates, and Support sections
- **Recommendation**: Further extract the Display and Session Presets sections into sub-views

### 5. Silence on Import/Export Failure

- **Location**: `Views/SettingsMenuView.swift` — `exportJSON()`, `exportCSV()`, `importData()`
- **Concern**: File I/O failures are silently swallowed (`try?`). Users get no feedback on success or failure.
- **Recommendation**: Add NSAlert for both success and failure paths

### 6. No Session Deduplication on Import

- **Location**: `Services/ProgressManager.swift` — `importRecords(from:)`
- **Concern**: Importing the same file twice creates duplicate `SessionRecord` entries (different UUIDs)
- **Recommendation**: Deduplicate by matching `startTime` + `type` instead of blind `append(contentsOf:)`

### 7. Keyboard Shortcut Customization UI

- **Issue**: #67 requested configurable shortcut keys; current implementation shows read-only badges
- **Location**: `Views/SettingsMenuView.swift` — keyboard section
- **Recommendation**: Add key-recording UI to let users customize shortcut bindings

### 8. Global Hotkey Permission Check

- **Location**: `Services/KeyboardShortcutService.swift` — `startGlobalMonitor()`
- **Concern**: Global hotkey monitoring requires Accessibility permission; no proactive check or guidance
- **Recommendation**: Check `AXIsProcessTrusted()` and prompt user when global hotkeys are enabled

### 9. Row-Level UI for Today's Timeline

- **Issue**: #66 — detailed session timeline with per-session stats
- **Location**: `Views/ProgressMenuView.swift`
- **Recommendation**: Add expandable rows showing session type, exact duration, start/end times

## Watch Items

- **NotchCompanionView file growth** — currently 351 lines, approaching 500-line warn threshold
- **Swift 6 concurrency readiness** — `@MainActor` usage is consistent but some deinit patterns access MainActor-isolated properties
- **Test isolation** — some tests may share UserDefaults if suite names collide (UUID-based names prevent this)
- **macOS version dependencies** — conditional `@available` checks for 13.0+ and 13.3+ features (safe area regions)
