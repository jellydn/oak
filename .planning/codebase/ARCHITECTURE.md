# Architecture

**Analysis Date:** 2026-07-26

## Pattern Overview

**Overall:** MVVM with `@MainActor` isolation, layered over a SwiftUI/AppKit hybrid window host

**Key Characteristics:**

- Single-window app: one borderless `NSPanel` positioned at the screen notch
- `@MainActor` on every `ObservableObject` and UI controller — UI state mutations are main-thread-isolated
- Finite-state-machine for session lifecycle (`SessionState` enum + `SessionStateMachine` pure transitions)
- Reactive glue via Combine (`@Published` + `sink` + `PassthroughSubject`)
- Persistence split into small `*Config` value-type helpers behind one `PresetSettingsStore` façade
- Protocol-based dependency injection for testability (notifications, sound, audio engine)

## Layers

**App / Composition Root:**

- Purpose: Bootstrap, own long-lived services, wire them together
- Location: `Oak/Oak/OakApp.swift`
- Contains: `OakApp` (`@main`, `Settings` scene), `AppDelegate` (owns services + `NotchWindowController`)
- Depends on: All services, `NotchWindowController`, `FocusSessionViewModel`
- Used by: SwiftUI app lifecycle

**View Layer (SwiftUI):**

- Purpose: Render notch companion UI, popovers (audio/progress/settings), settings scene
- Location: `Oak/Oak/Views/`
- Contains: `NotchCompanionView` (+ `StandardViews` / `InsideNotch` extensions), `NotchWindowController`, `NotchWindow`, menu views, `NotchVisualStyle` + factory
- Depends on: `FocusSessionViewModel`, `AudioManager`, `NotificationService`, `SparkleUpdater`, `KeyboardShortcutService`, `PresetSettingsStore`, `ProgressManager`
- Used by: `NotchWindowController` hosts `NotchCompanionView` via `NSHostingView`; `OakApp` hosts `SettingsMenuView`

**ViewModel Layer:**

- Purpose: Session orchestration, derived display state, command handlers
- Location: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- Contains: `FocusSessionViewModel` (`ObservableObject`), `SessionCompletionSoundPlaying` protocol + `SystemSessionCompletionSoundPlayer`
- Depends on: `SessionStateMachine`, `SessionTimerService`, `AudioManager`, `ProgressManager`, `PresetSettingsStore`, `SessionCompletionNotifying`, `SessionCompletionSoundPlaying`
- Used by: View layer, `KeyboardShortcutService`

**Service Layer:**

- Purpose: Domain logic — timing, audio, persistence, notifications, updates, hotkeys
- Location: `Oak/Oak/Services/`
- Contains: `SessionTimerService`, `AudioManager` (+ `AudioEngineProtocol`/`AudioEngineAdapter`), `NoiseGenerator`, `ProgressManager`, `PresetSettingsStore` (+ `SessionDurationConfig`/`DisplayConfig`/`BehaviorConfig`), `NotificationService`, `SparkleUpdater` (+ `AppcastVersionParser`), `KeyboardShortcutService`
- Depends on: Foundation, AVFoundation, AppKit, UserNotifications, Sparkle, Combine
- Used by: ViewModel, AppDelegate, View layer

**Model Layer:**

- Purpose: Value types and FSM definitions
- Location: `Oak/Oak/Models/`
- Contains: `SessionModels` (`SessionState`, `SessionStateMachine`, `Preset`, `DisplayTarget`), `ProgressData` (`SessionType`, `SessionRecord`, `ProgressData`, `DailyStats`), `AudioTrack`, `NotchLayout`, `CountdownDisplayMode`
- Depends on: Foundation only
- Used by: All higher layers

**Extensions:**

- Purpose: AppKit additions for display/screen resolution
- Location: `Oak/Oak/Extensions/` — `NSScreen+DisplayTarget.swift`, `NSScreen+UUID.swift`

## Data Flow

**Session tick (running → UI):**

1. `SessionTimerService.start(seconds:)` schedules a 1s `Timer`, computes `sessionEndDate` (`Oak/Oak/Services/SessionTimerService.swift:24`)
2. Each tick recomputes `remainingSeconds` from `sessionEndDate` (drift-free), publishes via `@Published` (`:81`)
3. `FocusSessionViewModel.setupTimerServiceBindings()` sinks `timerService.$remainingSeconds` → `SessionStateMachine.tick(...)` → updates `sessionState` (`Oak/Oak/ViewModels/FocusSessionViewModel.swift:191`)
4. SwiftUI views observing `@Published sessionState` re-render (`displayTime`, `progressPercentage`, `currentSessionType`)

**Session completion:**

1. `SessionTimerService.tick()` hits 0 → invalidates timer, sends `timerFinished` (`Oak/Oak/Services/SessionTimerService.swift:91`)
2. ViewModel sink calls `completeSession()` (`Oak/Oak/ViewModels/FocusSessionViewModel.swift:207`)
3. `completeSession()` updates `completedRounds`, records to `ProgressManager`, calls `notificationService.sendSessionCompletionNotification(...)`, optionally plays completion sound, sets `sessionState = .completed`, sets `isSessionComplete = true`
4. After 1.5s `Task.sleep`, `isSessionComplete` resets; if `autoStartNextInterval`, `timerService.startAutoStartCountdown()` begins a 10s countdown
5. `autoStartFinished` sink → `startNextSession(isAutoStart: true)`

**Settings change → window:**

1. User toggles display target in `SettingsMenuView` → `presetSettings.setDisplayTarget(...)`
2. `PresetSettingsStore` persists via `DisplayConfig` and updates `@Published displayTarget`
3. `NotchWindowController.setupBindings()` sink on `presetSettings.$displayTarget` → `requestFrameUpdate(...)` coalesced on main queue → `setExpanded(...)` repositions `NotchWindow`

**State Management:**

- `@Published` on `ObservableObject`s drives SwiftUI observation
- `SessionStateMachine` is a pure enum namespace — all transitions are static functions returning `SessionState?` (nil = invalid transition), keeping `FocusSessionViewModel` free of duplicated pattern matching
- `currentDate: () -> Date` injected into `FocusSessionViewModel` and `ProgressManager` for testable day-rollover logic
- ViewModel bridges `PresetSettingsStore.objectWillChange` into its own `objectWillChange` via Combine sink so preset changes refresh the view

## Key Abstractions

**SessionState FSM:**

- Purpose: Model the four session phases without invalid states
- Examples: `Oak/Oak/Models/SessionModels.swift:3` (enum), `Oak/Oak/Models/SessionModels.swift:15` (`SessionStateMachine`)
- Pattern: Enum with associated values + static pure transition functions (`start`/`tick`/`pause`/`resume`/`complete`/`reset`) returning Optional for guarded transitions

**Protocol-based collaborators (DI):**

- Purpose: Decouple ViewModel from concrete services for unit testing
- Examples: `SessionCompletionNotifying` (`Oak/Oak/Services/NotificationService.swift:7`), `SessionCompletionSoundPlaying` (`Oak/Oak/ViewModels/FocusSessionViewModel.swift:5`), `AudioEngineProtocol` (`Oak/Oak/Services/AudioManager.swift:8`)
- Pattern: `any Protocol` type-erased dependencies; concrete defaults injected in `init` with `??` fallbacks; mocks in tests implement/override

**Config helper split:**

- Purpose: Keep `PresetSettingsStore` file manageable by moving UserDefaults read/write/validation into focused value-type structs
- Examples: `SessionDurationConfig`, `DisplayConfig`, `BehaviorConfig` (`Oak/Oak/Services/`)
- Pattern: `static func registerDefaults/read/save` + `static func validated*`; `PresetSettingsStore` is a thin `ObservableObject` façade delegating to these

**Notch visual style:**

- Purpose: Switch UI metrics/colors between "inside physical notch" and "standard" placements
- Examples: `Oak/Oak/Views/NotchVisualStyle.swift`, `Oak/Oak/Views/NotchVisualStyle+Factory.swift`
- Pattern: Value struct + factory function keyed on `isInsideNotch`

## Entry Points

**`@main OakApp`:**

- Location: `Oak/Oak/OakApp.swift:5`
- Triggers: macOS launch
- Responsibilities: Declare `Settings` scene (hosts `SettingsMenuView`); adapt `AppDelegate`

**`AppDelegate.applicationDidFinishLaunching`:**

- Location: `Oak/Oak/OakApp.swift:36`
- Triggers: App launch (skipped when `XCTestConfigurationFilePath` env set)
- Responsibilities: Set accessory activation policy, construct `NotchWindowController`, wire `KeyboardShortcutService.viewModel`, order window front, refresh notification auth status

## Error Handling

**Strategy:** Defensive, silent-failure with logging; no error propagation to UI

**Patterns:**

- `try?` for non-critical decoding/persistence (`ProgressManager.loadRecords`, `saveRecords`)
- `do/catch` with `logger.error(...)` for audio engine start, AVAudioPlayer init, notification requests
- Guard/early-return for invalid state transitions (`SessionStateMachine.*` returns nil)
- `Result` not used — async ops use `try await` with `do/catch` (e.g. `NotificationService.requestAuthorization`)
- `@unknown default` handled in `NotificationService.isGrantedStatus` for future-proofing

## Cross-Cutting Concerns

**Logging:** `os.log.Logger(subsystem: "com.productsway.oak.app", category: ...)` in `AudioManager`, `NotificationService`, `SparkleUpdater`. `print()` banned by lint in production.

**Validation:** Input clamping in `SessionDurationConfig.validatedWork/Break/Rounds` (static bounds). `AudioManager.setVolume` clamps 0...1. `ProgressManager.recordSessionCompletion` guards `durationMinutes > 0` and `startTime <= endTime`.

**Authentication:** None.

**Concurrency:** `@MainActor` on all `ObservableObject`/controller classes. Timers wrapped in `Task { @MainActor in self?.tick() }`. `[weak self]` in all escaping closures. `deinit` invalidates timers (and dispatches `Task { @MainActor in service.stop() }` for MainActor-isolated cleanup). `NoiseGenerator` marked `@unchecked Sendable` (owned exclusively by its `AVAudioSourceNode` render callback).

---

_Architecture analysis: 2026-07-26_
