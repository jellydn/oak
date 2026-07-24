# TESTING — Oak Testing Patterns

## Framework

- **XCTest** (Swift Testing not used)
- All test classes annotated `@MainActor`
- Tests located in `Tests/OakTests/` mirroring source structure

## Test Structure

### Setup Pattern

```swift
override func setUp() async throws {
    try await super.setUp()
    suiteName = "OakTests.ClassName.\(UUID().uuidString)"
    guard let userDefaults = UserDefaults(suiteName: suiteName) else {
        throw NSError(domain: "ClassName", code: 1)
    }
    userDefaults.removePersistentDomain(forName: suiteName)
    presetSettings = PresetSettingsStore(userDefaults: userDefaults)
    viewModel = FocusSessionViewModel(
        presetSettings: presetSettings,
        notificationService: notificationService
    )
}
```

### Teardown Pattern

```swift
override func tearDown() async throws {
    viewModel.cleanup()
    UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    try await super.tearDown()
}
```

## Key Patterns

### UserDefaults Isolation

Every test uses a **unique suite name** to prevent state leakage:

```swift
let suiteName = "OakTests.ClassName.\(UUID().uuidString)"
let userDefaults = UserDefaults(suiteName: suiteName)
```

### Protocol-Based Mocking

```swift
// Mock protocol for DI
class MockNotificationService: SessionCompletionNotifying {
    var didNotify = false
    func sendSessionCompletionNotification(isWorkSession: Bool) { didNotify = true }
}

class MockSessionCompletionSoundPlayer: SessionCompletionSoundPlaying {
    var didPlay = false
    func playCompletionSound() { didPlay = true }
}
```

### MockAudioManager

`MockAudioManager.swift` provides a full mock of `AudioManager` for tests:

- Overrides `play(track:)`, `pause()`, `resume()`, `stop()`
- Uses `MockTestAudioEngine` implementing `AudioEngineProtocol`
- No real audio I/O — pure state tracking

### State Transition Testing

Tests verify the complete session lifecycle:

```
idle → start → running → complete → idle
                  ↓
               pause → resume
```

## Test File Organization

| File | Coverage Area |
| --- | --- |
| `US001Tests.swift` | Session presets (25/5, 50/10) |
| `US002Tests.swift` | Preset selection & validation |
| `US003Tests.swift` | Session completion behavior |
| `US004Tests.swift` | Settings persistence to UserDefaults |
| `US005Tests.swift` | Long break logic |
| `US006Tests.swift` | Daily progress & round tracking |
| `NotchCompanionViewTests.swift` | View initialization, expansion toggle |
| `NotchCompanionViewTests+Layout.swift` | Preset labels, popover state, layout defaults |
| `NotchCompanionViewTests+SessionState.swift` | Session state-bound view behavior |
| `NotchWindowControllerTests.swift` | Window lifecycle, notch-first behavior |
| `AudioManagerTests.swift` | Playback, volume, track selection, noise generation |
| `AccessibilityTests.swift` | Accessibility identifiers, labels, hints |
| `SessionCompletionNotificationTests.swift` | Notification sending, sound playing |
| `AutoStartNextIntervalTests.swift` | Auto-start toggle and countdown |
| `AlwaysOnTopTests.swift` | Window level toggling |
| `LongBreakTests.swift` | Long break triggers and reset |
| `CountdownDisplayModeTests.swift` | Display mode persistence |
| `SparkleUpdaterTests.swift` | Update checker configuration |
| `NSScreenNotchTests.swift` | Notch detection |
| `ClickOutsideModifierTests.swift` | Popover dismiss behavior |

## Test Commands

```bash
just test                           # Run all tests
just test-class NotchCompanionViewTests  # Run specific class
just test-method US002Tests testPresetDurationsCorrect  # Run single test
```

## Known Testing Limitations

- `@State` properties on SwiftUI views **cannot be mutated outside the rendering pipeline** — tests can only read defaults
- No UI/integration tests — only unit tests
- No snapshot testing
- Environment requires full Xcode installation (Command Line Tools insufficient for `xcodebuild test`)
