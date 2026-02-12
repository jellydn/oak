import Foundation

enum SessionState: Equatable {
    case idle
    case running(remainingSeconds: Int, isWorkSession: Bool)
    case paused(remainingSeconds: Int, isWorkSession: Bool)
    case completed(isWorkSession: Bool)
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
