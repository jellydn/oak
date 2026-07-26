# Testing Patterns

**Analysis Date:** 2026-07-26

## Test Framework

**Runner:**

- XCTest (Apple built-in)
- Config: `Oak/project.yml` — `OakTests` bundle target with `Oak` app as dependency; scheme `Oak` test target

**Assertion Library:**

- `XCTestCase` assertions (`XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNotNil`, `XCTAssertLessThan`, etc.)

**Run Commands:**

```bash
just test                                          # Run all tests (xcodebuild)
just test-class FocusSessionViewModelTests         # Run one class
just test-method FocusSessionViewModelTests testStartSession  # Run single method
just test-verbose                                  # Verbose output
just check                                         # Incremental build (compile check)
just check-style                                   # SwiftLint + SwiftFormat lint
```

CI runs `xcodebuild ... test CODE_SIGNING_ALLOWED=NO` on `macos-26` with Xcode latest-stable (`.github/workflows/ci.yml`).

## Test File Organization

**Location:** Separate `Oak/Tests/OakTests/` directory (not co-located with sources).

**Naming:** `<Subject>Tests.swift` for feature suites; `US00xTests.swift` for user-story-driven suites; `<Subject>Tests+<Aspect>.swift` for split suites (`NotchWindowControllerTests+WindowBehavior.swift`, `NotchWindowControllerTests+NotchWindow.swift`, `NotchWindowControllerTests+NotchFirstUI.swift`).

**Structure:**

```
Oak/Tests/OakTests/
├── SmokeTests.swift                 # Type-existence + default-value smoke checks
├── US001Tests.swift ... US006Tests.swift   # User-story acceptance tests
├── AudioManagerTests.swift
├── AudioPersistenceTests.swift
├── AutoStartNextIntervalTests.swift
├── AccessibilityTests.swift
├── AlwaysOnTopTests.swift
├── AppcastVersionParserTests.swift
├── ClickOutsideModifierTests.swift
├── ConfettiViewTests.swift
├── CountdownDisplayModeTests.swift
├── LongBreakTests.swift
├── MockAudioManager.swift           # Shared mock (subclass pattern)
├── NSScreenNotchTests.swift
├── NotchCompanionViewTests*.swift   # 3 split suites (+Layout, +SessionState)
├── NotchWindowControllerTests*.swift # 4 split suites
├── NotificationTests.swift
├── SessionCompletionNotificationTests.swift
├── SparkleUpdaterTests.swift
└── ...
```

33 test files, ~4252 lines total (source is ~5024 lines — test:source ratio ~0.85).

## Test Structure

**Suite Organization:** Typical user-story suite (`Oak/Tests/OakTests/US001Tests.swift`):

```swift
@MainActor
internal final class US001Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.US001.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else { throw NSError(...) }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        viewModel = FocusSessionViewModel(presetSettings: presetSettings, notificationService: NotificationService())
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        if let presetSuiteName { UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName) }
    }

    func testPrimaryActionStarts25MinuteSession() { ... }
}
```

**Patterns:**

- `@MainActor` on every test class (matches production `@MainActor` isolation)
- `setUp` async throws; create isolated `UserDefaults` suite with UUID per test run
- `tearDown` calls `viewModel.cleanup()` then `removePersistentDomain` to avoid cross-test contamination
- `internal` class access (matches `explicit_top_level_acl` rule)
- Arrange → Act → Assert with descriptive test method names (`testPrimaryActionStarts25MinuteSession`)

## Mocking

**Framework:** Hand-rolled protocol mocks and subclass overrides (no mocking library).

**Patterns:**

Protocol mock (`Oak/Tests/OakTests/SessionCompletionNotificationTests.swift:6`):

```swift
@MainActor
private final class MockNotificationService: SessionCompletionNotifying {
    private(set) var sentNotifications: [Bool] = []
    func sendSessionCompletionNotification(isWorkSession: Bool) {
        sentNotifications.append(isWorkSession)
    }
}

@MainActor
private final class MockSessionCompletionSoundPlayer: SessionCompletionSoundPlaying {
    private(set) var playCallCount = 0
    func playCompletionSound() { playCallCount += 1 }
}
```

Subclass mock with fake engine (`Oak/Tests/OakTests/MockAudioManager.swift`):

```swift
@MainActor
internal final class MockAudioManager: AudioManager {
    init() { super.init { MockTestAudioEngine() } }
    override func play(track: AudioTrack) { ... }   // no-op audio, just sets state
}

private final class MockTestAudioEngine: AudioEngineProtocol {
    var isRunning: Bool = false
    var outputChannelCount: UInt32 = 2
    var outputSampleRate: Double = 44100
    func start() throws { isRunning = true }
    // ...
}
```

**What to Mock:**

- `SessionCompletionNotifying` — to assert notification calls without `UNUserNotificationCenter`
- `SessionCompletionSoundPlaying` — to assert beep calls without `NSSound.beep()`
- `AudioEngineProtocol` — to avoid real `AVAudioEngine` in tests
- `currentDate: () -> Date` closure — to simulate day rollover in `ProgressManager`/`FocusSessionViewModel`
- `UserDefaults` suite — isolate persistence per test

**What NOT to Mock:**

- `SessionStateMachine` (pure functions — test directly)
- `SessionTimerService` — sometimes real (rely on calling `completeSession()` directly to bypass 1s ticks), sometimes injected
- `PresetSettingsStore` — use real instance with isolated UserDefaults suite

## Fixtures and Factories

**Test Data:** Inline construction; no shared fixtures directory.

```swift
let first = SessionState.running(remainingSeconds: 1500, isWorkSession: true)
```

`ProgressManager.recordSessionCompletion` tests build `SessionRecord`/`ProgressData` inline via the production init defaults.

**Location:** No fixtures folder — data constructed in-test. Shared mock (`MockAudioManager.swift`) is the only cross-suite helper.

## Coverage

**Requirements:** None enforced. No coverage report generation in CI.

**View Coverage:** `xcodebuild` test output is the only signal; `just test` runs the full suite.

## Test Types

**Unit Tests:**

- Dominant. Cover `FocusSessionViewModel` state transitions, `SessionStateMachine` purity, `AudioManager` (with fake engine), `ProgressManager` streak/retention/export-import, `PresetSettingsStore` persistence, `KeyboardShortcutService` config load/save, `AppcastVersionParser` semver parsing, `CountdownDisplayMode`, `NotchLayout` dimensions.

**Integration Tests:**

- `NotchWindowControllerTests*` — instantiate `NotchWindowController` and assert window behavior, notch-first UI, frame updates (light integration; no full UI rendering).
- `NotchCompanionViewTests*` — construct views and assert existence/layout/session-state-driven content.
- `AccessibilityTests` — assert view subviews (audio/progress/settings/expand buttons, preset chips) are non-nil and accessibility identifiers are unique.

**E2E Tests:** Not used. No UI automation (XCUITest) — the app is notch-only and accessory-mode, making XCUITest impractical.

## Common Patterns

**Async Testing:**

```swift
override func setUp() async throws { ... }      // async setUp for MainActor isolation
viewModel.startSession()
viewModel.completeSession()                     // bypass real timer by calling completion directly
```

Real `Task.sleep` (1.5s completion reset, 10s auto-start countdown) is **not** awaited in tests — completion is invoked synchronously via `completeSession()`.

**Error Testing:**

- No `XCTAssertThrowsError` usage observed. Failures are silent-failure paths in production; tests assert the _observable outcome_ (e.g. `playCallCount == 0` when opted out) rather than thrown errors.

**State-transition testing:** `SmokeTests` validates `SessionState` equality for each phase; `SessionCompletionNotificationTests` walks full work → break → auto-start sequences asserting side-effects at each step.

---

_Testing analysis: 2026-07-26_
