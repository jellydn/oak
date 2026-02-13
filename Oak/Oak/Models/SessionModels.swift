import Foundation

internal enum SessionState: Equatable {
    case idle
    case running(remainingSeconds: Int, isWorkSession: Bool)
    case paused(remainingSeconds: Int, isWorkSession: Bool)
    case completed(isWorkSession: Bool)
}

internal enum Preset: CaseIterable {
    case short
    case long

    var workDuration: Int {
        defaultWorkMinutes * 60
    }

    var breakDuration: Int {
        defaultBreakMinutes * 60
    }

    var defaultWorkMinutes: Int {
        switch self {
        case .short: return 25
        case .long: return 50
        }
    }

    var defaultBreakMinutes: Int {
        switch self {
        case .short: return 5
        case .long: return 10
        }
    }

    var displayName: String {
        switch self {
        case .short: return "25/5"
        case .long: return "50/10"
        }
    }
}

internal enum DisplayTarget: String, CaseIterable, Identifiable {
    case mainDisplay
    case notchedDisplay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mainDisplay: return "Main display"
        case .notchedDisplay: return "Notched display"
        }
    }
}
