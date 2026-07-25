# ARCHITECTURE.md — System Design & Patterns

## Pattern: MVVM with Protocol-Based DI

Oak follows the **Model-View-ViewModel** pattern with protocol-based dependency injection.

```
┌─────────────────────────────────────────┐
│  OakApp.swift (Entry Point)             │
│  ┌─────────────────────────────────────┐│
│  │ AppDelegate (NSApplicationDelegate) ││
│  │  • Creates NotchWindowController    ││
│  │  • Creates PresetSettingsStore      ││
│  │  • Creates NotificationService      ││
│  │  • Creates SparkleUpdater           ││
│  └──────────────┬──────────────────────┘│
└─────────────────┼───────────────────────┘
                  │
     ┌────────────▼─────────────┐
     │  NotchWindowController   │  NSPanel wrapper
     │  (NSWindowController)    │  • Frame management
     │                          │  • Display target binding
     │  Creates:                │  • Screen change observer
     │  • FocusSessionViewModel │
     │  • NotchCompanionView    │
     └────────────┬─────────────┘
                  │
     ┌────────────▼─────────────┐
     │  NotchCompanionView      │  SwiftUI View
     │  @ObservedObject:        │  • Collapsed/Expanded states
     │    viewModel              │  • Inside-notch layout variant
     │    notificationService    │  • Popovers (audio, progress, settings)
     │    sparkleUpdater         │  • Completion animations (confetti)
     └────────────┬─────────────┘
                  │
     ┌────────────▼─────────────┐
     │  FocusSessionViewModel   │  @MainActor ObservableObject
     │                          │  • Session FSM (idle→running→paused→completed)
     │  Dependencies:           │  • Timer management
     │  • PresetSettingsStore   │  • Auto-start countdown
     │  • AudioManager          │  • Progress tracking delegation
     │  • ProgressManager       │  • Notification & sound triggers
     │  • NotificationService   │
     │  • completionSoundPlayer │
     └──────────────────────────┘
```

## Data Flow

```
UserDefaults ←→ PresetSettingsStore ←→ FocusSessionViewModel ←→ NotchCompanionView
                     ↕ (published properties)              ↕ (display data)
UserDefaults ←→ ProgressManager ←→ FocusSessionViewModel ←→ ProgressMenuView
                     ↕
AVAudioEngine ←→ AudioManager ←→ FocusSessionViewModel
```

## FSM: Session State Machine

```
     ┌──────────┐
     │   IDLE   │──── startSession() ────┐
     └──────────┘                        │
          ▲                              ▼
          │                       ┌──────────┐
          │ resetSession()        │ RUNNING  │
          │                       └─────┬────┘
          │                    pauseSession()│
          │                              ▼
          │                       ┌──────────┐
          │                       │  PAUSED  │
          │                       └─────┬────┘
          │                   resumeSession()│
          │                              ▼
          │                       ┌──────────┐
          │           tick() → 0  │ RUNNING  │
          │           (auto)      └─────┬────┘
          │                             │ completeSession()
          │                             ▼
          │                      ┌───────────┐
          └────── resetSession() │ COMPLETED │
                                 └───────────┘
                                       │
                          startNextSession() (manual or auto-start)
                                       │
                                       ▼
                                 ┌──────────┐
                                 │ RUNNING  │ (next interval)
                                 └──────────┘
```

## Key Abstractions

### Protocol-Based DI

```swift
// Session completion notification
internal protocol SessionCompletionNotifying { ... }
// Completion sound
internal protocol SessionCompletionSoundPlaying { ... }
// Audio engine (for testability)
internal protocol AudioEngineProtocol { ... }
```

### @MainActor Enforcement

All `ObservableObject` classes, ViewModels, and window controllers are annotated `@MainActor`:

- `FocusSessionViewModel`
- `AudioManager`
- `NotificationService`
- `PresetSettingsStore`
- `ProgressManager`
- `SparkleUpdater`
- `NotchWindowController`

### Published State

State flows through `@Published` properties:

- `sessionState: SessionState` — FSM state with associated values
- `selectedPreset: Preset` — short (25/5) or long (50/10)
- `isSessionComplete: Bool` — triggers confetti & animations
- `autoStartCountdown: Int` — 10-second countdown for auto-start
- `completedRounds: Int` — tracks rounds before long break trigger

## Entry Points

| Entry | File | Role |
| --- | --- | --- |
| `@main` | `Oak/OakApp.swift` | SwiftUI App lifecycle |
| `AppDelegate` | `Oak/OakApp.swift` | NSApplicationDelegate, window creation |
| `NotchWindowController` | `Oak/Oak/Views/NotchWindowController.swift` | Window lifecycle, frame management |

## Window Architecture

`NotchWindow` is an `NSPanel` with:

- `.borderless` + `.nonactivatingPanel` style mask
- `.canJoinAllSpaces` + `.stationary` collection behavior
- `level`: `.statusBar` (always on top) or `.floating` (normal)
- Transparent background, no shadow
- Dynamic width: collapsed (compact) vs expanded (full controls)
- Y-position calculated based on notch presence and `showBelowNotch` setting
