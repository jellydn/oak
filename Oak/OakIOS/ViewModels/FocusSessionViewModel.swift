import Combine
import Foundation

@MainActor
internal final class FocusSessionViewModel: ObservableObject {
    @Published private(set) var session = FocusSessionEngine()
    @Published private(set) var progressSummary: FocusProgressSummary

    internal let audioService: FocusAudioService

    private let currentDate: () -> Date
    private let progressRepository: FocusProgressRepository
    private let sessionCheckpointStore: any FocusSessionCheckpointStoring
    private let completionNotifier: any FocusCompletionNotifying
    private var timer: Timer?
    private var isAppActive = true

    internal init(
        audioService: FocusAudioService? = nil,
        progressStore: any FocusProgressStoring = UserDefaultsFocusProgressStore(),
        sessionCheckpointStore: any FocusSessionCheckpointStoring = UserDefaultsFocusSessionCheckpointStore(),
        completionNotifier: (any FocusCompletionNotifying)? = nil,
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.audioService = audioService ?? FocusAudioService()
        self.sessionCheckpointStore = sessionCheckpointStore
        self.completionNotifier = completionNotifier ?? FocusCompletionNotifier()
        self.currentDate = currentDate
        progressRepository = FocusProgressRepository(store: progressStore)
        progressSummary = progressRepository.summary(on: currentDate())
        if let restoredSession = sessionCheckpointStore.load() {
            session = restoredSession
        }
        restoreSession()
    }

    deinit {
        timer?.invalidate()
    }

    internal func selectPreset(_ preset: FocusPreset) {
        session.selectPreset(preset)
    }

    internal func selectTrack(_ track: FocusAmbientTrack) {
        let shouldPlay = session.phase == .running && session.intervalKind.isFocus
        audioService.select(track, playImmediately: shouldPlay)
    }

    internal func startSession() {
        session.start(now: currentDate())
        startCurrentInterval()
    }

    internal func pauseSession() {
        let completion = session.pause(now: currentDate())
        if let completion {
            handleCompletion(completion)
            return
        }
        stopTimer()
        completionNotifier.cancelPendingCompletion()
        audioService.pause()
        sessionCheckpointStore.save(session)
    }

    internal func resumeSession() {
        session.resume(now: currentDate())
        guard session.phase == .running else { return }
        if session.intervalKind.isFocus {
            audioService.resume()
        }
        sessionCheckpointStore.save(session)
        scheduleCompletion()
        startTimer()
    }

    internal func startNextSession() {
        session.startNext(now: currentDate())
        startCurrentInterval()
    }

    internal func resetSession() {
        session.reset()
        stopTimer()
        completionNotifier.cancelPendingCompletion()
        audioService.stop()
        sessionCheckpointStore.clear()
    }

    internal func becameActive() {
        refresh()
        isAppActive = true
        progressSummary = progressRepository.summary(on: currentDate())
        if session.phase == .running {
            startTimer()
        }
    }

    internal func becameInactive() {
        isAppActive = false
        refresh()
        if !audioService.isPlaying {
            stopTimer()
        }
    }

    private func startCurrentInterval() {
        guard session.phase == .running else { return }
        if session.intervalKind.isFocus {
            audioService.playSelected()
        } else {
            audioService.stop()
        }
        sessionCheckpointStore.save(session)
        scheduleCompletion()
        startTimer()
    }

    private func scheduleCompletion() {
        guard let endDate = session.endDate, let intervalID = session.currentIntervalID else { return }
        completionNotifier.scheduleCompletion(for: session.intervalKind, at: endDate, intervalID: intervalID)
    }

    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        guard let completion = session.refresh(now: currentDate()) else { return }
        handleCompletion(completion)
    }

    private func handleCompletion(_ completion: CompletedFocusInterval) {
        stopTimer()
        if isAppActive {
            completionNotifier.cancelPendingCompletion()
        }
        audioService.stop()
        progressRepository.record(completion)
        sessionCheckpointStore.save(session)
        progressSummary = progressRepository.summary(on: currentDate())
    }

    private func restoreSession() {
        guard session.phase == .running else { return }
        if let completion = session.refresh(now: currentDate()) {
            handleCompletion(completion)
            return
        }
        scheduleCompletion()
        startTimer()
    }
}
