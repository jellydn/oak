# Codebase Structure

**Analysis Date:** 2026-02-15

## Directory Layout
```
oak/
├── Oak/                            # Xcode project root
│   ├── Oak/                        # Main app source
│   │   ├── Extensions/             # AppKit/CoreGraphics extensions
│   │   ├── Models/                 # Data models, enums, constants
│   │   ├── Resources/              # Assets and bundled files
│   │   │   ├── Assets.xcassets/     # App icons and image assets
│   │   │   └── Sounds/             # Bundled ambient audio tracks (.m4a)
│   │   ├── Services/               # Business logic and system integrations
│   │   ├── ViewModels/             # ObservableObject classes
│   │   ├── Views/                  # SwiftUI views and AppKit window management
│   │   ├── Info.plist              # App configuration (Sparkle, LSUIElement)
│   │   ├── Oak.entitlements        # App sandbox entitlements
│   │   └── OakApp.swift            # @main entry point and AppDelegate
│   ├── Oak.xcodeproj/              # Generated Xcode project (via XcodeGen)
│   ├── Tests/                      # Test target
│   │   └── OakTests/               # Unit test files
│   ├── .gitignore                  # Xcode-specific ignores
│   └── project.yml                 # XcodeGen project definition
├── doc/                            # Documentation
│   └── adr/                        # Architecture Decision Records
├── docs/                           # GitHub Pages / public docs
├── tasks/                          # PRDs and feature specifications
├── scripts/                        # Build/release automation
│   ├── ralph/                      # Ralph agent scripts
│   ├── release/                    # Release automation
│   └── check-ambient-sounds.sh     # Sound file validator
├── assets/                         # Project assets (screenshots, etc.)
├── Casks/                          # Homebrew Cask formula
├── .github/                        # GitHub Actions workflows
│   └── workflows/                  # CI/CD pipeline definitions
├── .planning/                      # Planning documents
├── .swiftformat                    # SwiftFormat configuration
├── .swiftlint.yml                  # SwiftLint rules
├── appcast.xml                     # Sparkle update feed
├── justfile                        # Task runner commands
├── AGENTS.md                       # Agent coding guidelines
├── CLAUDE.md                       # Claude AI context
└── README.md                       # Project documentation
```

## Directory Purposes

**`Oak/Oak/Models/`:**
- Purpose: Pure data types, enums, and layout constants
- Contains: Swift enums (`SessionState`, `Preset`, `DisplayTarget`, `AudioTrack`, `CountdownDisplayMode`), structs (`ProgressData`, `DailyStats`), constants (`NotchLayout`)
- Key files: `SessionModels.swift`, `AudioTrack.swift`, `NotchLayout.swift`, `ProgressData.swift`

**`Oak/Oak/ViewModels/`:**
- Purpose: Session state machine and timer logic
- Contains: Single ViewModel class
- Key files: `FocusSessionViewModel.swift`

**`Oak/Oak/Views/`:**
- Purpose: All UI code — SwiftUI views and AppKit window management
- Contains: Main view with extensions split by concern, window controller, visual styling, reusable components, popover menus
- Key files: `NotchCompanionView.swift`, `NotchWindowController.swift`, `NotchVisualStyle.swift`, `SettingsMenuView.swift`

**`Oak/Oak/Services/`:**
- Purpose: System integrations and business logic decoupled from UI
- Contains: Audio engine, settings persistence, progress tracking, notifications, auto-updates
- Key files: `AudioManager.swift`, `PresetSettingsStore.swift`, `ProgressManager.swift`, `NotificationService.swift`, `SparkleUpdater.swift`

**`Oak/Oak/Extensions/`:**
- Purpose: Platform API extensions for display detection and identification
- Contains: NSScreen extensions for display target resolution, UUID generation, notch detection
- Key files: `NSScreen+DisplayTarget.swift`, `NSScreen+UUID.swift`

**`Oak/Oak/Resources/Sounds/`:**
- Purpose: Bundled ambient audio tracks for focus sessions
- Contains: 5 `.m4a` files (`ambient_rain.m4a`, `ambient_forest.m4a`, `ambient_cafe.m4a`, `ambient_brown_noise.m4a`, `ambient_lofi.m4a`)
- Key files: `README.md` (sound file documentation)

**`Oak/Tests/OakTests/`:**
- Purpose: Unit tests for all layers
- Contains: 21 test files covering ViewModels, Views, Services, and user stories
- Key files: `US001Tests.swift`–`US006Tests.swift` (user story tests), `NotchWindowControllerTests.swift` (split across 3 files)

## Key File Locations

**Entry Points:**
- `Oak/Oak/OakApp.swift`: `@main` app struct + `AppDelegate` — creates window controller, initializes services
- `Oak/project.yml`: XcodeGen project definition — targets, dependencies, build settings

**Configuration:**
- `Oak/Oak/Info.plist`: App metadata, `LSUIElement` (accessory app), Sparkle feed URL, EdDSA public key
- `Oak/Oak/Oak.entitlements`: App sandbox permissions
- `.swiftlint.yml`: SwiftLint rules and opt-in rules
- `.swiftformat`: SwiftFormat configuration
- `justfile`: Task runner with build, test, lint, format commands

**Core Logic:**
- `Oak/Oak/ViewModels/FocusSessionViewModel.swift`: Session state machine, timer, work/break cycling, long break logic
- `Oak/Oak/Services/PresetSettingsStore.swift`: All user preferences with UserDefaults persistence
- `Oak/Oak/Services/AudioManager.swift`: Audio playback — bundled files + procedural generation
- `Oak/Oak/Services/ProgressManager.swift`: Session history, daily stats, streak calculation
- `Oak/Oak/Models/SessionModels.swift`: `SessionState` enum, `Preset` enum, `DisplayTarget` enum

**Testing:**
- `Oak/Tests/OakTests/US001Tests.swift`–`US006Tests.swift`: User story acceptance tests
- `Oak/Tests/OakTests/NotchWindowControllerTests.swift`: Window controller tests (+ 3 extension files)
- `Oak/Tests/OakTests/SparkleUpdaterTests.swift`: Auto-update tests
- `Oak/Tests/OakTests/CountdownDisplayModeTests.swift`: Display mode tests
- `Oak/Tests/OakTests/LongBreakTests.swift`: Long break session logic

## Naming Conventions

**Files:**
- Views: PascalCase with `View` suffix — `NotchCompanionView.swift`, `SettingsMenuView.swift`
- View extensions: `ViewName+Feature.swift` — `NotchCompanionView+Controls.swift`, `NotchCompanionView+InsideNotch.swift`
- ViewModels: `FeatureViewModel.swift` — `FocusSessionViewModel.swift`
- Services: PascalCase describing responsibility — `AudioManager.swift`, `PresetSettingsStore.swift`
- Models: PascalCase describing data — `SessionModels.swift`, `AudioTrack.swift`
- Extensions: `Type+Feature.swift` — `NSScreen+DisplayTarget.swift`, `NSScreen+UUID.swift`
- Tests: `FeatureTests.swift` or `USxxxTests.swift` — `SmokeTests.swift`, `US001Tests.swift`
- Bundled audio: `ambient_trackname.m4a` — `ambient_rain.m4a`, `ambient_lofi.m4a`

**Directories:**
- PascalCase for source directories: `Models/`, `Views/`, `ViewModels/`, `Services/`, `Extensions/`, `Resources/`
- lowercase for project-level directories: `doc/`, `docs/`, `tasks/`, `scripts/`, `assets/`

**Code:**
- Types: PascalCase — `FocusSessionViewModel`, `NotchWindowController`
- Properties/methods: camelCase — `sessionState`, `startSession()`
- Booleans: `is`/`has`/`can`/`should` prefix — `isWorkSession`, `canStart`, `hasNotch`
- Singletons: `.shared` static property — `PresetSettingsStore.shared`, `NotificationService.shared`
- UserDefaults keys: dot-delimited strings — `"preset.short.workMinutes"`, `"session.roundsBeforeLongBreak"`

## Where to Add New Code

**New Feature:**
- Primary code: `Oak/Oak/ViewModels/` (logic), `Oak/Oak/Views/` (UI)
- Tests: `Oak/Tests/OakTests/`

**New Service:**
- Implementation: `Oak/Oak/Services/`
- Protocol: Define in the service file or `Oak/Oak/Models/` if shared

**New Model:**
- Implementation: `Oak/Oak/Models/`

**New View Component:**
- Implementation: `Oak/Oak/Views/`
- Use extensions (`+Feature.swift`) to split large views by concern

**New Extension:**
- Implementation: `Oak/Oak/Extensions/`
- Follow `Type+Feature.swift` naming

**New Audio Track:**
- Audio file: `Oak/Oak/Resources/Sounds/` (as `.m4a`)
- Enum case: `Oak/Oak/Models/AudioTrack.swift`
- Generator: `Oak/Oak/Services/AudioManager.swift` (add noise generator method)

## Special Directories

**`Oak/Oak.xcodeproj/`:**
- Purpose: Xcode project files generated by XcodeGen
- Generated: Yes (from `Oak/project.yml`)
- Committed: Yes

**`.planning/`:**
- Purpose: Architecture analysis and planning documents
- Generated: No (manual)
- Committed: Yes

**`doc/adr/`:**
- Purpose: Architecture Decision Records (numbered: `0001-*.md`, `0002-*.md`)
- Generated: No (manual)
- Committed: Yes

**`.github/workflows/`:**
- Purpose: CI/CD pipeline definitions (GitHub Actions)
- Generated: No
- Committed: Yes

**`Casks/`:**
- Purpose: Homebrew Cask formula for distribution
- Generated: No
- Committed: Yes

**`scripts/`:**
- Purpose: Build automation, release scripts, sound validation
- Generated: No
- Committed: Yes

---
*Structure analysis: 2026-02-15*
