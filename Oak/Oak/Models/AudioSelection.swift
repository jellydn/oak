import Foundation

internal struct CustomAudioAsset: Equatable, Hashable, Identifiable {
    internal let url: URL

    internal init(url: URL) {
        self.url = url.resolvingSymlinksInPath().standardizedFileURL
    }

    internal var id: String {
        url.path
    }

    internal var name: String {
        url.deletingPathExtension().lastPathComponent
    }
}

internal enum AudioSelection: Equatable, Identifiable {
    case builtIn(AudioTrack)
    case custom(CustomAudioAsset)

    internal var id: String {
        switch self {
        case let .builtIn(track):
            "built-in-\(track.id)"
        case let .custom(asset):
            "custom-\(asset.id)"
        }
    }

    internal var name: String {
        switch self {
        case let .builtIn(track):
            track.rawValue
        case let .custom(asset):
            asset.name
        }
    }

    internal var systemImageName: String {
        switch self {
        case let .builtIn(track):
            track.systemImageName
        case .custom:
            "music.note"
        }
    }

    internal var isNone: Bool {
        self == .builtIn(.none)
    }
}
