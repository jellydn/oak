# AGENTS.md - Agent Guidelines for Oak

## Project Overview

Oak is a lightweight macOS focus companion app with notch-based Pomodoro-style focus sessions and ambient audio.

**Stack**: Swift 5.9+, SwiftUI, AVFoundation | **Platform**: macOS 13+ (Apple Silicon)
**Architecture**: MVVM with `@MainActor` for UI layer

---

## Build/Test Commands

Use `just` for common tasks (requires [just](https://github.com/casey/just)):

```bash
just                        # Show available commands
just build                  # Build the project
just build-release         # Build release version
just test                   # Run all tests
just test-verbose          # Run tests with verbose output
just test-class Tests      # Run specific test class
just test-method Tests methodName  # Run specific test method
just check                 # Check compilation errors
just clean && just open    # Clean and open in Xcode
```

**Single test command examples:**

```bash
just test-method FocusSessionViewModelTests "testStartSession"
just test-method FocusSessionViewModelTests "testPauseSession"
just test-method AudioServiceTests "testPlayAndStop"
```

**Manual xcodebuild:**

```bash
# Build
cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' build

# Run specific test
cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' \
  -only-testing:OakTests/FocusSessionViewModelTests/testStartSession test
```

**Regenerate Xcode project:** `cd Oak && xcodegen generate`

---

## Code Style Guidelines

### Imports & Formatting

- Group: Foundation → SwiftUI/AppKit → Apple frameworks → project imports
- No blank lines between imports, one blank line between type declarations
- 4 spaces indentation (no tabs), 120 char line limit (soft)
- Trailing newline at end of files

### Types & Naming

- **Types**: PascalCase (`FocusSessionViewModel`, `SessionState`)
- **Functions/Variables**: camelCase (`startSession`, `remainingSeconds`)
- **Constants**: lowerCamelCase (instance), PascalCase (static)
- **Enums**: PascalCase with lowerCamelCase cases
- **Booleans**: Start with is/has/should (`isWorkSession`, `canStart`)

### SwiftUI Conventions

- Use `@MainActor` on all ViewModels and UI-related classes
- ViewModels: `@MainActor class X: ObservableObject` with `@Published`
- Prefer `private` for internal state, `private(set)` for read-only published
- Use computed properties for derived state (`displayTime`, `canPause`)
- Extract views as `private var some View` computed properties

### State Management

- Use enums with associated values for finite state machines
- Use pattern matching with `if case` for state checks
- Keep state transitions explicit and side-effect-free

### Error Handling

- Use Swift's `Result` type for async operations that can fail
- Prefer early returns/guard clauses over nested if-else
- **Logging**: Use `os.log` in production; `print()` acceptable in dev/debug

### Memory & Concurrency

- Use `[weak self]` in escaping closures (timers, async callbacks)
- Always `invalidate()` timers in `cleanup()` or `deinit`
- Wrap timer callbacks with `Task { @MainActor in self?.tick() }`

### Persistence

```swift
guard let data = userDefaults.data(forKey: key),
      let records = try? JSONDecoder().decode([T].self, from: data) else { return [] }
```

---

## File Organization

```
Oak/
├── Oak/
│   ├── Models/              # Data models, enums, protocols
│   ├── Views/               # SwiftUI Views
│   ├── ViewModels/          # ObservableObject classes
│   ├── Services/            # Business logic, audio, persistence
│   ├── Resources/            # Assets, sounds, config files
│   └── OakApp.swift         # App entry point
├── Oak.xcodeproj/
├── project.yml              # XcodeGen config
└── Tests/                   # Unit tests
```

---

## Testing Guidelines

- Test files mirror source structure with `Tests` suffix
- Use XCTest framework
- Test state transitions: idle → running → paused → idle
- Test computed properties and edge cases (0 values, boundaries)

---

## MVP Constraints (Do Not Violate)

- Fixed presets only: `25/5` and `50/10` (no custom durations)
- Notch-only UI (no menu bar fallback yet)
- No global keyboard shortcuts
- Auto-start next interval defaults to OFF
- Built-in audio tracks only (no user imports)
- Local persistence only (no cloud sync)

---

## Performance Requirements

- Launch time < 1 second, idle CPU < 3% in release
- Timer accuracy under backgrounding and sleep/wake

---

## Commit Message Style

`type(scope): brief description`

- **Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- **Scope**: `timer`, `audio`, `ui`, `persistence`, etc.

---

## What Agents Should Know

- Always run `just build` after making changes to verify compilation
- Run relevant tests before submitting changes: `just test-method ViewModelTests "testName"`
- Verify changes don't break existing UI constraints (notch-only display)
- Use `os.log` for logging in production, `print()` for debugging
- When in doubt, check the PRD at `tasks/prd-macos-focus-companion-app.md`

---

## References

- PRD: `tasks/prd-macos-focus-companion-app.md`
- ADRs: `doc/adr/`
- Use `///` for public API documentation
