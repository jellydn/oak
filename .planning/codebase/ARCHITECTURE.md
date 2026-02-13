# Architecture

**Analysis Date:** 2026-02-13

## Pattern Overview

**Overall:** MVVM (Model-View-ViewModel) with SwiftUI, using dependency injection via protocol-based abstractions.

**Key Characteristics:**
- SwiftUI declarative UI with `@MainActor` isolation for all UI layers
- Singleton services (`shared` instances) for global state management
- Protocol-oriented design for testability (`SessionCompletionNotifying`, `SessionCompletionSoundPlaying`, `UpdateChecking`)
- UserDefaults-based persistence with validation
- Timer-based countdown with state machine for session lifecycle

## Layers

**Models Layer:**
- Purpose: Domain data types, enums, and value objects
- Location: `Oak/Oak/Models/`
- Contains: `SessionState` enum, `Preset` enum, `DisplayTarget` enum, `AudioTrack` enum, `ProgressData` struct, `DailyStats` struct, `NotchLayout` enum, `CountdownDisplayMode` enum
- Depends on: Foundation (CoreGraphics for display IDs)
- Used by: ViewModels, Views, Services

**ViewModels Layer:**
- Purpose: Business logic and state management for focus sessions
- Location: `Oak/Oak/ViewModels/`
- Contains: `FocusSessionViewModel` - session state machine, timer coordination, user actions
- Depends on: Models, Services (AudioManager, ProgressManager, NotificationService)
- Used by: Views (NotchCompanionView, ProgressMenuView)

**Views Layer:**
- Purpose: SwiftUI declarative UI components
- Location: `Oak/Oak/Views/`
- Contains: `NotchCompanionView` (main notch UI), `SettingsMenuView`, `AudioMenuView`, `ProgressMenuView`, `CircularProgressRing`, `ConfettiView`
- Depends on: ViewModels, Models, AppKit (NSHostingView integration)
- Used by: NotchWindowController

**Window/Controller Layer:**
- Purpose: NSWindow/NSPanel management for notch positioning
- Location: `Oak/Oak/Views/NotchWindowController.swift`
- Contains: `NotchWindowController`, `NotchWindow` (NSPanel subclass)
- Depends on: SwiftUI views, NSScreen extensions
- Used by: AppDelegate

**Services Layer:**
- Purpose: Business logic, persistence, external system integration
- Location: `Oak/Oak/Services/`
- Contains: `AudioManager`, `NotificationService`, `ProgressManager`, `UpdateChecker`, `PresetSettingsStore`
- Depends on: AVFoundation, UserNotifications, UserDefaults, GitHub API
- Used by: ViewModels, Views

**Extensions Layer:**
- Purpose: Utility extensions on system types
- Location: `Oak/Oak/Extensions/`
- Contains: `NSScreen+DisplayTarget.swift` - screen resolution for multi-display setups
- Depends on: AppKit, CoreGraphics
- Used by: NotchWindowController, PresetSettingsStore, Settings views

**App Layer:**
- Purpose: Application lifecycle and entry point
- Location: `Oak/Oak/OakApp.swift`
- Contains: `OakApp` (@main struct), `AppDelegate` (NSApplicationDelegate)
- Depends on: All layers
- Used by: System (application launch)

## Data Flow

**Session Start Flow:**
1. User taps play button in `NotchCompanionView`
2. `FocusSessionViewModel.startSession()` called
3. Session state transitions from `.idle` to `.running(remainingSeconds, isWorkSession)`
4. Timer starts via `startTimer()` -> `tick()` every second
5. View updates via `@Published` properties (`displayTime`, `progressPercentage`, `currentSessionType`)

**Session Completion Flow:**
1. Timer reaches 0 seconds in `tick()`
2. `completeSession()` called
3. Work sessions: updates `ProgressManager` (records focus minutes, completed sessions), increments `completedRounds`
4. Break sessions: resets `completedRounds` to 0 if long break
5. `NotificationService.sendSessionCompletionNotification()` sends system notification
6. `completionSoundPlayer.playCompletionSound()` plays beep
7. Session state transitions to `.completed(isWorkSession)`
8. Confetti animation triggered for work sessions

**Settings Persistence Flow:**
1. User modifies setting in `SettingsMenuView`
2. Binding calls `PresetSettingsStore` setter (e.g., `setWorkMinutes(_:for:)`)
3. Value validated (min/max bounds)
4. `@Published` property updated
5. `UserDefaults` updated with new value
6. Observers (via `Combine`) notified of change

**Display Target Change Flow:**
1. User selects display in `SettingsMenuView`
2. `displayTargetBinding` set -> calls `PresetSettingsStore.setDisplayTarget()`
3. `@Published` `displayTarget` updated
4. `NotchWindowController` receives update via `Combine` sink
5. `requestFrameUpdate()` queued with `forceReposition: true`
6. `setExpanded()` calculates new frame for target display
7. Window frame updated via `window.setFrame()`

**State Management:**
- `FocusSessionViewModel`: `@Published` properties for session state, computed properties for UI state
- `PresetSettingsStore`: Singleton with `@Published` properties for all settings
- `AudioManager`: `@Published` for track selection, volume, playing state
- `NotificationService`: `@Published` for authorization status
- `ProgressManager`: `@Published` `dailyStats` struct

## Key Abstractions

**SessionState Enum:**
- Purpose: Finite state machine for focus session lifecycle
- Examples: `Oak/Oak/Models/SessionModels.swift`
- Pattern: Enum with associated values for state-specific data (`running(remainingSeconds, isWorkSession)`, `paused`, `completed`, `idle`)

**Protocol-Based Dependencies:**
- Purpose: Enable testability through dependency injection
- Examples: `SessionCompletionNotifying` (NotificationService), `SessionCompletionSoundPlaying` (SystemSessionCompletionSoundPlayer), `UpdateChecking` (UpdateChecker)
- Pattern: Protocol with concrete implementations, injected via `init` parameters

**Display Target Abstraction:**
- Purpose: Abstract multi-display setup (main vs notched)
- Examples: `DisplayTarget` enum (`.mainDisplay`, `.notchedDisplay`), `NSScreen+DisplayTarget` extension
- Pattern: Enum with computed properties for screen resolution, preferred display IDs stored in UserDefaults

**Preset Abstraction:**
- Purpose: Predefined focus/break configurations
- Examples: `Preset` enum (`.short`, `.long`) with default durations, `PresetSettingsStore` for per-preset customizable durations
- Pattern: Enum with associated default values, store overrides for customization

## Entry Points

**OakApp (@main):**
- Location: `Oak/Oak/OakApp.swift`
- Triggers: System application launch
- Responsibilities: Sets up SwiftUI Settings scene, initializes `@StateObject` singletons (PresetSettingsStore, NotificationService)

**AppDelegate:**
- Location: `Oak/Oak/Views/NotchWindowController.swift` (nested in OakApp.swift)
- Triggers: NSApplicationDelegate callbacks (`applicationDidFinishLaunching`, `applicationWillTerminate`)
- Responsibilities: Creates `NotchWindowController`, orders window front, checks for updates, manages notification authorization, cleanup on termination

**NotchWindowController:**
- Location: `Oak/Oak/Views/NotchWindowController.swift`
- Triggers: Created by `AppDelegate` on launch
- Responsibilities: Creates `FocusSessionViewModel`, sets up `NotchWindow`, positions window on notch, handles screen configuration changes, manages window expansion/collapse

## Error Handling

**Strategy:** Result types for async operations, early returns/guard clauses, logging with `os.log`

**Patterns:**
- UserDefaults persistence: Silent fallback to defaults (e.g., `try? JSONDecoder().decode()`)
- Audio playback: Stop current playback, log error, update state to stopped
- Notification requests: Log specific error types (UNError.notificationsNotAllowed vs generic errors)
- Display resolution: Fallback through `.mainDisplay` -> `.notchedDisplay` -> primary screen -> first available screen
- GitHub update checks: Rate limiting detection (403/429), timeout after 10 seconds, log errors
- Validation: Min/max bounds clamping for all user inputs (work/break minutes, rounds before long break)

## Cross-Cutting Concerns

**Logging:** `os.Logger` with subsystem "com.productsway.oak.app" and category per service (e.g., "AudioManager", "NotificationService", "UpdateChecker")

**Validation:** `PresetSettingsStore` static validation methods (`validatedWorkMinutes`, `validatedBreakMinutes`, `validatedRoundsBeforeLongBreak`) with min/max constants

**Concurrency:** `@MainActor` on all ViewModels, ObservableObject classes, and UI-related services. Timer callbacks wrapped in `Task { @MainActor in }`. `[weak self]` used in all escaping closures.

**Persistence:** UserDefaults as backing store, `UserDefaults` injected via init for testability, `register(defaults:)` for initial values, JSON encoding/decoding for complex types (`ProgressData`)

**Memory Management:** Explicit `cleanup()` methods for timers and audio resources, `[weak self]` in closures, `deinit` safety nets

**Testing:** Dependency injection via protocol types, isolated UserDefaults per test suite, `completeSessionForTesting()` method for direct state transitions

---

*Architecture analysis: 2026-02-13*
