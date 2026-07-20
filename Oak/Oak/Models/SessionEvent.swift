import Foundation

/// Input event applied to `SessionEngine`.
///
/// Every event carries `now: Date` so the engine is fully driven by an
/// explicit clock — tests advance time by passing different values.
internal enum SessionEvent: Equatable {
    case start(now: Date)
    case pause(now: Date)
    case resume(now: Date)
    case tick(now: Date)
    case startNext(now: Date, isAutoStart: Bool)
    case reset
}
