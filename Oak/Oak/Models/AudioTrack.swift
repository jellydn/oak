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

    var bundledFileBaseName: String? {
        switch self {
        case .none:
            return nil
        case .rain:
            return "ambient_rain"
        case .forest:
            return "ambient_forest"
        case .cafe:
            return "ambient_cafe"
        case .brownNoise:
            return "ambient_brown_noise"
        case .lofi:
            return "ambient_lofi"
        }
    }

    static let supportedAudioExtensions = ["m4a", "wav", "mp3"]
}
