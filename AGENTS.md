# AGENTS.md - Agent Guidelines for Oak

## Project Overview

Oak is a lightweight macOS focus companion app built with Swift and SwiftUI. It provides a notch-based UI for Pomodoro-style focus sessions with ambient audio support.

**Stack**: Swift 5.9+, SwiftUI, AVFoundation
**Platform**: macOS 13+ (Apple Silicon target)
**Architecture**: MVVM with `@MainActor` for UI layer

---

## Build/Test Commands

Use `just` for common tasks (requires [just](https://github.com/casey/just)):

```bash
just build                          # Build the project
just test                           # Run all tests
just test-class FocusSessionViewModelTests    # Run specific test class
just test-method FocusSessionViewModelTests testStartSession  # Run specific test method
just clean && just open             # Clean and open in Xcode
```

Alternative: `cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' build`

**Note:** Project uses XcodeGen. Regenerate with: `cd Oak && xcodegen generate`

---

## Code Style Guidelines

### Imports & Formatting

- Group imports: Foundation first, then SwiftUI/AppKit, then Apple frameworks, then project imports
- No blank lines between import statements
- 4 spaces for indentation (no tabs), 120 character line limit (soft)
- Trailing newline at end of files, one blank line between type declarations

### Types & Naming

- **Types**: PascalCase (`FocusSessionViewModel`, `SessionState`)
- **Functions/Variables**: camelCase (`startSession`, `remainingSeconds`)
- **Constants**: lowerCamelCase for instance, PascalCase for static
- **Enums**: PascalCase with lowerCamelCase cases
- **Boolean properties**: Start with is/has/should (`isWorkSession`, `canStart`)

### SwiftUI Conventions

- Use `@MainActor` on all ViewModels and UI-related classes
- ViewModels: `@MainActor class X: ObservableObject` with `@Published` properties
- Prefer `private` for internal state, `private(set)` for read-only published state
- Use computed properties for derived state (e.g., `displayTime`, `canPause`)
- **Ownership**: `@StateObject` for ViewModels created in View, `@ObservedObject` for passed-in dependencies
- Extract views as `private var some View` computed properties

### State Management

- Use enums with associated values for finite state machines
- Use pattern matching with `if case` for state checks
- Keep state transitions explicit and side-effect-free

### Error Handling

- Use Swift's `Result` type for async operations that can fail
- Prefer early returns/guard clauses over nested if-else
- **Logging**: Use `os.log` in production; `print()` acceptable during development/debugging

### Memory Management & Concurrency

- Use `[weak self]` in closures that escape (timers, async callbacks)
- Always `invalidate()` timers in `cleanup()` or `deinit`
- Wrap timer callbacks with `Task { @MainActor in }`:
  ```swift
  timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.tick() }
  }
  ```

### Persistence

Use UserDefaults + Codable for simple local storage:

```swift
guard let data = userDefaults.data(forKey: key),
      let records = try? JSONDecoder().decode([T].self, from: data) else { return [] }
```

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
- Test state transitions (idle → running → paused → idle)
- Test computed properties and edge cases (0 values, boundary conditions)

---

## Performance Requirements

- Launch time < 1 second
- Idle CPU < 3% in release builds
- Timer accuracy under backgrounding and sleep/wake

---

## Documentation

- Use `///` for public API documentation
- ADRs go in `doc/adr/` with sequential numbering
- PRD: `tasks/prd-macos-focus-companion-app.md`

---

## Commit Message Style

```
type(scope): brief description
```

- **Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- **Scope**: `timer`, `audio`, `ui`, `persistence`, etc.

---

## MVP Constraints (Do Not Violate)

- Fixed presets only: `25/5` and `50/10` (no custom durations)
- Notch-only UI (no menu bar fallback yet)
- No global keyboard shortcuts
- Auto-start next interval defaults to OFF
- Built-in audio tracks only (no user imports)
- Local persistence only (no cloud sync)

---

## References

- PRD: `tasks/prd-macos-focus-companion-app.md`
- ADRs: `doc/adr/`
