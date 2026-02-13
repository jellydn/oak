# Coding Conventions

**Analysis Date:** 2026-02-13

## Naming Patterns

**Files:**
- PascalCase for types matching the type name (`FocusSessionViewModel.swift` → `FocusSessionViewModel`)
- `Tests` suffix for test files matching source structure (`OakTests/`)
- Descriptive names that reflect contents (`PresetSettingsStore.swift`, `AudioManager.swift`)

**Functions:**
- camelCase for all functions (`startSession()`, `setWorkMinutes()`)
- Verb-first names for actions (`play()`, `stop()`, `requestAuthorization()`)
- Computed properties use camelCase (`displayTime`, `canStart`, `isRunning`)
- Bool properties prefixed with `is`, `has`, `should`, `can` (`isRunning`, `canPause`, `hasSoundPermission`)

**Variables:**
- camelCase for local variables and parameters (`remainingSeconds`, `isWorkSession`)
- Descriptive names over abbreviations (`preferredDisplayID` not `dispID`)
- `_` prefix for @StateObject wrappers in views when external binding is needed

**Types:**
- PascalCase for all types (`SessionState`, `AudioTrack`, `Preset`)
- Enums use PascalCase with lowerCamelCase cases (`DisplayTarget.mainDisplay`, `SessionState.idle`)
- Protocols use -ing suffix for capabilities (`SessionCompletionNotifying`, `UpdateChecking`)
- `internal` access control by default, explicit `public` for exposed APIs

## Code Style

**Formatting:**
- **Tool:** SwiftFormat + SwiftLint
- **Indentation:** 4 spaces
- **Line length:** 120 chars (warning), 150 chars (error)
- **Trailing newline:** Required
- **Single-line statements:** Single `if`/`guard` without braces allowed for early returns

**Linting:**
- **Tool:** SwiftLint
- **Key rules:**
  - `explicit_init` - Require explicit `self.init()` calls
  - `explicit_top_level_acl` - Require explicit access control at top level
  - `trailing_closure` - Prefer trailing closure syntax
  - `empty_count` - Use `.isEmpty` instead of `.count == 0`
  - `first_where` - Use `.first(where:)` instead of `.filter{}.first`
  - `toggle_bool` - Use `toggle()` for bools
  - `modifier_order` - Enforce SwiftUI modifier order
  - `custom: no_print_statements` - Warn against `print()` in production

## Import Organization

**Order:**
1. AppKit/Foundation (system frameworks)
2. Combine/SwiftUI (Apple frameworks)
3. Third-party (if any)
4. `@testable import Oak` (test imports last)

**Examples:**
```swift
import AppKit
import Combine
import Foundation
import os
import SwiftUI
@testable import Oak
```

**No blank lines** between import groups of same level, one blank line between type declarations.

**Path Aliases:** None used - direct module imports only.

## Error Handling

**Patterns:**
- `Result` type for async operations where failure is expected
- `try?` for optional failure handling (seen in persistence)
- `guard let` for early returns on unavailable data
- Early returns with `guard` statements over nested conditions
- `XCTSkip` for tests that should not run in CI (notification permission tests)

**UserDefaults persistence:**
```swift
guard let data = userDefaults.data(forKey: key),
      let records = try? JSONDecoder().decode([T].self, from: data) else { return [] }
```

**Optional error logging:**
```swift
if let error {
    Task { @MainActor in
        self.logger.error("Failed: \(error.localizedDescription)")
    }
}
```

## Logging

**Framework:** `os.log` (Logger) for production, `print()` acceptable in dev/debug tests

**Patterns:**
- `Logger(subsystem: "com.productsway.oak.app", category: "ClassName")`
- Use `privacy: .public` for non-sensitive log data
- Error logging uses `logger.error()`, debug uses `logger.debug()`
- Custom SwiftLint rule warns against `print()` in production code

**Example:**
```swift
private let logger = Logger(subsystem: "com.productsway.oak.app", category: "AudioManager")
logger.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
```

## Comments

**When to Comment:**
- `///` for public API documentation
- `// MARK: -` for code organization (section dividers)
- Inline comments for non-obvious logic (noise generation algorithms)
- Property comments for shared constants (`NotchLayout.swift`)

**Documentation:**
- Triple-slash `///` for public types and properties
- Explanation of "why" not "what"
- Parameter descriptions where intent isn't obvious

**Example:**
```swift
/// Shared layout constants for notch companion UI.
/// These values define window dimensions and ensure consistency
/// between NotchCompanionView and NotchWindowController.
internal enum NotchLayout { ... }
```

## Function Design

**Size:**
- Target under 50 lines (warning at 50, error at 100 per SwiftLint)
- Extract complex view modifiers to `private var someView: some View`
- Extract logic to private helper methods

**Parameters:**
- Prefer parameter labels that read naturally at call site
- Default values for optional parameters (`preset: Preset? = nil`)
- Closure parameters use trailing closure syntax

**Return Values:**
- Computed properties for derived state
- `-> Bool` for validation/predicates
- `-> some View` for SwiftUI view builders
- `async throws` for operations that can fail

## Module Design

**Exports:** All types use `internal` by default, `public` where needed

**Barrel Files:** Not used - direct imports

**Access Control:**
- Explicit `internal` on top-level declarations (SwiftLint rule)
- `private` for implementation details
- `private(set)` for read-only published properties
- `fileprivate` avoided, prefer `private`

**Shared Instances:**
- Singleton pattern with `static let shared = ClassName()` for services
- Shared instances: `PresetSettingsStore.shared`, `NotificationService.shared`

**Dependency Injection:**
- Constructor injection for testability
```swift
init(presetSettings: PresetSettingsStore,
     progressManager: ProgressManager? = nil,
     notificationService: (any SessionCompletionNotifying)? = nil)
```

## SwiftUI Conventions

**State Management:**
- `@MainActor` on all ViewModels and UI-related classes
- `@Published` for observable properties
- `@StateObject` for view-owned ViewModel instances
- `@ObservedObject` for passed-in dependencies
- `private(set)` for externally read-only published properties

**View Organization:**
- Extract reusable views as `private var someView: some View`
- Use `#available` checks for version-specific APIs
- Defer view updates to next run loop to prevent "Publishing changes from within view updates"
- `onChange` handlers wrap state updates in `DispatchQueue.main.async`

**Protocols for Testing:**
- Protocol-based dependencies for mockable services
- `any SessionCompletionNotifying` protocol for notification abstraction
- `any SessionCompletionSoundPlaying` for sound abstraction

## Memory & Concurrency

**Patterns:**
- `[weak self]` in escaping closures to prevent retain cycles
- Timer callbacks wrapped in `Task { @MainActor in self?.tick() }`
- Always `invalidate()` timers in `cleanup()` or `deinit`
- `@MainActor` for UI-related classes
- `deinit` cleanup with `Task { @MainActor in ... }` for async cleanup

**Example:**
```swift
timer?.invalidate()
timer = nil
presetSettingsCancellable?.cancel()
```

---

*Convention analysis: 2026-02-13*
