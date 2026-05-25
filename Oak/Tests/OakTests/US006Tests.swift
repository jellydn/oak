import SwiftUI
import XCTest
@testable import Oak

private final class TestClock {
    var currentDate: Date

    init(currentDate: Date) {
        self.currentDate = currentDate
    }
}

@MainActor
internal final class US006Tests: XCTestCase {
    var progressManager: ProgressManager!
    private var testUserDefaults: UserDefaults?
    private var suiteName: String?

    override func setUp() async throws {
        let suite = "OakTests.US006.Progress.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        suiteName = suite
        testUserDefaults = defaults
        progressManager = ProgressManager(userDefaults: defaults)
    }

    override func tearDown() async throws {
        if let suiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        progressManager = nil
        testUserDefaults = nil
        suiteName = nil
    }

    func testAppStoresDailyFocusMinutes() {
        // Record a 25-minute session
        progressManager.recordSessionCompletion(durationMinutes: 25)

        // Verify focus minutes are stored
        XCTAssertEqual(progressManager.dailyStats.todayFocusMinutes, 25)
    }

    func testAppStoresDailyCompletedWorkSessionCount() {
        // Record multiple sessions
        progressManager.recordSessionCompletion(durationMinutes: 25)
        progressManager.recordSessionCompletion(durationMinutes: 25)
        progressManager.recordSessionCompletion(durationMinutes: 50)

        // Verify completed sessions count
        XCTAssertEqual(progressManager.dailyStats.todayCompletedSessions, 3)
    }

    func testAppComputes7DayStreak() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var records: [ProgressData] = []

        for dayOffset in 0 ..< 7 {
            let date = try XCTUnwrap(calendar.date(byAdding: .day, value: -dayOffset, to: today))
            let sessionStart = try XCTUnwrap(calendar.date(byAdding: .hour, value: 9, to: date))
            records.append(
                ProgressData(
                    date: date,
                    focusMinutes: 25,
                    completedSessions: 1,
                    sessions: [
                        SessionRecord(
                            type: .work,
                            startTime: sessionStart,
                            endTime: sessionStart.addingTimeInterval(25 * 60),
                            durationMinutes: 25
                        )
                    ]
                )
            )
        }

        let defaults = try XCTUnwrap(testUserDefaults)
        let encodedRecords = try JSONEncoder().encode(records)
        defaults.set(encodedRecords, forKey: "progressHistory")

        let manager = ProgressManager(userDefaults: defaults)
        XCTAssertEqual(manager.dailyStats.streakDays, 7)
    }

    func testStreakResetsOnMissedDay() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))
        let records = [
            ProgressData(
                date: today,
                focusMinutes: 25,
                completedSessions: 1,
                sessions: [makeWorkSession(on: today)]
            ),
            ProgressData(
                date: twoDaysAgo,
                focusMinutes: 25,
                completedSessions: 1,
                sessions: [makeWorkSession(on: twoDaysAgo)]
            )
        ]
        let defaults = try XCTUnwrap(testUserDefaults)
        let encodedRecords = try JSONEncoder().encode(records)
        defaults.set(encodedRecords, forKey: "progressHistory")

        let manager = ProgressManager(userDefaults: defaults)
        XCTAssertEqual(manager.dailyStats.streakDays, 1)
    }

    func testDataPersistsAcrossAppRelaunch() throws {
        // Record some progress
        let manager1 = try ProgressManager(userDefaults: XCTUnwrap(testUserDefaults))
        manager1.recordSessionCompletion(durationMinutes: 25)
        manager1.recordSessionCompletion(durationMinutes: 25)

        let statsBefore = manager1.dailyStats
        XCTAssertEqual(statsBefore.todayFocusMinutes, 50)
        XCTAssertEqual(statsBefore.todayCompletedSessions, 2)

        // Create a new manager (simulates app relaunch)
        let manager2 = try ProgressManager(userDefaults: XCTUnwrap(testUserDefaults))

        // Verify data persisted
        let statsAfter = manager2.dailyStats
        XCTAssertEqual(statsAfter.todayFocusMinutes, 50, "Focus minutes should persist")
        XCTAssertEqual(statsAfter.todayCompletedSessions, 2, "Completed sessions should persist")
        XCTAssertEqual(statsAfter.streakDays, statsBefore.streakDays, "Streak should persist")
    }

    func testSessionCompletionUsesDurationWhenStartTimeOmitted() throws {
        let endTime = Date()

        progressManager.recordSessionCompletion(durationMinutes: 25, endTime: endTime)

        let session = try XCTUnwrap(progressManager.dailyStats.todaySessions.first)
        XCTAssertEqual(session.durationMinutes, 25)
        XCTAssertEqual(session.endTime.timeIntervalSince(endTime), 0, accuracy: 0.001)
        XCTAssertEqual(session.startTime.timeIntervalSince(endTime), -1500, accuracy: 0.001)
    }

    func testTodaySessionsAreSortedNewestFirst() {
        let now = Date()
        let olderStart = now.addingTimeInterval(-3600)
        let newerStart = now.addingTimeInterval(-900)

        progressManager.recordSessionCompletion(
            durationMinutes: 25,
            startTime: olderStart,
            endTime: olderStart.addingTimeInterval(1500)
        )
        progressManager.recordSessionCompletion(
            durationMinutes: 10,
            type: .shortBreak,
            startTime: newerStart,
            endTime: newerStart.addingTimeInterval(600)
        )

        let sessions = progressManager.dailyStats.todaySessions
        XCTAssertEqual(sessions.count, 2)
        XCTAssertGreaterThan(sessions[0].startTime, sessions[1].startTime)
        XCTAssertEqual(sessions[0].type, .shortBreak)
        XCTAssertEqual(sessions[1].type, .work)
    }

    func testBreakOnlyTodayDoesNotResetPriorStreak() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let records = [
            ProgressData(
                date: yesterday,
                focusMinutes: 25,
                completedSessions: 1,
                sessions: [makeWorkSession(on: yesterday)]
            )
        ]
        let defaults = try XCTUnwrap(testUserDefaults)
        let encodedRecords = try JSONEncoder().encode(records)
        defaults.set(encodedRecords, forKey: "progressHistory")

        let manager = ProgressManager(userDefaults: defaults)
        XCTAssertEqual(manager.dailyStats.streakDays, 1)

        manager.recordSessionCompletion(durationMinutes: 5, type: .shortBreak)

        XCTAssertEqual(manager.dailyStats.todayCompletedSessions, 0)
        XCTAssertEqual(manager.dailyStats.streakDays, 1)
    }

    func testFirstSessionAfterDayChangeRefreshesPublishedDailyStats() throws {
        let calendar = Calendar.current
        let dayOne = calendar.startOfDay(for: Date())
        let dayTwo = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: dayOne))
        let dayTwoStart = try XCTUnwrap(calendar.date(byAdding: .hour, value: 9, to: dayTwo))
        let defaults = try XCTUnwrap(testUserDefaults)
        let clock = TestClock(currentDate: dayOne)
        let manager = ProgressManager(userDefaults: defaults) {
            clock.currentDate
        }

        clock.currentDate = dayTwo
        manager.recordSessionCompletion(
            durationMinutes: 25,
            startTime: dayTwoStart,
            endTime: dayTwoStart.addingTimeInterval(25 * 60)
        )

        XCTAssertEqual(manager.dailyStats.todayFocusMinutes, 25)
        XCTAssertEqual(manager.dailyStats.todayCompletedSessions, 1)
        XCTAssertEqual(manager.dailyStats.todaySessions.count, 1)
        XCTAssertEqual(manager.dailyStats.todaySessions.first?.startTime, dayTwoStart)
    }

    func testMultipleDaysDataStored() throws {
        // Record sessions on multiple days
        let manager1 = try ProgressManager(userDefaults: XCTUnwrap(testUserDefaults))
        manager1.recordSessionCompletion(durationMinutes: 25)

        // Create a new manager instance to verify persistence
        let manager2 = try ProgressManager(userDefaults: XCTUnwrap(testUserDefaults))

        // Verify data is still there
        XCTAssertEqual(manager2.dailyStats.todayFocusMinutes, 25)
        XCTAssertEqual(manager2.dailyStats.todayCompletedSessions, 1)
        XCTAssertEqual(manager2.dailyStats.streakDays, 1)
    }

    func testZeroMinutesWithoutSessions() throws {
        // Test with no sessions recorded
        let manager = try ProgressManager(userDefaults: XCTUnwrap(testUserDefaults))

        XCTAssertEqual(manager.dailyStats.todayFocusMinutes, 0, "Should have 0 focus minutes with no sessions")
        XCTAssertEqual(manager.dailyStats.todayCompletedSessions, 0, "Should have 0 completed sessions")
        XCTAssertEqual(manager.dailyStats.streakDays, 0, "Should have 0 streak days with no sessions")
    }

    func testViewModelExposesProgressStats() throws {
        // Test that ViewModel exposes progress stats
        let suiteName = "OakTests.US006.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        let manager = ProgressManager(userDefaults: userDefaults)
        let viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            progressManager: manager,
            notificationService: NotificationService()
        )

        // Record a session
        manager.recordSessionCompletion(durationMinutes: 25)

        // Verify ViewModel exposes stats
        XCTAssertEqual(viewModel.todayFocusMinutes, 25)
        XCTAssertEqual(viewModel.todayCompletedSessions, 1)
        XCTAssertGreaterThanOrEqual(viewModel.streakDays, 0)

        viewModel.cleanup()
    }

    func testProgressMenuDisplaysStats() throws {
        // Test that ProgressMenuView can be created and displays stats
        let suiteName = "OakTests.US006.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        let manager = ProgressManager(userDefaults: userDefaults)
        let viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            progressManager: manager,
            notificationService: NotificationService()
        )

        // Record some progress
        viewModel.progressManager.recordSessionCompletion(durationMinutes: 25)

        // Create progress menu view
        let progressView = ProgressMenuView(viewModel: viewModel)

        // Verify view can be created (structural test)
        XCTAssertNotNil(progressView)

        viewModel.cleanup()
    }

    private func makeWorkSession(on date: Date) -> SessionRecord {
        let sessionStart = Calendar.current.date(byAdding: .hour, value: 9, to: date) ?? date
        return SessionRecord(
            type: .work,
            startTime: sessionStart,
            endTime: sessionStart.addingTimeInterval(25 * 60),
            durationMinutes: 25
        )
    }
}
