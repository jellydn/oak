# Codebase Structure

**Analysis Date:** 2026-02-13

## Directory Layout
```
oak/
├── Oak/                        # Xcode project root
│   ├── Oak/                    # Application source code
│   │   ├── Models/             # Domain types, enums, value objects
│   │   ├── Views/              # SwiftUI views + AppKit window controllers
│   │   ├── ViewModels/         # ObservableObject view models
│   │   ├── Services/           # Business logic (audio, persistence, updates)
│   │   ├── Resources/          # Asset catalogs
│   │   ├── OakApp.swift        # @main entry point + AppDelegate
│   │   └── Oak.entitlements    # App entitlements (empty)
│   ├── Sources/Oak/            # SPM source target (empty, unused)
│   ├── Tests/OakTests/         # XCTest unit tests
│   ├── Oak.xcodeproj/          # Generated Xcode project
│   ├── Package.swift           # Swift Package Manager manifest
│   └── project.yml             # XcodeGen project definition
├── doc/adr/                    # Architecture Decision Records
├── tasks/                      # PRD and planning documents
├── scripts/                    # Build/release automation
│   ├── ralph/                  # Ralph agent scripts
│   └── release/                # Release tooling
├── assets/                     # Project assets (icons, etc.)
├── .planning/codebase/         # Architecture analysis documents
├── .github/                    # GitHub workflows and config
├── AGENTS.md                   # Agent guidelines
├── justfile                    # Task runner commands
└── README.md                   # Project documentation
```

## Directory Purposes
**Oak/Oak/Models/:**
- Purpose: Domain model types shared across layers
- Contains: Enums (`SessionState`, `Preset`, `AudioTrack`), structs (`ProgressData`, `DailyStats`)
- Key files: `SessionModels.swift`, `AudioTrack.swift`, `ProgressData.swift`

**Oak/Oak/Views/:**
- Purpose: UI layer — SwiftUI views and AppKit window management
- Contains: Main notch view, popover menus, window controller, custom NSPanel
- Key files: `NotchCompanionView.swift` (main UI + `AudioMenuView` + `ProgressMenuView`), `NotchWindowController.swift` (`NotchWindowController` + `NotchWindow`)

**Oak/Oak/ViewModels/:**
- Purpose: State management and business logic coordination
- Contains: Single ViewModel handling all session state, timer, and service orchestration
- Key files: `FocusSessionViewModel.swift`

**Oak/Oak/Services/:**
- Purpose: Side-effect services isolated from UI
- Contains: Audio engine management, progress persistence, GitHub update checking
- Key files: `AudioManager.swift`, `ProgressManager.swift`, `UpdateChecker.swift`

**Oak/Oak/Resources/:**
- Purpose: Static assets for the application
- Contains: `Assets.xcassets/` (app icons, colors)
- Key files: `Assets.xcassets/`

**Oak/Tests/OakTests/:**
- Purpose: Unit tests organized by user story
- Contains: XCTest classes testing ViewModel state transitions, session logic, audio, progress
- Key files: `US001Tests.swift` through `US006Tests.swift`, `SmokeTests.swift`

**doc/adr/:**
- Purpose: Architecture Decision Records
- Contains: Markdown ADR documents
- Key files: `0001-notch-first-kiss-mvp.md`

## Key File Locations
**Entry Points:**
- `Oak/Oak/OakApp.swift`: `@main` app struct + `AppDelegate` — bootstraps window and update checker

**Configuration:**
- `Oak/project.yml`: XcodeGen project definition (targets, settings, deployment target)
- `Oak/Package.swift`: SPM manifest (macOS 13+, Swift 5.9)
- `Oak/Oak/Oak.entitlements`: App sandbox entitlements (currently empty)
- `justfile`: Task runner for build, test, clean commands

**Core Logic:**
- `Oak/Oak/ViewModels/FocusSessionViewModel.swift`: Session FSM, timer, service coordination
- `Oak/Oak/Models/SessionModels.swift`: `SessionState` enum + `Preset` enum
- `Oak/Oak/Services/AudioManager.swift`: Procedural ambient sound via AVAudioEngine
- `Oak/Oak/Services/ProgressManager.swift`: UserDefaults-backed daily stats persistence

**Testing:**
- `Oak/Tests/OakTests/US001Tests.swift`: Notch visibility, session start, preset display
- `Oak/Tests/OakTests/US002Tests.swift` – `US006Tests.swift`: User story acceptance tests
- `Oak/Tests/OakTests/SmokeTests.swift`: Basic sanity check

## Naming Conventions
**Files:**
- Models: Singular noun (`SessionModels.swift`, `AudioTrack.swift`, `ProgressData.swift`)
- Views: Descriptive noun with View/Controller suffix (`NotchCompanionView.swift`, `NotchWindowController.swift`)
- ViewModels: Feature + ViewModel suffix (`FocusSessionViewModel.swift`)
- Services: Feature + Manager/Checker suffix (`AudioManager.swift`, `ProgressManager.swift`, `UpdateChecker.swift`)
- Tests: User story prefix `US00N` or descriptive suffix `Tests` (`US001Tests.swift`, `SmokeTests.swift`)

**Directories:**
- PascalCase plural for layer folders (`Models/`, `Views/`, `ViewModels/`, `Services/`)
- PascalCase for `Resources/`

## Where to Add New Code
**New Feature:**
- Primary code: `Oak/Oak/ViewModels/` (new ViewModel or extend `FocusSessionViewModel`)
- Tests: `Oak/Tests/OakTests/` (new `US00NTests.swift` or feature-specific test file)

**New Component/Module:**
- Model types: `Oak/Oak/Models/`
- SwiftUI views: `Oak/Oak/Views/`
- Service/manager: `Oak/Oak/Services/`

**Utilities:**
- Shared helpers: `Oak/Oak/Services/` (no dedicated Utils directory exists; services act as the helper layer)

## Special Directories
**Oak/Oak.xcodeproj/:**
- Purpose: Xcode project files (generated by XcodeGen)
- Generated: Yes (via `xcodegen generate` from `project.yml`)
- Committed: Yes

**Oak/Sources/Oak/:**
- Purpose: SPM executable target source directory
- Generated: No
- Committed: Yes (empty — app sources live in `Oak/Oak/` for XcodeGen compatibility)

**.planning/codebase/:**
- Purpose: Architecture analysis and codebase documentation
- Generated: Yes (by analysis tooling)
- Committed: Yes

**Oak/.build/:**
- Purpose: SPM build artifacts
- Generated: Yes
- Committed: No (gitignored)

---
*Structure analysis: 2026-02-13*
