# Coding Conventions

**Analysis Date:** 2026-07-26

## Naming Patterns

**Files:** PascalCase matching primary type — `FocusSessionViewModel.swift`, `NotchWindowController.swift`. Extraction files use `<Type>+<Aspect>.swift`.

**Functions:** camelCase. Boolean queries prefixed `is/has/should/can` — `isIdle`, `canPause`, `shouldUseLongBreak`. Transition/verb methods: `start`, `pause`, `resume`, `complete`, `tick`, `reset`.

**Variables:** camelCase. Constants: lowerCamelCase (instance), PascalCase (static) — `NotchLayout.height`, `SessionDurationConfig.minWorkMinutes`. Booleans: `is/has/should` prefix — `isWorkSession`, `isLongBreak`, `wasAutoStarted`, `hasNotch`.

**Types:** PascalCase. Protocols use `*ing` suffix for capabilities — `SessionCompletionNotifying`, `SessionCompletionSoundPlaying`, `AudioEngineProtocol` (note: `AudioEngineProtocol` uses `Protocol` suffix, the one exception).

## Code Style

**Formatting:** SwiftFormat (Swift 6.2 mode)

- 4-space indent, max width 120
- `--self remove` (SwiftFormat removes explicit `self` except where required)
- `--importgrouping testable-bottom` (testable imports last)
- `--header strip`, `--elseposition same-line`, `--indentcase false`, `--wraparguments before-first`, `--linebreaks lf`, `--semicolons never`
- Enabled rules: `isEmpty`, `sortImports`, `blankLinesBetweenScopes`, `consecutiveBlankLines`, `redundantSelf`, `redundantReturn`, `trailingCommas`, `wrapArguments`, `wrapAttributes`

**Linting:** SwiftLint (`--strict` in CI)

- Line length: warn 120, error 150 (ignores comments/URLs)
- File length: warn 500, error 1000
- Type body: warn 300, error 500
- Function body: warn 50, error 100
- Identifier: min 2, warn 50, error 60 (excludes `id`, `x`, `y`)
- Type name: min 3, warn 50, error 60
- Opt-in: `explicit_init`, `explicit_top_level_acl`, `trailing_closure`, `vertical_parameter_alignment_on_call`, `unneeded_parentheses_in_closure_argument`, `closure_spacing`, `empty_count`, `file_header`, `first_where`, `sorted_first_last`, `modifier_order`, `redundant_type_annotation`, `toggle_bool`, `yoda_condition`
- Analyzer rules: `explicit_self`, `unused_import`
- Custom rule `no_print_statements`: regex `^\s*print\(` → warning "Use os.log for logging in production code"
- Disabled: `todo`, `trailing_whitespace`

## Import Organization

**Order (enforced by SwiftFormat `--importgrouping testable-bottom`):**

1. Foundation
2. Combine
3. SwiftUI / AppKit
4. Other Apple frameworks (`AVFoundation`, `CoreGraphics`, `os`, `UserNotifications`, `Sparkle`)
5. `@testable import Oak` (last, in tests)

No blank lines between imports; one blank line between types. `unused_import` analyzer rule removes unused imports.

## Error Handling

**Patterns:**

- Guard/early-return over nested `if` — universal across services and view model
- `try?` for non-critical persistence/decoding (`ProgressManager.loadRecords`, `saveRecords`, `KeyboardShortcutService.loadConfig`)
- `do/catch` + `logger.error(...)` for audio engine start, `AVAudioPlayer` init, notification authorization
- `SessionStateMachine` transitions return `Optional` — nil signals invalid transition; callers guard with `if let newState = ...`
- `@unknown default` handled in `NotificationService.isGrantedStatus` for forward compatibility
- No `Result` type usage; async APIs use `try await` with `do/catch`
- Errors never surface to UI — silent failure with logging is the norm

## Logging

**Framework:** `os.log` `Logger(subsystem: "com.productsway.oak.app", category: <Category>)`

**Categories:** `AudioManager`, `NotificationService`, `SparkleUpdater`

**Patterns:**

- `logger.error(...)` for failures (audio engine start, notification send, permission request)
- `logger.warning(...)` for recoverable misconfiguration (missing/invalid `SUPublicEDKey`)
- `logger.info(...)` for lifecycle events (Sparkle init, manual check, auto-check toggle)
- `logger.debug(...)` for expected fallback paths (no bundled asset → procedural generation)
- String interpolation uses `\(value, privacy: .public)` for non-sensitive runtime values
- `print()` prohibited in production by custom lint rule (debug only)

## Comments

**When to Comment:**

- Explain _why_, not what (per AGENTS.md) — e.g. `KeyboardShortcutService.init` comment explains why monitors start in `load()` not `init()` to avoid corrupting the event monitor chain (`Oak/Oak/Services/KeyboardShortcutService.swift:105`)
- MARK sections for grouping: `// MARK: - <Section>` (e.g. `// MARK: - Session Control`, `// MARK: - Private`)
- `///` doc comments on public-facing APIs and non-obvious value types (e.g. `NoiseGenerator`, `WindowPositioning`, `BehaviorConfig`)

**JSDoc/TSDoc:** N/A (Swift). Uses `///` for Swift doc comments on types and intent-revealing methods.

## Function Design

**Size:** Function body warn 50 / error 100 lines (SwiftLint). `FocusSessionViewModel.completeSession()` is ~50 lines — at the warn threshold; refactor candidate if it grows.

**Parameters:** Labeled, descriptive. Factory closures for DI: `audioEngineFactory: @escaping () -> any AudioEngineProtocol = { AudioEngineAdapter() }`. Time injection: `currentDate: @escaping () -> Date = Date.init` for testable day-rollover.

**Return Values:** `Optional` for guarded transitions (`SessionStateMachine.*` returns nil on invalid state). `@discardableResult` on side-effecting queries (`ProgressManager.checkDayChange`). Static value-producing functions return concrete types.

## Module Design

**Exports:** Every declaration explicitly marked `internal` (SwiftLint `explicit_top_level_acl`). No `public` API — single app target. `private(set)` on `@Published` properties for read-only published state.

**Type Erasure:** `any Protocol` syntax for type-erased dependencies — `let notificationService: any SessionCompletionNotifying`, `private var audioEngine: (any AudioEngineProtocol)?`.

**Extensions for decomposition:** Large views split via `extension NotchCompanionView { var someView: some View { ... } }` in `+StandardViews` / `+InsideNotch` files. `FocusSessionViewModel` session-control methods in an `internal extension`.

**FSM as enum namespace:** `SessionStateMachine` is an `enum` (uninhabited) used purely as a namespace for static transition functions — the Swift idiom for namespacing without free functions.

---

_Convention analysis: 2026-07-26_
