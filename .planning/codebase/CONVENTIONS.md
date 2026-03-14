# Coding Conventions

**Analysis Date:** 2026-03-14

## Naming Patterns

**Files:**
- PascalCase for all type definitions: `FocusSessionViewModel.swift`, `NotchCompanionView.swift`
- Extensions use `+` separator: `NotchCompanionView+StandardViews.swift`, `NSScreen+DisplayTarget.swift`
- Test files use `Tests` suffix: `NotchCompanionViewTests.swift`, `AudioManagerTests.swift`

**Functions:**
- camelCase for functions: `startSession()`, `updateProgress()`
- Boolean prefixes: `is*`, `has*`, `should*`: `isWorkSession`, `canStart`

**Variables:**
- camelCase: `sessionState`, `remainingTime`
- Private properties use underscore for disambiguation when needed

**Types:**
- PascalCase for types: `FocusSessionViewModel`, `SessionState`
- Protocols use *ing suffix for capabilities: `SessionCompletionNotifying`
- Enums with associated values for FSM: `SessionState.idle, .running, .paused`

## Code Style

**Formatting:**
- SwiftFormat for automatic formatting
- Key settings:
  - Indent: 4 spaces
  - Line length: 120 (warn), 150 (error)
  - Trailing newline: required
  - Function body: warn at 50 lines, error at 100
  - File length: warn at 500 lines, error at 1000

**Linting:**
- SwiftLint with custom rules
- Key rules:
  - `explicit_top_level_acl`: Require explicit `internal` keyword
  - `testable_bottom`: Testable imports last
  - `custom_print`: Warn on print() statements
  - `explicit_init`: Explicit self.init
  - `first_where`: Replace `first { }` with `first(where:)`
  - `modifier_order`: SwiftUI modifier order

## Import Organization

**Order:**
1. Foundation
2. Combine
3. SwiftUI/AppKit
4. Apple frameworks
5. @testable import Oak (test files only)

**No blank lines** between import groups

**Path Aliases:**
- None used (standard SPM module structure)

## Error Handling

**Patterns:**
- Guard clauses for early returns
- Result types for async operations
- Optional binding with `guard let` or `if let`
- fatalError only for unreachable states
- No force unwrapping in production code

## Logging

**Framework:** os.log (production), print() (debug)

**Patterns:**
- Use `os.log` for production logging
- `print()` allowed in debug but triggers SwiftLint warning
- No logging frameworks (use system logging)

## Comments

**When to Comment:**
- Public APIs use `///` documentation comments
- Complex business logic gets brief explanations
- Non-obvious decisions explained inline
- No TODO/FIXME in production (tracked separately)

**JSDoc/TSDoc:**
- `///` for public API documentation
- `//` for inline comments
- `MARK:` for code organization

## Function Design

**Size:** Prefer functions under 20 lines

**Parameters:**
- Parameter labels in Swift style
- Closures at end of parameter list
- @escaping for closure parameters

**Return Values:**
- Result<Success, Error> for failable operations
- Optional for nullable returns
- Tuple returns for multiple related values

## Module Design

**Exports:**
- No barrel files (standard SPM structure)
- Internal access by default
- Public for ViewModels and protocols used in tests

**Access Control:**
- Explicit `internal` keyword required (SwiftLint rule)
- `private` for implementation details
- `private(set)` for read-only published properties

## SwiftUI Specific

**@MainActor:**
- Required on all ViewModels
- Required on all ObservableObject with @Published
- Ensures UI updates on main thread

**State Management:**
- @Published for observable properties
- @State for local view state
- @Binding for child view communication
- @Environment for dependency injection

**View Updates:**
- Use async dispatch in onChange to avoid publishing from view update
```swift
// ❌ Wrong - publishes from view update
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ Correct - async dispatch
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

---

*Convention analysis: 2026-03-14*
