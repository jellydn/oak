# CONVENTIONS.md — Code Conventions & Patterns

## Swift & SwiftUI Conventions

### Access Control

- **Explicit `internal`** keyword on all declarations (enforced by `explicit_top_level_acl`)
- Prefer `private` for state, `private(set)` for read-only published properties
- Use `fileprivate` for view extraction within the same file

### Naming

- **Types**: PascalCase (`FocusSessionViewModel`, `NotchCompanionView`)
- **Functions/Vars**: camelCase (`startSession()`, `displayTime`, `canStart`)
- **Constants**: lowerCamelCase for instance, PascalCase for static (`let horizontalPadding`)
- **Booleans**: `is`/`has`/`should` prefix (`isWorkSession`, `canStart`, `shouldUseLongBreak`)
- **Protocols**: `*ing` suffix for capability protocols (`SessionCompletionNotifying`, `SessionCompletionSoundPlaying`)
- **Enums**: Singular PascalCase for enum name, lowerCamelCase for cases (`SessionState.idle`, `Preset.short`)

### Imports

- **Order**: Foundation → Combine → SwiftUI/AppKit → Apple frameworks → @testable import Oak
- **Grouping**: `testable-bottom` (testable imports last in test files)
- No blank lines between imports
- One blank line between import block and type definitions
- Unused imports removed (analyzer rule: `unused_import`)

### Formatting

- **Indent**: 4 spaces
- **Line length**: 120 warning, 150 error
- **Wrapping**: `before-first` for arguments, parameters, collections
- **Closing paren**: balanced
- **Trailing commas**: enabled
- **Semicolons**: never

## State Management Patterns

### Session State Machine (FSM)

```
idle → running → paused → running → completed → (auto-start) → running
                   ↓                              ↓
                running                        idle (if not auto-start)
```

- Implemented as `SessionState` enum with associated values
- State transitions validated via computed properties (`canStart`, `canPause`, `canResume`)
- Use `if case` pattern matching for state inspection

### Published Properties

- `@Published` for all observable state that drives UI
- `private(set)` on published properties that shouldn't be mutated externally
- Computed properties for derived state (`displayTime`, `progressPercentage`)

### Combine Bindings

- `.sink` on `@Published` properties for reactive behavior
- Store cancellables as private `AnyCancellable?`
- `[weak self]` in all sink closures
- Used for: display target changes, always-on-top toggles, preset settings propagation

## Error Handling

- **No throwing errors in ViewModels** — guard/early return pattern preferred
- **Logging**: `os.log` (`Logger`) for production, SwiftLint warns on `print()`
- **Optional handling**: `guard let` / `if let` over forced unwrapping
- **No `try!`** in production code (test code may use `try! XCTUnwrap`)

## Memory Management

- `[weak self]` in ALL escaping closures:
  - Timer callbacks
  - Combine `.sink`
  - `DispatchQueue.main.async`
  - NotificationCenter observers
- `invalidate()` timers in `deinit`
- Wrap timer callbacks: `Task { @MainActor in self?.tick() }`
- Clean up Combine subscriptions via `.cancel()` in `deinit`

## View Update Safety (Critical Pattern)

```swift
// ❌ WRONG — publishes from view update
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ CORRECT — async dispatch
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

## SwiftUI View Patterns

### View Composition

- Extract sub-views as `private var someView: some View` properties within the main view
- Use separate files for complex extensions: `NotchCompanionView+Controls.swift`
- Popover-based sub-menus: Audio, Progress, Settings
- `ZStack` for overlay content (confetti animation on top of notch)

### Visual Design

- `RoundedRectangle(cornerRadius:style: .continuous)` for notch shape
- `LinearGradient` with custom colors per visual style
- `spring(response:dampingFraction:)` animation for state transitions
- `scaleEffect` for completion bounce animation
- Confetti animation on work session completion

### State-Driven UI

```swift
@State private var showAudioMenu = false
@State private var showConfetti = false

// Triggers
.onChange(of: viewModel.isSessionComplete) { isComplete in ... }
```

## Protocol-Oriented Design

```swift
// Production protocol
internal protocol AudioEngineProtocol {
    var isRunning: Bool { get }
    func setMixerVolume(_ volume: Float)
    func start() throws
    func stop()
}

// Production implementation
internal final class AudioEngineAdapter: AudioEngineProtocol { ... }

// Mock implementation (test)
internal final class MockAudioEngine: AudioEngineProtocol { ... }
```

- Use `any Protocol` syntax for protocol type-erasure
- Factory closures enable DI for testing (`audioEngineFactory`, `currentDate`)

## File Organization

- **Models**: ≤ 1 major type per file
- **Views**: 1 view per file (with fileprivate helper views allowed)
- **Extensions**: One file per extended type per aspect
- **Services**: 1 class per file
- **Test files**: Mirror source structure with `Tests` suffix

## Build Verification Sequence

Per ADR-0002, the required verification sequence:

1. `just format` (or `just format-check`)
2. `swiftlint lint --strict --no-cache` (or `just lint`)
3. `just test`

## MVP Constraints (Do Not Violate)

- Presets: only `25/5` and `50/10` (configurable durations in `PresetSettingsStore`)
- Notch-only UI — no menu bar icon, no dock icon
- No global keyboard shortcuts
- Auto-start next interval: default OFF
- Built-in audio only
- No cloud sync
