# Directory Structure

```
Oak/
├── Oak/                          # Main application target
│   ├── OakApp.swift              # @main entry point + AppDelegate
│   ├── Info.plist                # App metadata, LSUIElement, Sparkle config
│   ├── Oak.entitlements          # Network client entitlement
│   │
│   ├── Models/                   # Data models (value types, enums)
│   │   ├── SessionModels.swift   # SessionState (FSM), Preset, SessionType
│   │   ├── ProgressData.swift    # ProgressData, SessionRecord, DailyStats
│   │   ├── AudioTrack.swift      # Ambient audio track enum
│   │   ├── NotchLayout.swift     # Layout constants (height, sizing)
│   │   └── CountdownDisplayMode.swift
│   │
│   ├── ViewModels/               # ViewModels (@MainActor, ObservableObject)
│   │   └── FocusSessionViewModel.swift  # 373 lines — session lifecycle
│   │
│   ├── Views/                    # SwiftUI Views
│   │   ├── NotchCompanionView.swift          # 351 lines — main notch UI
│   │   ├── NotchCompanionView+StandardViews.swift  # 282 lines
│   │   ├── NotchCompanionView+InsideNotch.swift     # 259 lines
│   │   ├── NotchWindowController.swift      # 255 lines — NSPanel management
│   │   ├── WindowPositioning.swift          # 90 lines — frame math
│   │   ├── SettingsMenuView.swift           # 341 lines — settings panel
│   │   ├── PresetEditorView.swift           # 82 lines — stepper controls
│   │   ├── ProgressMenuView.swift           # 140 lines — daily stats
│   │   ├── AudioMenuView.swift              # Ambient track picker
│   │   ├── CircularProgressRing.swift       # Progress indicator
│   │   ├── ConfettiView.swift               # Session completion effect
│   │   ├── TransientPopover.swift           # Click-outside dismiss
│   │   ├── NotificationSettingsView.swift   # Notification permission UI
│   │   ├── UpdateSettingsView.swift         # Sparkle update controls
│   │   ├── SupportSectionView.swift         # Links and support info
│   │   ├── NotchVisualStyle.swift           # Visual theming
│   │   └── NotchVisualStyle+Factory.swift   # Style factory
│   │
│   ├── Services/                 # Business logic & persistence
│   │   ├── AudioManager.swift             # 328 lines — AVAudioPlayer
│   │   ├── ProgressManager.swift          # 163 lines — UserDefaults persistence
│   │   ├── PresetSettingsStore.swift      # 261 lines — all settings
│   │   ├── SessionTimerService.swift      # 108 lines — Timer-based countdown
│   │   ├── NotificationService.swift      # 101 lines — UserNotifications
│   │   ├── SparkleUpdater.swift           # 219 lines — update framework
│   │   ├── KeyboardShortcutService.swift  # 258 lines — NSEvent monitoring
│   │   ├── NoiseGenerator.swift           # White/brown noise generator
│   │   ├── SessionDurationConfig.swift    # 136 lines — duration settings
│   │   ├── DisplayConfig.swift            # 108 lines — display settings
│   │   └── BehaviorConfig.swift           # Behavior settings
│   │
│   ├── Extensions/               # Swift extensions
│   │   ├── NSScreen+UUID.swift            # Display UUID tracking
│   │   └── NSScreen+DisplayTarget.swift   # Screen matching & notch detection
│   │
│   └── Resources/                # Assets
│       ├── Assets.xcassets/      # App icon
│       └── Sounds/               # Built-in ambient audio (m4a)
│           ├── ambient_rain.m4a
│           ├── ambient_forest.m4a
│           ├── ambient_cafe.m4a
│           ├── ambient_lofi.m4a
│           └── ambient_brown_noise.m4a
│
├── Tests/OakTests/               # 29 test files
│   ├── US001Tests.swift through US006Tests.swift  # Feature-level tests
│   ├── NotchCompanionViewTests.swift (+Layout, +SessionState)
│   ├── NotchWindowControllerTests.swift (+NotchWindow, +WindowBehavior, +NotchFirstUI)
│   ├── AudioManagerTests.swift, AudioPersistenceTests.swift
│   ├── AccessibilityTests.swift
│   ├── ConfettiViewTests.swift, ClickOutsideModifierTests.swift
│   ├── CountdownDisplayModeTests.swift
│   ├── AlwaysOnTopTests.swift
│   ├── LongBreakTests.swift
│   ├── AutoStartNextIntervalTests.swift
│   ├── NotificationTests.swift, SessionCompletionNotificationTests.swift
│   ├── SparkleUpdaterTests.swift, AppcastVersionParserTests.swift
│   ├── NSScreenNotchTests.swift
│   ├── SmokeTests.swift
│   └── MockAudioManager.swift
│
├── project.yml                  # XcodeGen configuration
├── justfile                     # Task runner
├── .swiftlint.yml               # Lint rules
├── .swiftformat                 # Format rules
├── appcast.xml                  # Sparkle release feed
├── CHANGELOG.md                 # Release history
├── README.md                    # Project readme
├── DEVELOPMENT.md               # Developer setup guide
├── CONTEXT.md                   # Codebase context
├── TROUBLESHOOTING.md           # Common issues
├── AGENTS.md                    # AI agent guidelines
├── RELEASES.md                  # Release notes
├── LICENSE                      # MIT license
│
├── .planning/codebase/          # Codebase map (these docs)
├── .github/workflows/           # CI/CD pipelines
├── scripts/release/             # Release asset scripts
├── docs/                        # GitHub Pages site
├── Casks/                       # Homebrew cask formula
└── tasks/                       # PRD documents
```

## File Line Counts (Largest 10)

| File                                     | Lines |
| ---------------------------------------- | ----- |
| `FocusSessionViewModel.swift`            | 373   |
| `NotchCompanionView.swift`               | 351   |
| `SettingsMenuView.swift`                 | 341   |
| `AudioManager.swift`                     | 328   |
| `NotchCompanionView+StandardViews.swift` | 282   |
| `PresetSettingsStore.swift`              | 261   |
| `NotchCompanionView+InsideNotch.swift`   | 259   |
| `KeyboardShortcutService.swift`          | 258   |
| `NotchWindowController.swift`            | 255   |
| `SparkleUpdater.swift`                   | 219   |

## Naming Conventions

- **Files**: PascalCase, mirroring primary type name
- **Extensions**: `TypeName+Feature.swift` (e.g., `NotchCompanionView+Controls.swift`)
- **Tests**: `{Feature}Tests.swift` or `{Feature}Tests+{Aspect}.swift`
- **Directories**: Models, Views, ViewModels, Services, Extensions, Resources
