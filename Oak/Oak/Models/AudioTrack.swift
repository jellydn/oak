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
        case .none: "speaker.slash"
        case .rain: "cloud.rain"
        case .forest: "tree"
        case .cafe: "cup.and.saucer"
        case .brownNoise: "waveform"
        case .lofi: "music.note"
        }
    }

    var bundledFileBaseName: String? {
        switch self {
        case .none:
            nil
        case .rain:
            "ambient_rain"
        case .forest:
            "ambient_forest"
        case .cafe:
            "ambient_cafe"
        case .brownNoise:
            "ambient_brown_noise"
        case .lofi:
            "ambient_lofi"
        }
    }

    static let supportedAudioExtensions = ["m4a", "wav", "mp3"]
}
