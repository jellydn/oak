import AppKit
import CoreGraphics

internal extension NSScreen {
    private static let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")

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
        return CFUUIDCreateString(nil, uuid) as String
    }

    @MainActor static func screen(withUUID uuid: String) -> NSScreen? {
        NSScreenUUIDCache.shared.screen(forUUID: uuid)
    }

    @MainActor static var screensByUUID: [String: NSScreen] {
        NSScreenUUIDCache.shared.allScreens
    }

    @MainActor var hasNotch: Bool {
        NSScreenUUIDCache.shared.hasNotch(for: self)
    }
}

@MainActor
internal final class NSScreenUUIDCache {
    internal static let shared = NSScreenUUIDCache()

    private var cache: [String: NSScreen] = [:]
    private var notchCache: [String: Bool] = [:]
    private var observer: Any?

    private init() {
        rebuildCache()
        setupObserver()
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // The observer is registered on the main queue, so rebuilding is MainActor-isolated.
            MainActor.assumeIsolated {
                self?.rebuildCache()
            }
        }
    }

    private func rebuildCache() {
        var newCache: [String: NSScreen] = [:]
        var newNotchCache: [String: Bool] = [:]

        for screen in NSScreen.screens {
            if let uuid = screen.displayUUID {
                newCache[uuid] = screen
                newNotchCache[uuid] = screen.safeAreaInsets.top > 0
            }
        }

        cache = newCache
        notchCache = newNotchCache
    }

    func screen(forUUID uuid: String) -> NSScreen? {
        cache[uuid]
    }

    func hasNotch(for screen: NSScreen) -> Bool {
        guard let uuid = screen.displayUUID else {
            return screen.safeAreaInsets.top > 0
        }

        if let cachedValue = notchCache[uuid] {
            return cachedValue
        }

        let value = screen.safeAreaInsets.top > 0
        notchCache[uuid] = value
        return value
    }

    var allScreens: [String: NSScreen] {
        cache
    }
}
