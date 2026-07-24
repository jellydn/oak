# CONCERNS — Oak Technical Concerns

## Known Issues

### 1. SwiftLint Crashes Without Full Xcode

`SourceKittenFramework/library_wrapper.swift:58: Fatal error: Loading sourcekitdInProc.framework failed`

- **Impact**: Lint checks fail in CI or dev environments without full Xcode
- **Workaround**: None — requires full Xcode installation
- **File**: `.swiftlint.yml`

### 2. Pre-Existing Format Issues — RESOLVED

Two files previously failed `just format-check` due to `wrapIfStatementBodies` violations:

- `Oak/Oak/ViewModels/FocusSessionViewModel.swift` — 12 violations (fixed in v0.5.34)
- `Oak/Tests/OakTests/AudioManagerTests.swift` — 2 violations (fixed in v0.5.34)

Format-check now passes with 0 violations.

### 3. Building Requires Full Xcode

`xcodebuild` (used by all `just` commands: build, test, check, etc.) requires a full Xcode installation. Command Line Tools are insufficient.

- **Impact**: Cannot build, test, or typecheck from terminal environments with only Command Line Tools
- **Workaround**: Open in Xcode IDE and build from there

## Code Quality

### Positive

- ✅ All 13 `weak self` usages are correctly applied in escaping closures
- ✅ All 5 `deinit` methods properly invalidate timers
- ✅ `@MainActor` consistently applied across 59 UI/service declarations
- ✅ Protocol-based DI enables clean test mocking
- ✅ UserDefaults isolated per test with unique suite names
- ✅ No `print()` statements found (logged via `os.log` or removed)
- ✅ No TODO, FIXME, HACK, or XXX comments in source code
- ✅ `fatalError` only in 1 standard location (`init(coder:)` in `NotchWindowController`)

### Watch Points

- **Single large ViewModel**: `FocusSessionViewModel.swift` at 417 lines is the most complex file. Could benefit from extraction of session completion logic or auto-start countdown into separate types.
- **View extensions**: `NotchCompanionView` has 3 extension files (`+Controls`, `+StandardViews`, `+InsideNotch`) plus the main view file. Monitor for further fragmentation.
- **PresetSettingsStore**: 16 `@Published` properties with 311 lines — consider grouping related settings into sub-types if this grows further.

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
