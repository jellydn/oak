import XCTest
@testable import OakIOS

@MainActor
internal final class FocusSessionRecoveryTests: XCTestCase {
    func testExpiredSessionIsRecoveredExactlyOnce() {
        let startDate = date(day: 1)
        let dateProvider = TestDateProvider(date: startDate)
        let progressStore = RecoveryProgressStore()
        let checkpointStore = MemoryFocusSessionCheckpointStore()
        let notifier = RecoveryCompletionNotifier()

        var viewModel: FocusSessionViewModel? = makeViewModel(
            dateProvider: dateProvider,
            progressStore: progressStore,
            checkpointStore: checkpointStore,
            notifier: notifier
        )
        viewModel?.startSession()
        viewModel?.becameInactive()
        viewModel = nil

        dateProvider.date = startDate.addingTimeInterval(1501)
        viewModel = makeViewModel(
            dateProvider: dateProvider,
            progressStore: progressStore,
            checkpointStore: checkpointStore,
            notifier: notifier
        )

        XCTAssertEqual(viewModel?.session.phase, .completed)
        XCTAssertEqual(viewModel?.progressSummary.focusMinutes, 25)
        XCTAssertEqual(viewModel?.progressSummary.completedSessions, 1)
        viewModel = nil

        viewModel = makeViewModel(
            dateProvider: dateProvider,
            progressStore: progressStore,
            checkpointStore: checkpointStore,
            notifier: notifier
        )

        XCTAssertEqual(viewModel?.session.phase, .completed)
        XCTAssertEqual(viewModel?.progressSummary.focusMinutes, 25)
        XCTAssertEqual(viewModel?.progressSummary.completedSessions, 1)
    }

    func testRunningSessionReusesNotificationIdentifierAfterRelaunch() throws {
        let dateProvider = TestDateProvider(date: date(day: 1))
        let progressStore = RecoveryProgressStore()
        let checkpointStore = MemoryFocusSessionCheckpointStore()
        let firstNotifier = RecoveryCompletionNotifier()

        var viewModel: FocusSessionViewModel? = makeViewModel(
            dateProvider: dateProvider,
            progressStore: progressStore,
            checkpointStore: checkpointStore,
            notifier: firstNotifier
        )
        viewModel?.startSession()
        let firstIdentifier = try XCTUnwrap(firstNotifier.scheduledIntervalIDs.last)
        viewModel = nil

        let restoredNotifier = RecoveryCompletionNotifier()
        viewModel = makeViewModel(
            dateProvider: dateProvider,
            progressStore: progressStore,
            checkpointStore: checkpointStore,
            notifier: restoredNotifier
        )

        XCTAssertEqual(restoredNotifier.scheduledIntervalIDs, [firstIdentifier])
        XCTAssertEqual(viewModel?.session.phase, .running)
    }

    func testBackgroundCompletionPreservesScheduledNotification() {
        let startDate = date(day: 1)
        let dateProvider = TestDateProvider(date: startDate)
        let notifier = RecoveryCompletionNotifier()
        let viewModel = makeViewModel(
            dateProvider: dateProvider,
            progressStore: RecoveryProgressStore(),
            checkpointStore: MemoryFocusSessionCheckpointStore(),
            notifier: notifier
        )
        viewModel.startSession()
        viewModel.becameInactive()

        dateProvider.date = startDate.addingTimeInterval(1501)
        viewModel.becameActive()

        XCTAssertEqual(viewModel.session.phase, .completed)
        XCTAssertEqual(notifier.cancelCount, 0)
    }

    private func makeViewModel(
        dateProvider: TestDateProvider,
        progressStore: RecoveryProgressStore,
        checkpointStore: MemoryFocusSessionCheckpointStore,
        notifier: RecoveryCompletionNotifier
    ) -> FocusSessionViewModel {
        FocusSessionViewModel(
            progressStore: progressStore,
            sessionCheckpointStore: checkpointStore,
            completionNotifier: notifier
        ) { dateProvider.date }
    }

    private func date(day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12))!
    }
}

@MainActor
private final class TestDateProvider {
    var date: Date

    init(date: Date) {
        self.date = date
    }
}

private final class RecoveryProgressStore: FocusProgressStoring {
    private var records: [FocusSessionRecord] = []

    func load() -> [FocusSessionRecord] {
        records
    }

    func save(_ records: [FocusSessionRecord]) {
        self.records = records
    }
}

private final class MemoryFocusSessionCheckpointStore: FocusSessionCheckpointStoring {
    private var session: FocusSessionEngine?

    func load() -> FocusSessionEngine? {
        session
    }

    func save(_ session: FocusSessionEngine) {
        self.session = session
    }

    func clear() {
        session = nil
    }
}

@MainActor
private final class RecoveryCompletionNotifier: FocusCompletionNotifying {
    private(set) var scheduledIntervalIDs: [UUID] = []
    private(set) var cancelCount = 0

    func scheduleCompletion(for _: FocusIntervalKind, at _: Date, intervalID: UUID) {
        scheduledIntervalIDs.append(intervalID)
    }

    func cancelPendingCompletion() {
        cancelCount += 1
    }
}
