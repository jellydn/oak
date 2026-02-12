import SwiftUI
import Combine

@MainActor
class FocusSessionViewModel: ObservableObject {
    @Published var sessionState: SessionState = .idle
    @Published var selectedPreset: Preset = .short
    
    private var timer: Timer?
    private var currentRemainingSeconds: Int = 0
    private var isWorkSession: Bool = true
    let audioManager = AudioManager()
    
    var canStart: Bool {
        if case .idle = sessionState {
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
        }
    }
    
    func startSession() {
        currentRemainingSeconds = selectedPreset.workDuration
        isWorkSession = true
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
            // Work session complete - start break
            isWorkSession = false
            currentRemainingSeconds = selectedPreset.breakDuration
            sessionState = .running(remainingSeconds: currentRemainingSeconds, isWorkSession: false)
        } else {
            // Break session complete - return to idle
            timer?.invalidate()
            timer = nil
            sessionState = .idle
            audioManager.stop()
        }
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        audioManager.stop()
    }
}
