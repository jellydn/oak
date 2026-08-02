import Foundation

internal protocol ProgressStoring {
    func load() -> [ProgressData]
    func save(_ records: [ProgressData])
}

internal final class UserDefaultsProgressStore: ProgressStoring {
    private let userDefaults: UserDefaults
    private let progressKey: String

    internal init(userDefaults: UserDefaults = .standard, progressKey: String = "progressHistory") {
        self.userDefaults = userDefaults
        self.progressKey = progressKey
    }

    internal func load() -> [ProgressData] {
        guard let data = userDefaults.data(forKey: progressKey),
              let records = try? JSONDecoder().decode([ProgressData].self, from: data)
        else {
            return []
        }
        return records
    }

    internal func save(_ records: [ProgressData]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        userDefaults.set(data, forKey: progressKey)
    }
}
