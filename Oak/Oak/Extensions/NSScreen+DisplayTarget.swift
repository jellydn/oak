import AppKit

internal extension NSScreen {
    static func screen(for target: DisplayTarget) -> NSScreen? {
        switch target {
        case .mainDisplay:
            return NSScreen.main ?? NSScreen.screens.first
        case .notchedDisplay:
            return NSScreen.screens.first { $0.auxiliaryTopLeftArea != nil }
                ?? NSScreen.main
                ?? NSScreen.screens.first
        }
    }
}
