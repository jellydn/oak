# Testing Patterns

**Analysis Date:** 2026-02-15

## Test Framework
**Runner:**
- XCTest (Apple built-in)
- Config: `Oak/project.yml` (OakTests target), built via `xcodebuild`
**Assertion Library:**
- XCTest assertions: `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertFalse`, `XCTAssertNotNil`, `XCTAssertNil`, `XCTAssertNoThrow`, `XCTAssertLessThan`, `XCTAssertGreaterThan`, `XCTAssertGreaterThanOrEqual`, `XCTAssertLessThanOrEqual`
**Run Commands:**
```bash
just test                                          # Run all tests
just test-verbose                                  # Run tests with verbose output
just test-class US001Tests                         # Run specific test class
just test-method US001Tests testStartSession       # Run specific test method
```

## Test File Organization
**Location:**
- Separate directory: `Oak/Tests/OakTests/` (not co-located with source)
**Naming:**
- User story tests: `US001Tests.swift`, `US002Tests.swift` ... `US006Tests.swift`
- Feature tests: `LongBreakTests.swift`, `AlwaysOnTopTests.swift`, `CountdownDisplayModeTests.swift`, `NotificationTests.swift`
- Component tests: `NotchWindowControllerTests.swift`, `ConfettiViewTests.swift`, `NSScreenNotchTests.swift`
- Service tests: `UpdateCheckerTests.swift`, `SparkleUpdaterTests.swift`, `AppcastVersionParserTests.swift`
- Smoke tests: `SmokeTests.swift`
- Extension files for large test classes: `NotchWindowControllerTests+WindowBehavior.swift`, `NotchWindowControllerTests+NotchWindow.swift`, `NotchWindowControllerTests+NotchFirstUI.swift`
**Structure:**
```
Oak/Tests/OakTests/
├── SmokeTests.swift                                    # Basic sanity check
├── US001Tests.swift                                    # User story: Start session
├── US002Tests.swift                                    # User story: Preset selection
├── US003Tests.swift                                    # User story: Pause/Resume
├── US004Tests.swift                                    # User story: Audio & settings
├── US005Tests.swift                                    # User story: Completion feedback
├── US006Tests.swift                                    # User story: Progress tracking
├── LongBreakTests.swift                                # Long break feature
├── AlwaysOnTopTests.swift                              # Always-on-top window
├── CountdownDisplayModeTests.swift                     # Display mode switching
├── NotificationTests.swift                             # Notification service
├── SessionCompletionNotificationTests.swift            # Completion + sound mocking
├── ConfettiViewTests.swift                             # Confetti view init
├── NSScreenNotchTests.swift                            # Screen notch detection
├── NotchWindowControllerTests.swift                    # Window controller base + helpers
├── NotchWindowControllerTests+WindowBehavior.swift     # Expansion/collapse behavior
├── NotchWindowControllerTests+NotchWindow.swift        # Window properties
├── NotchWindowControllerTests+NotchFirstUI.swift       # Notch-first positioning
├── UpdateCheckerTests.swift                            # Legacy update checker
├── SparkleUpdaterTests.swift                           # Sparkle updater
└── AppcastVersionParserTests.swift                     # Appcast XML parsing
```

## Test Structure
**Suite Organization:**
```swift
import SwiftUI
import XCTest
@testable import Oak

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

    func testPrimaryActionStarts25MinuteSession() {
        XCTAssertEqual(viewModel.canStart, true)
        viewModel.startSession()
        XCTAssertEqual(viewModel.isRunning, true)
    }
}
```
**Patterns:**
- `@MainActor` on all test classes that touch UI/ViewModel code
- `internal final class` with explicit access control
- `override func setUp() async throws` for async setup
- `override func tearDown() async throws` for cleanup
- Force-unwrapped (`!`) instance variables set in `setUp`
- `// MARK: -` sections to group related tests within a class
- Extension files (e.g., `+WindowBehavior`) to split large test classes across files

## Mocking
**Framework:** Manual protocol-based mocks (no third-party mocking library)
**Patterns:**
```swift
// Protocol defined in production code (Oak/Oak/Services/NotificationService.swift)
@MainActor
internal protocol SessionCompletionNotifying {
    func sendSessionCompletionNotification(isWorkSession: Bool)
}

// Mock in test file (Oak/Tests/OakTests/SessionCompletionNotificationTests.swift)
@MainActor
private final class MockNotificationService: SessionCompletionNotifying {
    private(set) var sentNotifications: [Bool] = []

    func sendSessionCompletionNotification(isWorkSession: Bool) {
        sentNotifications.append(isWorkSession)
    }
}

// URLProtocol-based network mocking (Oak/Tests/OakTests/UpdateCheckerTests.swift)
private class MockURLProtocol: URLProtocol {
    static var statusCode = 200
    static var responseData = Data()

    override class func canInit(with _: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { /* return mock response */ }
    override func stopLoading() {}
}
```
**What to Mock:**
- Notification services (`MockNotificationService`)
- Sound players (`MockSessionCompletionSoundPlayer`)
- Network sessions via `URLProtocol` subclass (`MockURLProtocol`)
- UserDefaults with unique suite names per test class

**What NOT to Mock:**
- ViewModels (tested directly with real instances)
- Models and enums (pure value types, tested directly)
- `PresetSettingsStore` (uses isolated UserDefaults instead)
- Window/screen APIs (use `XCTSkip` when hardware unavailable)

## Fixtures and Factories
**Test Data:**
```swift
// Isolated UserDefaults per test class (standard pattern in all test files)
let suiteName = "OakTests.US001.\(UUID().uuidString)"
guard let userDefaults = UserDefaults(suiteName: suiteName) else {
    throw NSError(domain: "US001Tests", code: 1)
}
userDefaults.removePersistentDomain(forName: suiteName)

// XML fixtures inline for parser tests (Oak/Tests/OakTests/AppcastVersionParserTests.swift)
let appcast = """
<rss>
  <channel>
    <item>
      <sparkle:shortVersionString>0.4.10</sparkle:shortVersionString>
    </item>
  </channel>
</rss>
"""

// Helper methods for complex setup (Oak/Tests/OakTests/LongBreakTests.swift)
private func completeFourWorkSessions() {
    for round in 1 ... 4 {
        if round == 1 { viewModel.startSession() }
        else { viewModel.startNextSession() }
        viewModel.completeSessionForTesting()
        if round < 4 {
            viewModel.startNextSession()
            viewModel.completeSessionForTesting()
        }
    }
}

// Polling helper for async window behavior (Oak/Tests/OakTests/NotchWindowControllerTests.swift)
@discardableResult
func waitForFrameWidth(_ width: CGFloat, timeout: TimeInterval) -> Bool {
    let endTime = Date().addingTimeInterval(timeout)
    while Date() < endTime {
        if let window = windowController.window as? NotchWindow,
           abs(window.frame.width - width) <= 1.0 { return true }
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
    }
    return false
}
```
**Location:**
- Inline in test files (no shared fixtures directory)
- Helper methods defined as `private func` or in `internal extension` blocks within test files

## Coverage
**Requirements:** None enforced (no coverage threshold configured)
**View Coverage:**
```bash
# No built-in coverage command in justfile; use Xcode or:
cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak \
  -destination 'platform=macOS' -enableCodeCoverage YES test
```

## Test Types
**Unit Tests:**
- Primary test type; all 21 test files are unit tests
- State machine transitions: idle → running → paused → resumed → completed (see `Oak/Tests/OakTests/US003Tests.swift`)
- Computed property verification: `displayTime`, `canStart`, `canPause`, `progressPercentage`
- Persistence round-trips: write to UserDefaults → create new instance → verify loaded values
- Model/enum validation: preset durations, case counts
- `completeSessionForTesting()` method exposed on ViewModel for test-only session completion

**Integration Tests:**
- Window behavior tests act as integration tests: `NotchWindowControllerTests` creates real `NotchWindowController` with real `NotchWindow` (see `Oak/Tests/OakTests/NotchWindowControllerTests.swift`)
- Notification observer tests: post `NSApplication.didChangeScreenParametersNotification` and verify response
- Published property observation with Combine: `presetSettings.$alwaysOnTop.dropFirst().sink { ... }` (see `Oak/Tests/OakTests/AlwaysOnTopTests.swift`)

**E2E Tests:**
- Not used (no UI testing target or XCUITest)

## Common Patterns
**Async Testing:**
```swift
// Expectation-based async (Oak/Tests/OakTests/UpdateCheckerTests.swift)
func testHandles403RateLimitResponse() async {
    let expectation = self.expectation(description: "Update check completes")
    Task {
        checker.checkForUpdatesOnLaunch()
        try? await Task.sleep(nanoseconds: 100000000)
        expectation.fulfill()
    }
    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
}

// Combine publisher observation (Oak/Tests/OakTests/AlwaysOnTopTests.swift)
func testAlwaysOnTopIsPublished() async {
    let expectation = expectation(description: "Published value changed")
    var receivedValue: Bool?
    let cancellable = presetSettings.$alwaysOnTop
        .dropFirst()
        .sink { value in
            receivedValue = value
            expectation.fulfill()
        }
    presetSettings.setAlwaysOnTop(true)
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertEqual(receivedValue, true)
    cancellable.cancel()
}

// RunLoop polling for window animations (Oak/Tests/OakTests/NotchWindowControllerTests.swift)
let endTime = Date().addingTimeInterval(1.0)
while Date() < endTime {
    if window?.level == .statusBar { break }
    RunLoop.main.run(until: Date().addingTimeInterval(0.02))
}
```
**Error Testing:**
```swift
// XCTSkip for environment-dependent tests (Oak/Tests/OakTests/NotchWindowControllerTests.swift)
override func setUp() async throws {
    guard NSScreen.main != nil else {
        throw XCTSkip("No display available for window tests")
    }
}

// XCTSkip for system prompt avoidance (Oak/Tests/OakTests/NotificationTests.swift)
func testNotificationServiceAuthorizationRequest() throws {
    throw XCTSkip("Skipping authorization request test to avoid system notification prompts")
}

// XCTAssertNoThrow for crash-safety verification (Oak/Tests/OakTests/NotchWindowControllerTests+WindowBehavior.swift)
XCTAssertNoThrow(windowController.cleanup(), "Cleanup should not throw")
XCTAssertNoThrow(
    NotificationCenter.default.post(
        name: NSApplication.didChangeScreenParametersNotification, object: NSApp
    ),
    "Posting notification after cleanup should not crash"
)

// Guard-based test failures (Oak/Tests/OakTests/NotchWindowControllerTests.swift)
guard let userDefaults = UserDefaults(suiteName: suiteName) else {
    throw NSError(domain: "US001Tests", code: 1)
}
```
**State Transition Testing:**
```swift
// Full lifecycle: idle → running → paused → resumed → completed (Oak/Tests/OakTests/US003Tests.swift)
func testUIIndicatesPausedState() {
    viewModel.startSession()
    XCTAssertFalse(viewModel.isPaused)
    XCTAssertTrue(viewModel.isRunning)

    viewModel.pauseSession()
    XCTAssertTrue(viewModel.isPaused)
    XCTAssertFalse(viewModel.isRunning)

    viewModel.resumeSession()
    XCTAssertFalse(viewModel.isPaused)
    XCTAssertTrue(viewModel.isRunning)
}

// Round counter lifecycle (Oak/Tests/OakTests/LongBreakTests.swift)
func testRoundCounterResetsAfterLongBreak() {
    completeFourWorkSessions()
    XCTAssertEqual(viewModel.completedRounds, 4)
    viewModel.startNextSession()
    viewModel.completeSessionForTesting()
    XCTAssertEqual(viewModel.completedRounds, 0)
}
```

## Test Naming Convention
- Method names describe behavior: `testPrimaryActionStarts25MinuteSession`, `testCanPauseActiveSession`, `testAlwaysOnTopDefaultsToFalse`
- Pattern: `test[Subject][Behavior]` or `test[Subject][Condition][Expectation]`
- Assertion messages describe expected behavior: `XCTAssertEqual(viewModel.canStart, true, "Should be able to pause active session")`

---
*Testing analysis: 2026-02-15*
