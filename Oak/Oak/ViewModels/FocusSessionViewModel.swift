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
    private var presetSettingsCancellable: AnyCancellable?
    let audioManager = AudioManager()
    let progressManager: ProgressManager
    let notificationService: any SessionCompletionNotifying
    let completionSoundPlayer: any SessionCompletionSoundPlaying

    init(
        presetSettings: PresetSettingsStore,
        progressManager: ProgressManager? = nil,
        notificationService: any SessionCompletionNotifying,
        completionSoundPlayer: (any SessionCompletionSoundPlaying)? = nil
    ) {
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
        let roundsBeforeLongBreak = presetSettings.roundsBeforeLongBreak
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
                if completedRounds >= roundsBeforeLongBreak {
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
        let roundsBeforeLongBreak = presetSettings.roundsBeforeLongBreak
        switch sessionState {
        case .idle:
            return "Ready"
        case let .running(_, isWork), let .paused(_, isWork):
            if isWork {
                return "Focus"
            } else {
                return isLongBreak ? "Long Break" : "Break"
            }
        case let .completed(isWorkSession):
            if isWorkSession {
                if completedRounds >= roundsBeforeLongBreak {
                    return "Long Break"
                } else {
                    return "Break"
                }
            } else {
                return "Focus"
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

    func selectPreset(_ preset: Preset) {
        guard canStart else { return }
        selectedPreset = preset
    }

    func startSession(using preset: Preset? = nil) {
        if let preset {
            selectedPreset = preset
        }
        currentRemainingSeconds = presetSettings.workDuration(for: selectedPreset)
        isWorkSession = true
        isLongBreak = false
        sessionStartSeconds = currentRemainingSeconds
        completedRounds = 0
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        startTimer()
    }

    func pauseSession() {
        timer?.invalidate()
        timer = nil
        sessionEndDate = nil
        sessionState = .paused(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
    }

    func resumeSession() {
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        startTimer()
    }

    func startNextSession() {
        let roundsBeforeLongBreak = presetSettings.roundsBeforeLongBreak
        guard case let .completed(completedWorkSession) = sessionState else {
            return
        }

        // Cancel auto-start countdown if manually starting
        if autoStartCountdown > 0 {
            autoStartTimer?.invalidate()
            autoStartTimer = nil
            autoStartCountdown = 0
        }

        isWorkSession = !completedWorkSession

        if isWorkSession {
            currentRemainingSeconds = presetSettings.workDuration(for: selectedPreset)
            isLongBreak = false
        } else {
            if completedRounds >= roundsBeforeLongBreak {
                currentRemainingSeconds = presetSettings.longBreakDuration(for: selectedPreset)
                isLongBreak = true
            } else {
                currentRemainingSeconds = presetSettings.breakDuration(for: selectedPreset)
                isLongBreak = false
            }
        }

        sessionStartSeconds = currentRemainingSeconds
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
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
        isSessionComplete = false
        completedRounds = 0
        autoStartCountdown = 0
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
        if isWorkSession {
            let durationMinutes = (sessionStartSeconds - currentRemainingSeconds) / 60
            if durationMinutes > 0 {
                progressManager.recordSessionCompletion(durationMinutes: durationMinutes)
            }
            completedRounds += 1
        } else {
            if isLongBreak {
                completedRounds = 0
            }
        }

        // Send notification
        notificationService.sendSessionCompletionNotification(isWorkSession: isWorkSession)

        // Stop audio when any session ends
        audioManager.stop()

        if presetSettings.playSoundOnSessionCompletion {
            completionSoundPlayer.playCompletionSound()
        }

        timer?.invalidate()
        timer = nil
        sessionEndDate = nil
        sessionState = .completed(isWorkSession: isWorkSession)

        // Trigger UI animations after state is updated
        isSessionComplete = true

        // Reset animation state after 1.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 1500000000)
            isSessionComplete = false
            
            // Start auto-start countdown if enabled
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
                startNextSession()
            }
        }
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

    func cleanup() {
        resetSession()
    }
}
