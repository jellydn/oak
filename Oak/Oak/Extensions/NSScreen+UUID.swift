import AppKit
import CoreGraphics

internal extension NSScreen {
    /// Device description key for NSScreenNumber
    private static let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")
    
    /// Returns a persistent UUID for this display based on CoreGraphics display ID
    var displayUUID: String? {
        guard let number = deviceDescription[Self.screenNumberKey] as? NSNumber else {
            return nil
        }
        let displayID = CGDirectDisplayID(number.uint32Value)
        // CGDisplayCreateUUIDFromDisplayID follows Core Foundation "Create" naming convention,
        // returning a +1 retained reference that we must take ownership of
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return nil
        }
        // CFUUIDCreateString also returns a +1 retained reference; Swift's automatic
        // bridging to String properly releases the CFString for us
        let uuidString = CFUUIDCreateString(nil, uuid) as String
        return uuidString
    }

    /// Find a screen by its UUID
    @MainActor static func screen(withUUID uuid: String) -> NSScreen? {
        return NSScreenUUIDCache.shared.screen(forUUID: uuid)
    }

    /// Get UUID to NSScreen mapping for all screens
    @MainActor static var screensByUUID: [String: NSScreen] {
        return NSScreenUUIDCache.shared.allScreens
    }

    /// Check if this screen has a notch by examining safe area insets
    /// 
    /// This property detects displays with actual notch hardware (like MacBook Pro 14"/16" with notch)
    /// by checking if the top safe area inset is greater than zero. The safe area inset represents
    /// the area occupied by the notch where regular window content cannot be displayed.
    ///
    /// - Returns: `true` if the display has a notch, `false` otherwise
    var hasNotch: Bool {
        return safeAreaInsets.top > 0
    }
}

/// Cache for UUID to NSScreen mappings to avoid repeated lookups
@MainActor
internal final class NSScreenUUIDCache {
    static let shared = NSScreenUUIDCache()

    private var cache: [String: NSScreen] = [:]
    private var observer: Any?

    private init() {
        rebuildCache()
        setupObserver()
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildCache()
        }
    }

    private func rebuildCache() {
        var newCache: [String: NSScreen] = [:]

        for screen in NSScreen.screens {
            if let uuid = screen.displayUUID {
                newCache[uuid] = screen
            }
        }

        cache = newCache
    }

    func screen(forUUID uuid: String) -> NSScreen? {
        return cache[uuid]
    }

    var allScreens: [String: NSScreen] {
        return cache
    }
}
