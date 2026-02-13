import Foundation

internal enum CountdownDisplayMode: String, CaseIterable {
    case number
    case circleRing

    var displayName: String {
        switch self {
        case .number:
            return "Number"
        case .circleRing:
            return "Circle Ring"
        }
    }
}
