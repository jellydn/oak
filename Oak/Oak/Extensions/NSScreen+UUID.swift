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
        return NSScreenUUIDCache.shared.screen(forUUID: uuid)
    }

    @MainActor static var screensByUUID: [String: NSScreen] {
        return NSScreenUUIDCache.shared.allScreens
    }

    var hasNotch: Bool {
        return safeAreaInsets.top > 0
    }
}

@MainActor
internal final class NSScreenUUIDCache {
    internal static let shared = NSScreenUUIDCache()

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
