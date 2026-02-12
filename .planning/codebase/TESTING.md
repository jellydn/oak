# Testing Patterns

**Analysis Date:** 2026-02-13

## Test Framework
**Runner:**
- XCTest (built-in Apple framework)
- Config: `Oak/project.yml` (XcodeGen) defines `OakTests` bundle target
- Note: `NotchWindowControllerTests.swift` is excluded from the test target in `project.yml` (requires windowing environment)

**Assertion Library:**
- XCTest built-in assertions (`XCTAssert*` family)

**Run Commands:**
```bash
just test                              # Run all tests
just test-verbose                      # Run tests with verbose output
just test-class US001Tests             # Run specific test class
just test-method US001Tests testPrimaryActionStarts25MinuteSession  # Run specific test method
```

## Test File Organization
**Location:**
- Separate `Tests/` directory (not co-located with source)

**Naming:**
- User story tests: `US00XTests.swift` (US001–US006) mapping to user stories
- Feature tests: `NotchWindowControllerTests.swift` (named after the class under test + `Tests`)
- Smoke tests: `SmokeTests.swift` for basic sanity checks

**Structure:**
```
Oak/
├── Oak/                    # Source code
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   └── Services/
└── Tests/
    └── OakTests/
        ├── SmokeTests.swift
        ├── US001Tests.swift
        ├── US002Tests.swift
        ├── US003Tests.swift
        ├── US004Tests.swift
        ├── US005Tests.swift
        ├── US006Tests.swift
        └── NotchWindowControllerTests.swift  (excluded from CI)
```

## Test Structure
**Suite Organization:**
```swift
import XCTest
import SwiftUI
@testable import Oak

@MainActor
final class US001Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!

    override func setUp() async throws {
        viewModel = FocusSessionViewModel()
    }

    override func tearDown() async throws {
        viewModel.cleanup()
    }

    func testPrimaryActionStarts25MinuteSession() {
        XCTAssertEqual(viewModel.canStart, true)
        viewModel.startSession()
        XCTAssertEqual(viewModel.isRunning, true)
    }
}
```
**Patterns:**
- **Setup**: `override func setUp() async throws` — creates fresh ViewModel or Manager instance
- **Teardown**: `override func tearDown() async throws` — calls `cleanup()` or removes UserDefaults keys
- **Assertions**: Descriptive failure messages on most assertions: `XCTAssertEqual(presets.count, 2, "MVP should support exactly two presets")`
- All test classes marked `@MainActor` (matching ViewModel threading model)
- All test classes are `final`

## Mocking
**Framework:** None (no mocking library)
**Patterns:**
```swift
// Protocol-based dependency injection (UpdateChecker)
protocol UpdateChecking {
    func checkForUpdatesOnLaunch()
}

// In AppDelegate:
var updateChecker: UpdateChecking = UpdateChecker()

// UserDefaults cleanup for isolation:
override func setUp() async throws {
    UserDefaults.standard.removeObject(forKey: "progressHistory")
    progressManager = ProgressManager()
}
```
**What to Mock:**
- External dependencies via protocols (`UpdateChecking`)
- State is reset via `cleanup()` and UserDefaults removal between tests

**What NOT to Mock:**
- ViewModels are tested directly (real instances)
- AudioManager is tested with real AVFoundation (functional tests)
- Models and enums tested as-is (no mocking needed)

## Fixtures and Factories
**Test Data:**
```swift
// Inline test data — no separate fixture files
viewModel.selectedPreset = .short
viewModel.startSession()

// Persistence tests use real UserDefaults, cleaned per-test:
UserDefaults.standard.removeObject(forKey: "progressHistory")
progressManager = ProgressManager()
progressManager.recordSessionCompletion(durationMinutes: 25)
```
**Location:**
- No dedicated fixtures directory; all test data is inline within test methods

## Coverage
**Requirements:** None enforced (no coverage targets configured)
**View Coverage:**
```bash
# Not configured; add -enableCodeCoverage YES to xcodebuild for ad-hoc reports
just test  # does not generate coverage by default
```

## Test Types
**Unit Tests:**
- ViewModel state transitions (idle → running → paused → completed → idle)
- Model property validation (preset durations, display names)
- Computed property correctness (`displayTime`, `canStart`, `canPause`, `currentSessionType`)
- Persistence round-trip (UserDefaults save/load via ProgressManager)
- Volume clamping and audio track selection

**Integration Tests:**
- Window controller creation and frame management (`NotchWindowControllerTests`)
- View instantiation with real ViewModels (structural tests)
- Data persistence across manager instances (simulating app relaunch)

**E2E Tests:**
- Not used (no UI testing target configured)

## Common Patterns
**Async Testing:**
```swift
// Async setUp/tearDown for @MainActor compatibility:
override func setUp() async throws {
    viewModel = FocusSessionViewModel()
}

// XCTestExpectation for async frame updates:
private func waitForFrameUpdate() {
    let expectation = expectation(description: "Wait for window resize")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
}
```
**Error Testing:**
```swift
// Guard-based validation (no throwing; test that invalid operations are no-ops):
func testCannotSwitchPresetAfterSessionStart() {
    viewModel.startSession()
    viewModel.selectPreset(.long)
    XCTAssertEqual(viewModel.selectedPreset, .short) // unchanged
}

// Cleanup safety:
XCTAssertNoThrow(windowController.cleanup(), "Cleanup should not throw")
```
**State Machine Testing:**
```swift
// Verify state transitions through full lifecycle:
func testUIIndicatesPausedState() {
    viewModel.startSession()
    XCTAssertTrue(viewModel.isRunning)
    XCTAssertFalse(viewModel.isPaused)

    viewModel.pauseSession()
    XCTAssertTrue(viewModel.isPaused)
    XCTAssertFalse(viewModel.isRunning)

    viewModel.resumeSession()
    XCTAssertFalse(viewModel.isPaused)
    XCTAssertTrue(viewModel.isRunning)
}
```
**Performance Testing:**
```swift
// Timing assertions for responsiveness:
func testSessionStateChangesWithin500ms() {
    let startTime = Date()
    viewModel.startSession()
    let elapsed = Date().timeIntervalSince(startTime) * 1000
    XCTAssertLessThan(elapsed, 500, "Session state should change within 500ms")
}
```

---
*Testing analysis: 2026-02-13*
