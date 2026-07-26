# Coding Conventions

## Swift Style

### Access Control

- Explicit `internal` keyword on all declarations (enforced by SwiftLint `explicit_top_level_acl`)
- `private` for encapsulated state, `private(set)` for read-only published properties
- `public` only where needed (rare — mostly testable internals)

### Naming

- **Types**: PascalCase (`FocusSessionViewModel`, `SessionState`)
- **Functions/Variables**: camelCase (`startSession`, `displayTime`)
- **Constants**: lowerCamelCase for instances, PascalCase for statics
- **Booleans**: `is`/`has`/`should` prefix (`isWorkSession`, `canStart`, `shouldUseLongBreak`)
- **Protocols**: `*ing` suffix for capabilities (`SessionCompletionNotifying`, `SessionCompletionSoundPlaying`)

### Imports

- **Order**: Foundation → Combine → SwiftUI/AppKit → Apple frameworks → `@testable import Oak`
- **Grouping**: `testable-bottom` (testable imports last)
- No blank lines between imports, one blank line between types
- Remove unused imports (analyzer rule)

### Formatting

- **Indent**: 4 spaces
- **Line length**: 120 (warn), 150 (error)
- **Trailing newline**: Required
- **Documentation**: `///` for public/internal APIs
- **File length**: Warn at 500 lines, error at 1000
- **Function body**: Warn at 50 lines

### SwiftLint Opt-in Rules

`explicit_init`, `explicit_top_level_acl`, `trailing_closure`, `first_where`, `toggle_bool`, `modifier_order`, `vertical_parameter_alignment_on_call`, `closure_spacing`, `empty_count`, `sorted_first_last`, `redundant_type_annotation`, `yoda_condition`, `unneeded_parentheses_in_closure_argument`

### SwiftFormat

- 4-space indent, 120 max width, `wraparguments before-first`
- `self` removal, `isEmpty` enforcement
- Blank lines between scopes, sorted imports

## Architecture Conventions

### @MainActor

- All `ObservableObject` classes must be `@MainActor` or use `@MainActor`-annotated methods
- All ViewModels must be `@MainActor`
- Services that don't need UI isolation can omit `@MainActor` if they dispatch properly
- **CRITICAL**: Keep `@MainActor` on `ObservableObject` with `@Published`

### State Management

- Enums with associated values for FSMs (`SessionState`)
- `if case` for state checks
- Computed properties for derived state (`displayTime`, `canPause`, `progressPercentage`)

### Memory & Concurrency

- `[weak self]` in all escaping closures
- Always `invalidate()` timers in `deinit`
- Wrap timer callbacks: `Task { @MainActor in self?.tick() }`
- Use `AnyCancellable` for Combine subscriptions
- Cancel subscriptions in `deinit`

### View Update Safety

```swift
// ❌ Wrong — publishes from view update
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ Correct — async dispatch
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

### Error Handling

- Use `Result` for async operations
- Prefer `guard`/early returns over nested `if`
- **Logging**: `os.log` for production, `print()` only for debug (SwiftLint warns on `print()`)

### Dependency Injection

- Protocol-based mocks for testing
- Optional parameters with defaults for production code:
  ```swift
  init(audioManager: AudioManager? = nil, ...)
  ```
- Use `any Protocol` syntax for type-erasure

## Testing Conventions

- `@MainActor` on test classes
- `@testable import Oak` for internal access
- Isolate `UserDefaults` with unique suite names
- Always `cleanup()` and remove persistent domains in `tearDown()`

## Commit Style

`type(scope): description` — types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
