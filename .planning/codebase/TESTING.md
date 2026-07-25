# TESTING.md — Test Structure & Practices

## Framework

| Aspect    | Detail                                                         |
| --------- | -------------------------------------------------------------- |
| Framework | XCTest                                                         |
| Runner    | `xcodebuild test` via `just test`                              |
| Target    | `OakTests` (bundle.unit-test, `GENERATE_INFOPLIST_FILE: true`) |
| CI        | GitHub Actions, `macos-26` runner, unsigned builds             |

## Test File Organization

```
Tests/OakTests/
├── US001Tests.swift                            # Notch visibility, session start
├── US002Tests.swift                            # Preset selection
├── US003Tests.swift                            # Pause/resume session
├── US004Tests.swift                            # Audio, volume, display target
├── US005Tests.swift                            # Session completion states
├── US006Tests.swift                            # Progress tracking & streaks
├── SessionCompletionNotificationTests.swift    # Notifications & sounds
├── AudioManagerTests.swift                     # Audio engine
├── AudioPersistenceTests.swift                 # Audio track persistence
├── AutoStartNextIntervalTests.swift            # Auto-start countdown
├── CountdownDisplayModeTests.swift             # Display mode persistence
├── LongBreakTests.swift                        # Long break logic
├── AlwaysOnTopTests.swift                      # Always-on-top setting
├── NotchCompanionViewTests.swift               # View initialization
├── NotchCompanionViewTests+SessionState.swift  # State transitions
├── NotchCompanionViewTests+Layout.swift        # Layout tests
├── NotchWindowControllerTests.swift            # Window creation
├── NotchWindowControllerTests+WindowBehavior.swift  # Expand/collapse
├── NotchWindowControllerTests+NotchWindow.swift     # Window features
├── NotchWindowControllerTests+NotchFirstUI.swift    # Notch-first positioning
├── NotificationTests.swift                     # Notification service
├── AccessibilityTests.swift                    # Accessibility
├── SparkleUpdaterTests.swift                   # Sparkle updater
├── ConfettiViewTests.swift                     # Confetti view
├── ClickOutsideModifierTests.swift             # Click-outside dismiss
├── AppcastVersionParserTests.swift             # Appcast parsing
├── NSScreenNotchTests.swift                    # Notch detection
├── SmokeTests.swift                            # Sanity check
└── MockAudioManager.swift                      # Audio manager mock
```

## Conventions

### @MainActor on All Test Classes

```swift
@MainActor
internal final class US003Tests: XCTestCase { ... }
```

### UserDefaults Isolation

Every test uses a unique `UserDefaults` suite to prevent cross-test contamination:

```swift
override func setUp() async throws {
    let suiteName = "OakTests.ClassName.\(UUID().uuidString)"
    guard let userDefaults = UserDefaults(suiteName: suiteName) else {
        XCTFail("Failed to create UserDefaults")
        return
    }
    userDefaults.removePersistentDomain(forName: suiteName)
    presetSuiteName = suiteName
    // ... create dependencies with userDefaults
}

override func tearDown() async throws {
    viewModel.cleanup()
    UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
}
```

### Protocol-Based Mocks

```swift
// Mock notification service
private final class MockNotificationService: SessionCompletionNotifying {
    var didNotify = false
    func notifySessionComplete() { didNotify = true }
}

// Mock audio manager
@MainActor
internal class MockAudioManager: AudioManager {
    var playCalledWithTrack: AudioTrack?
    var stopCallCount = 0
    // ...
}
```

### State Transition Testing

Tests verify the complete FSM cycle:

- `idle → running → paused → running → completed → (next) → running → ... → idle`
- Individual transitions tested: `canStart`, `canPause`, `canResume`, `canStartNext`
- Guard clauses tested: "cannot pause when not running", "cannot resume when not paused"

### User Story Tests (US001–US006)

Each `US00XTests` file corresponds to a user story from the PRD:

- **US001**: Notch companion visibility and session start
- **US002**: Preset selection (short 25/5, long 50/10)
- **US003**: Pause and resume session with time preservation
- **US004**: Built-in audio tracks, volume control
- **US005**: Session completion, round counting
- **US006**: Progress tracking, streaks, daily stats

### Dependency Injection in Tests

```swift
viewModel = FocusSessionViewModel(
    presetSettings: presetSettings,
    audioManager: MockAudioManager(),
    notificationService: MockNotificationService(),
    completionSoundPlayer: MockSessionCompletionSoundPlayer()
)
```

### TestClock Pattern

For time-dependent tests (streaks, daily rollover), a `TestClock` is used:

```swift
private final class TestClock {
    var currentDate: Date
    func advance(days: Int) { ... }
}
```

## Running Tests

```bash
just test                            # All tests
just test-verbose                    # Verbose output
just test-class FocusSessionViewModelTests
just test-method US003Tests testCanPauseActiveSession
```

## CI Pipeline

Tests run on every PR and push to `main` via `.github/workflows/ci.yml`:

1. Lint: `swiftlint lint --strict`
2. Build: `xcodebuild build CODE_SIGNING_ALLOWED=NO`
3. Test: `xcodebuild test CODE_SIGNING_ALLOWED=NO`
