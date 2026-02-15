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
just test-method Class Method  # Run specific test
just check                 # Check compilation
just check-sounds          # Validate ambient sounds
just clean                 # Clean artifacts
just lint                  # Run SwiftLint
just lint-fix              # Auto-fix issues
just format                # Format with SwiftFormat
just format-check          # Check formatting
just check-style           # Run all checks
```

**Single test**: `just test-method FocusSessionViewModelTests testStartSession`
**Manual build**: `xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' build`
**Regenerate**: `cd Oak && xcodegen generate`

## Code Style

### Formatting

- **Indent**: 4 spaces | **Line length**: 120 (warn), 150 (error)
- **Trailing newline**: Required | **Docs**: Use `///` for public APIs

### Imports

- **Order**: Foundation → Combine → SwiftUI/AppKit → Apple → @testable import Oak
- **Grouping**: `testable-bottom` (testable last)
- No blank lines between imports, one blank line between types

### Naming

- **Types**: PascalCase | **Functions/Vars**: camelCase
- **Constants**: lowerCamelCase (instance), PascalCase (static)
- **Booleans**: is/has/should prefix (`isWorkSession`, `canStart`)
- **Access**: Explicit `internal` keyword

### SwiftUI

- Use `@MainActor` on all ViewModels and UI classes
- **CRITICAL**: Keep `@MainActor` on all `ObservableObject` with `@Published`
- Prefer `private` for state, `private(set)` for read-only published
- Extract views as `private var someView: some View` properties
- Use `any Protocol` syntax for type-erasure (`let service: any Notifying`)

### State Management

- Enums with associated values for FSMs
- Use `if case` for state checks
- Computed properties for derived state (`displayTime`, `canPause`)

### Error Handling

- Use `Result` for async | Prefer guard/early returns
- **Logging**: `os.log` (production), `print()` (debug)

### Memory & Concurrency

- `[weak self]` in escaping closures
- Always `invalidate()` timers in `deinit`
- Wrap timer callbacks: `Task { @MainActor in self?.tick() }`

### View Update Safety

**Never publish changes from within view updates**:

```swift
// ❌ Wrong
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ Correct
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

### Persistence

```swift
guard let data = userDefaults.data(forKey: key),
      let records = try? JSONDecoder().decode([T].self, from: data)
else { return [] }
```

### Lint/Format

- **SwiftLint**: explicit_init, trailing_closure, first_where, toggle_bool, modifier_order, empty_count, explicit_top_level_acl
- **Custom rule**: `no_print_statements` warns on `print()`
- **SwiftFormat**: indent 4, maxwidth 120, wraparguments before-first, stripunusedargs always, self remove

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
- Methods: `async throws` | Use `setUp/tearDown`
- **Isolate UserDefaults** with unique suite names
- Test state transitions: idle → running → paused → idle
- Use protocol-based mocks for DI

## MVP Constraints (Do Not Violate)

- Presets: `25/5` and `50/10` (configurable)
- Notch-only UI | No menu bar fallback
- No global keyboard shortcuts
- Auto-start next: OFF by default
- Built-in audio only | No cloud sync

## Auto-Update

Uses [Sparkle](https://sparkle-project.org/):

- Framework: Sparkle 2.6.4+ via SPM
- Feed: `https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml`
- Components: `SparkleUpdater.swift`, `appcast.xml`
- `UpdateChecker` is deprecated

## Commit Style

`type(scope): description`

- **Types**: feat, fix, refactor, test, docs, chore
- **Scopes**: timer, audio, ui, persistence

## Agent Checklist

- [ ] Run `just build` after changes
- [ ] Run `just check-style` before submitting
- [ ] Run relevant tests: `just test-method Class Method`
- [ ] Verify notch-only constraints
- [ ] Use `os.log` (prod), `print()` (debug)
- [ ] Check PRD at `tasks/prd-macos-focus-companion-app.md`
- [ ] Use protocol-based DI for testability
