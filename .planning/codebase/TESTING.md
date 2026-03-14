# Testing Patterns

**Analysis Date:** 2026-03-14

## Test Framework

**Runner:**
- XCTest (built into Xcode)
- Config: `project.yml` test target configuration

**Assertion Library:**
- XCTest assertions (XCTAssertTrue, XCTAssertEqual, etc.)

**Run Commands:**
```bash
just test                          # Run all tests
just test-class Name               # Run specific test class
just test-method Class Method      # Run single test
just test-verbose                  # Run with verbose output
```

## Test File Organization

**Location:**
- Separate directory: `Oak/Tests/OakTests/`
- Mirrors source structure but not 1:1

**Naming:**
- Source file name + "Tests" suffix: `NotchCompanionView.swift` → `NotchCompanionViewTests.swift`
- User story tests: `US001Tests.swift`, `US002Tests.swift`, etc.

**Structure:**
```
Oak/Tests/OakTests/
├── NotchCompanionViewTests.swift           # Main UI tests
├── NotchCompanionViewTests+Layout.swift    # Layout-specific tests
├── NotchCompanionViewTests+SessionState.swift # State tests
├── FocusSessionViewModelTests.swift        # View model tests (not visible - may be split)
├── AudioManagerTests.swift                 # Service tests
├── SmokeTests.swift                        # Smoke tests
└── US*Tests.swift                          # User story tests
```

## Test Structure

**Suite Organization:**
```swift
@MainActor
final class NotchCompanionViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Setup code
    }

    override func tearDown() {
        // Cleanup code
        super.tearDown()
    }

    func testExample() async throws {
        // Given
        // When
        // Then
    }
}
```

**Patterns:**
- **Setup:** Isolate UserDefaults with unique suite names
- **Teardown:** Always cleanup UserDefaults and call viewModel.cleanup()
- **Assertion:** XCTest assertions with descriptive messages

**UserDefaults Isolation:**
```swift
let suiteName = "OakTests.ClassName.\(UUID().uuidString)"
let userDefaults = UserDefaults(suiteName: suiteName)

// In tearDown:
viewModel.cleanup()
UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
```

## Mocking

**Framework:** Protocol-based manual mocking

**Patterns:**
```swift
// Protocol for DI
protocol SessionCompletionNotifying {
    func notifySessionComplete()
}

// Mock for testing
class MockNotificationService: SessionCompletionNotifying {
    var didNotify = false
    func notifySessionComplete() { didNotify = true }
}

// Usage in tests
let mockService = MockNotificationService()
let viewModel = FocusSessionViewModel(notificationService: mockService)
```

**What to Mock:**
- External services (Audio, Notifications)
- System dependencies (UserDefaults)
- Time-based operations (Timers)

**What NOT to Mock:**
- ViewModels (test directly)
- Models (test directly)
- Simple View logic

## Fixtures and Factories

**Test Data:**
```swift
// Create test data inline
let testTrack = AudioTrack(name: "Test", filename: "test.mp3")
```

**Location:**
- No separate fixtures directory
- Test data created inline in test methods

## Coverage

**Requirements:** No enforced coverage target

**View Coverage:**
```bash
# Use Xcode's built-in coverage
# Product > Test > Edit Scheme > Code Coverage
```

## Test Types

**Unit Tests:**
- Scope: Individual ViewModels, Services, Models
- Approach: Test state transitions and business logic
- Framework: XCTest

**Integration Tests:**
- Scope: View + ViewModel interactions
- Approach: User story tests (US001, US002, etc.)
- Framework: XCTest

**E2E Tests:**
- Framework: Smoke tests
- Approach: Basic workflow validation
- File: `SmokeTests.swift`

## Common Patterns

**Async Testing:**
```swift
func testAsyncOperation() async throws {
    // Given
    let viewModel = FocusSessionViewModel()

    // When
    await viewModel.startSession()

    // Then
    XCTAssertEqual(viewModel.state, .running)
}
```

**Error Testing:**
```swift
func testErrorHandling() {
    // Given
    let invalidInput = -1

    // When/Then
    XCTAssertThrowsError(try subject.validate(invalidInput))
}
```

**State Transition Testing:**
```swift
func testSessionStateTransitions() async throws {
    // Idle → Running
    await viewModel.startSession()
    XCTAssertEqual(viewModel.state, .running)

    // Running → Paused
    await viewModel.pauseSession()
    XCTAssertEqual(viewModel.state, .paused)

    // Paused → Idle
    await viewModel.cancelSession()
    XCTAssertEqual(viewModel.state, .idle)
}
```

---

*Testing analysis: 2026-03-14*
