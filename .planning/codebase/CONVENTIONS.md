# Coding Conventions

**Analysis Date:** 2026-02-13

## Naming Patterns
**Files:**
- PascalCase for all Swift source files (`FocusSessionViewModel.swift`, `NotchCompanionView.swift`)
- Models: singular nouns (`AudioTrack.swift`, `ProgressData.swift`, `SessionModels.swift`)
- ViewModels: suffixed with `ViewModel` (`FocusSessionViewModel.swift`)
- Views: descriptive noun phrases (`NotchCompanionView.swift`, `NotchWindowController.swift`)
- Services: suffixed with `Manager` or descriptive role (`AudioManager.swift`, `ProgressManager.swift`, `UpdateChecker.swift`)

**Functions:**
- camelCase verbs for actions: `startSession()`, `pauseSession()`, `resumeSession()`, `resetSession()`
- `can`/`is`/`has` prefixes for boolean computed properties: `canStart`, `canPause`, `isRunning`, `isPaused`
- Private helpers prefixed with verbs: `startTimer()`, `tick()`, `completeSession()`
- Factory-style private methods: `createBrownNoiseNode()`, `createRainNode()`

**Variables:**
- camelCase throughout
- Boolean properties use `is`/`has`/`can`/`should` prefixes: `isWorkSession`, `isPlaying`, `isSessionComplete`, `isExpandedByToggle`
- Constants as `private let` with camelCase: `collapsedWidth`, `expandedWidth`, `notchHeight`
- UserDefaults keys as inline strings: `"progressHistory"`, `"oak.lastPromptedUpdateVersion"`

**Types:**
- PascalCase for all types: `SessionState`, `Preset`, `AudioTrack`, `ProgressData`, `DailyStats`
- Enums: PascalCase type with lowerCamelCase cases (`SessionState.idle`, `Preset.short`, `AudioTrack.brownNoise`)
- Protocols: suffixed with `-ing` or `-Checking` (`UpdateChecking`)
- Private nested types: PascalCase (`GitHubRelease`)

## Code Style
**Formatting:**
- No explicit formatter tool (SwiftFormat/SwiftLint not configured)
- 4-space indentation consistently
- No trailing whitespace observed
- Trailing newline at end of files
- Single blank line between type declarations and method groups
- No blank lines between imports

**Linting:**
- No SwiftLint or other linter configured
- Code style enforced by convention (documented in AGENTS.md)
- Soft 120-character line limit

## Import Organization
**Order:**
1. Foundation (always first when used)
2. SwiftUI / AppKit (UI frameworks)
3. Apple frameworks (AVFoundation, Combine, os)
4. No third-party dependencies

**Path Aliases:**
- None; the project uses no external packages (zero dependencies in Package.swift)
- `@testable import Oak` used in tests

## Error Handling
**Patterns:**
- `guard` with early return for preconditions: `guard canStart else { return }`, `guard let window else { return }`
- `do/catch` with `print()` for non-critical failures (AudioManager): `print("Failed to start audio engine: \(error)")`
- `try?` with optional binding for persistence decode/encode (ProgressManager): `try? JSONDecoder().decode(...)`
- `os.Logger` with `.error` level for production-facing errors (UpdateChecker): `logger.error("Update check failed: \(error.localizedDescription, privacy: .public)")`
- No custom error types; errors are handled inline

## Logging
**Framework:** `os.Logger` for production code (UpdateChecker); `print()` for dev/debug (AudioManager)
**Patterns:**
- Logger initialized with subsystem and category: `Logger(subsystem: "com.oak.app", category: "UpdateChecker")`
- Privacy-aware logging: `\(error.localizedDescription, privacy: .public)`
- `print()` used sparingly for audio engine failures during development

## Comments
**When to Comment:**
- Inline comments for non-obvious logic: `// Work session complete - record progress`
- State transition explanations: `// Reset animation state after 1.5 seconds`
- Comments used to explain "why" not "what"
- `// MARK: -` used in test files to group related test sections

**JSDoc/TSDoc:**
- No `///` documentation comments used anywhere in the codebase
- No formal API documentation; code is self-documenting through naming

## Function Design
**Size:** Functions are small, typically 5-15 lines. Largest is `generateAmbientSound(for:)` at ~35 lines
**Parameters:** Minimal parameters (0-2); optional parameters use default values: `startSession(using preset: Preset? = nil)`
**Return Values:** Computed properties preferred for derived state (`displayTime`, `canStart`, `currentSessionType`); void functions for mutations

## Module Design
**Exports:** All types are `internal` (default access); `private` used extensively for implementation details; `private(set)` not observed but `@Published` properties are public-facing
**Barrel Files:** Not used; each file contains one primary type (except `SessionModels.swift` which groups `SessionState`, `Preset`)
**Protocols:** Used for testability (`UpdateChecking` protocol for dependency injection in `AppDelegate`)

---
*Convention analysis: 2026-02-13*
