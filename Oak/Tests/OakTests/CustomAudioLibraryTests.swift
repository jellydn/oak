import Foundation
import XCTest
@testable import Oak

internal final class CustomAudioLibraryTests: XCTestCase {
    private var rootURL: URL!
    private var libraryURL: URL!
    private var sourceURL: URL!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CustomAudioLibraryTests-\(UUID().uuidString)", isDirectory: true)
        libraryURL = rootURL.appendingPathComponent("Library", isDirectory: true)
        sourceURL = rootURL.appendingPathComponent("Sources", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: rootURL)
        rootURL = nil
        libraryURL = nil
        sourceURL = nil
    }

    func testImportCopiesAudioIntoPersistentLibrary() throws {
        let source = try makeSource(named: "Ocean.mp3")
        let library = makeLibrary()

        let imported = try library.importAudio(from: source)
        let reloadedAssets = try makeLibrary().assets()

        XCTAssertEqual(imported.name, "Ocean")
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(reloadedAssets, [imported])
    }

    func testImportKeepsBothAssetsWhenNamesMatch() throws {
        let source = try makeSource(named: "Ocean.mp3")
        let library = makeLibrary()

        let first = try library.importAudio(from: source)
        let second = try library.importAudio(from: source)

        XCTAssertEqual(first.name, "Ocean")
        XCTAssertEqual(second.name, "Ocean (2)")
        XCTAssertEqual(try library.assets().count, 2)
    }

    func testImportRejectsUnsupportedFormat() throws {
        let source = try makeSource(named: "notes.txt")

        XCTAssertThrowsError(try makeLibrary().importAudio(from: source)) { error in
            XCTAssertEqual(error as? CustomAudioLibraryError, .unsupportedFormat)
        }
    }

    func testImportRejectsInvalidAudio() throws {
        let source = try makeSource(named: "broken.mp3")
        let library = CustomAudioLibrary(directoryURL: libraryURL) { _ in false }

        XCTAssertThrowsError(try library.importAudio(from: source)) { error in
            XCTAssertEqual(error as? CustomAudioLibraryError, .invalidAudio)
        }
        XCTAssertEqual(try library.assets(), [])
    }

    func testRemoveDeletesManagedCopy() throws {
        let library = makeLibrary()
        let asset = try library.importAudio(from: makeSource(named: "Ocean.mp3"))

        try library.remove(asset)

        XCTAssertFalse(FileManager.default.fileExists(atPath: asset.url.path))
        XCTAssertEqual(try library.assets(), [])
    }

    func testRemoveRejectsFileOutsideLibrary() throws {
        let source = try makeSource(named: "Ocean.mp3")

        XCTAssertThrowsError(try makeLibrary().remove(CustomAudioAsset(url: source))) { error in
            XCTAssertEqual(error as? CustomAudioLibraryError, .outsideLibrary)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    private func makeLibrary() -> CustomAudioLibrary {
        CustomAudioLibrary(directoryURL: libraryURL) { _ in true }
    }

    private func makeSource(named name: String) throws -> URL {
        let url = sourceURL.appendingPathComponent(name)
        try Data("test audio".utf8).write(to: url)
        return url
    }
}
