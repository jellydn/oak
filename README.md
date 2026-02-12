<div align="center">
  <img src="assets/readme-header.svg" alt="Oak - Focus Companion for macOS" width="800"/>
</div>

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-13+-blue.svg)]()
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)]()

</div>

# Oak

A lightweight macOS focus companion designed for deep work.

## ✨ Features

- 🎯 **Notch-first** focus companion UI
- ⏱️ **Fixed Pomodoro** presets: `25/5` and `50/10`
- ▶️ **Session controls**: start, pause, resume
- 🎵 **Ambient sounds**: rain, forest, cafe, brown noise, lo-fi
- 📊 **Local tracking**: daily focus minutes, completed sessions, 7-day streak

## 🚀 Getting Started

### Prerequisites

- macOS 13+ (Apple Silicon recommended)
- XcodeGen (`brew install xcodegen`)

### Installation

```bash
# Clone the repository
git clone https://github.com/jellydn/oak.git
cd oak

# Generate Xcode project
cd Oak && xcodegen generate

# Build and run
open Oak.xcodeproj
```

### Build Commands

```bash
# Build the project
just build

# Run all tests
just test

# Clean build artifacts
just clean
```

## 📁 Project Structure

```
Oak/
├── Models/          # Data models, enums, protocols
├── Views/           # SwiftUI Views
├── ViewModels/      # ObservableObject classes
├── Services/        # Business logic, audio, persistence
├── Resources/       # Assets, sounds, config files
└── OakTests/       # Test files
```

## 📝 Documentation

- [PRD](tasks/prd-macos-focus-companion-app.md) - Product Requirements Document
- [Architecture Decisions](doc/adr/) - ADRs for key technical decisions
- [Agent Guidelines](AGENTS.md) - Development guidelines for contributors

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Dung Huynh**

- Website: [https://productsway.com](https://productsway.com)
- Twitter: [@jellydn](https://twitter.com/jellydn)
- GitHub: [@jellydn](https://github.com/jellydn)

## 💖 Support

[![ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/dunghd)
[![paypal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/dunghd)
[![buymeacoffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dunghd)
