# CONCERNS — Oak Technical Concerns

## Known Issues

### 1. SwiftLint Crashes Without Full Xcode

`SourceKittenFramework/library_wrapper.swift:58: Fatal error: Loading sourcekitdInProc.framework failed`

- **Impact**: Lint checks fail in CI or dev environments without full Xcode
- **Workaround**: None — requires full Xcode installation
- **File**: `.swiftlint.yml`

### 2. Building Requires Full Xcode

`xcodebuild` (used by all `just` commands: build, test, check, etc.) requires a full Xcode installation. Command Line Tools are insufficient.

- **Impact**: Cannot build, test, or typecheck from terminal environments with only Command Line Tools
- **Workaround**: Open in Xcode IDE and build from there

## Code Quality

### Positive

- ✅ All `weak self` usages are correctly applied in escaping closures
- ✅ All `deinit` methods properly invalidate timers or cancel tasks
- ✅ `@MainActor` consistently applied across UI/service declarations
- ✅ Protocol-based DI enables clean test mocking
- ✅ UserDefaults isolated per test with unique suite names
- ✅ No `print()` statements found (logged via `os.log` or removed)
- ✅ No TODO, FIXME, HACK, or XXX comments in source code
- ✅ `fatalError` only in 1 standard location (`init(coder:)` in `NotchWindowController`)

### Resolved (v0.5.35+)

| Concern | Resolution |
| --- | --- |
| FocusSessionViewModel (415 lines) | Timer logic extracted to `SessionTimerService` (PR #130); state logic extracted to `SessionStateMachine` (PR #133); now ~330 lines |
| View extension proliferation (4 files) | Merged `+Controls` into main file, reduced from 4 to 3 files (PR #135) |
| PresetSettingsStore (311 lines, 16 props) | Split into `SessionDurationConfig`, `DisplayConfig`, `BehaviorConfig` modules (PR #132); now ~175 lines |
| Thin test files (ConfettiView, ClickOutside, Smoke) | Expanded with integration-level tests (PR #129, #131) |
| NoiseGenerator in AudioManager | Extracted to `Services/NoiseGenerator.swift` (PR #129) |
| Window positioning logic scattered | Extracted into `WindowPositioning` module (PR #137) |
| Pre-existing format issues | Resolved in v0.5.34 |
| SettingsMenuView preset editor (50 lines) | Extracted to `PresetEditorView` standalone component |

### Watch Points

- **SettingsMenuView**: Reduced from 334 to ~280 lines after extracting `PresetEditorView`. Still moderately large but well-structured with section helpers.
- **No UI/integration tests**: All tests are unit tests. No automated UI testing for notch positioning, window behavior, or visual states.

## Security

- App is sandboxed (`Oak.entitlements`)
- No network requests except Sparkle updates (HTTPS appcast)
- No user data collection or telemetry
- UserDefaults for local-only storage — no PII or secrets stored

## Performance

- Ambient audio uses `AVAudioEngine` with standby for smooth playback
- Noise generation (`NoiseGenerator`) is computationally light (per-sample math)
- Timer-based countdown at 1s intervals — low overhead
- No known memory leaks (all Combine subscriptions properly managed with `AnyCancellable` + `deinit`)

## MVP Constraints (Enforced)

| Constraint                             | Status |
| -------------------------------------- | ------ |
| Presets: 25/5 and 50/10 (configurable) | ✅     |
| Notch-only UI, no menu bar fallback    | ✅     |
| No global keyboard shortcuts           | ✅     |
| Auto-start next: OFF by default        | ✅     |
| Built-in audio only, no cloud sync     | ✅     |
