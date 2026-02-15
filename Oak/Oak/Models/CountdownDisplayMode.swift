import Foundation

internal enum CountdownDisplayMode: String, CaseIterable {
    case number
    case circleRing

    var displayName: String {
        switch self {
        case .number:
            "Number"
        case .circleRing:
            "Circle Ring"
        }
    }
}
