# Architecture

## Pattern: MVVM with @MainActor

Oak follows **Model-View-ViewModel** (MVVM) architecture with all observable state pinned to `@MainActor`:

```
┌─────────────────────┐
│   Views (SwiftUI)    │  ← user interaction, layout, rendering
├─────────────────────┤
│  ViewModels          │  ← @MainActor, ObservableObject, @Published state
├─────────────────────┤
│  Services            │  ← business logic, audio, timers, persistence
├─────────────────────┤
│  Models              │  ← Codable structs, enums, value types
└─────────────────────┘
```

## Layer Responsibilities

### Models (`Models/`)

Pure data types — all value types or enums, no business logic:

- `SessionModels.swift` — `SessionState` (FSM enum), `Preset` enum, `SessionType`
- `ProgressData.swift` — `ProgressData`, `SessionRecord`, `DailyStats`
- `AudioTrack.swift` — ambient audio track enum
- `NotchLayout.swift` — layout constants
- `CountdownDisplayMode.swift` — display mode enum

### Services (`Services/`)

Business logic and system integration — reference types (`class`):

- **`FocusSessionViewModel`** — session lifecycle orchestrator (start/pause/resume/complete/reset)
- **`AudioManager`** — AVAudioPlayer management, track switching, volume
- **`ProgressManager`** — session history persistence in UserDefaults, daily stats, streaks
- **`SessionTimerService`** — Timer-based countdown and auto-start countdown
- **`PresetSettingsStore`** — all user preferences (durations, display, behavior)
- **`NotificationService`** — UserNotifications authorization and delivery
- **`SparkleUpdater`** — SPUStandardUpdaterController wrapper
- **`KeyboardShortcutService`** — NSEvent local/global keyboard monitoring
- Configuration services: `SessionDurationConfig`, `DisplayConfig`, `BehaviorConfig`
- Utility: `NoiseGenerator`

### Views (`Views/`)

SwiftUI views — stateless rendering, `@ObservedObject` bindings to ViewModels:

- `NotchCompanionView` — main notch UI (compact + expanded states)
- `NotchWindowController` — NSWindowController managing NSPanel lifecycle
- `SettingsMenuView` — settings panel (presets, display, audio, keyboard, data, updates)
- Supporting views: `AudioMenuView`, `ProgressMenuView`, `PresetEditorView`, `CircularProgressRing`, `ConfettiView`, etc.

### ViewModels (`ViewModels/`)

- `FocusSessionViewModel` — the single ViewModel bridging all services to views

## Data Flow

```
User Action (click/keypress)
  → View calls ViewModel method (e.g., startSession())
    → ViewModel updates @Published state
      → View re-renders via SwiftUI observation

Timer tick (Timer/Task)
  → Service publishes new state
    → ViewModel subscriber receives update
      → @Published property changes
        → View re-renders
```

## State Machine

`SessionState` is a finite state machine implemented as an enum with associated values:

```
idle → running(seconds, isWork) → paused(seconds, isWork) → running(...)
                                                    → reset → idle
running → completed(isWork) → startNext → running(...)
                           → reset → idle
```

`SessionStateMachine` (introduced in #133) consolidates all state queries and transitions:

- `isIdle()`, `isRunning()`, `isPaused()`, `isCompleted()`
- `start()`, `pause()`, `resume()`, `complete()`, `reset()`, `tick()`

## Entry Points

1. **`OakApp.swift`** — `@main` App struct + `AppDelegate` (NSApplicationDelegate)
   - `applicationDidFinishLaunching` — creates `NotchWindowController`, sets `activationPolicy(.accessory)`
2. **`NotchWindowController.swift`** — owns `NSPanel`, hosts `NotchCompanionView` via `NSHostingView`

## Dependency Injection

Services use protocol-based DI with optional default parameters:

```swift
init(
    audioManager: AudioManager? = nil,
    progressManager: ProgressManager? = nil,
    notificationService: any SessionCompletionNotifying,
    ...
)
```

Tests inject protocol-based mocks (`MockAudioManager`, `MockNotificationService`) and isolated `UserDefaults` suites.

## Key Abstractions

| Abstraction                     | Type     | Purpose                                            |
| ------------------------------- | -------- | -------------------------------------------------- |
| `SessionCompletionNotifying`    | protocol | Decouple notification delivery from ViewModel      |
| `SessionCompletionSoundPlaying` | protocol | Decouple sound playback (beep) from ViewModel      |
| `SessionTimerServicing`         | protocol | Decouple timer implementation from ViewModel       |
| `WindowPositioning`             | enum     | Consolidate frame math and Y-position calculations |
| `SessionStateMachine`           | enum     | Pure state transition logic                        |
