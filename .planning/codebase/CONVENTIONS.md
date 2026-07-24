# CONVENTIONS — Oak Code Conventions

> Primary reference: `AGENTS.md` — the authoritative source for coding standards.

## Formatting

| Rule             | Specification              |
| ---------------- | -------------------------- |
| Indent           | 4 spaces                   |
| Line length      | Warn 120, Error 150        |
| File length      | Warn 500 lines, Error 1000 |
| Function body    | Warn 50 lines, Error 100   |
| Trailing newline | Required                   |
| Documentation    | `///` for public APIs      |

## Module Structure

**Imports order**: Foundation → Combine → SwiftUI/AppKit → Apple frameworks → `@testable import Oak`

- No blank lines between imports
- One blank line between types
- `testable-bottom` grouping (testable imports last)
- Remove unused imports (analyzer rule: `unused_import`)

## Naming

| Category | Convention | Example |
| --- | --- | --- |
| Types | PascalCase | `FocusSessionViewModel`, `SessionState` |
| Functions/Vars | camelCase | `startSession(using:)`, `displayTime` |
| Constants (instance) | lowerCamelCase | `controlSize`, `contentSpacing` |
| Constants (static) | PascalCase | `PresetSettingsStore.minWorkMinutes` |
| Booleans | is/has/should prefix | `isWorkSession`, `canStart`, `shouldUseLongBreak` |
| Access | Explicit `internal` | `internal struct NotchCompanionView` |
| Protocols (capability) | `*ing` suffix | `SessionCompletionNotifying`, `SessionCompletionSoundPlaying` |
| Protocols (infrastructure) | `*Protocol` suffix | `AudioEngineProtocol` |

## State Management

- **`SessionState` enum with associated values** for the session FSM
- Use `if case` for state checks (e.g., `if case .idle = sessionState`)
- Computed properties for derived state (`displayTime`, `progressPercentage`, `canPause`)
- `@Published private(set)` for read-only published state
- `private` for internal state not published to views

## SwiftUI Patterns

- `@MainActor` on all ViewModels and UI classes (CRITICAL for `ObservableObject`)
- Extract views as computed properties (`var audioButton: some View`, `var compactView: some View`)
- Use `any Protocol` for type-erasure in DI
- `.buttonStyle(.plain)` on all custom-styled buttons
- Accessibility identifiers on all interactive elements

## Memory & Concurrency

- `[weak self]` in **all** escaping closures (verified: all 13 instances in codebase)
- Always `invalidate()` timers in `deinit` (verified: all 5 `deinit` methods)
- Wrap timer callbacks: `Task { @MainActor in self?.tick() }`
- `AnyCancellable` for Combine subscriptions
- `@MainActor` on 59 declarations across the codebase (all UI/service types)

## View Update Safety (CRITICAL)

```swift
// ❌ Wrong — publishes from view update synchronously
.onChange(of: value) { newValue in viewModel.update(newValue) }

// ✅ Correct — async dispatch
.onChange(of: value) { newValue in
    DispatchQueue.main.async { viewModel.update(newValue) }
}
```

## Error Handling

- Prefer `guard` / early returns over nested `if` statements
- Use `os.log` for production logging (SwiftLint warns on `print()`)
- `fatalError` only in required-but-unimplemented initializers (1 instance in `NotchWindowController.init(coder:)`)

## SwiftLint Rules (Opt-In)

`explicit_init`, `explicit_top_level_acl`, `trailing_closure`, `first_where`, `toggle_bool`, `modifier_order`, `vertical_parameter_alignment_on_call`, `closure_spacing`, `empty_count`, `sorted_first_last`, `redundant_type_annotation`, `yoda_condition`, `unneeded_parentheses_in_closure_argument`

**Custom rules**:

- `no_print_statements`: warns on `print()` — use `os.log` instead

## SwiftFormat Rules

- `indent 4`, `maxwidth 120`, `wraparguments before-first`
- `self` removal, `isEmpty` enforcement
- Blank lines between scopes, sorted imports
- `trailingCommas`, `redundantSelf`, `redundantReturn`
- Disabled: `andOperator`, `redundantType`, `redundantInternal`, `redundantPublic`

## Commit Style

`type(scope): description` — Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

Example: `fix(ui): add preset toggle to compact non-notch view with chevron indicator`
