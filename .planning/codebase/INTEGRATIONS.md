# External Integrations

## Sparkle Update Framework

- **Package**: `sparkle-project/Sparkle` v2.9.4
- **Purpose**: In-app software updates via appcast
- **Integration point**: `Services/SparkleUpdater.swift` — wraps `SPUStandardUpdaterController`
- **Public key**: EdDSA (`IjFqN1R6i4Dh8IZxQ42RtSEii7pUgS45+NvidSwQup0=`)
- **Appcast URL**: `https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml`
- **Check interval**: 86400 seconds (daily)
- **Settings UI**: `Views/UpdateSettingsView.swift` — manual check button, auto-check toggle

## Apple Notification Center

- **Framework**: `UserNotifications`
- **Purpose**: Local notifications for session completion
- **Integration point**: `Services/NotificationService.swift`
- **Requires**: User-granted notification permission (requested from Settings)
- **Settings UI**: `Views/NotificationSettingsView.swift` — permission request button, sound toggle

## Apple System Frameworks (Direct API)

| Framework | Usage | Key Files |
| --- | --- | --- |
| **AppKit** | Window management, NSEvent monitoring, file dialogs | `NotchWindowController.swift`, `KeyboardShortcutService.swift`, `TransientPopover.swift` |
| **AVFoundation** | Ambient audio playback | `AudioManager.swift` |
| **CoreGraphics** | Display identification | `NSScreen+DisplayTarget.swift`, `DisplayConfig.swift` |
| **UserDefaults** | Local persistence (progress, settings, audio prefs) | `ProgressManager.swift`, `PresetSettingsStore.swift` |

## Local Persistence Only

- No cloud sync, no remote database, no account system
- All data stored in `UserDefaults`:
  - `progressHistory` — `[ProgressData]` as JSON
  - `keyboardShortcutConfig` — `KeyboardShortcutConfig` as JSON
  - Various settings keys managed by `SessionDurationConfig`, `DisplayConfig`, `BehaviorConfig`

## No External APIs

- No REST APIs called
- No WebSocket connections
- No third-party analytics or crash reporting
- Network used only for Sparkle appcast fetching (outbound HTTP)
