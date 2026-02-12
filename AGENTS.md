# AGENTS.md - Agent Guidelines for Oak

## Project Overview

Oak is a lightweight macOS focus companion app built with Swift and SwiftUI. It provides a notch-based UI for Pomodoro-style focus sessions with ambient audio support.

**Stack**: Swift 5.9+, SwiftUI, AVFoundation, Core Data (planned)  
**Platform**: macOS 13+ (Apple Silicon target)  
**Architecture**: MVVM with `@MainActor` for UI layer

---

## Build/Test Commands

Use `just` for common tasks (requires [just](https://github.com/casey/just)):

```bash
# Build the project
just build

# Run all tests
just test

# Run a specific test class
just test-class FocusSessionViewModelTests

# Run a specific test method
just test-method FocusSessionViewModelTests testStartSession

# Clean build artifacts
just clean

# Open in Xcode
just open

# Build release version
just build-release

# List all available commands
just
```

Alternative: Use `xcodebuild` directly:

```bash
cd Oak
xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' build
xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' test
```

**Note:** Project uses XcodeGen (project.yml). Regenerate Xcode project if needed:

```bash
cd Oak
xcodegen generate
```

---

## Code Style Guidelines

### Imports

- Group imports: Foundation first, then SwiftUI/AppKit, then Apple frameworks, then project imports
- No blank lines between import statements
- Use `@preconcurrency` imports only when necessary for Objective-C interop

### Formatting

- 4 spaces for indentation (no tabs)
- 120 character line limit (soft)
- Trailing newline at end of files
- One blank line between type declarations
- No trailing whitespace

### Types & Naming

- **Types**: PascalCase (`FocusSessionViewModel`, `SessionState`)
- **Functions/Variables**: camelCase (`startSession`, `remainingSeconds`)
- **Constants**: lowerCamelCase for instance, PascalCase for static
- **Enums**: PascalCase with lowerCamelCase cases
- **Associated values**: Descriptive labels (`remainingSeconds: Int`)
- **Boolean properties**: Start with is/has/should (`isWorkSession`, `canStart`)

### SwiftUI Conventions

- Use `@MainActor` on all ViewModels and UI-related classes
- ViewModels: `@MainActor class X: ObservableObject` with `@Published` properties
- Prefer `private` for internal state, `private(set)` for read-only published state
- Use computed properties for derived state (e.g., `displayTime`, `canPause`)

### State Management

- Use enums with associated values for finite state machines:
  ```swift
  enum SessionState {
      case idle
      case running(remainingSeconds: Int, isWorkSession: Bool)
      case paused(remainingSeconds: Int, isWorkSession: Bool)
  }
  ```
- Use pattern matching with `if case` for state checks
- Keep state transitions explicit and side-effect-free

### Error Handling

- Use Swift's `Result` type for async operations that can fail
- Prefer early returns/guard clauses over nested if-else
- Log errors with `os.log` (not print statements in production)
- For timer-based operations, handle edge cases (zero/negative values)

### Memory Management

- Use `[weak self]` in closures that escape (timers, async callbacks)
- Always `invalidate()` timers in `cleanup()` or `deinit`
- Avoid retain cycles in ViewModel -> Service dependencies

### File Organization

```
Oak/
├── Models/          # Data models, enums, protocols
├── Views/           # SwiftUI Views
├── ViewModels/      # ObservableObject classes
├── Services/        # Business logic, audio, persistence
└── Resources/       # Assets, sounds, config files
```

---

## Testing Guidelines

- Test files mirror source structure with `Tests` suffix
- Use XCTest framework
- Test state transitions thoroughly (idle → running → paused → idle)
- Mock time-based operations where possible
- Test computed properties and edge cases (0 values, boundary conditions)

---

## Performance Requirements

Per PRD requirements:

- Launch time < 1 second on target hardware
- Idle CPU < 3% in release builds
- Timer accuracy under backgrounding and sleep/wake
- Minimal memory footprint for always-available companion

---

## Documentation

- Use `///` for public API documentation
- Include parameter descriptions for non-obvious functions
- ADRs go in `doc/adr/` with sequential numbering
- User-facing documentation in `README.md`
- Detailed requirements in `tasks/prd-macos-focus-companion-app.md`

---

## Commit Message Style

```
type(scope): brief description

Body explaining what and why (not how)

Fixes #issue-number
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`  
Scope: `timer`, `audio`, `ui`, `persistence`, etc.

Example: `feat(timer): add pause/resume functionality`

---

## MVP Constraints (Do Not Violate)

- Fixed presets only: `25/5` and `50/10` (no custom durations)
- Notch-only UI (no menu bar fallback yet)
- No global keyboard shortcuts
- Auto-start next interval defaults to OFF
- Built-in audio tracks only (no user imports)
- Local persistence only (no cloud sync)
- Free MVP (no paywall code yet)

See ADR-0001 in `doc/adr/` for detailed rationale.

---

## Questions?

- Check the PRD: `tasks/prd-macos-focus-companion-app.md`
- Review ADRs: `doc/adr/`
