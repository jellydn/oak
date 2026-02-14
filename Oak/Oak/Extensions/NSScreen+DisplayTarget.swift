import AppKit

internal extension NSScreen {
    static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }

    private static func isSystemMainScreen(_ screen: NSScreen) -> Bool {
        guard let id = displayID(for: screen) else { return false }
        return id == CGMainDisplayID()
    }

    private static func primaryScreen() -> NSScreen? {
        NSScreen.screens.first(where: isSystemMainScreen)
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    private static func secondaryScreen(excluding primary: NSScreen?) -> NSScreen? {
        guard let primary else { return NSScreen.screens.first }
        guard let primaryID = displayID(for: primary) else {
            return NSScreen.screens.first { $0 !== primary } ?? NSScreen.screens.first
        }
        return NSScreen.screens.first { displayID(for: $0) != primaryID } ?? primary
    }

    private static func notchedScreen() -> NSScreen? {
        // Prefer screens with actual notch (safeAreaInsets.top > 0) over just auxiliary areas
        // Single pass through screens checking both conditions for efficiency
        for screen in NSScreen.screens {
            if screen.hasNotch {
                return screen
            }
        }
        // Fall back to screens with auxiliary areas if no actual notch found
        return NSScreen.screens.first { $0.auxiliaryTopLeftArea != nil }
    }

    private static func screen(forDisplayID id: CGDirectDisplayID?) -> NSScreen? {
        guard let id else { return nil }
        return NSScreen.screens.first { displayID(for: $0) == id }
    }

    static func screen(for target: DisplayTarget, preferredDisplayID: CGDirectDisplayID? = nil) -> NSScreen? {
        if let preferredScreen = screen(forDisplayID: preferredDisplayID) {
            return preferredScreen
        }

        switch target {
        case .mainDisplay:
            return primaryScreen()
        case .notchedDisplay:
            // Prioritize display with actual notch hardware
            if let notched = notchedScreen() {
                return notched
            }
            // Fall back to secondary screen if no notch found
            let primary = primaryScreen()
            return secondaryScreen(excluding: primary) ?? primary
        }
    }

    static func displayName(for target: DisplayTarget, preferredDisplayID: CGDirectDisplayID? = nil) -> String {
        screen(for: target, preferredDisplayID: preferredDisplayID)?.localizedName ?? target.displayName
    }
}
