# AGENTS.md - Agent Guidelines for Oak

## Project Overview

Oak is a lightweight macOS focus companion app with notch-based Pomodoro-style focus sessions and ambient audio.

**Stack**: Swift 5.9+, SwiftUI, AVFoundation | **Platform**: macOS 13+ (Apple Silicon)
**Architecture**: MVVM with `@MainActor` for UI layer | **Config**: XcodeGen (`project.yml`)

---

## Build/Test Commands

Use `just` (requires [just](https://github.com/casey/just)):

```bash
just                        # Show available commands
just build                  # Build the project
just build-release         # Build release version
just dev                   # Regenerate project, build, and run app
just open                  # Open project in Xcode
just test                   # Run all tests
just test-verbose          # Run tests with verbose output
just test-class Tests      # Run specific test class
just test-method Tests methodName  # Run specific test method
just check                 # Check compilation errors
just check-sounds          # Validate bundled ambient sound files
just clean                 # Clean build artifacts
just lint                  # Run SwiftLint
just lint-fix              # Auto-fix linting issues
just format                # Format with SwiftFormat
just format-check          # Check formatting
just check-style           # Run lint and format checks
```

**Single test**: `just test-method FocusSessionViewModelTests "testStartSession"`
**Manual build**: `xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' build`
**Regenerate project**: `cd Oak && xcodegen generate`

---

## Code Style

### Formatting

- **Indent**: 4 spaces | **Line length**: 120 chars (warning), 150 chars (error)
- **Trailing newline**: Required | **Documentation**: Use `///` for public APIs

### Imports

- **Order**: Foundation → Combine → SwiftUI/AppKit → Apple frameworks → @testable import Oak
- **Import grouping**: `testable-bottom` (testable imports go last)
- No blank lines between imports, one blank line between type declarations

### Naming

- **Types**: PascalCase (`FocusSessionViewModel`) | **Functions/Variables**: camelCase
- **Constants**: lowerCamelCase (instance), PascalCase (static) | **Enums**: PascalCase with lowerCamelCase cases
- **Booleans**: Start with is/has/should (`isWorkSession`, `canStart`)
- **Access control**: Explicit `internal` keyword

### SwiftUI Conventions

- Use `@MainActor` on all ViewModels and UI-related classes
- **CRITICAL**: Keep `@MainActor` on all `ObservableObject` classes with `@Published` properties
- Prefer `private` for internal state, `private(set)` for read-only published
- Extract views as `private var someView: some View` computed properties

### State Management

- Use enums with associated values for finite state machines
- Use `if case` for state checks, keep transitions explicit
- Use computed properties for derived state (`displayTime`, `canPause`)

### Error Handling

- Use `Result` type for async operations | Prefer early returns/guard clauses
- **Logging**: `os.log` in production, `print()` acceptable in dev/debug

### Memory & Concurrency

- Use `[weak self]` in escaping closures | Always `invalidate()` timers in `cleanup()` or `deinit`
- Wrap timer callbacks with `Task { @MainActor in self?.tick() }`

### View Update Safety

- **Never publish changes from within view updates**: Wrap in `DispatchQueue.main.async`:

```swift
// ❌ Wrong - causes "Publishing changes from within view updates"
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ Correct - defers to next run loop
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

### Persistence

```swift
guard let data = userDefaults.data(forKey: key),
      let records = try? JSONDecoder().decode([T].self, from: data) else { return [] }
```

### Linter (SwiftLint) & Formatter (SwiftFormat)

- **SwiftLint opt-in**: explicit_init, trailing_closure, first_where, toggle_bool, modifier_order, empty_count, explicit_top_level_acl
- **Custom rule**: `no_print_statements` warns against `print()` in production
- **SwiftFormat**: indent 4, maxwidth 120, wraparguments before-first, stripunusedargs always, self remove

---

## File Organization

```
Oak/
├── Oak/
│   ├── Models/              # Data models, enums, protocols
│   ├── Views/               # SwiftUI Views
│   ├── ViewModels/          # ObservableObject classes
│   ├── Services/            # Business logic, audio, persistence
│   ├── Resources/           # Assets, sounds, config files
│   └── OakApp.swift        # App entry point
├── Oak.xcodeproj/
├── project.yml              # XcodeGen config
└── Tests/                   # Unit tests
```

---

## Testing Guidelines

- Test files: `Tests` suffix, mirror source structure | Use XCTest with `@MainActor` on test classes
- Test methods: `async throws` | Use `setUp()` and `tearDown()` for fixtures
- **Isolate UserDefaults** with unique suite names per test class
- Test state transitions: idle → running → paused → idle | Test computed properties and edge cases

---

## MVP Constraints (Do Not Violate)

- Default presets: `25/5` and `50/10` (configurable in settings)
- Notch-only UI (no menu bar fallback yet) | No global keyboard shortcuts
- Auto-start next interval defaults to OFF | Built-in audio tracks only
- Local persistence only (no cloud sync)

---

## Commit Style

`type(scope): brief description` | **Types**: feat, fix, refactor, test, docs, chore | **Scope**: timer, audio, ui, persistence

---

## What Agents Should Know

- Run `just build` after changes to verify compilation
- Run `just check-style` before submitting
- Run relevant tests: `just test-method ViewModelTests "testName"`
- Verify changes don't break notch-only display constraints
- Use `os.log` for production logging, `print()` for debugging
- Check PRD at `tasks/prd-macos-focus-companion-app.md` and ADRs in `doc/adr/`
