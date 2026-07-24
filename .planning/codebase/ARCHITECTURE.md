# ARCHITECTURE — Oak System Architecture

## Pattern: MVVM with @MainActor

Oak follows **Model-View-ViewModel (MVVM)** with all UI-layer types annotated `@MainActor` for thread safety.

```
┌─────────────────────────────────────────┐
│                  Views                   │
│  NotchCompanionView, SettingsMenuView,  │
│  AudioMenuView, ProgressMenuView, etc.  │
│         @ObservedObject / @State         │
└──────────────┬──────────────────────────┘
               │  binds to
┌──────────────▼──────────────────────────┐
│              ViewModels                  │
│     FocusSessionViewModel (central)      │
│   @Published state, session lifecycle    │
└──────┬──────────────────┬───────────────┘
       │                  │
       │  owns            │  reads/writes
┌──────▼──────┐    ┌──────▼──────────────┐
│  Services   │    │  PresetSettingsStore │
│             │    │  (ObservableObject)   │
│ AudioManager│    │  UserDefaults-backed │
│ ProgressMgr │    └─────────────────────┘
│ Notification│
│ Sparkle     │
└──────┬──────┘
       │
┌──────▼──────────────────────────────────┐
│              Models                      │
│  SessionState (enum FSM), Preset (enum),│
│  AudioTrack (enum), ProgressData, etc.  │
└─────────────────────────────────────────┘
```

## Entry Points

| File | Role |
| --- | --- |
| `OakApp.swift` | SwiftUI `@main App` entry point, creates `AppDelegate` |
| `AppDelegate` (in `OakApp.swift`) | `NSApplicationDelegate`, creates `FocusSessionViewModel` + `NotchWindowController` |
| `NotchWindowController.swift` | Manages `NSPanel` window lifecycle (show, hide, position, always-on-top) |

## Key Abstractions

### Session State Machine

`SessionState` enum with associated values drives all UI:

```
idle → running(remaining, isWork) → paused(remaining, isWork) → running → completed(isWork) → idle
                                                                       ↓
                                                              (auto-start countdown)
```

### Protocol-Based DI

ViewModels accept protocols, not concrete types:

- `FocusSessionViewModel` takes `any SessionCompletionNotifying` and `any SessionCompletionSoundPlaying`
- `AudioManager` takes `AudioEngineProtocol` for testability
- `MockAudioManager`, `MockAudioEngine`, `MockNotificationService` in tests

### Combine Reactivity

- All services/ViewModels are `ObservableObject` with `@Published` properties
- Views use `@ObservedObject` to subscribe
- `PresetSettingsStore.objectWillChange` forwarded to `FocusSessionViewModel.objectWillChange` for cascading updates

## Data Flow

1. User taps "Start" → `NotchCompanionView` calls `viewModel.startSession(using:)`
2. ViewModel configures timer, sets `@Published sessionState = .running(...)`
3. SwiftUI re-renders views observing `sessionState`
4. On tick → `tick()` updates `currentRemainingSeconds`, publishes updated state
5. Session completes → `completeSession()` records progress, sends notification, plays sound, updates state to `.completed`
6. If auto-start enabled → 10s countdown → `startNextSession(isAutoStart: true)`

## Window Management

- `NotchWindowController` creates a borderless `NSPanel` positioned at the top-center of the target display
- Two display modes: **inside notch** (fills notch area) vs **below notch** (standard position)
- `NotchVisualStyle.make(isInsideNotch:)` adapts colors, opacities, corner radius
- Always-on-top controlled via `NSWindow.Level.floating` when enabled, `.statusBar` otherwise
- Window persists across all Spaces and screens (`.canJoinAllSpaces`, `.stationary`) — does not auto-hide

## Layer Boundaries

| Layer | Contains | Depends On |
| --- | --- | --- |
| Views | SwiftUI `View` structs | ViewModels, `@State`, `@ObservedObject` |
| ViewModels | `FocusSessionViewModel` | Services, `PresetSettingsStore`, Models |
| Services | `AudioManager`, `ProgressManager`, `NotificationService`, `SparkleUpdater` | System APIs, `UserDefaults` |
| Models | Enums, structs, protocols | Foundation |
| Extensions | `NSScreen+*`, `NotchVisualStyle` | AppKit, SwiftUI |
