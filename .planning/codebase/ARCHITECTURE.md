# ARCHITECTURE.md — System Architecture

## Architectural Pattern

**MVVM** (Model-View-ViewModel) with `@MainActor` constraint on all UI-facing classes.

- **Models**: Pure data structs/enums (`SessionModels.swift`, `ProgressData.swift`)
- **Views**: SwiftUI `View` structs (`NotchCompanionView.swift`, sub-views)
- **ViewModels**: `ObservableObject` classes (`FocusSessionViewModel.swift`)
- **Services**: Business logic managers conforming to `ObservableObject` (`AudioManager`, `ProgressManager`, `NotificationService`, `PresetSettingsStore`)

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│  OakApp (SwiftUI @main)                                          │
│  └── AppDelegate (NSApplicationDelegate)                         │
│       ├── NotchWindowController (NSWindowController)             │
│       │    ├── NotchWindow (NSPanel)                             │
│       │    │    └── NSHostingView ─► NotchCompanionView (SwiftUI)│
│       │    └── FocusSessionViewModel                             │
│       ├── PresetSettingsStore                                    │
│       ├── NotificationService                                    │
│       └── SparkleUpdater                                         │
│                                                                  │
│  Settings Scene (SwiftUI Settings)                               │
│   └── SettingsMenuView                                           │
│        ├── PresetSettingsStore (shared)                          │
│        ├── NotificationService (shared)                          │
│        └── SparkleUpdater (shared)                               │
└──────────────────────────────────────────────────────────────────┘

Services (singletons shared via AppDelegate):
┌──────────────┬───────────────────┬─────────────────┬──────────────┐
│ AudioManager │ ProgressManager   │ PresetSettings │ Notification │
│ (Observable) │ (Observable)      │ Store          │ Service      │
│              │                   │ (Observable)   │ (Observable) │
│ AVFoundation │ UserDefaults      │ UserDefaults   │ UserNotif.   │
└──────────────┴───────────────────┴─────────────────┴──────────────┘
```

## Layers

### 1. App Entry Point

- **OakApp.swift**: `@main` SwiftUI `App` with `@NSApplicationDelegateAdaptor`
- **AppDelegate**: Creates notch window, initializes services, manages lifecycle
- Sets activation policy to `.accessory` (no dock icon, no menu bar)

### 2. View Layer (SwiftUI)

- **NotchCompanionView**: Root notch UI, handles expand/collapse, delegates to sub-views
- **Sub-views**: `AudioMenuView`, `ProgressMenuView`, `SettingsMenuView`, `ConfettiView`, `CircularProgressRing`
- **Composition**: Extracted as fileprivate/extensions (`NotchCompanionView+Controls`, `NotchCompanionView+StandardViews`, `NotchCompanionView+InsideNotch`)

### 3. ViewModel Layer

- **FocusSessionViewModel**: Single ViewModel managing:
  - Session state machine (`SessionState` enum: idle → running → paused → completed)
  - Timer management (1-second `Timer` with `sessionEndDate` reference)
  - Preset selection
  - Auto-start countdown
  - Round tracking for long breaks
  - Session type strings ("Focus", "Break", "Long Break")

### 4. Service Layer

| Service | Responsibility | Pattern |
| --- | --- | --- |
| **AudioManager** | Play/stop/pause/resume bundled or generated audio | Protocol-based (`AudioEngineProtocol`), factory injection |
| **ProgressManager** | Record/load/prune session history, calculate streaks | JSON in `UserDefaults`, 90-day retention |
| **PresetSettingsStore** | Read/write all user-configurable settings | Clustered `@Published` properties, `UserDefaults` backing |
| **NotificationService** | Request permission, send local notifications | Protocol-based (`SessionCompletionNotifying`) |
| **SparkleUpdater** | Check/download/install app updates | SPUUpdaterDelegate, ObservableObject |

### 5. Window Layer (AppKit)

- **NotchWindowController**: Manages window lifecycle, frame positioning, screen bindings
- **NotchWindow (NSPanel)**: Borderless, non-activating panel with `canJoinAllSpaces`
- **Layout**: Top-center of target screen, below notch or inside notch depending on config

## Design Patterns

### Dependency Injection

- Constructor injection for all ViewModels and Services
- Factory closures for testability (e.g., `audioEngineFactory`, `currentDate`)
- Protocol-based mocks (`AudioEngineProtocol`, `SessionCompletionNotifying`, `SessionCompletionSoundPlaying`)

### State Management

- **State machine**: `SessionState` enum with associated values (FSM for session lifecycle)
- **Published properties**: `@Published var sessionState` drives UI updates
- **Computed properties**: Derived state like `displayTime`, `canStart`, `canPause`, `isRunning`
- **Combine bindings**: `.sink` on settings changes to update window position

### Protocol-Oriented Design

```
AudioEngineProtocol        → AudioEngineAdapter (production), MockAudioEngine (test)
SessionCompletionNotifying → NotificationService (production), MockNotificationService (test)
SessionCompletionSoundPlaying → SystemSessionCompletionSoundPlayer (production), MockSessionCompletionSoundPlayer (test)
```

## Data Flow

### Session Start Flow

```
User taps play →
  NotchCompanionView → FocusSessionViewModel.startSession()
    → Updates sessionState to .running
    → Creates Timer with 1s interval
    → Tick updates remaining seconds via sessionEndDate
    → UI reacts to @Published sessionState changes
```

### Session Complete Flow

```
Timer tick reaches 0 →
  FocusSessionViewModel.completeSession()
    → ProgressManager.recordSessionCompletion() (persist to UserDefaults)
    → NotificationService.sendSessionCompletionNotification() (local push)
    → AudioManager.stop()
    → Play completion sound (NSSound.beep or system sound)
    → Update sessionState to .completed(isWorkSession:)
    → Show confetti animation (ConfettiView)
    → If autoStartNextInterval: start 10s countdown → auto-start next session
```

### Window Positioning Flow

```
PresetSettingsStore.displayTarget changes →
  Combine .sink in NotchWindowController
    → requestFrameUpdate(forceReposition: true)
    → NSScreen resolution via screen(for:preferredDisplayID:)
    → Frame computed (top-center, width based on expanded state)
    → NSWindow.setFrame()
```

## Concurrency Model

- **`@MainActor`** on all `ObservableObject` classes and their methods
- Timer callbacks wrap in `Task { @MainActor in ... }` to ensure main-thread delivery
- `[weak self]` in all escaping closures (timers, Combine sinks, notification callbacks)
- `NoiseGenerator` marked `@unchecked Sendable` (used exclusively on audio thread, no cross-thread sharing)

## Key Design Constraints

- **Notch-only UI**: No menu bar icon, no dock icon (`.accessory` activation policy)
- **No global shortcuts**: MVP constraint
- **Offline-first**: Zero cloud dependencies
- **Single ViewModel**: `FocusSessionViewModel` handles all session logic (not broken into multiple ViewModels)
