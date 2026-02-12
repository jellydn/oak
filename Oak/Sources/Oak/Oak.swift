import SwiftUI
import AppKit

@main
struct OakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindowController: NotchWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        notchWindowController = NotchWindowController()
        notchWindowController?.showWindow(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        notchWindowController?.cleanup()
    }
}

enum SessionState: Equatable {
    case idle
    case running(remainingSeconds: Int, isWorkSession: Bool)
    case paused(remainingSeconds: Int, isWorkSession: Bool)
}

enum Preset: CaseIterable {
    case short
    case long
    
    var workDuration: Int {
        switch self {
        case .short: return 25 * 60
        case .long: return 50 * 60
        }
    }
    
    var breakDuration: Int {
        switch self {
        case .short: return 5 * 60
        case .long: return 10 * 60
        }
    }
    
    var displayName: String {
        switch self {
        case .short: return "25/5"
        case .long: return "50/10"
        }
    }
}

@MainActor
class FocusSessionViewModel: ObservableObject {
    @Published var sessionState: SessionState = .idle
    @Published var selectedPreset: Preset = .short
    
    private var timer: Timer?
    private var currentRemainingSeconds: Int = 0
    private var isWorkSession: Bool = true
    
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
        timer?.invalidate()
        timer = nil
        sessionState = .idle
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}

struct NotchCompanionView: View {
    @StateObject var viewModel = FocusSessionViewModel()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            HStack(spacing: 16) {
                if viewModel.canStart {
                    startView
                } else {
                    sessionView
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 280, height: 60)
    }
    
    private var startView: some View {
        HStack(spacing: 12) {
            Picker("", selection: $viewModel.selectedPreset) {
                ForEach(Preset.allCases, id: \.self) { preset in
                    Text(preset.displayName)
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            
            Button(action: {
                viewModel.startSession()
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private var sessionView: some View {
        HStack(spacing: 12) {
            Text(viewModel.displayTime)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundColor(viewModel.isPaused ? .orange : .primary)
            
            if viewModel.canPause {
                Button(action: {
                    viewModel.pauseSession()
                }) {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else if viewModel.canResume {
                Button(action: {
                    viewModel.resumeSession()
                }) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

class NotchWindowController: NSWindowController {
    private let viewModel = FocusSessionViewModel()
    
    convenience init() {
        let window = NotchWindow()
        self.init(window: window)
        
        let contentView = NotchCompanionView()
        window.contentView = NSHostingView(rootView: contentView)
        
        window.makeKeyAndOrderFront(nil)
    }
    
    func cleanup() {
        (window?.contentView as? NSHostingView<NotchCompanionView>)?.rootView.viewModel.cleanup()
    }
}

class NotchWindow: NSWindow {
    init() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let notchWidth: CGFloat = 300
        let notchHeight: CGFloat = 80
        let xPosition = (screenFrame.width - notchWidth) / 2
        
        super.init(
            contentRect: NSRect(x: xPosition, y: screenFrame.height - notchHeight, width: notchWidth, height: notchHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
    }
}
