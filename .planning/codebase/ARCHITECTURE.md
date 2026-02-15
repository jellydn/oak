# Architecture

**Analysis Date:** 2026-02-15

## Pattern Overview
**Overall:** MVVM (Model-View-ViewModel) with Service Layer
**Key Characteristics:**
- Single `FocusSessionViewModel` drives all timer/session state via `@Published` properties
- Services are singletons (`PresetSettingsStore.shared`, `NotificationService.shared`, `SparkleUpdater.shared`)
- `@MainActor` enforced on all ViewModels, Services, and UI-related classes
- State machine pattern for session lifecycle using enums with associated values
- NSPanel-based borderless window positioned at macOS notch area

## Layers

**Models:**
- Purpose: Define data structures, enums, and layout constants
- Location: `Oak/Oak/Models/`
- Contains: `SessionState` enum (state machine), `Preset` enum, `AudioTrack` enum, `DisplayTarget` enum, `NotchLayout` constants, `ProgressData`/`DailyStats` structs, `CountdownDisplayMode` enum
- Depends on: Foundation
- Used by: ViewModels, Views, Services

**ViewModels:**
- Purpose: Business logic, timer management, session state transitions
- Location: `Oak/Oak/ViewModels/`
- Contains: `FocusSessionViewModel` — the single ViewModel managing all focus session state
- Depends on: Models, Services (`AudioManager`, `ProgressManager`, `NotificationService`, `PresetSettingsStore`)
- Used by: Views (`NotchCompanionView`, `NotchWindowController`)

**Views:**
- Purpose: SwiftUI views and AppKit window management for the notch-based UI
- Location: `Oak/Oak/Views/`
- Contains: `NotchCompanionView` (main SwiftUI view with extensions for controls, standard views, inside-notch views), `NotchWindowController` (NSWindowController managing borderless NSPanel), `NotchWindow` (NSPanel subclass), `NotchVisualStyle`, `CircularProgressRing`, `ConfettiView`, popover menus (`AudioMenuView`, `ProgressMenuView`, `SettingsMenuView`)
- Depends on: ViewModels, Models, Services
- Used by: `AppDelegate` (creates `NotchWindowController`)

**Services:**
- Purpose: Business logic decoupled from UI — audio playback, persistence, notifications, updates
- Location: `Oak/Oak/Services/`
- Contains: `AudioManager` (AVFoundation audio engine + bundled track playback), `PresetSettingsStore` (UserDefaults persistence), `ProgressManager` (session history + streaks), `NotificationService` (UNUserNotificationCenter), `SparkleUpdater` (auto-updates via Sparkle SPM), `UpdateChecker` (deprecated legacy)
- Depends on: Models, AVFoundation, UserNotifications, Sparkle
- Used by: ViewModels, Views

**Extensions:**
- Purpose: Platform API augmentation for display/screen detection
- Location: `Oak/Oak/Extensions/`
- Contains: `NSScreen+DisplayTarget` (screen resolution by target type), `NSScreen+UUID` (persistent display UUID, notch detection via `hasNotch`, `NSScreenUUIDCache`)
- Depends on: AppKit, CoreGraphics
- Used by: Views (`NotchWindowController`), Services (`PresetSettingsStore`)

## Data Flow

**Session Lifecycle (idle → running → paused → completed → next/reset):**
1. User taps Play → `FocusSessionViewModel.startSession()` sets `sessionState = .running`
2. Internal `Timer` fires every 1s → `tick()` decrements `currentRemainingSeconds`, updates `sessionState`
3. At zero → `completeSession()` records progress via `ProgressManager`, sends notification via `NotificationService`, stops audio, sets `sessionState = .completed`
4. User taps Next → `startNextSession()` toggles work/break, resets timer → `.running`
5. User taps Reset → `resetSession()` → `.idle`

**Window Positioning:**
1. `AppDelegate.applicationDidFinishLaunching` creates `NotchWindowController`
2. `NotchWindowController.init` creates `NotchWindow` (borderless `NSPanel`) positioned at screen top/notch
3. Expansion toggle in `NotchCompanionView` calls `onExpansionChanged` closure → `handleExpansionChange` → `requestFrameUpdate` → `setExpanded` resizes/repositions window
4. `PresetSettingsStore.$displayTarget` subscription triggers repositioning on display change

**Audio Playback:**
1. User selects track in `AudioMenuView` → `AudioManager.play(track:)`
2. Attempts bundled `.m4a` file via `AVAudioPlayer` first
3. Falls back to procedural generation via `AVAudioEngine` + `AVAudioSourceNode` with `NoiseGenerator`
4. Session completion → `AudioManager.stop()` halts playback

**State Management:**
- `SessionState` enum with associated values: `.idle`, `.running(remainingSeconds, isWorkSession)`, `.paused(remainingSeconds, isWorkSession)`, `.completed(isWorkSession)`
- Computed properties (`canStart`, `canPause`, `canResume`, `canStartNext`, `displayTime`, `progressPercentage`) derive UI state from `sessionState`
- `PresetSettingsStore` persists all settings to `UserDefaults` with validated ranges
- `ProgressManager` persists `[ProgressData]` as JSON in `UserDefaults`, calculates daily stats and streaks

## Key Abstractions

**SessionState (State Machine):**
- Purpose: Represents all possible states of a focus/break session
- Examples: `Oak/Oak/Models/SessionModels.swift`
- Pattern: Enum with associated values, checked via `if case` pattern matching

**NotchWindow (Custom Window):**
- Purpose: Borderless, floating NSPanel that positions itself at the macOS notch area
- Examples: `Oak/Oak/Views/NotchWindowController.swift`
- Pattern: NSPanel subclass with `.borderless`, `.nonactivatingPanel` style, `.canJoinAllSpaces` collection behavior

**AudioTrack (Audio Identity):**
- Purpose: Enumerate available ambient sound tracks with bundled file mapping
- Examples: `Oak/Oak/Models/AudioTrack.swift`
- Pattern: String-backed enum with computed properties for file names, SF Symbol icons

**SessionCompletionNotifying (Protocol):**
- Purpose: Abstract notification delivery for testability
- Examples: `Oak/Oak/Services/NotificationService.swift`
- Pattern: Protocol with default implementation, injectable in ViewModel init

**SessionCompletionSoundPlaying (Protocol):**
- Purpose: Abstract completion sound for testability
- Examples: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- Pattern: Protocol with `SystemSessionCompletionSoundPlayer` default, injectable

## Entry Points

**App Launch (`OakApp`):**
- Location: `Oak/Oak/OakApp.swift`
- Triggers: macOS app launch
- Responsibilities: Declares SwiftUI `App`, registers `AppDelegate` via `@NSApplicationDelegateAdaptor`, provides `Settings` scene with `SettingsMenuView`

**AppDelegate:**
- Location: `Oak/Oak/OakApp.swift` (lines 33–78)
- Triggers: `applicationDidFinishLaunching`, `applicationWillTerminate`, `applicationDidBecomeActive`
- Responsibilities: Sets activation policy to `.accessory` (no dock icon), creates `NotchWindowController`, initializes `SparkleUpdater`, refreshes notification authorization

**NotchWindowController:**
- Location: `Oak/Oak/Views/NotchWindowController.swift`
- Triggers: Created by `AppDelegate` on launch
- Responsibilities: Creates and manages the notch window, handles expansion/collapse, responds to display configuration changes, owns `FocusSessionViewModel`

## Error Handling

**Strategy:** Graceful degradation with structured logging
**Patterns:**
- Audio failures: `AVAudioPlayer` errors caught and logged via `os.Logger`, falls back to procedural generation; if `AVAudioEngine` fails, playback silently skipped
- Network failures: `SparkleUpdater` and `UpdateChecker` catch all errors, log warnings, do not interrupt user
- Notification failures: `UNUserNotificationCenter` errors logged but not surfaced to user
- Validation: `PresetSettingsStore` clamps all numeric inputs to valid ranges (`validatedWorkMinutes`, `validatedBreakMinutes`)
- Guard clauses: Early returns used extensively (`guard let`, `guard case let`)

## Cross-Cutting Concerns

**Logging:** `os.Logger` with subsystem `com.productsway.oak.app` and per-service categories (`AudioManager`, `NotificationService`, `SparkleUpdater`, `UpdateChecker`)
**Persistence:** `UserDefaults` for all settings (`PresetSettingsStore`) and progress history (`ProgressManager`) — JSON-encoded `[ProgressData]`
**Concurrency:** `@MainActor` on all ViewModels and Services; timer callbacks wrapped in `Task { @MainActor in }`;  `[weak self]` in all escaping closures; timers invalidated in `cleanup()` and `deinit`
**Auto-Updates:** Sparkle 2.6.4+ via SPM, appcast feed at `https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml`, EdDSA signature verification
**Display Adaptation:** Notch detection via `NSScreen.hasNotch` (`safeAreaInsets.top > 0`), dual layout modes (inside-notch vs standard), `NSScreenUUIDCache` for persistent screen identification

---
*Architecture analysis: 2026-02-15*
