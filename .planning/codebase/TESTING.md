# TESTING.md — Testing Strategy & Practices

## Test Framework

- **Framework**: XCTest (Apple built-in)
- **Parallelism**: Tests run on `@MainActor` (all test classes annotated)
- **Target**: `OakTests` (bundle.unit-test in `project.yml`)

## Test File Organization

Test files mirror source structure with `Tests` suffix naming:

```
Tests/OakTests/
├── FocusSessionViewModelTests equivalents (user story based):
│   ├── US001Tests.swift                — Start session from notch
│   ├── US002Tests.swift                — Fixed Pomodoro presets
│   ├── US003Tests.swift                — Pause/resume sessions
│   ├── US004Tests.swift                — Ambient sound during sessions
│   ├── US005Tests.swift                — Session completion feedback
│   └── US006Tests.swift                — Personal progress tracking
├── Service tests:
│   ├── AudioManagerTests.swift         — Audio playback, volume, tracks
│   ├── AudioPersistenceTests.swift     — Audio preferences persistence
│   ├── NotificationTests.swift         — Notification permissions
│   ├── SessionCompletionNotificationTests.swift — Completion notifications
│   ├── SparkleUpdaterTests.swift       — Auto-update integration
│   └── AppcastVersionParserTests.swift — Version string parsing
├── UI/View tests:
│   ├── NotchCompanionViewTests.swift          — Notch view rendering
│   ├── NotchCompanionViewTests+Layout.swift   — Layout calculations
│   ├── NotchCompanionViewTests+SessionState.swift — State-based rendering
│   ├── NotchWindowControllerTests.swift       — Window lifecycle
│   ├── NotchWindowControllerTests+NotchWindow.swift — Window properties
│   ├── NotchWindowControllerTests+WindowBehavior.swift — Window behavior
│   ├── NotchWindowControllerTests+NotchFirstUI.swift — Initial UI state
│   ├── ConfettiViewTests.swift       — Confetti animation
│   └── ClickOutsideModifierTests.swift — Popover dismiss behavior
├── Feature tests:
│   ├── LongBreakTests.swift           — Long break after 4 rounds
│   ├── AutoStartNextIntervalTests.swift — Auto-start countdown
│   ├── AlwaysOnTopTests.swift         — Always-on-top window setting
│   ├── CountdownDisplayModeTests.swift — Number vs circle ring
│   ├── AccessibilityTests.swift       — Accessibility identifiers
│   └── NSScreenNotchTests.swift       — Notch detection
└── Support:
    ├── MockAudioManager.swift         — Mock audio manager for DI
    └── SmokeTests.swift               — Basic infrastructure test
```

## Testing Patterns

### Setup & Teardown

```swift
@MainActor
internal final class US001Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.US001.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "US001Tests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            notificationService: NotificationService()
        )
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?
                .removePersistentDomain(forName: presetSuiteName)
        }
    }
}
```

### UserDefaults Isolation

- **Every test suite uses a unique `UserDefaults` suite** with `UUID().uuidString`
- This prevents state pollution between test runs
- Cleaned up in `tearDown()` via `removePersistentDomain(forName:)`

### Mocking / DI

Protocol-based mocks with manual spy tracking:

```swift
// Protocol
internal protocol AudioEngineProtocol {
    var isRunning: Bool { get }
    func start() throws
    func stop()
}

// Mock
internal final class MockAudioEngine: AudioEngineProtocol {
    var isRunning: Bool = false
    var startError: Error?
    var startCalled = false
    var stopCalled = false

    func start() throws {
        if let error = startError { throw error }
        isRunning = true
        startCalled = true
    }

    func stop() {
        isRunning = false
        stopCalled = true
    }
}
```

### Test Class Hierarchy

| Pattern | Example | When Used |
| --- | --- | --- |
| User story tests | `US001Tests`, `US002Tests` | Acceptance criteria from PRD |
| Feature tests | `LongBreakTests`, `AutoStartNextIntervalTests` | Cross-cutting feature behavior |
| Component tests | `AudioManagerTests`, `NotchWindowControllerTests` | Single class/module |
| Mock/support | `MockAudioManager` | Shared test doubles |

## Test Coverage Areas

### Session State Machine

- State transitions: idle → running → paused → completed → idle
- Timer accuracy (1s intervals)
- Remaining time preservation across pause/resume

### Preset Configuration

- Both presets (short/long) work correctly
- Configurable durations via `PresetSettingsStore`
- Long break trigger at 4 rounds (configurable)

### Audio System

- All 5 ambient tracks play correctly
- Volume clamping (0.0–1.0)
- Pause/resume preserves track selection
- Stop clears state
- Noise generator output range validation (all 5 types)
- Rain noise seed wrapping after 700K+ iterations

### Progress Tracking

- Session recording with correct start/end times
- Streak calculation across days
- Data persistence across view model re-creation
- 90-day pruning

### Window Management

- Screen positioning on main/notched display
- Expand/collapse states
- Always-on-top behavior
- Screen configuration changes

### Notification

- Permission request flow
- Completion notification content
- Sound playing configuration

## Test Execution

```bash
# Run all tests
just test

# Run a specific test class
just test-class LongBreakTests

# Run a specific test method
just test-method US001Tests testPrimaryActionStarts25MinuteSession

# Run with verbose output
just test-verbose
```

## Known Test Limitations

- Tests cannot verify actual audio output (no audio hardware mocking)
- Window positioning tests use mocked screen objects
- Timer-based tests rely on direct `completeSession()` calls rather than waiting for real time
- No UI snapshot or integration tests exist (unit test only)
- Sparkle updater tests require careful mock setup to avoid network calls
