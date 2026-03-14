# Architecture

**Analysis Date:** 2026-03-14

## Pattern Overview

**Overall:** MVVM (Model-View-ViewModel) with SwiftUI

**Key Characteristics:**
- MainActor-based UI components
- Protocol-oriented design for testability
- FSM (Finite State Machine) for session states
- Combine-based reactive state management
- View composition with extensions

## Layers

**Models Layer:**
- Purpose: Data structures and business logic entities
- Location: `Oak/Oak/Models/`
- Contains: SessionModels, CountdownDisplayMode, ProgressData, NotchLayout, AudioTrack
- Depends on: Foundation
- Used by: ViewModels and Views

**ViewModels Layer:**
- Purpose: State management and business logic coordination
- Location: `Oak/Oak/ViewModels/`
- Contains: FocusSessionViewModel (360 lines - largest file)
- Depends on: Models, Services
- Used by: Views

**Views Layer:**
- Purpose: SwiftUI UI components
- Location: `Oak/Oak/Views/`
- Contains: NotchCompanionView, SettingsMenuView, AudioMenuView, etc.
- Depends on: ViewModels, Models
- Used by: App entry point

**Services Layer:**
- Purpose: Business logic and external integrations
- Location: `Oak/Oak/Services/`
- Contains: AudioManager, NotificationService, PresetSettingsStore, SparkleUpdater, ProgressManager
- Depends on: AVFoundation, Foundation, System APIs
- Used by: ViewModels

## Data Flow

**Session Lifecycle Flow:**
1. User starts session via NotchCompanionView
2. FocusSessionViewModel manages state (idle → running → paused → complete)
3. ProgressManager tracks time and audio
4. AudioManager plays ambient sounds
5. NotificationService delivers completion notification
6. View updates reflect state changes via @Published properties

**State Management:**
- @Published properties in ViewModels drive UI updates
- @MainActor ensures all UI updates on main thread
- Enum with associated values for FSM (SessionState: idle, running, paused)

## Key Abstractions

**SessionCompletionNotifying Protocol:**
- Purpose: Dependency injection for notifications
- Examples: `Oak/Oak/Services/NotificationService.swift`, test mocks
- Pattern: Protocol-based dependency injection for testability

**AudioEngineProtocol:**
- Purpose: Abstraction for audio playback
- Examples: `Oak/Oak/Services/AudioManager.swift`
- Pattern: Protocol for mocking audio in tests

**Notch Layout System:**
- Purpose: Dynamic UI adaptation for notch vs non-notch displays
- Examples: `Oak/Oak/Models/NotchLayout.swift`, `Oak/Oak/Views/NotchCompanionView+InsideNotch.swift`
- Pattern: Computed properties based on display detection

## Entry Points

**OakApp.swift:**
- Location: `Oak/Oak/OakApp.swift`
- Triggers: App launch
- Responsibilities: App lifecycle, initial view setup

**NotchWindowController:**
- Location: `Oak/Oak/Views/NotchWindowController.swift`
- Triggers: Session start, display changes
- Responsibilities: Manages notch panel window, positioning

## Error Handling

**Strategy:** Guard clauses and early returns

**Patterns:**
- Result types for async operations
- Optional handling with guard let
- fatalError for unreachable states (minimal use)

## Cross-Cutting Concerns

**Logging:** os.log for production, print() for debug (with SwiftLint warnings)

**Validation:** User input validation in ViewModels before state changes

**Authentication:** None (local-only app)

**Memory Management:**
- [weak self] in escaping closures
- Timer cleanup in deinit
- AnyCancellable for Combine subscriptions

---

*Architecture analysis: 2026-03-14*
