import XCTest
@testable import Oak

private final class InMemoryProgressStore: ProgressStoring {
    var records: [ProgressData] = []
    var saveCount = 0

    func load() -> [ProgressData] {
        records
    }

    func save(_ records: [ProgressData]) {
        self.records = records
        saveCount += 1
    }
}

@MainActor
internal final class ProgressStoreTests: XCTestCase {
    func testUserDefaultsStoreRoundTripsRecords() throws {
        let suiteName = "OakTests.ProgressStore.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsProgressStore(userDefaults: defaults)
        let record = ProgressData(date: Date(timeIntervalSince1970: 100), focusMinutes: 25, completedSessions: 1)

        store.save([record])

        XCTAssertEqual(store.load().map(\.focusMinutes), [25])
        XCTAssertEqual(store.load().first?.date, record.date)
    }

    func testProgressManagerUsesInjectedStoreForReadsAndWrites() {
        let store = InMemoryProgressStore()
        let manager = ProgressManager(progressStore: store)

        manager.recordSessionCompletion(durationMinutes: 25)

        XCTAssertEqual(store.saveCount, 1)
        XCTAssertEqual(store.records.first?.focusMinutes, 25)
        XCTAssertEqual(manager.dailyStats.todayFocusMinutes, 25)
    }
}
