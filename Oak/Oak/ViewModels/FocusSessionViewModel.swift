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

    let presetSettings: PresetSettingsStore
    private var timer: Timer?
    private var currentRemainingSeconds: Int = 0
    private var isWorkSession: Bool = true
    private var isLongBreak: Bool = false
    private var sessionStartSeconds: Int = 0
    private var presetSettingsCancellable: AnyCancellable?
    let audioManager = AudioManager()
    let progressManager: ProgressManager
    let notificationService: any SessionCompletionNotifying
    let completionSoundPlayer: any SessionCompletionSoundPlaying

    private let roundsBeforeLongBreak = 4

    init(
        presetSettings: PresetSettingsStore,
        progressManager: ProgressManager? = nil,
        notificationService: (any SessionCompletionNotifying)? = nil,
        completionSoundPlayer: (any SessionCompletionSoundPlaying)? = nil
    ) {
        self.presetSettings = presetSettings
        self.progressManager = progressManager ?? ProgressManager()
        self.notificationService = notificationService ?? NotificationService.shared
        self.completionSoundPlayer = completionSoundPlayer ?? SystemSessionCompletionSoundPlayer()
        presetSettingsCancellable = presetSettings.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    convenience init() {
        self.init(presetSettings: PresetSettingsStore.shared, progressManager: nil)
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
                // Work session completed, show next break duration
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
                // Work session completed, show what's next
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
        sessionState = .paused(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
    }

    func resumeSession() {
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        startTimer()
    }

    func startNextSession() {
        guard case let .completed(completedWorkSession) = sessionState else {
            return
        }

        isWorkSession = !completedWorkSession

        if isWorkSession {
            // Starting a new work session
            currentRemainingSeconds = presetSettings.workDuration(for: selectedPreset)
            isLongBreak = false
        } else {
            // Starting a break session
            // Check if we should use long break
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
        currentRemainingSeconds = 0
        isWorkSession = true
        isLongBreak = false
        sessionStartSeconds = 0
        isSessionComplete = false
        completedRounds = 0
        audioManager.stop()
        sessionState = .idle
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        currentRemainingSeconds -= 1

        if currentRemainingSeconds <= 0 {
            completeSession()
        } else {
            sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        }
    }

    private func completeSession() {
        if isWorkSession {
            // Work session complete - record progress and increment rounds
            let durationMinutes = (sessionStartSeconds - currentRemainingSeconds) / 60
            if durationMinutes > 0 {
                progressManager.recordSessionCompletion(durationMinutes: durationMinutes)
            }
            completedRounds += 1
        } else {
            // Break session complete
            // Reset rounds after long break completes
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
        sessionState = .completed(isWorkSession: isWorkSession)

        // Trigger UI animations after state is updated
        isSessionComplete = true

        // Reset animation state after 1.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 1500000000)
            isSessionComplete = false
        }
    }

    func completeSessionForTesting() {
        completeSession()
    }

    deinit {
        timer?.invalidate()
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
