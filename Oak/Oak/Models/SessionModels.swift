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

    var longBreakDuration: Int {
        defaultLongBreakMinutes * 60
    }

    var defaultWorkMinutes: Int {
        switch self {
        case .short: 25
        case .long: 50
        }
    }

    var defaultBreakMinutes: Int {
        switch self {
        case .short: 5
        case .long: 10
        }
    }

    var defaultLongBreakMinutes: Int {
        switch self {
        case .short: 15
        case .long: 20
        }
    }

    var displayName: String {
        switch self {
        case .short: "25/5"
        case .long: "50/10"
        }
    }
}

internal enum DisplayTarget: String, CaseIterable, Identifiable {
    case mainDisplay
    case notchedDisplay

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .mainDisplay: "Main display"
        case .notchedDisplay: "Notched display"
        }
    }
}
