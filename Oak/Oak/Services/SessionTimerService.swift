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

    deinit {
        timer?.invalidate()
        autoStartTimer?.invalidate()
    }

    func start(seconds: Int) {
        timer?.invalidate()
        sessionDuration = seconds
        remainingSeconds = seconds
        sessionEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        sessionEndDate = nil
    }

    func resume() {
        guard timer == nil else { return }
        sessionEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
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
    }

    func startAutoStartCountdown() {
        autoStartCountdown = 10
        autoStartTimer?.invalidate()
        autoStartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickAutoStart()
            }
        }
    }

    func cancelAutoStartCountdown() {
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        autoStartCountdown = 0
    }

    // MARK: - Private

    private func tick() {
        guard let sessionEndDate else {
            timer?.invalidate()
            timer = nil
            timerFinished.send()
            return
        }

        remainingSeconds = max(0, Int(ceil(sessionEndDate.timeIntervalSinceNow)))

        if remainingSeconds <= 0 {
            timer?.invalidate()
            timer = nil
            self.sessionEndDate = nil
            timerFinished.send()
        }
    }

    private func tickAutoStart() {
        autoStartCountdown -= 1
        if autoStartCountdown <= 0 {
            autoStartTimer?.invalidate()
            autoStartTimer = nil
            autoStartCountdown = 0
            autoStartFinished.send()
        }
    }
}
