# Testing Patterns

**Analysis Date:** 2026-02-13

## Test Framework

**Runner:**
- XCTest (built-in)
- Swift 5.9+, macOS 13.0+ deployment target
- Config: `project.yml` via XcodeGen

**Assertion Library:**
- XCTest assertions (`XCTAssertEqual`, `XCTAssertTrue`, `XCTFail`)

**Run Commands:**
```bash
just test               # Run all tests
just test-verbose       # Run tests with verbose output
just test-class Tests   # Run specific test class
just test-method Tests "testName"  # Run specific test method
```

## Test File Organization

**Location:**
- Separate `Tests/` directory mirrored from source structure
- Test bundle target: `OakTests`
- Source: `Oak/Tests/OakTests/`

**Naming:**
- Test files: Source name + `Tests` suffix (`LongBreakTests.swift`, `US001Tests.swift`)
- Test classes: Match filename (`internal final class US001Tests: XCTestCase`)
- Test methods: `test` prefix describing what is tested (`testLongBreakTriggeredAfterFourthRound`)

**Structure:**
```
Oak/Tests/OakTests/
├── SmokeTests.swift           # Basic smoke tests
├── US001Tests.swift           # User Story 1 tests
├── US002Tests.swift           # User Story 2 tests
├── US003Tests.swift
├── US004Tests.swift
├── US005Tests.swift
├── US006Tests.swift
├── LongBreakTests.swift       # Long break feature tests
├── NotificationTests.swift    # Notification service tests
├── ConfettiViewTests.swift
├── CountdownDisplayModeTests.swift
├── NotchWindowControllerTests.swift
├── SessionCompletionNotificationTests.swift
└── UpdateCheckerTests.swift
```

## Test Structure

**Suite Organization:**
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
        viewModel = FocusSessionViewModel(presetSettings: presetSettings)
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
        }
    }

    // MARK: - Helper Methods

    private func completeFourWorkSessions() {
        for round in 1 ... 4 {
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSessionForTesting()
            if round < 4 {
                viewModel.startNextSession()
                viewModel.completeSessionForTesting()
            }
        }
    }
}
```

**Patterns:**
- `@MainActor` annotation on all test classes
- `setUp() async throws` - fixture setup with unique UserDefaults suite
- `tearDown() async throws` - cleanup and UserDefaults removal
- `// MARK: - Helper Methods` section for test utilities
- Descriptive test names that read as assertions
- Given/When/Then structure in test body

## Mocking

**Framework:** Protocol-based injection with `any` type

**Patterns:**
```swift
// Protocol for dependency abstraction
internal protocol SessionCompletionNotifying {
    func sendSessionCompletionNotification(isWorkSession: Bool)
}

// Constructor injection for testability
init(
    presetSettings: PresetSettingsStore,
    notificationService: (any SessionCompletionNotifying)? = nil,
    completionSoundPlayer: (any SessionCompletionSoundPlaying)? = nil
) {
    self.notificationService = notificationService ?? NotificationService.shared
    self.completionSoundPlayer = completionSoundPlayer ?? SystemSessionCompletionSoundPlayer()
}
```

**What to Mock:**
- External services (notifications, sound, updates)
- System dependencies (UserDefaults, network, file system)
- Cross-cutting concerns (time, randomness)

**What NOT to Mock:**
- Data models and simple value types
- ViewModels in integration tests
- Pure functions and computed properties

## Fixtures and Factories

**Test Data:**
- Helper methods for complex state setup
- Example: `completeFourWorkSessions()` in LongBreakTests

**Location:**
- Inline within test classes as private methods
- Shared fixtures via base class (not currently used)

**UserDefaults Isolation:**
```swift
let suiteName = "OakTests.US001.\(UUID().uuidString)"
guard let userDefaults = UserDefaults(suiteName: suiteName) else {
    throw NSError(domain: "US001Tests", code: 1)
}
userDefaults.removePersistentDomain(forName: suiteName)
```

## Coverage

**Requirements:** No enforced minimum, aim for high-value coverage

**View Coverage:** Not tracked

**Coverage Focus:**
- ViewModel state transitions and computed properties
- Settings persistence and validation
- Edge cases (bounds checking, state resets)
- Long break cycle logic (complex state machine)

## Test Types

**Unit Tests:**
- Individual ViewModel behavior
- Settings validation and clamping
- Helper function correctness
- Enum case handling

**Integration Tests:**
- ViewModel + SettingsStore interaction
- Multi-round session cycles
- Progress tracking and streaks
- Audio state during session lifecycle

**E2E Tests:**
- Not used (macOS app limitation)
- SmokeTests.swift verifies basic app instantiation

## Common Patterns

**Async Testing:**
```swift
@MainActor
internal final class NotificationTests: XCTestCase {
    override func setUp() async throws {
        notificationService = NotificationService.shared
    }

    func testNotificationServiceAuthorizationRequest() async throws {
        // Test async methods
    }
}
```

**Error Testing:**
```swift
func testNotificationServiceAuthorizationRequest() throws {
    throw XCTSkip("Skipping authorization request test to avoid system notification prompts in automated runs")
}
```

**State Transition Testing:**
```swift
func testRoundCounterIncrementsAfterWorkSession() {
    viewModel.startSession()
    XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should be 0 before completion")

    viewModel.completeSessionForTesting()
    XCTAssertEqual(viewModel.completedRounds, 1, "Rounds should increment to 1 after work completion")
}
```

**Bounds Testing:**
```swift
func testRoundsBeforeLongBreakIsClampedToValidRange() {
    presetSettings.setRoundsBeforeLongBreak(0)
    XCTAssertEqual(presetSettings.roundsBeforeLongBreak, PresetSettingsStore.minRoundsBeforeLongBreak)

    presetSettings.setRoundsBeforeLongBreak(100)
    XCTAssertEqual(presetSettings.roundsBeforeLongBreak, PresetSettingsStore.maxRoundsBeforeLongBreak)
}
```

**Persistence Testing:**
```swift
func testDisplayTargetIsPersisted() {
    presetSettings.setDisplayTarget(.notchedDisplay)

    guard let reloadedDefaults = UserDefaults(suiteName: presetSuiteName) else {
        XCTFail("Failed to create UserDefaults with suite name")
        return
    }
    let reloadedStore = PresetSettingsStore(userDefaults: reloadedDefaults)
    XCTAssertEqual(reloadedStore.displayTarget, .notchedDisplay)
}
```

---

*Testing analysis: 2026-02-13*
