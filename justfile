# Justfile for Oak - macOS Focus Companion
derived-data := "/tmp/oak-derived"

# Default recipe - shows available commands
default:
    @just --list

# Build the project
build:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' -derivedDataPath {{derived-data}} build

# Run all tests
test:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' -derivedDataPath {{derived-data}} test

# Run a specific test class (usage: just test-class FocusSessionViewModelTests)
test-class CLASS:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' -derivedDataPath {{derived-data}} -only-testing:OakTests/{{CLASS}} test

# Run a specific test method (usage: just test-method FocusSessionViewModelTests testStartSession)
test-method CLASS METHOD:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' -derivedDataPath {{derived-data}} -only-testing:OakTests/{{CLASS}}/{{METHOD}} test

# Clean build artifacts
clean:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -derivedDataPath {{derived-data}} clean

# Open project in Xcode
open:
    open Oak/Oak.xcodeproj

# Build release version
build-release:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' -derivedDataPath {{derived-data}} -configuration Release build

# Run tests with verbose output
test-verbose:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' -derivedDataPath {{derived-data}} test -verbose

# Check for compilation errors (incremental build)
check:
    cd Oak && xcodebuild -project Oak.xcodeproj -scheme Oak -destination 'platform=macOS' -derivedDataPath {{derived-data}} build

# Lint Swift code with SwiftLint
lint:
    @command -v swiftlint >/dev/null 2>&1 || { echo "SwiftLint is not installed. Install with: brew install swiftlint"; exit 1; }
    swiftlint lint --strict

# Auto-fix linting issues where possible
lint-fix:
    @command -v swiftlint >/dev/null 2>&1 || { echo "SwiftLint is not installed. Install with: brew install swiftlint"; exit 1; }
    swiftlint lint --fix

# Format Swift code with SwiftFormat
format:
    @command -v swiftformat >/dev/null 2>&1 || { echo "SwiftFormat is not installed. Install with: brew install swiftformat"; exit 1; }
    swiftformat .

# Check if code is formatted correctly without modifying
format-check:
    @command -v swiftformat >/dev/null 2>&1 || { echo "SwiftFormat is not installed. Install with: brew install swiftformat"; exit 1; }
    swiftformat --lint .

# Run both lint and format checks
check-style:
    @echo "Running SwiftLint..."
    just lint
    @echo "Running SwiftFormat check..."
    just format-check
