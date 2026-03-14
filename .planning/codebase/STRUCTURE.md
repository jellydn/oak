# Codebase Structure

**Analysis Date:** 2026-03-14

## Directory Layout

```
.
├── .build/                    # Build artifacts (not committed)
├── .changeset/                # Changelog management
├── .claude/                   # Claude AI agent configuration
├── .planning/                 # Planning documents
├── .worktrees/                # Git worktree storage
├── assets/                    # Design and branding assets
├── Casks/                     # Homebrew cask definitions
├── doc/                       # Documentation
│   └── adr/                   # Architecture Decision Records
├── docs/                      # Additional documentation
├── Oak/                       # Main app source
│   ├── Oak/                   # App source code
│   │   ├── Extensions/        # Swift extensions
│   │   ├── Models/            # Data models
│   │   ├── Resources/         # Assets, sounds, configs
│   │   ├── Services/          # Business logic services
│   │   ├── ViewModels/        # SwiftUI ViewModels
│   │   ├── Views/             # SwiftUI Views
│   │   └── OakApp.swift       # App entry point
│   ├── Oak.xcodeproj/         # Generated Xcode project
│   ├── Sources/               # SPM packages (not committed)
│   └── Tests/                 # Test source (not actual location)
├── scripts/                   # Build and release scripts
│   ├── ralph/                 # Ralph agent scripts
│   └── release/               # Release automation
└── tasks/                     # Task definitions (PRD, etc.)
```

## Directory Purposes

**Oak/Oak/:**
- Purpose: Main application source code
- Contains: Swift source files, resources, assets
- Key files: `OakApp.swift` (entry point), `project.yml` (XcodeGen config)

**Oak/Oak/Models/:**
- Purpose: Data structures and domain models
- Contains: Session state, audio track definitions, layout models
- Key files: `SessionModels.swift`, `AudioTrack.swift`, `NotchLayout.swift`

**Oak/Oak/Views/:**
- Purpose: SwiftUI view components
- Contains: NotchCompanionView (main UI), settings views, controls
- Key files: `NotchCompanionView.swift`, `SettingsMenuView.swift`, `NotchWindowController.swift`

**Oak/Oak/ViewModels/:**
- Purpose: State management for views
- Contains: FocusSessionViewModel (main coordinator)
- Key files: `FocusSessionViewModel.swift` (360 lines - largest file)

**Oak/Oak/Services/:**
- Purpose: Business logic and external integrations
- Contains: Audio, notifications, settings persistence, updates
- Key files: `AudioManager.swift`, `NotificationService.swift`, `PresetSettingsStore.swift`

**Oak/Oak/Extensions/:**
- Purpose: Swift and system extensions
- Contains: NSScreen extensions for notch detection
- Key files: `NSScreen+UUID.swift`, `NSScreen+DisplayTarget.swift`

**Oak/Tests/OakTests/:**
- Purpose: Unit and integration tests
- Contains: XCTest test cases, organized by user story
- Key files: `NotchCompanionViewTests.swift`, `FocusSessionViewModelTests.swift`

**Casks/:**
- Purpose: Homebrew cask formula for distribution
- Contains: Ruby cask definition

**doc/adr/:**
- Purpose: Architecture Decision Records
- Contains: Markdown files documenting key architectural decisions

## Key File Locations

**Entry Points:**
- `Oak/Oak/OakApp.swift`: Main app entry point, App struct

**Configuration:**
- `Oak/project.yml`: XcodeGen project configuration
- `.swiftlint.yml`: SwiftLint rules and settings
- `Justfile`: Build automation commands

**Core Logic:**
- `Oak/Oak/ViewModels/FocusSessionViewModel.swift`: Main session state machine
- `Oak/Oak/Services/AudioManager.swift`: Audio playback logic
- `Oak/Oak/Services/NotificationService.swift`: Notification handling

**Testing:**
- `Oak/Tests/OakTests/`: All test files (mirrors source structure)
- `Oak/Tests/OakTests/SmokeTests.swift`: Smoke tests

## Naming Conventions

**Files:**
- PascalCase for types: `FocusSessionViewModel.swift`, `NotchCompanionView.swift`
- Extensions use `+` separator: `NotchCompanionView+StandardViews.swift`, `NSScreen+UUID.swift`
- Test files use `Tests` suffix: `NotchCompanionViewTests.swift`

**Directories:**
- PascalCase for feature directories: `Models/`, `Views/`, `Services/`
- kebab-case for tool directories: `scripts/`, `doc/`

## Where to Add New Code

**New Feature (e.g., new timer type):**
- Primary code: `Oak/Oak/ViewModels/NewFeatureViewModel.swift`
- Tests: `Oak/Tests/OakTests/NewFeatureTests.swift`
- Models (if needed): `Oak/Oak/Models/NewFeatureModels.swift`

**New View (e.g., settings panel):**
- Implementation: `Oak/Oak/Views/NewSettingsView.swift`
- View extension: `Oak/Oak/Views/NotchCompanionView+NewFeature.swift` (if extending main view)
- Tests: `Oak/Tests/OakTests/NewSettingsViewTests.swift`

**New Service (e.g., cloud sync):**
- Implementation: `Oak/Oak/Services/CloudSyncService.swift`
- Protocol: `Oak/Oak/Services/CloudSyncProtocol.swift` (for DI)
- Tests: `Oak/Tests/OakTests/CloudSyncServiceTests.swift`

**Utilities:**
- Shared helpers: `Oak/Oak/Extensions/Type+Helper.swift`

## Special Directories

**Oak/.build/:**
- Purpose: SPM build artifacts
- Generated: Yes
- Committed: No (in .gitignore)

**Oak/Oak.xcodeproj/:**
- Purpose: Xcode project file
- Generated: Yes (by XcodeGen)
- Committed: Yes (but can be regenerated)

**.planning/:**
- Purpose: Planning and design documents
- Generated: Partially (by agents)
- Committed: Yes

**.changeset/:**
- Purpose: Changelog and release notes management
- Generated: Partially
- Committed: Yes

---

*Structure analysis: 2026-03-14*
