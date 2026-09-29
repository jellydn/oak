# Development Guide

This guide covers everything you need to know for developing Oak.

## Prerequisites

- macOS 13+ (Apple Silicon recommended)
- XcodeGen (`brew install xcodegen`) - for building from source
- SwiftLint (optional, for code linting: `brew install swiftlint`)
- SwiftFormat (optional, for code formatting: `brew install swiftformat`)

## Building from Source

```bash
# Clone the repository
git clone https://github.com/jellydn/oak.git
cd oak

# Generate Xcode project
cd Oak && xcodegen generate

# Build and run
open Oak.xcodeproj
```

## Build Commands

We use [just](https://github.com/casey/just) for task automation. Here are the available commands:

```bash
# Show available commands
just

# Build the project
just build

# Build release version
just build-release

# Run all tests
just test

# Run tests with verbose output
just test-verbose

# Run a specific test class
just test-class FocusSessionViewModelTests

# Run a specific test method
just test-method FocusSessionViewModelTests testStartSession

# Check for compilation errors
just check

# Clean build artifacts
just clean

# Open in Xcode
just open

# Validate bundled ambient sound files
just check-sounds
```

## iOS App

The `OakIOS` target is a native iOS 16+ first version with the two Oak presets, pause and resume, work/break cycles, built-in ambient audio, completion notifications, and local daily progress. It is intentionally separate from the macOS notch presentation and its AppKit-only services.

```bash
# Generate the project and build for iOS Simulator
just build-ios

# Run the iOS unit tests on the default iPhone 17 Pro Simulator
just test-ios

# Or select another installed Simulator
IOS_SIMULATOR='iPhone 16' just test-ios
```

To run the app interactively, regenerate the project with `cd Oak && xcodegen generate`, open `Oak.xcodeproj`, select the `OakIOS` scheme and an iPhone or iPad Simulator, then Run.

### Test on a physical iPhone with a free Apple Account

The recommended free workflow is to build and install Oak directly from Xcode. A paid Apple Developer Program membership is not required for personal testing on an iPhone that you own.

Requirements:

- A Mac with the full current Xcode release and iOS platform support installed.
- XcodeGen (`brew install xcodegen`).
- An Apple Account that has accepted the Apple Developer Agreement. Xcode shows this account as a **Personal Team**.
- An iPhone running iOS 16 or newer and a USB cable for initial pairing.

Set up and install Oak:

1. Run `cd Oak && xcodegen generate`, then open `Oak.xcodeproj`.
2. In **Xcode → Settings → Accounts**, add your Apple Account.
3. Connect the iPhone, accept **Trust This Computer**, and select it in Xcode's Device Hub.
4. On the iPhone, enable **Settings → Privacy & Security → Developer Mode**, restart the phone, then confirm Developer Mode with the device passcode. Apple notes that Developer Mode reduces device security; use a spare device when possible, or turn it off after testing.
5. Select the `OakIOS` and `OakIOSTests` targets in turn and open **Signing & Capabilities**. For both targets, enable **Automatically manage signing** and select your Personal Team. If Xcode reports that `com.productsway.oak.ios` is unavailable, set a unique local bundle ID, such as `com.yourname.oak.dev`. Do not commit your Personal Team ID or personal bundle ID.
6. Select the `OakIOS` scheme and the connected iPhone as the run destination, then choose **Product → Run**. Xcode registers the phone, creates the development profile, installs Oak, and starts it.
7. Choose **Product → Test** to install and run `OakIOSTests` on the phone.

After the first Xcode setup, tests can also run from Terminal. Replace the placeholders with the values from Xcode's Device Hub and Signing settings. Do not regenerate the project between the Xcode signing setup and this command, because generation can replace the local bundle ID selection.

```bash
cd Oak
xcodebuild \
  -project Oak.xcodeproj \
  -scheme OakIOS \
  -destination 'platform=iOS,id=<DEVICE_UDID>' \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM=<PERSONAL_TEAM_ID> \
  CODE_SIGN_STYLE=Automatic \
  test
```

Apple applies these limits to a free Personal Team:

- Up to 10 registered App IDs, which expire after 7 days.
- Up to 3 registered devices, which expire after 7 days.
- Up to 3 Personal Team apps installed on each device.
- Development provisioning profiles expire after 7 days. Reconnect the phone and run Oak from Xcode again to rebuild and reinstall it.
- No App Store, TestFlight, Ad Hoc, enterprise, or general app distribution.

Oak's local completion notifications are not APNs push notifications, and its background audio does not require a paid distribution capability. A development-signed IPA may be available through **Archive → Distribute App → Debugging**, but it remains device-bound and expires with the 7-day profile. Direct Xcode installation is the safer, supported workflow for a Personal Team.

See Apple's documentation for [Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account), [running on a physical device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), and [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

## Test a Pull Request Build

The `macOS Test Build` workflow runs for pull requests and manual workflow dispatches. It uploads an Apple Silicon
Release build as an artifact for 7 days. Open the workflow run, download the `oak-macos-test-*` artifact, and unzip
both the downloaded artifact and its `Oak-*.zip` file. Move `Oak.app` to Applications before testing it.

The app has an ad-hoc signature but is not notarized. On first launch, Control-click `Oak.app`, select **Open**, and
confirm the prompt. If macOS still blocks the app, use **System Settings → Privacy & Security → Open Anyway**.

For personal sound verification, open Oak's sound library and import a supported audio file. Select and play the
personal sound, restart Oak to confirm that it remains available, remove it, and confirm that built-in sounds still
play.

## Code Quality Commands

```bash
# Lint Swift code
just lint

# Auto-fix linting issues
just lint-fix

# Format Swift code
just format

# Check if code is formatted correctly
just format-check

# Run both lint and format checks
just check-style
```

## Ambient Sound Assets

Oak expects bundled ambient files under `Oak/Oak/Resources/Sounds` with these base names:

- `ambient_rain`
- `ambient_forest`
- `ambient_cafe`
- `ambient_brown_noise`
- `ambient_lofi`

Bundled tracks use `.m4a` (preferred), `.wav`, or `.mp3` files.

Users can also import `.m4a`, `.wav`, `.mp3`, `.aac`, `.aiff`, `.aif`, and `.caf` files from the sound library
in Oak's notch popover. Oak validates each file and copies it to `~/Library/Application Support/Oak/Sounds`, so
playback remains available if the original file moves or is removed. The copied files are user-managed data and
must not be added to the app bundle.

### 🎵 Sound Attribution

The ambient sounds included in Oak are sourced from [Pixabay](https://pixabay.com/) under the [Pixabay Content License](https://pixabay.com/service/license-summary/):

- **Rain Sound**: [Real Rain Sound](https://pixabay.com/sound-effects/real-rain-sound-379215/) by feedthestraycats
- **Forest Sound**: [Ambient Spring Forest](https://pixabay.com/sound-effects/ambient-spring-forest-323801/) by soundreality
- **Cafe Sound**: [Cafe Noise](https://pixabay.com/sound-effects/cafe-noise-32940/) by freesound_community
- **Brown Noise**: [Brown Noise](https://pixabay.com/sound-effects/brown-noise-by-digitalspa-170337/) by digitalspa
- **Lo-fi Sound**: [Lofi Guitar](https://pixabay.com/sound-effects/lofi-guitar-105361/) by freesound_community

We are grateful to these creators for making their work available for projects like Oak.

## Project Structure

```
Oak/
├── Oak/
│   ├── Models/              # Data models, enums, protocols
│   ├── Views/               # SwiftUI Views
│   ├── ViewModels/          # ObservableObject classes
│   ├── Services/            # Business logic, audio, persistence
│   ├── Resources/           # Assets, sounds, config files
│   └── OakApp.swift        # App entry point
├── Oak.xcodeproj/           # Generated by XcodeGen
├── project.yml              # XcodeGen config (project definition)
└── Tests/                   # Unit tests
```

**Note**: This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project management. The Xcode project is generated from `project.yml`. Do not use Swift Package Manager (`swift build` or `swift test`) for this project.

## Development Resources

- [PRD](tasks/prd-macos-focus-companion-app.md) - Product Requirements Document
- [Architecture Decisions](doc/adr/) - ADRs for key technical decisions
- [Agent Guidelines](AGENTS.md) - Development guidelines for contributors

## Contributing

Contributions are welcome! Please ensure your code follows the project's style guidelines and passes all linting and formatting checks before submitting PRs.
