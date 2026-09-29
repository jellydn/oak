import Foundation

internal enum FocusAmbientTrack: String, CaseIterable, Identifiable {
    case none = "None"
    case rain = "Rain"
    case forest = "Forest"
    case cafe = "Cafe"
    case brownNoise = "Brown Noise"
    case lofi = "Lo-Fi"

    internal var id: String {
        rawValue
    }

    internal var systemImageName: String {
        switch self {
        case .none: "speaker.slash.fill"
        case .rain: "cloud.rain.fill"
        case .forest: "tree.fill"
        case .cafe: "cup.and.saucer.fill"
        case .brownNoise: "waveform"
        case .lofi: "music.note"
        }
    }

    internal var bundledFileName: String? {
        switch self {
        case .none: nil
        case .rain: "ambient_rain"
        case .forest: "ambient_forest"
        case .cafe: "ambient_cafe"
        case .brownNoise: "ambient_brown_noise"
        case .lofi: "ambient_lofi"
        }
    }
}
