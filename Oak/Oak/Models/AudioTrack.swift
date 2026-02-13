import AppKit
import Foundation

internal enum AudioTrack: String, CaseIterable, Identifiable {
    case none = "None"
    case rain = "Rain"
    case forest = "Forest"
    case cafe = "Cafe"
    case brownNoise = "Brown Noise"
    case lofi = "Lo-Fi"

    public var id: String {
        rawValue
    }

    var systemImageName: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .forest: return "tree"
        case .cafe: return "cup.and.saucer"
        case .brownNoise: return "waveform"
        case .lofi: return "music.note"
        }
    }
}
