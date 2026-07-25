import XCTest
@testable import Oak

internal final class SmokeTests: XCTestCase {
    func testTrue() {
        XCTAssertTrue(true)
    }

    func testAppTargetCanBeImported() {
        // Verify the Oak module is importable and key types exist
        let _: SessionState.Type = SessionState.self
        let _: Preset.Type = Preset.self
        let _: DisplayTarget.Type = DisplayTarget.self
        let _: AudioTrack.Type = AudioTrack.self
    }

    func testPresetHasDefaultValues() {
        XCTAssertEqual(Preset.short.defaultWorkMinutes, 25)
        XCTAssertEqual(Preset.short.defaultBreakMinutes, 5)
        XCTAssertEqual(Preset.long.defaultWorkMinutes, 50)
        XCTAssertEqual(Preset.long.defaultBreakMinutes, 10)
    }

    func testSessionStateIsEquatable() {
        let idle = SessionState.idle
        XCTAssertEqual(idle, SessionState.idle)
    }

    func testAudioTrackHasAllCases() {
        let allCases = AudioTrack.allCases
        XCTAssertEqual(allCases.count, 6, "Should have 6 audio tracks")
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertTrue(allCases.contains(.rain))
        XCTAssertTrue(allCases.contains(.forest))
    }
}
