# Coding Conventions

**Analysis Date:** 2026-02-15

## Naming Patterns
**Files:**
- Types use PascalCase matching the primary type declared: `FocusSessionViewModel.swift`, `SessionModels.swift`, `AudioManager.swift`
- Extensions use `TypeName+Feature.swift` pattern: `NSScreen+DisplayTarget.swift`, `NSScreen+UUID.swift`
- Views split via extensions: `NotchCompanionView+Controls.swift`, `NotchCompanionView+InsideNotch.swift`, `NotchCompanionView+StandardViews.swift`
- Style/layout helpers: `NotchVisualStyle.swift`, `NotchVisualStyle+Factory.swift`

**Functions:**
- camelCase: `startSession()`, `pauseSession()`, `completeSessionForTesting()`
- Setters prefixed with `set`: `setWorkMinutes(_:for:)`, `setAlwaysOnTop(_:)`, `setVolume(_:)`
- Boolean-returning computed properties: `canStart`, `canPause`, `canResume`, `isRunning`, `isPaused`
- Private helpers: `startTimer()`, `tick()`, `completeSession()`, `fillOutputBuffer(_:sample:)`

**Variables:**
- camelCase for instances: `viewModel`, `presetSettings`, `audioManager`, `windowController`
- Booleans prefixed with `is/has/should/can`: `isWorkSession`, `isLongBreak`, `isPlaying`, `hasNotch`, `canStart`, `showBelowNotch`
- Published properties use `private(set)` for read-only external access: `@Published private(set) var completedRounds: Int`

**Types:**
- PascalCase for all types: `FocusSessionViewModel`, `PresetSettingsStore`, `NotchWindowController`
- Enums use PascalCase with lowerCamelCase cases: `SessionState.idle`, `Preset.short`, `DisplayTarget.mainDisplay`
- Enums with associated values for state machines: `SessionState.running(remainingSeconds:isWorkSession:)`
- Protocols use `-ing`/`-able` suffixes: `SessionCompletionNotifying`, `SessionCompletionSoundPlaying`
- Static constants use PascalCase: `PresetSettingsStore.minWorkMinutes`, `PresetSettingsStore.maxWorkMinutes`

## Code Style
**Formatting:**
- Tool: SwiftFormat (config: `.swiftformat`)
- Indent: 4 spaces
- Max line width: 120 characters
- Wrap arguments: `before-first`
- Wrap parameters: `before-first`
- Wrap collections: `before-first`
- Closing paren: `balanced`
- Else position: `same-line`
- Line breaks: `lf`
- Semicolons: `never`
- Self: `remove` (redundant self removed)
- Strip unused args: `always`
- Trailing commas: enabled
- Import grouping: `testable-bottom`
- Header: `strip` (no file headers)

**Linting:**
- Tool: SwiftLint (config: `.swiftlint.yml`)
- Line length: warning at 120, error at 150 (ignores comments and URLs)
- File length: warning at 500, error at 1000
- Type body length: warning at 300, error at 500
- Function body length: warning at 50, error at 100
- Identifier names: min 2 chars, max 50 (warning) / 60 (error); excluded: `id`, `x`, `y`
- Opt-in rules: `explicit_init`, `explicit_top_level_acl`, `trailing_closure`, `vertical_parameter_alignment_on_call`, `closure_spacing`, `empty_count`, `first_where`, `sorted_first_last`, `modifier_order`, `redundant_type_annotation`, `toggle_bool`, `yoda_condition`
- Analyzer rules: `explicit_self`, `unused_import`
- Disabled rules: `todo`, `trailing_whitespace`
- Custom rule `no_print_statements`: warns on `print()` calls in production code

## Import Organization
**Order:**
1. Foundation / core frameworks (`Foundation`, `AppKit`, `CoreGraphics`)
2. Combine
3. SwiftUI / UI frameworks
4. Apple frameworks (`AVFoundation`, `UserNotifications`, `os`)
5. `@testable import Oak` (last, in test files only)

**Path Aliases:**
- None used; all imports are direct module imports

**Grouping Rules:**
- No blank lines between imports (enforced by SwiftFormat `--importgrouping testable-bottom`)
- `@testable` imports always placed last

## Error Handling
**Patterns:**
- `guard` clauses for early returns: `guard canStart else { return }`, `guard track != .none else { stop(); return }`
- `guard let` for optional unwrapping: `guard let data = userDefaults.data(forKey: key)` (see `PresetSettingsStore.swift`)
- `do/catch` for recoverable errors: `do { try engine.start() } catch { logger.error(...) }` (see `AudioManager.swift`)
- `try?` for optional error suppression in non-critical paths: `try? await Task.sleep(nanoseconds: ...)`
- `Result` type referenced in guidelines but not widely used in current codebase
- `XCTSkip` in tests for environment-dependent checks: `throw XCTSkip("No display available for window tests")`

## Logging
**Framework:** `os.Logger` for production code
**Patterns:**
- Loggers declared as private constants with subsystem and category: `private let logger = Logger(subsystem: "com.productsway.oak.app", category: "AudioManager")` (see `Oak/Oak/Services/AudioManager.swift`)
- Privacy-aware logging with `privacy: .public` for non-sensitive data: `logger.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")`
- Log levels: `.error` for failures, `.debug` for informational, `.info` for expected non-critical states
- `print()` usage is warned by custom SwiftLint rule `no_print_statements`
- `print()` acceptable only in dev/debug contexts

## Comments
**When to Comment:**
- `///` doc comments on protocols and their methods: `/// Tests for the legacy manual UpdateChecker service` (see `Oak/Tests/OakTests/UpdateCheckerTests.swift`)
- `// MARK: -` sections to organize test groups and extension blocks: `// MARK: - Rate Limit Tests`, `// MARK: - Initialization Tests`
- Inline comments for non-obvious logic or constraints: `// Let AVAudioEngine negotiate the best internal format` (see `Oak/Oak/Services/AudioManager.swift`)
- No excessive commenting; code is self-documenting by convention

**JSDoc/TSDoc:**
- N/A (Swift project); `///` used sparingly for public/internal protocol APIs

## Function Design
**Size:** Warning at 50 lines, error at 100 (enforced by SwiftLint `function_body_length`)
**Parameters:** Wrap before-first when exceeding line width; labeled parameters with Swift API design conventions: `func setWorkMinutes(_ minutes: Int, for preset: Preset)`
**Return Values:** Computed properties preferred for derived state (`displayTime`, `progressPercentage`, `canStart`); explicit `-> Bool` / `-> String` on methods

## Module Design
**Exports:** Explicit `internal` access control on all top-level declarations (enforced by SwiftLint `explicit_top_level_acl`)
**Barrel Files:** Not used; each file declares one primary type
**Singletons:** `static let shared` pattern for services: `PresetSettingsStore.shared`, `NotificationService.shared`, `SparkleUpdater.shared`
**Dependency Injection:** Constructor injection with defaults: `init(presetSettings: PresetSettingsStore, progressManager: ProgressManager? = nil, ...)`
**Protocols for testability:** `SessionCompletionNotifying`, `SessionCompletionSoundPlaying` enable mock injection in tests

## Architecture Patterns
**MVVM:** ViewModels are `@MainActor ObservableObject` classes in `Oak/Oak/ViewModels/`; Views in `Oak/Oak/Views/`; Models in `Oak/Oak/Models/`
**State Machine:** `SessionState` enum with `.idle`, `.running`, `.paused`, `.completed` and associated values (see `Oak/Oak/Models/SessionModels.swift`)
**View Decomposition:** Large views split into extensions across files: `NotchCompanionView+Controls.swift`, `NotchCompanionView+InsideNotch.swift`
**View Update Safety:** `DispatchQueue.main.async` or `DispatchQueue.main.asyncAfter` used to avoid publishing changes from within view updates (see `Oak/Oak/Views/NotchCompanionView.swift`)

## Memory & Concurrency
- `[weak self]` in all escaping closures: `Timer.scheduledTimer { [weak self] _ in ... }` (see `Oak/Oak/ViewModels/FocusSessionViewModel.swift`)
- `Task { @MainActor in ... }` for timer callbacks and async work
- Timers always invalidated in `cleanup()` and `deinit`
- `deinit` captures local references to avoid accessing `self`: `let engine = audioEngine; engine?.stop()` (see `Oak/Oak/Services/AudioManager.swift`)
- `AnyCancellable` stored and cancelled in `deinit`: `presetSettingsCancellable?.cancel()` (see `Oak/Oak/ViewModels/FocusSessionViewModel.swift`)

## Persistence
- `UserDefaults` with namespaced string keys via private enum: `Keys.shortWorkMinutes = "preset.short.workMinutes"` (see `Oak/Oak/Services/PresetSettingsStore.swift`)
- `userDefaults.register(defaults:)` for default values
- Validation on read with clamping: `validatedWorkMinutes()`, `validatedBreakMinutes()`
- Guard against redundant writes: `guard alwaysOnTop != value else { return }`

## Project Configuration
- XcodeGen via `Oak/project.yml` for project generation
- `justfile` as task runner (see root `justfile`)
- SPM for dependencies (Sparkle 2.6.4+)
- Deployment target: macOS 13.0

---
*Convention analysis: 2026-02-15*
