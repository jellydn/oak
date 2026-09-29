import Foundation

internal enum FocusPreset: String, CaseIterable, Codable, Identifiable {
    case short
    case long

    internal var id: String {
        rawValue
    }

    internal var title: String {
        switch self {
        case .short: "25 / 5"
        case .long: "50 / 10"
        }
    }

    internal var workDuration: Int {
        switch self {
        case .short: 25 * 60
        case .long: 50 * 60
        }
    }

    internal var breakDuration: Int {
        switch self {
        case .short: 5 * 60
        case .long: 10 * 60
        }
    }

    internal var longBreakDuration: Int {
        switch self {
        case .short: 15 * 60
        case .long: 20 * 60
        }
    }
}

internal enum FocusIntervalKind: String, Codable {
    case focus
    case shortBreak
    case longBreak

    internal var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Break"
        case .longBreak: "Long Break"
        }
    }

    internal var isFocus: Bool {
        self == .focus
    }
}

internal enum FocusSessionPhase: String, Codable, Equatable {
    case idle
    case running
    case paused
    case completed
}

internal struct CompletedFocusInterval: Equatable {
    internal let id: UUID
    internal let kind: FocusIntervalKind
    internal let startedAt: Date
    internal let endedAt: Date
    internal let durationSeconds: Int

    internal init(
        id: UUID = UUID(),
        kind: FocusIntervalKind,
        startedAt: Date,
        endedAt: Date,
        durationSeconds: Int
    ) {
        self.id = id
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
    }
}
