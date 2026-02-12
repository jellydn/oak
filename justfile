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

# Check for compilation errors without building
check:
    cd Oak && swift build 2>&1 | head -50 || echo "Note: swift build may require Package.swift"
