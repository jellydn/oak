# Testing

## Framework

- **XCTest** — Apple's native testing framework
- All tests annotated with `@MainActor`
- `@testable import Oak` for internal API access

## Test Structure

````
Tests/OakTests/                        # 29 test files
├── US001Tests.swift                   # Start focus session
├── US002Tests.swift                   # Pomodoro presets (25/5, 50/10)
├── US003Tests.swift                   # Pause and resume
├── US004Tests.swift                   # Ambient audio playback
├── US005Tests.swift                   # Session completion feedback
├── US006Tests.swift                   # Progress tracking & persistence
├── NotchCompanionViewTests.swift      # Main view tests
├── NotchCompanionViewTests+Layout.swift
├── NotchCompanionViewTests+SessionState.swift
├── NotchWindowControllerTests.swift   # Window management
├── NotchWindowControllerTests+NotchWindow.swift
├── NotchWindowControllerTests+WindowBehavior.swift
├── NotchWindowControllerTests+NotchFirstUI.swift
├── AudioManagerTests.swift            # Audio engine
├── AudioPersistenceTests.swift        # Audio settings persistence
├── AccessibilityTests.swift           # Accessibility labels/hints
├── AutoStartNextIntervalTests.swift   # Auto-start countdown
├── LongBreakTests.swift               # Long break cycle
├── ConfettiViewTests.swift            # Completion animation
├── ClickOutsideModifierTests.swift    # Popover dismiss
├── CountdownDisplayModeTests.swift    # Display format
├── AlwaysOnTopTests.swift             # Window level
├── NotificationTests.swift            # Notification permissions
├── SessionCompletionNotificationTests.swift
├── NSScreenNotchTests.swift           # Notch detection
├── SparkleUpdaterTests.swift          # Update framework
├── AppcastVersionParserTests.swift    # Appcast parsing
├── SmokeTests.swift                   # Basic sanity
└── MockAudioManager.swift             # Test double

## Mocking Strategy

### Protocol-Based Mocks
```swift
class MockNotificationService: SessionCompletionNotifying {
    var didNotify = false
    func notifySessionComplete() { didNotify = true }
}
````

### UserDefaults Isolation

Each test creates isolated UserDefaults suites to prevent cross-test contamination:

```swift
let suiteName = "OakTests.ClassName.\(UUID().uuidString)"
let userDefaults = UserDefaults(suiteName: suiteName)
```

### Cleanup in tearDown()

```swift
override func tearDown() {
    viewModel.cleanup()
    UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    super.tearDown()
}
```

## Test Coverage by Area

| Area              | Test Files                                            |
| ----------------- | ----------------------------------------------------- |
| Session lifecycle | US001, US002, US003, LongBreak, AutoStartNextInterval |
| Audio             | US004, AudioManager, AudioPersistence                 |
| Notifications     | US005, Notification, SessionCompletionNotification    |
| Progress          | US006                                                 |
| Notch UI          | NotchCompanionView, ConfettiView, NSScreenNotch       |
| Window management | NotchWindowController (4 files)                       |
| Settings          | CountdownDisplayMode, AlwaysOnTop                     |
| Accessibility     | AccessibilityTests                                    |
| Updates           | SparkleUpdater, AppcastVersionParser                  |
| Misc              | Smoke, ClickOutsideModifier                           |

## Running Tests

```bash
just test                          # Run all tests
just test-class ClassName          # Run specific test class
just test-method ClassName Method  # Run single test method
just test-verbose                  # Run all tests with verbose output
```
