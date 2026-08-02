import Combine
import Foundation

// MARK: - SessionTimerService

@MainActor
internal final class SessionTimerService: ObservableObject {
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var autoStartCountdown: Int = 0
    @Published private(set) var sessionDuration: Int = 0

    let timerFinished = PassthroughSubject<Void, Never>()
    let autoStartFinished = PassthroughSubject<Void, Never>()

    private var timer: Timer?
    private var autoStartTimer: Timer?
    private var sessionEndDate: Date?
    private var remainingInterval: TimeInterval = 0
    private var autoStartEndDate: Date?
    private static let timerInterval: TimeInterval = 0.25

    deinit {
        timer?.invalidate()
        autoStartTimer?.invalidate()
    }

    func start(seconds: Int) {
        timer?.invalidate()
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        autoStartEndDate = nil
        autoStartCountdown = 0
        sessionDuration = seconds
        remainingSeconds = seconds
        remainingInterval = TimeInterval(seconds)
        sessionEndDate = Date().addingTimeInterval(remainingInterval)
        timer = makeRepeatingTimer { [weak self] in
            self?.tick()
        }
        tick()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        if let sessionEndDate {
            remainingInterval = max(0, sessionEndDate.timeIntervalSinceNow)
        }
        sessionEndDate = nil
    }

    func resume() {
        guard timer == nil else { return }
        sessionEndDate = Date().addingTimeInterval(remainingInterval)
        timer = makeRepeatingTimer { [weak self] in
            self?.tick()
        }
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        remainingSeconds = 0
        autoStartCountdown = 0
        sessionDuration = 0
        sessionEndDate = nil
        remainingInterval = 0
        autoStartEndDate = nil
    }

    func startAutoStartCountdown() {
        autoStartTimer?.invalidate()
        autoStartCountdown = 10
        autoStartEndDate = Date().addingTimeInterval(TimeInterval(autoStartCountdown))
        autoStartTimer = makeRepeatingTimer { [weak self] in
            self?.tickAutoStart()
        }
        tickAutoStart()
    }

    func cancelAutoStartCountdown() {
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        autoStartEndDate = nil
        autoStartCountdown = 0
    }

    // MARK: - Private

    private func makeRepeatingTimer(action: @escaping @MainActor () -> Void) -> Timer {
        // Timer callbacks run on MainActor because every timer is installed on RunLoop.main.
        let timer = Timer(timeInterval: Self.timerInterval, repeats: true) { _ in
            MainActor.assumeIsolated {
                action()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func tick() {
        guard let sessionEndDate else {
            timer?.invalidate()
            timer = nil
            timerFinished.send()
            return
        }

        remainingInterval = max(0, sessionEndDate.timeIntervalSinceNow)
        remainingSeconds = max(0, Int(ceil(remainingInterval)))

        if remainingSeconds <= 0 {
            timer?.invalidate()
            timer = nil
            self.sessionEndDate = nil
            remainingInterval = 0
            timerFinished.send()
        }
    }

    private func tickAutoStart() {
        guard let autoStartEndDate else {
            autoStartTimer?.invalidate()
            autoStartTimer = nil
            return
        }

        let remainingInterval = max(0, autoStartEndDate.timeIntervalSinceNow)
        autoStartCountdown = max(0, Int(ceil(remainingInterval)))

        if autoStartCountdown == 0 {
            autoStartTimer?.invalidate()
            autoStartTimer = nil
            self.autoStartEndDate = nil
            autoStartFinished.send()
        }
    }
}
