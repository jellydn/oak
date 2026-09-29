import Foundation

internal protocol FocusSessionCheckpointStoring {
    func load() -> FocusSessionEngine?
    func save(_ session: FocusSessionEngine)
    func clear()
}

internal final class UserDefaultsFocusSessionCheckpointStore: FocusSessionCheckpointStoring {
    private let userDefaults: UserDefaults
    private let key: String

    internal init(userDefaults: UserDefaults = .standard, key: String = "iosFocusSessionCheckpoint") {
        self.userDefaults = userDefaults
        self.key = key
    }

    internal func load() -> FocusSessionEngine? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FocusSessionEngine.self, from: data)
    }

    internal func save(_ session: FocusSessionEngine) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        userDefaults.set(data, forKey: key)
    }

    internal func clear() {
        userDefaults.removeObject(forKey: key)
    }
}
