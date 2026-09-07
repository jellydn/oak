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

    func testImportCopiesAudioIntoPersistentLibrary() async throws {
        let source = try makeSource(named: "Ocean.mp3")
        let library = makeLibrary()

        let imported = try await library.importAudio(from: source)
        let reloadedAssets = try await makeLibrary().assets()

        XCTAssertEqual(imported.name, "Ocean")
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(reloadedAssets, [imported])
    }

    func testImportKeepsBothAssetsWhenNamesMatch() async throws {
        let source = try makeSource(named: "Ocean.mp3")
        let library = makeLibrary()

        let first = try await library.importAudio(from: source)
        let second = try await library.importAudio(from: source)

        XCTAssertEqual(first.name, "Ocean")
        XCTAssertEqual(second.name, "Ocean (2)")
        let assets = try await library.assets()
        XCTAssertEqual(assets.count, 2)
    }

    func testImportRejectsUnsupportedFormat() async throws {
        let source = try makeSource(named: "notes.txt")

        do {
            _ = try await makeLibrary().importAudio(from: source)
            XCTFail("Import should reject unsupported formats")
        } catch {
            XCTAssertEqual(error as? CustomAudioLibraryError, .unsupportedFormat)
        }
    }

    func testImportRejectsInvalidAudio() async throws {
        let source = try makeSource(named: "broken.mp3")
        let library = CustomAudioLibrary(directoryURL: libraryURL) { _ in false }

        do {
            _ = try await library.importAudio(from: source)
            XCTFail("Import should reject invalid audio")
        } catch {
            XCTAssertEqual(error as? CustomAudioLibraryError, .invalidAudio)
        }
        let assets = try await library.assets()
        XCTAssertEqual(assets, [])
    }

    func testRemoveDeletesManagedCopy() async throws {
        let library = makeLibrary()
        let asset = try await library.importAudio(from: makeSource(named: "Ocean.mp3"))

        try await library.remove(asset)

        XCTAssertFalse(FileManager.default.fileExists(atPath: asset.url.path))
        let assets = try await library.assets()
        XCTAssertEqual(assets, [])
    }

    func testRemoveRejectsFileOutsideLibrary() async throws {
        let source = try makeSource(named: "Ocean.mp3")

        do {
            try await makeLibrary().remove(CustomAudioAsset(url: source))
            XCTFail("Remove should reject files outside the library")
        } catch {
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
