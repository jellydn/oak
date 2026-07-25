# STRUCTURE.md — Directory Layout & Organization

## Top-Level Layout

```
Oak/                           # XcodeGen root (project.yml lives here)
├── Oak/                       # Main app target sources
│   ├── OakApp.swift          # @main entry point + AppDelegate
│   ├── Models/               # Data models, enums, protocols
│   ├── Views/                # SwiftUI Views + NSWindowController
│   ├── ViewModels/           # @MainActor ObservableObject classes
│   ├── Services/             # Business logic, audio, persistence
│   ├── Extensions/           # NSScreen and other extensions
│   ├── Resources/            # Assets catalog, bundled sounds
│   ├── Info.plist            # App metadata & Sparkle config
│   └── Oak.entitlements      # Sandbox entitlements
├── Tests/                    # Unit test target
│   └── OakTests/             # All test files
├── project.yml               # XcodeGen project definition
└── Oak.xcodeproj/            # Generated Xcode project (do not edit)
```

## Source Files by Directory

### `Oak/Oak/Models/` — Data Models & Enums

| File | Lines | Contents |
| --- | --- | --- |
| `SessionModels.swift` | 69 | `SessionState` enum (FSM), `Preset` enum, `DisplayTarget` enum |
| `ProgressData.swift` | 59 | `SessionType`, `SessionRecord`, `DailyStats` structs (Codable) |
| `AudioTrack.swift` | 45 | `AudioTrack` enum (rain, forest, cafe, brownNoise, lofi, none) |
| `NotchLayout.swift` | 29 | `NotchLayout` enum (width/height constants) |
| `CountdownDisplayMode.swift` | 15 | `CountdownDisplayMode` enum (number, circleRing) |

### `Oak/Oak/Views/` — UI Layer

| File | Lines | Role |
| --- | --- | --- |
| `NotchWindowController.swift` | 317 | Window lifecycle, frame management, screen change handling |
| `SettingsMenuView.swift` | 334 | Settings popover (preset config, display, notifications, updates) |
| `NotchCompanionView+StandardViews.swift` | 285 | Expanded/collapsed view layouts for non-notch displays |
| `NotchCompanionView+InsideNotch.swift` | 257 | Layout variants for inside-physical-notch displays |
| `NotchCompanionView+Controls.swift` | 189 | Audio/Progress/Settings buttons, timer display, session controls |
| `NotchCompanionView.swift` | 158 | Root view composing all layouts, popovers, completion animations |
| `ProgressMenuView.swift` | 140 | Progress & streak display popover |
| `TransientPopover.swift` | 77 | Click-outside-to-dismiss popover modifier |
| `NotificationSettingsView.swift` | 67 | Notification permission management in Settings |
| `AudioMenuView.swift` | 66 | Audio track selection & volume control popover |
| `ConfettiView.swift` | 65 | Confetti animation on work session completion |
| `UpdateSettingsView.swift` | 41 | Sparkle update check & auto-download settings |
| `CircularProgressRing.swift` | 39 | Circular progress indicator for countdown |
| `NotchVisualStyle+Factory.swift` | 22 | Factory for visual style based on inside-notch state |
| `NotchVisualStyle.swift` | 15 | Visual style constants (colors, corner radius) |
| `SupportSectionView.swift` | 19 | Support/feedback links in Settings |

### `Oak/Oak/ViewModels/` — View Models

| File | Lines | Role |
| --- | --- | --- |
| `FocusSessionViewModel.swift` | 415 | Core session management, FSM transitions, timer, auto-start |

### `Oak/Oak/Services/` — Business Logic

| File                        | Lines | Role                                                    |
| --------------------------- | ----- | ------------------------------------------------------- |
| `AudioManager.swift`        | 374   | Audio playback (bundled + procedural), `NoiseGenerator` |
| `PresetSettingsStore.swift` | 311   | UserDefaults-backed settings with validation            |
| `SparkleUpdater.swift`      | 219   | Sparkle integration, `AppcastVersionParser`             |
| `ProgressManager.swift`     | 163   | Daily stats, streaks, session recording                 |
| `NotificationService.swift` | 101   | Local notification authorization & delivery             |

### `Oak/Oak/Extensions/` — Swift Extensions

| File                           | Lines | Role                                              |
| ------------------------------ | ----- | ------------------------------------------------- |
| `NSScreen+UUID.swift`          | 82    | Screen UUID caching, notch detection (`hasNotch`) |
| `NSScreen+DisplayTarget.swift` | 62    | Screen resolution for display targets             |

### `Oak/Tests/OakTests/` — Test Suite

| File | Lines | Focus |
| --- | --- | --- |
| `US006Tests.swift` | ~270 | Progress tracking & streaks |
| `LongBreakTests.swift` | ~300 | Long break logic and round tracking |
| `US004Tests.swift` | ~190 | Audio selection, volume, display target |
| `SessionCompletionNotificationTests.swift` | ~220 | Notification & sound on session completion |
| `NotchWindowControllerTests+WindowBehavior.swift` | ~180 | Window expand/collapse, reposition |
| `AudioPersistenceTests.swift` | ~245 | Audio track persistence across sessions |
| `AutoStartNextIntervalTests.swift` | ~260 | Auto-start countdown logic |
| `US003Tests.swift` | ~100 | Pause/resume session |
| `US001Tests.swift` | ~75 | Notch visibility, session start |
| `US002Tests.swift` | ~50 | Preset selection |
| `US005Tests.swift` | ~80 | Session completion state |
| `NotchCompanionViewTests.swift` | ~50 | View initialization |
| `NotchCompanionViewTests+SessionState.swift` | ~110 | State transitions |
| `NotchCompanionViewTests+Layout.swift` | ~30 | Layout tests |
| `NotchWindowControllerTests.swift` | ~60 | Window creation |
| `NotchWindowControllerTests+NotchWindow.swift` | ~20 | Window positioning |
| `NotchWindowControllerTests+NotchFirstUI.swift` | ~110 | Notch-first positioning |
| `AlwaysOnTopTests.swift` | ~100 | Always-on-top setting |
| `CountdownDisplayModeTests.swift` | ~60 | Display mode persistence |
| `AudioManagerTests.swift` | ~130 | Audio engine tests |
| `NotificationTests.swift` | ~35 | Notification service |
| `AccessibilityTests.swift` | ~30 | Accessibility |
| `SparkleUpdaterTests.swift` | ~10 | Sparkle updater |
| `ConfettiViewTests.swift` | ~15 | Confetti view |
| `ClickOutsideModifierTests.swift` | ~15 | Click-outside dismiss |
| `AppcastVersionParserTests.swift` | ~10 | Appcast version parsing |
| `NSScreenNotchTests.swift` | ~10 | Notch detection |
| `SmokeTests.swift` | ~5 | Sanity check |
| `MockAudioManager.swift` | N/A | Audio manager mock |

## Naming Conventions

| Pattern         | Example                                              |
| --------------- | ---------------------------------------------------- |
| View files      | `NotchCompanionView.swift`, `SettingsMenuView.swift` |
| View extensions | `NotchCompanionView+InsideNotch.swift`               |
| ViewModel files | `FocusSessionViewModel.swift`                        |
| Service files   | `AudioManager.swift`, `ProgressManager.swift`        |
| Model files     | `SessionModels.swift`, `ProgressData.swift`          |
| Extension files | `NSScreen+UUID.swift`                                |
| Test files      | `US001Tests.swift`, `AudioManagerTests.swift`        |
| Test extensions | `NotchWindowControllerTests+WindowBehavior.swift`    |
| Protocol names  | `SessionCompletionNotifying`, `AudioEngineProtocol`  |
