import AppKit
import Combine
import SwiftUI

internal protocol SessionCompletionSoundPlaying {
    func playCompletionSound()
}

internal struct SystemSessionCompletionSoundPlayer: SessionCompletionSoundPlaying {
    func playCompletionSound() {
        NSSound.beep()
    }
}

@MainActor
internal class FocusSessionViewModel: ObservableObject {
    @Published var sessionState: SessionState = .idle
    @Published var selectedPreset: Preset = .short
    @Published var isSessionComplete: Bool = false
    @Published private(set) var completedRounds: Int = 0
    @Published private(set) var autoStartCountdown: Int = 0

    let presetSettings: PresetSettingsStore
    private var isWorkSession: Bool = true
    private var isLongBreak: Bool = false
    private var currentSessionStartTime: Date?
    private let currentDate: () -> Date
    private var roundTrackingDate: Date
    private var presetSettingsCancellable: AnyCancellable?
    private var timerServiceCancellables = Set<AnyCancellable>()
    private var lastPlayingAudioTrack: AudioTrack = .none
    private var wasAutoStarted: Bool = false
    let audioManager: AudioManager
    let progressManager: ProgressManager
    let notificationService: any SessionCompletionNotifying
    let completionSoundPlayer: any SessionCompletionSoundPlaying
    let timerService: SessionTimerService

    init(
        presetSettings: PresetSettingsStore,
        audioManager: AudioManager? = nil,
        progressManager: ProgressManager? = nil,
        notificationService: any SessionCompletionNotifying,
        completionSoundPlayer: (any SessionCompletionSoundPlaying)? = nil,
        timerService: SessionTimerService? = nil,
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.currentDate = currentDate
        roundTrackingDate = Calendar.current.startOfDay(for: currentDate())
        self.audioManager = audioManager ?? AudioManager()
        self.presetSettings = presetSettings
        self.progressManager = progressManager ?? ProgressManager()
        self.notificationService = notificationService
        self.completionSoundPlayer = completionSoundPlayer ?? SystemSessionCompletionSoundPlayer()
        self.timerService = timerService ?? SessionTimerService()
        presetSettingsCancellable = presetSettings.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        setupTimerServiceBindings()
    }

    var canStart: Bool {
        SessionStateMachine.isIdle(sessionState)
    }

    var canStartNext: Bool {
        SessionStateMachine.isCompleted(sessionState)
    }

    var canPause: Bool {
        SessionStateMachine.isRunning(sessionState)
    }

    var canResume: Bool {
        SessionStateMachine.isPaused(sessionState)
    }

    var displayTime: String {
        let minutes: Int
        let seconds: Int

        switch sessionState {
        case .idle:
            minutes = presetSettings.workDuration(for: selectedPreset) / 60
            seconds = 0
        case let .running(remaining, _), let .paused(remaining, _):
            minutes = remaining / 60
            seconds = remaining % 60
        case let .completed(isWorkSession):
            if isWorkSession {
                if shouldUseLongBreak {
                    minutes = presetSettings.longBreakDuration(for: selectedPreset) / 60
                } else {
                    minutes = presetSettings.breakDuration(for: selectedPreset) / 60
                }
            } else {
                minutes = presetSettings.workDuration(for: selectedPreset) / 60
            }
            seconds = 0
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progressPercentage: Double {
        switch sessionState {
        case .idle:
            return 0.0
        case let .running(remaining, _), let .paused(remaining, _):
            let duration = timerService.sessionDuration
            guard duration > 0 else { return 0.0 }
            return Double(duration - remaining) / Double(duration)
        case .completed:
            return 0.0
        }
    }

    var isPaused: Bool {
        SessionStateMachine.isPaused(sessionState)
    }

    var isRunning: Bool {
        SessionStateMachine.isRunning(sessionState)
    }

    var currentSessionType: String {
        switch sessionState {
        case .idle:
            "Ready"
        case let .running(_, isWork), let .paused(_, isWork):
            if isWork {
                "Focus"
            } else {
                isLongBreak ? "Long Break" : "Break"
            }
        case let .completed(isWorkSession):
            if isWorkSession {
                if shouldUseLongBreak {
                    "Long Break"
                } else {
                    "Break"
                }
            } else {
                "Focus"
            }
        }
    }

    var todayFocusMinutes: Int {
        progressManager.dailyStats.todayFocusMinutes
    }

    var todayCompletedSessions: Int {
        progressManager.dailyStats.todayCompletedSessions
    }

    var streakDays: Int {
        progressManager.dailyStats.streakDays
    }

    var todaySessions: [SessionRecord] {
        progressManager.dailyStats.todaySessions
    }

    func cleanup() {
        resetSession()
    }

    private var completedRoundsForCurrentDay: Int {
        guard Calendar.current.isDate(roundTrackingDate, inSameDayAs: currentDate()) else {
            return 0
        }
        return completedRounds
    }

    private var shouldUseLongBreak: Bool {
        completedRoundsForCurrentDay >= presetSettings.roundsBeforeLongBreak
    }

    private func resetCompletedRoundsIfNeeded() {
        let today = Calendar.current.startOfDay(for: currentDate())
        guard !Calendar.current.isDate(roundTrackingDate, inSameDayAs: today) else {
            return
        }

        roundTrackingDate = today
        completedRounds = 0
    }

    private func setupTimerServiceBindings() {
        timerService.$remainingSeconds
            .sink { [weak self] remaining in
                guard let self,
                      let newState = SessionStateMachine.tick(remainingSeconds: remaining, from: sessionState),
                      remaining > 0 else { return }
                sessionState = newState
            }
            .store(in: &timerServiceCancellables)

        timerService.$autoStartCountdown
            .sink { [weak self] count in
                self?.autoStartCountdown = count
            }
            .store(in: &timerServiceCancellables)

        timerService.timerFinished
            .sink { [weak self] in
                self?.completeSession()
            }
            .store(in: &timerServiceCancellables)

        timerService.autoStartFinished
            .sink { [weak self] in
                guard let self, SessionStateMachine.isCompleted(self.sessionState) else { return }
                startNextSession(isAutoStart: true)
            }
            .store(in: &timerServiceCancellables)
    }

    deinit {
        let service = timerService
        Task { @MainActor in
            service.stop()
        }
        presetSettingsCancellable?.cancel()
        timerServiceCancellables.removeAll()
        let manager = audioManager
        Task { @MainActor in
            manager.stop()
        }
    }
}

// MARK: - Session Control

@MainActor
internal extension FocusSessionViewModel {
    func selectPreset(_ preset: Preset) {
        guard canStart else { return }
        selectedPreset = preset
    }

    func startSession(using preset: Preset? = nil) {
        resetCompletedRoundsIfNeeded()
        if let preset {
            selectedPreset = preset
        }
        let seconds = presetSettings.workDuration(for: selectedPreset)
        isWorkSession = true
        isLongBreak = false
        currentSessionStartTime = Date()
        completedRounds = 0
        sessionState = SessionStateMachine.start(duration: seconds, isWorkSession: isWorkSession)
        timerService.start(seconds: seconds)
    }

    func pauseSession() {
        guard let newState = SessionStateMachine.pause(from: sessionState) else { return }
        timerService.pause()
        audioManager.pause()
        sessionState = newState
    }

    func resumeSession() {
        guard let newState = SessionStateMachine.resume(from: sessionState) else { return }
        audioManager.resume()
        sessionState = newState
        timerService.resume()
    }

    func startNextSession(isAutoStart: Bool = false) {
        resetCompletedRoundsIfNeeded()
        guard let completedWorkSession = SessionStateMachine.isWorkSession(in: sessionState),
              SessionStateMachine.isCompleted(sessionState)
        else {
            return
        }

        timerService.cancelAutoStartCountdown()

        wasAutoStarted = isAutoStart
        isWorkSession = !completedWorkSession

        let seconds: Int
        if isWorkSession {
            seconds = presetSettings.workDuration(for: selectedPreset)
            isLongBreak = false
        } else if shouldUseLongBreak {
            seconds = presetSettings.longBreakDuration(for: selectedPreset)
            isLongBreak = true
        } else {
            seconds = presetSettings.breakDuration(for: selectedPreset)
            isLongBreak = false
        }

        currentSessionStartTime = Date()
        sessionState = SessionStateMachine.start(duration: seconds, isWorkSession: isWorkSession)

        if isWorkSession && lastPlayingAudioTrack != .none {
            audioManager.play(track: lastPlayingAudioTrack)
        }

        timerService.start(seconds: seconds)
    }

    func resetSession() {
        timerService.stop()
        isWorkSession = true
        isLongBreak = false
        currentSessionStartTime = nil
        isSessionComplete = false
        completedRounds = 0
        lastPlayingAudioTrack = .none
        wasAutoStarted = false
        audioManager.stop()
        sessionState = SessionStateMachine.reset()
    }

    func completeSession() {
        resetCompletedRoundsIfNeeded()
        let sessionType: SessionType
        if isWorkSession {
            sessionType = .work
            completedRounds += 1
        } else {
            sessionType = isLongBreak ? .longBreak : .shortBreak
            if isLongBreak {
                completedRounds = 0
            }
        }

        let remaining = timerService.remainingSeconds
        let durationMinutes = (timerService.sessionDuration - remaining) / 60
        if durationMinutes > 0, let startTime = currentSessionStartTime {
            progressManager.recordSessionCompletion(
                durationMinutes: durationMinutes,
                type: sessionType,
                startTime: startTime,
                endTime: Date()
            )
        }

        notificationService.sendSessionCompletionNotification(isWorkSession: isWorkSession)

        if isWorkSession || audioManager.isPlaying {
            lastPlayingAudioTrack = audioManager.isPlaying ? audioManager.selectedTrack : .none
        }

        audioManager.stop()

        let shouldPlaySound = if isWorkSession {
            presetSettings.playSoundOnSessionCompletion
        } else {
            presetSettings.playSoundOnBreakCompletion && !wasAutoStarted
        }
        if shouldPlaySound {
            completionSoundPlayer.playCompletionSound()
        }

        sessionState = SessionStateMachine.complete(from: sessionState) ?? .completed(isWorkSession: isWorkSession)

        isSessionComplete = true

        Task {
            try? await Task.sleep(nanoseconds: 1500000000)
            isSessionComplete = false

            if presetSettings.autoStartNextInterval {
                timerService.startAutoStartCountdown()
            }
        }
    }
}
