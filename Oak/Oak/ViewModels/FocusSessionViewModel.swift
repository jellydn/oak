import SwiftUI
import Combine

@MainActor
class FocusSessionViewModel: ObservableObject {
    @Published var sessionState: SessionState = .idle
    @Published var selectedPreset: Preset = .short
    @Published var isSessionComplete: Bool = false

    private var timer: Timer?
    private var currentRemainingSeconds: Int = 0
    private var isWorkSession: Bool = true
    private var sessionStartSeconds: Int = 0
    let audioManager = AudioManager()
    let progressManager = ProgressManager()

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
            minutes = selectedPreset.workDuration / 60
            seconds = 0
        case .running(let remaining, _), .paused(let remaining, _):
            minutes = remaining / 60
            seconds = remaining % 60
        case .completed(let isWorkSession):
            if isWorkSession {
                minutes = selectedPreset.breakDuration / 60
            } else {
                minutes = selectedPreset.workDuration / 60
            }
            seconds = 0
        }

        return String(format: "%02d:%02d", minutes, seconds)
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
        case .running(_, let isWork), .paused(_, let isWork):
            return isWork ? "Focus" : "Break"
        case .completed(let isWorkSession):
            return isWorkSession ? "Break" : "Focus"
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

    func startSession() {
        currentRemainingSeconds = selectedPreset.workDuration
        isWorkSession = true
        sessionStartSeconds = currentRemainingSeconds
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
        guard case .completed(let completedWorkSession) = sessionState else {
            return
        }

        isWorkSession = !completedWorkSession
        currentRemainingSeconds = isWorkSession ? selectedPreset.workDuration : selectedPreset.breakDuration
        sessionStartSeconds = currentRemainingSeconds
        sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: isWorkSession)
        startTimer()
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
        isSessionComplete = true

        if isWorkSession {
            // Work session complete - record progress
            let durationMinutes = (sessionStartSeconds - currentRemainingSeconds) / 60
            if durationMinutes > 0 {
                progressManager.recordSessionCompletion(durationMinutes: durationMinutes)
            }
        } else {
            // Break session complete - stop audio
            audioManager.stop()
        }

        // Stop audio when any session ends
        audioManager.stop()

        timer?.invalidate()
        timer = nil
        sessionState = .completed(isWorkSession: isWorkSession)

        // Reset animation state after 1.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isSessionComplete = false
        }
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
        audioManager.stop()
    }
}
