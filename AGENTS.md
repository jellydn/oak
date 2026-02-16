# AGENTS.md - Agent Guidelines for Oak

## Project Overview

Oak is a lightweight macOS focus companion app with notch-based Pomodoro-style focus sessions and ambient audio.

**Stack**: Swift 5.9+, SwiftUI, AVFoundation | **Platform**: macOS 13+ (Apple Silicon)
**Architecture**: MVVM with `@MainActor` | **Config**: XcodeGen (`project.yml`)

## Build/Test Commands

Use `just` ([install](https://github.com/casey/just)):

```bash
just                       # Show commands
just build                 # Build project
just build-release         # Build release
just dev                   # Regenerate, build, run
just open                  # Open in Xcode
just test                  # Run all tests
just test-class Name       # Run specific class
just test-method Class Method  # Run single test
just check                 # Check compilation
just clean                 # Clean artifacts
just lint                  # Run SwiftLint
just lint-fix              # Auto-fix issues
just format                # Format with SwiftFormat
just format-check          # Check formatting
just check-style           # Run all checks
just check-sounds          # Validate ambient sounds
```

**Examples**:

- Single test: `just test-method FocusSessionViewModelTests testStartSession`
- Manual build: `xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' build`
- Regenerate: `cd Oak && xcodegen generate`

## Code Style

### Formatting

- **Indent**: 4 spaces | **Line length**: 120 (warn), 150 (error)
- **Trailing newline**: Required | **Docs**: Use `///` for public APIs
- **File length**: Warn at 500 lines, error at 1000
- **Function body**: Warn at 50 lines, error at 100

### Imports

- **Order**: Foundation → Combine → SwiftUI/AppKit → Apple frameworks → @testable import Oak
- **Grouping**: `testable-bottom` (testable imports last)
- No blank lines between imports, one blank line between types
- Remove unused imports (analyzer rule enabled)

### Naming

- **Types**: PascalCase | **Functions/Vars**: camelCase
- **Constants**: lowerCamelCase (instance), PascalCase (static)
- **Booleans**: is/has/should prefix (`isWorkSession`, `canStart`)
- **Access**: Explicit `internal` keyword on all declarations
- **Protocols**: Use `*ing` suffix for capability protocols (`SessionCompletionNotifying`)

### SwiftUI & ViewModels

- Use `@MainActor` on all ViewModels and UI classes
- **CRITICAL**: Keep `@MainActor` on all `ObservableObject` with `@Published`
- Prefer `private` for state, `private(set)` for read-only published
- Extract views as `private var someView: some View` properties
- Use `any Protocol` syntax for type-erasure (`let service: any Notifying`)

### State Management

- Enums with associated values for FSMs (e.g., `SessionState`)
- Use `if case` for state checks
- Computed properties for derived state (`displayTime`, `canPause`)

### Error Handling & Logging

- Use `Result` for async operations
- Prefer guard/early returns over nested if statements
- **Logging**: `os.log` (production), `print()` (debug only)
- SwiftLint warns on `print()` statements via custom rule

### Memory & Concurrency

- `[weak self]` in all escaping closures
- Always `invalidate()` timers in `deinit`
- Wrap timer callbacks: `Task { @MainActor in self?.tick() }`
- Use `AnyCancellable` for Combine subscriptions

### View Update Safety (CRITICAL)

```swift
// ❌ Wrong - publishes from view update
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ Correct - async dispatch
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

### Lint/Format Rules

**SwiftLint opt-in rules**:

- `explicit_init`, `explicit_top_level_acl`, `trailing_closure`
- `first_where`, `toggle_bool`, `modifier_order`
- `vertical_parameter_alignment_on_call`, `closure_spacing`
- `empty_count`, `sorted_first_last`, `redundant_type_annotation`
- `yoda_condition`, `unneeded_parentheses_in_closure_argument`

**SwiftFormat**:

- indent 4, maxwidth 120, wraparguments before-first
- `self` removal, `isEmpty` enforcement
- Blank lines between scopes, sorted imports

## File Organization

```
Oak/
├── Oak/
│   ├── Models/         # Data models, enums, protocols
│   ├── Views/          # SwiftUI Views
│   ├── ViewModels/     # ObservableObject classes
│   ├── Services/       # Business logic, audio
│   ├── Extensions/     # Swift extensions
│   ├── Resources/      # Assets, sounds
│   └── OakApp.swift   # Entry point
├── Oak.xcodeproj/
├── project.yml         # XcodeGen config
└── Tests/              # Unit tests
```

## Testing

- Files: `Tests` suffix, mirror source structure
- Use XCTest with `@MainActor` on test classes
- **Isolate UserDefaults** with unique suite names:
  ```swift
  let suiteName = "OakTests.ClassName.\(UUID().uuidString)"
  let userDefaults = UserDefaults(suiteName: suiteName)
  ```
- Always clean up in `tearDown()`:
  ```swift
  viewModel.cleanup()
  UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
  ```
- Test state transitions: idle → running → paused → idle
- Use protocol-based mocks for DI

```swift
// Mock protocol for DI
class MockNotificationService: SessionCompletionNotifying {
    var didNotify = false
    func notifySessionComplete() { didNotify = true }
}
```

## MVP Constraints (Do Not Violate)

- Presets: `25/5` and `50/10` (configurable)
- Notch-only UI | No menu bar fallback
- No global keyboard shortcuts
- Auto-start next: OFF by default
- Built-in audio only | No cloud sync

## Commit Style

`type(scope): description` - Types: feat, fix, refactor, test, docs, chore

## Agent Checklist

- [ ] Run `just build` after changes
- [ ] Run `just check-style` before submitting
- [ ] Run relevant tests: `just test-method Class Method`
- [ ] Verify notch-only constraints
- [ ] Check PRD at `tasks/prd-macos-focus-companion-app.md`
