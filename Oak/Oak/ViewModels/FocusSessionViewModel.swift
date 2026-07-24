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
    private var timer: Timer?
    private var autoStartTimer: Timer?
    private var currentRemainingSeconds: Int = 0
    private var isWorkSession: Bool = true
    private var isLongBreak: Bool = false
    private var sessionStartSeconds: Int = 0
    private var sessionEndDate: Date?
    private var currentSessionStartTime: Date?
    private let currentDate: () -> Date
    private var roundTrackingDate: Date
    private var presetSettingsCancellable: AnyCancellable?
    private var lastPlayingAudioTrack: AudioTrack = .none
    private var wasAutoStarted: Bool = false
    let audioManager: AudioManager
    let progressManager: ProgressManager
    let notificationService: any SessionCompletionNotifying
    let completionSoundPlayer: any SessionCompletionSoundPlaying

    init(
        presetSettings: PresetSettingsStore,
        audioManager: AudioManager? = nil,
        progressManager: ProgressManager? = nil,
        notificationService: any SessionCompletionNotifying,
        completionSoundPlayer: (any SessionCompletionSoundPlaying)? = nil,
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.currentDate = currentDate
        roundTrackingDate = Calendar.current.startOfDay(for: currentDate())
        self.audioManager = audioManager ?? AudioManager()
        self.presetSettings = presetSettings
        self.progressManager = progressManager ?? ProgressManager()
        self.notificationService = notificationService
        self.completionSoundPlayer = completionSoundPlayer ?? SystemSessionCompletionSoundPlayer()
        presetSettingsCancellable = presetSettings.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var canStart: Bool {
        if case .idle = sessionState {
            return true
        }
        return false
    }

    var canStartNext: Bool {
        if case .completed = sessionState {
            return true
        }
        return false
    }

    var canPause: Bool {
        if case .running = sessionState {
            return true
        }
        return false
    }

    var canResume: Bool {
        if case .paused = sessionState {
            return true
        }
        return false
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
            guard sessionStartSeconds > 0 else { return 0.0 }
            return Double(sessionStartSeconds - remaining) / Double(sessionStartSeconds)
        case .completed:
            return 0.0
        }
    }

    var isPaused: Bool {
        if case .paused = sessionState {
            return true
        }
        return false
    }

    var isRunning: Bool {
        if case .running = sessionState {
            return true
        }
        return false
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

    deinit {
        timer?.invalidate()
        autoStartTimer?.invalidate()
        presetSettingsCancellable?.cancel()
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
        currentRemainingSeconds = presetSettings.workDuration(for: selectedPreset)
        isWorkSession = true
        isLongBreak = false
        sessionStartSeconds = currentRemainingSeconds
        currentSessionStartTime = Date()
        completedRounds = 0
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        startTimer()
    }

    func pauseSession() {
        timer?.invalidate()
        timer = nil
        sessionEndDate = nil
        audioManager.pause()
        sessionState = .paused(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
    }

    func resumeSession() {
        audioManager.resume()
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        startTimer()
    }

    func startNextSession(isAutoStart: Bool = false) {
        resetCompletedRoundsIfNeeded()
        guard case let .completed(completedWorkSession) = sessionState else {
            return
        }

        if autoStartCountdown > 0 {
            autoStartTimer?.invalidate()
            autoStartTimer = nil
            autoStartCountdown = 0
        }

        wasAutoStarted = isAutoStart
        isWorkSession = !completedWorkSession

        if isWorkSession {
            currentRemainingSeconds = presetSettings.workDuration(for: selectedPreset)
            isLongBreak = false
        } else if shouldUseLongBreak {
            currentRemainingSeconds = presetSettings.longBreakDuration(for: selectedPreset)
            isLongBreak = true
        } else {
            currentRemainingSeconds = presetSettings.breakDuration(for: selectedPreset)
            isLongBreak = false
        }

        sessionStartSeconds = currentRemainingSeconds
        currentSessionStartTime = Date()
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)

        if isWorkSession && lastPlayingAudioTrack != .none {
            audioManager.play(track: lastPlayingAudioTrack)
        }

        startTimer()
    }

    func resetSession() {
        timer?.invalidate()
        timer = nil
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        currentRemainingSeconds = 0
        isWorkSession = true
        isLongBreak = false
        sessionStartSeconds = 0
        sessionEndDate = nil
        currentSessionStartTime = nil
        isSessionComplete = false
        completedRounds = 0
        autoStartCountdown = 0
        lastPlayingAudioTrack = .none
        wasAutoStarted = false
        audioManager.stop()
        sessionState = .idle
    }

    private func startTimer() {
        timer?.invalidate()
        sessionEndDate = Date().addingTimeInterval(TimeInterval(currentRemainingSeconds))
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard let sessionEndDate else {
            completeSession()
            return
        }
        currentRemainingSeconds = max(0, Int(ceil(sessionEndDate.timeIntervalSinceNow)))

        if currentRemainingSeconds <= 0 {
            completeSession()
        } else {
            sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        }
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

        let durationMinutes = (sessionStartSeconds - currentRemainingSeconds) / 60
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

        timer?.invalidate()
        timer = nil
        sessionEndDate = nil
        sessionState = .completed(isWorkSession: isWorkSession)

        isSessionComplete = true

        Task {
            try? await Task.sleep(nanoseconds: 1500000000)
            isSessionComplete = false

            if presetSettings.autoStartNextInterval {
                startAutoStartCountdown()
            }
        }
    }

    private func startAutoStartCountdown() {
        autoStartCountdown = 10
        autoStartTimer?.invalidate()
        autoStartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickAutoStartCountdown()
            }
        }
    }

    private func tickAutoStartCountdown() {
        autoStartCountdown -= 1
        if autoStartCountdown <= 0 {
            autoStartTimer?.invalidate()
            autoStartTimer = nil
            autoStartCountdown = 0
            if case .completed = sessionState {
                startNextSession(isAutoStart: true)
            }
        }
    }
}
