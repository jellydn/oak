import AVFoundation
import Foundation

internal enum CustomAudioLibraryError: LocalizedError, Equatable {
    case unsupportedFormat
    case invalidAudio
    case outsideLibrary

    internal var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "Choose an M4A, WAV, MP3, AAC, AIFF, or CAF audio file."
        case .invalidAudio:
            "Oak could not read this audio file."
        case .outsideLibrary:
            "Oak can remove only files in your personal sound library."
        }
    }
}

internal final class CustomAudioLibrary {
    internal typealias AudioValidator = (URL) -> Bool

    private let directoryURL: URL
    private let fileManager: FileManager
    private let audioValidator: AudioValidator

    internal init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        audioValidator: @escaping AudioValidator = { CustomAudioLibrary.isPlayableAudio(at: $0) }
    ) {
        self.fileManager = fileManager
        self.audioValidator = audioValidator
        self.directoryURL = directoryURL ?? fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("Oak", isDirectory: true)
        .appendingPathComponent("Sounds", isDirectory: true)
    }

    internal func assets() throws -> [CustomAudioAsset] {
        try createDirectoryIfNeeded()
        return try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        .filter { url in
            AudioTrack.supportedAudioExtensions.contains(url.pathExtension.lowercased())
                && (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }
        .map(CustomAudioAsset.init(url:))
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    internal func importAudio(from sourceURL: URL) throws -> CustomAudioAsset {
        guard AudioTrack.supportedAudioExtensions.contains(sourceURL.pathExtension.lowercased()) else {
            throw CustomAudioLibraryError.unsupportedFormat
        }
        guard audioValidator(sourceURL) else {
            throw CustomAudioLibraryError.invalidAudio
        }

        try createDirectoryIfNeeded()
        let destinationURL = availableDestination(for: sourceURL)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return CustomAudioAsset(url: destinationURL)
    }

    internal func remove(_ asset: CustomAudioAsset) throws {
        let libraryPath = directoryURL.standardizedFileURL.path + "/"
        guard asset.url.standardizedFileURL.path.hasPrefix(libraryPath) else {
            throw CustomAudioLibraryError.outsideLibrary
        }
        try fileManager.removeItem(at: asset.url)
    }

    private func createDirectoryIfNeeded() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func availableDestination(for sourceURL: URL) -> URL {
        let fileExtension = sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var destinationURL = directoryURL.appendingPathComponent(sourceURL.lastPathComponent)
        var suffix = 2

        while fileManager.fileExists(atPath: destinationURL.path) {
            destinationURL = directoryURL
                .appendingPathComponent("\(baseName) (\(suffix))")
                .appendingPathExtension(fileExtension)
            suffix += 1
        }
        return destinationURL
    }

    internal static func isPlayableAudio(at url: URL) -> Bool {
        (try? AVAudioPlayer(contentsOf: url)) != nil
    }
}
