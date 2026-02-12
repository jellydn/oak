# Architecture

**Analysis Date:** 2026-02-13

## Pattern Overview
**Overall:** MVVM (Model-View-ViewModel)
**Key Characteristics:**
- Single `@MainActor` ViewModel (`FocusSessionViewModel`) owns all session logic and coordinates services
- Enum-based finite state machine (`SessionState`) drives UI reactivity via `@Published` properties
- Services layer (`AudioManager`, `ProgressManager`, `UpdateChecker`) encapsulates side effects (audio, persistence, networking)
- Notch-anchored window managed by AppKit (`NotchWindowController` / `NotchWindow`) hosting SwiftUI views via `NSHostingView`
- No third-party dependencies; built entirely on Apple frameworks (SwiftUI, AVFoundation, AppKit)

## Layers
**Models:**
- Purpose: Define domain types, enums, and value objects
- Location: `Oak/Oak/Models/`
- Contains: `SessionState` enum (FSM), `Preset` enum, `AudioTrack` enum, `ProgressData` struct, `DailyStats` struct
- Depends on: Foundation
- Used by: ViewModels, Services, Views

**ViewModels:**
- Purpose: Manage session state, timer logic, and expose computed properties for the UI
- Location: `Oak/Oak/ViewModels/`
- Contains: `FocusSessionViewModel` (`@MainActor ObservableObject`)
- Depends on: Models, Services (`AudioManager`, `ProgressManager`)
- Used by: Views (`NotchCompanionView`)

**Views:**
- Purpose: Render notch-based UI and handle user interactions
- Location: `Oak/Oak/Views/`
- Contains: `NotchCompanionView` (SwiftUI), `AudioMenuView`, `ProgressMenuView`, `NotchWindowController` (AppKit), `NotchWindow` (NSPanel)
- Depends on: ViewModels, Models
- Used by: `AppDelegate` (via `NotchWindowController`)

**Services:**
- Purpose: Encapsulate business logic and external interactions (audio playback, data persistence, update checking)
- Location: `Oak/Oak/Services/`
- Contains: `AudioManager` (AVAudioEngine-based ambient sound generation), `ProgressManager` (UserDefaults persistence), `UpdateChecker` (GitHub API)
- Depends on: Models, Foundation, AVFoundation, AppKit
- Used by: ViewModels

**App Entry:**
- Purpose: Bootstrap the application and wire the object graph
- Location: `Oak/Oak/OakApp.swift`
- Contains: `OakApp` (@main), `AppDelegate` (NSApplicationDelegate)
- Depends on: Views (`NotchWindowController`), Services (`UpdateChecker`)
- Used by: System (launch point)

## Data Flow
**Session Lifecycle (idle → running → paused → completed → idle):**
1. User taps Play in `NotchCompanionView` → calls `viewModel.startSession(using:)`
2. `FocusSessionViewModel` sets `sessionState = .running(...)`, starts `Timer.scheduledTimer`
3. Timer fires `tick()` every 1s → decrements `currentRemainingSeconds` → updates `sessionState` (`@Published`)
4. SwiftUI re-renders `NotchCompanionView` reactively via `@StateObject` observation
5. On completion, `completeSession()` records progress via `ProgressManager`, stops audio via `AudioManager`, sets `.completed`
6. User can `startNextSession()` (toggles work/break) or `resetSession()` (back to `.idle`)

**Audio Playback:**
1. User selects track in `AudioMenuView` popover → calls `audioManager.play(track:)`
2. `AudioManager` creates `AVAudioEngine` + `AVAudioSourceNode` with procedural noise generation
3. Volume controlled via `@Published var volume` bound to `Slider`

**Progress Persistence:**
1. `ProgressManager.recordSessionCompletion()` loads `[ProgressData]` from UserDefaults
2. Updates or appends today's record, encodes back to UserDefaults
3. `dailyStats` recomputed (today's minutes, sessions, streak)

**State Management:**
- `SessionState` is an enum with associated values — pattern-matched throughout ViewModel and Views
- Computed properties (`canStart`, `canPause`, `canResume`, `canStartNext`, `displayTime`) derive from `sessionState`
- State transitions are explicit and centralized in `FocusSessionViewModel`

## Key Abstractions
**SessionState (Finite State Machine):**
- Purpose: Represents all valid states of a focus session
- Examples: `Oak/Oak/Models/SessionModels.swift`
- Pattern: Enum with associated values (`.idle`, `.running(remainingSeconds:isWorkSession:)`, `.paused(...)`, `.completed(...)`)

**Preset:**
- Purpose: Encapsulates timer durations for work/break intervals
- Examples: `Oak/Oak/Models/SessionModels.swift`
- Pattern: Enum with computed properties (`workDuration`, `breakDuration`, `displayName`)

**AudioTrack:**
- Purpose: Represents available ambient sound types
- Examples: `Oak/Oak/Models/AudioTrack.swift`
- Pattern: RawRepresentable enum, CaseIterable for menu iteration

**NotchWindow (NSPanel):**
- Purpose: Borderless floating panel anchored to macOS notch area
- Examples: `Oak/Oak/Views/NotchWindowController.swift`
- Pattern: Custom NSPanel with `.nonactivatingPanel` style, `.canJoinAllSpaces` behavior

## Entry Points
**OakApp (@main):**
- Location: `Oak/Oak/OakApp.swift`
- Triggers: macOS app launch
- Responsibilities: Registers `AppDelegate` via `@NSApplicationDelegateAdaptor`, provides empty `Settings` scene

**AppDelegate.applicationDidFinishLaunching:**
- Location: `Oak/Oak/OakApp.swift`
- Triggers: App finish launching (skipped during XCTest runs)
- Responsibilities: Sets activation policy to `.accessory` (no dock icon), creates `NotchWindowController`, triggers `UpdateChecker`

**NotchWindow right-click menu:**
- Location: `Oak/Oak/Views/NotchWindowController.swift`
- Triggers: Right-click on notch window
- Responsibilities: Shows context menu with "Quit Oak" option

## Error Handling
**Strategy:** Defensive with silent fallback — errors are logged but do not surface to users
**Patterns:**
- `guard let` / early returns for nil-safety (e.g., `guard let window`, `guard let data`)
- `try?` for non-critical decoding/encoding (progress persistence)
- `do/catch` with `print()` for audio engine failures
- `os.Logger` for production logging in `UpdateChecker`
- Network errors caught and logged without user notification
- Test environment detection via `ProcessInfo` to skip UI initialization

## Cross-Cutting Concerns
**Logging:** `os.Logger` in `UpdateChecker`; `print()` in `AudioManager` for debug
**Validation:** Computed boolean guards (`canStart`, `canPause`, `canResume`) prevent invalid state transitions
**Authentication:** None — no user accounts, local-only app
**Concurrency:** `@MainActor` enforced on all ViewModels and Services; `Timer` callbacks wrapped in `Task { @MainActor in }` for thread safety
**Persistence:** `UserDefaults` with JSON-encoded `[ProgressData]` — no database or cloud sync
**Window Management:** `NotchWindowController` handles expand/collapse by repositioning `NSPanel` frame centered on screen

---
*Architecture analysis: 2026-02-13*
