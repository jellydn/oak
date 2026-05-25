# CONCERNS.md — Technical Debt, Risks & Issues

## Architectural Concerns

### Single ViewModel Bloat

- **File**: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- **Issue**: The single `FocusSessionViewModel` handles timer management, state machine, audio control, preset selection, progress tracking, auto-start countdown, and session type display — all in one class (~390 lines).
- **Risk**: As features grow, this class will become increasingly difficult to maintain and test.
- **Suggestion**: Split into focused ViewModels (e.g., `SessionTimerViewModel`, `AudioControlsViewModel`, `ProgressViewModel`) or use a reducer-based approach.

### Tight Coupling Between ViewModel and Services

- **File**: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- **Issue**: The ViewModel directly holds references to `AudioManager`, `ProgressManager`, and `NotificationService`. While this works, it creates a broad surface area that makes unit testing harder (requires mocks for multiple services).
- **Risk**: Adding new service dependencies increases setup complexity in tests.
- **Suggestion**: Consider a coordinator/mediator pattern or protocol-based service locator to reduce direct coupling.

### NotchWindowController Complexity

- **File**: `Oak/Oak/Views/NotchWindowController.swift`
- **Issue**: Handles frame positioning, screen management, debounced updates, and expansion state tracking (~250 lines). The debounce mechanism (`pendingExpandedState`, `pendingForceReposition`, `isFrameUpdateScheduled`) adds complexity.
- **Risk**: Race conditions in frame updates, especially during rapid hover in/out or screen configuration changes.
- **Suggestion**: Consider consolidating the frame update queue into a dedicated state machine or using a reactive stream (Combine) for frame updates.

## Code Quality Issues

### Manual Retain/Release in NSScreenUUIDCache

- **File**: `Oak/Oak/Extensions/NSScreen+UUID.swift`
- **Issue**: `NSScreenUUIDCache` uses `UnsafeMutableRawPointer` and manual `Unmanaged.passRetained`/`Unmanaged.passUnretained` for screen observation callbacks.
- **Risk**: Memory leaks or crashes if retain/release balance is incorrect.
- **Suggestion**: Consider using `NSWorkspace.shared.notificationCenter` with Combine for screen change observation instead of Core Graphics callbacks.

### @unchecked Sendable on NoiseGenerator

- **File**: `Oak/Oak/Services/AudioManager.swift`
- **Issue**: `NoiseGenerator` is marked `@unchecked Sendable` because it's used inside `AVAudioSourceNode` render callbacks (audio thread). The comment asserts no cross-thread sharing, but there's no compile-time enforcement.
- **Risk**: Future changes could accidentally introduce cross-thread access.
- **Suggestion**: Add a concurrency assertion (`dispatchPrecondition`) in generate methods, or wrap in an actor.

### print() Statements

- **Issue**: Some `print()` calls may exist in production code. SwiftLint custom rule warns on these but doesn't block CI.
- **Suggestion**: Audit for any remaining `print()` calls and replace with `os.log` (`Logger`).

## Testing Concerns

### No Integration Tests

- **Issue**: All tests are unit tests. There are no integration tests for:
  - The full session lifecycle (state machine → progress persistence → notification → audio stop)
  - Window positioning with actual `NSScreen` instances
  - Audio playback with real audio engine
- **Risk**: Integration bugs between components may not be caught until manual testing.

### Limited Edge Case Coverage

- **Issue**: Tests cover happy paths and some edge cases (pause/resume, long break thresholds), but gaps exist:
  - System sleep/wake during active session
  - Rapid state transitions (start → complete → start → complete)
  - Multiple monitor hotplug events
  - App termination during active session
  - Very long sessions (max 180 min) with progress persistence

### Mock Overhead

- **File**: `Oak/Tests/OakTests/MockAudioManager.swift`
- **Issue**: Tests that need audio mocking must either use `MockAudioManager` (which requires special init) or `MockAudioEngine` (which requires injecting a factory). Two different mock patterns exist.
- **Suggestion**: Standardize on a single mocking approach across all test suites.

## Performance Concerns

### Timer Tick Every Second

- **File**: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- **Issue**: A `Timer.scheduledTimer(withTimeInterval: 1.0)` fires every second during an active session. On each tick, it creates a `Task { @MainActor in }` and reads `sessionEndDate.timeIntervalSinceNow`.
- **Impact**: Negligible for a single session, but wasteful if multiple timers or observers are involved.
- **Suggestion**: Consider using `DispatchSource` timer for lower overhead, or consolidate to a single app-wide timer.

### UserDefaults Read on Every Progress Load

- **File**: `Oak/Oak/Services/ProgressManager.swift`
- **Issue**: `loadProgress()` decodes the entire `ProgressData` array from `UserDefaults` on every call. For 90 days of history, this is a full JSON decode of all records.
- **Impact**: Likely negligible for small datasets (< 100 records), but could become a concern with daily use over years.
- **Suggestion**: Consider splitting recent vs. archived records, or adding an in-memory cache.

### Day-Check Timer Runs Every 60 Seconds

- **File**: `Oak/Oak/Services/ProgressManager.swift`
- **Issue**: A `Timer` checks for day changes every 60 seconds indefinitely.
- **Impact**: Minimal (simple date comparison), but runs even when the app is idle.
- **Suggestion**: Use `NSCalendar` notification for day change, or only check when app becomes active.

## Security Concerns

### X-Protect/Quarantine Warning

- **Issue**: Oak is not signed with an Apple Developer certificate. macOS may show Gatekeeper warnings on first launch.
- **File**: `README.md` documents this as known limitation.
- **Suggestion**: Obtain Apple Developer signing certificate for production releases.

### UserDefaults Plain Text Storage

- **Issue**: Session history and user preferences stored in plain text `UserDefaults` (JSON encoded).
- **Impact**: Any app or process with sandbox access can read session data. Acceptable for a focus app, but worth noting.

## Maintainability Concerns

### Duplicate State in FocusSessionViewModel

- **File**: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- **Issue**: `currentRemainingSeconds` is tracked alongside `sessionState`'s associated values. On tick, both the state's `remainingSeconds` and `currentRemainingSeconds` are updated.
- **Risk**: Desynchronization between the two values if one code path updates only one of them.
- **Suggestion**: Derive `currentRemainingSeconds` directly from `sessionState` in a computed property instead of maintaining a separate variable.

### PresetSettingsStore Property Explosion

- **File**: `Oak/Oak/Services/PresetSettingsStore.swift`
- **Issue**: 16 `@Published` properties with corresponding `set*` methods, `Keys` enum with 14 keys, and 164 lines of code. Every new setting adds 5+ lines.
- **Suggestion**: Consider grouping related settings into sub-types (e.g., `DisplaySettings`, `PresetSettings`, `NotificationSettings`).

### Hardcoded Values

- **File**: Multiple locations
- **Issue**: Several timeout values are hardcoded (auto-start countdown: 10s from `FocusSessionViewModel.swift`, idle collapse timeout from PRD: 1.0s, confetti animation duration from `ConfettiView`)
- **Suggestion**: Extract to named constants or configurable settings.

## Dependency Risks

### Sparkle Framework

- **Issue**: Auto-update depends on Sparkle 2.6.4+. Version bumps could introduce breaking API changes.
- **Mitigation**: Pinned version range in `project.yml` (`from: 2.6.4`).

### macOS Version Target

- **Issue**: Targeting macOS 13+ with SwiftUI features that may behave differently across minor versions (e.g., `safeAreaRegions`, `sizingOptions` availability checks at macOS 13.3).
- **Risk**: Conditional `#available` checks needed for some APIs, increasing code complexity.

## Documentation Gaps

- **Limited inline docs**: Most public APIs have no documentation comments (`///`), despite the convention in `AGENTS.md`
- **No CHANGELOG.md**: Release notes in `RELEASES.md` but no structured changelog
- **No architecture decision records** after ADR-0002 (code quality gates from Feb 2026)
