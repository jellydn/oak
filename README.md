<h1 align="center">Welcome to Oak 👋</h1>

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->

[![All Contributors](https://img.shields.io/badge/all_contributors-0-orange.svg?style=flat-square)](#contributors-)

<!-- ALL-CONTRIBUTORS-BADGE:END -->

<p align="center">
  <strong>Oak</strong> is a lightweight macOS focus companion designed for deep work with notch-first UI and ambient sounds.
</p>

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-13+-blue.svg)]()
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)]()

</div>

<div align="center">
  <img src="assets/readme-header.svg" alt="Oak - Focus Companion for macOS" width="800"/>
</div>

## 🎬 Demo

<div align="center">
  <img src="https://gyazo.com/95dc23363c754bd58a902318726fd911.gif" alt="Oak Demo - Focus session in action" width="600"/>
</div>

## Installation Requirements

- macOS 13+ (Apple Silicon recommended)

> [!IMPORTANT]
> We don't have an Apple Developer account yet. The application will show a popup on first launch that the app is from an unidentified developer.
> 1. Click **OK** to close the popup.
> 2. Open **System Settings** > **Privacy & Security**.
> 3. Scroll down and click **Open Anyway** next to the warning about the app.
> 4. Confirm your choice if prompted.
>
> You only need to do this once.

## Motivation

In today's world of constant distractions, deep work has become increasingly rare and valuable. Oak was created to help you reclaim your focus and establish productive work sessions without cluttering your screen. By leveraging the MacBook's notch area, Oak provides a subtle, always-visible timer that keeps you accountable without being intrusive.

## Features

- 🎯 **Notch-first UI**: Elegant focus companion that lives in your MacBook's notch
- ⏱️ **Pomodoro presets**: Default `25/5` and `50/10` sessions (fully configurable)
- 🔄 **Smart breaks**: Automatic 15/20 min long breaks after 4 focus rounds
- ▶️ **Session controls**: Start, pause, and resume your focus sessions
- 🎵 **Ambient sounds**: Rain, forest, cafe, brown noise, and lo-fi to help you concentrate
- 📊 **Local tracking**: Track daily focus minutes, completed sessions, and 7-day streaks
- 🔄 **Auto-update**: Seamless updates via Sparkle framework

## Installation

### Using Homebrew (Recommended)

```bash
# Add the tap
brew tap jellydn/oak https://github.com/jellydn/oak

# Install Oak
brew install --cask oak
```

### From Source

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed build instructions and development setup.

## Auto-Update

Oak uses the [Sparkle framework](https://sparkle-project.org/) to provide automatic updates:

- **Automatic update checks**: Enable/disable in Settings (enabled by default)
- **Automatic downloads**: Enable/disable in Settings (disabled by default)
- **Manual check**: Check for updates on demand via Settings

For more details about the update system, see [RELEASES.md](RELEASES.md).

## 📝 Documentation

- [DEVELOPMENT.md](DEVELOPMENT.md) - Build commands and development setup
- [RELEASES.md](RELEASES.md) - CI/CD pipeline and release process
- [PRD](tasks/prd-macos-focus-companion-app.md) - Product Requirements Document
- [Architecture Decisions](doc/adr/) - ADRs for key technical decisions
- [Agent Guidelines](AGENTS.md) - Development guidelines for contributors

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

👤 **Dung Huynh**

- Website: [https://productsway.com](https://productsway.com)
- Twitter: [@jellydn](https://twitter.com/jellydn)
- GitHub: [@jellydn](https://github.com/jellydn)

## Show your support

Give a ⭐️ if this project helped you!

[![kofi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/dunghd)
[![paypal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/dunghd)
[![buymeacoffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dunghd)

## Contributors ✨

Thanks goes to these wonderful people:

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
