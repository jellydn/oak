import AppKit
import Combine

// MARK: - KeyboardShortcutAction

internal enum KeyboardShortcutAction: String, CaseIterable, Codable {
    case toggleSession
    case resetSession

    var displayName: String {
        switch self {
        case .toggleSession:
            "Start / Pause / Resume"
        case .resetSession:
            "Reset session"
        }
    }

    var defaultKey: KeyEquivalent {
        switch self {
        case .toggleSession:
            KeyEquivalent(character: " ", modifierRaw: 0)
        case .resetSession:
            KeyEquivalent(character: "\u{1b}", modifierRaw: 0) // Escape
        }
    }
}

// MARK: - KeyEquivalent

internal struct KeyEquivalent: Codable, Equatable {
    let character: String
    let modifierRaw: UInt

    var modifier: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierRaw)
    }

    init(character: String, modifierRaw: UInt = 0) {
        self.character = character
        self.modifierRaw = modifierRaw
    }

    init(character: String, modifier: NSEvent.ModifierFlags) {
        self.character = character
        modifierRaw = modifier.rawValue
    }

    var displayString: String {
        var parts: [String] = []
        if modifier.contains(.command) {
            parts.append("\u{2318}")
        }
        if modifier.contains(.option) {
            parts.append("\u{2325}")
        }
        if modifier.contains(.control) {
            parts.append("\u{2303}")
        }
        if modifier.contains(.shift) {
            parts.append("\u{21E7}")
        }
        switch character {
        case "\u{1b}":
            parts.append("Esc")
        case " ":
            parts.append("Space")
        default:
            parts.append(character.uppercased())
        }
        return parts.joined()
    }
}

// MARK: - KeyboardShortcutConfig

internal struct KeyboardShortcutConfig: Codable, Equatable {
    var enabled: Bool
    var globalHotkeysEnabled: Bool
    var shortcuts: [KeyboardShortcutAction: KeyEquivalent]

    static let `default` = KeyboardShortcutConfig(
        enabled: true,
        globalHotkeysEnabled: false,
        shortcuts: [
            .toggleSession: KeyboardShortcutAction.toggleSession.defaultKey,
            .resetSession: KeyboardShortcutAction.resetSession.defaultKey
        ]
    )
}

// MARK: - KeyboardShortcutService

internal final class KeyboardShortcutService: ObservableObject {
    @Published private var config: KeyboardShortcutConfig
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private let userDefaults: UserDefaults

    weak var viewModel: FocusSessionViewModel?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        config = Self.loadConfig(from: userDefaults)
        if config.enabled {
            startLocalMonitor()
        }
        if config.globalHotkeysEnabled {
            startGlobalMonitor()
        }
    }

    deinit {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Public API

    func load() {
        stop()
        config = Self.loadConfig(from: userDefaults)
        if config.enabled {
            startLocalMonitor()
        }
        if config.globalHotkeysEnabled {
            startGlobalMonitor()
        }
    }

    func stop() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }

    func updateConfig(_ newConfig: KeyboardShortcutConfig) {
        config = newConfig
        Self.saveConfig(newConfig, to: userDefaults)
        stop()
        load()
    }

    var currentConfig: KeyboardShortcutConfig {
        config
    }

    // MARK: - Private

    private func startLocalMonitor() {
        guard localEventMonitor == nil else { return }
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if handleKeyEvent(event) {
                return nil
            }
            return event
        }
    }

    private func startGlobalMonitor() {
        guard globalEventMonitor == nil else { return }
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            // Global monitor runs on background thread — dispatch viewModel calls
            handleGlobalKeyEvent(event)
        }
    }

    private func handleGlobalKeyEvent(_ event: NSEvent) {
        guard let vm = viewModel else { return }
        for (action, keyEquiv) in config.shortcuts {
            guard eventMatchesEquiv(event, keyEquiv) else { continue }
            Task { @MainActor in
                performAction(action, viewModel: vm)
            }
            return
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let vm = viewModel else { return false }

        for (action, keyEquiv) in config.shortcuts {
            guard eventMatchesEquiv(event, keyEquiv) else { continue }
            Task { @MainActor in
                performAction(action, viewModel: vm)
            }
            return true
        }
        return false
    }

    private func eventMatchesEquiv(_ event: NSEvent, _ equiv: KeyEquivalent) -> Bool {
        // Escape key is definitively keyCode 53 on macOS
        if equiv.character == "\u{1b}" {
            guard event.keyCode == 53 else { return false }
            let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return eventMods == equiv.modifier
        }

        if equiv.character == " " {
            guard event.characters == " " else { return false }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return flags == equiv.modifier
        }

        let eventChar = event.charactersIgnoringModifiers?.lowercased()
        let expected = equiv.character.lowercased()
        guard eventChar == expected else { return false }

        let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return eventMods == equiv.modifier
    }

    @MainActor
    private func performAction(_ action: KeyboardShortcutAction, viewModel: FocusSessionViewModel) {
        switch action {
        case .toggleSession:
            if viewModel.canPause {
                viewModel.pauseSession()
            } else if viewModel.canResume {
                viewModel.resumeSession()
            } else if viewModel.canStart {
                viewModel.startSession()
            } else if viewModel.canStartNext {
                viewModel.startNextSession()
            }
        case .resetSession:
            if !viewModel.canStart {
                viewModel.resetSession()
            }
        }
    }

    private static func loadConfig(from defaults: UserDefaults) -> KeyboardShortcutConfig {
        guard let data = defaults.data(forKey: "keyboardShortcutConfig"),
              let config = try? JSONDecoder().decode(KeyboardShortcutConfig.self, from: data)
        else {
            return .default
        }
        return config
    }

    private static func saveConfig(_ config: KeyboardShortcutConfig, to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: "keyboardShortcutConfig")
        }
    }
}
