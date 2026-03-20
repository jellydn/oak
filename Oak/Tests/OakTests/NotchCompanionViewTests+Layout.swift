import XCTest
@testable import Oak

@MainActor
internal extension NotchCompanionViewTests {
    // MARK: - Popover State

    func testShowAudioMenuDefaultsToFalse() {
        let view = makeView()
        XCTAssertFalse(view.showAudioMenu, "showAudioMenu should default to false")
    }

    func testShowProgressMenuDefaultsToFalse() {
        let view = makeView()
        XCTAssertFalse(view.showProgressMenu, "showProgressMenu should default to false")
    }

    func testShowSettingsMenuDefaultsToFalse() {
        let view = makeView()
        XCTAssertFalse(view.showSettingsMenu, "showSettingsMenu should default to false")
    }

    // NOTE: @State properties cannot be tested outside SwiftUI's rendering pipeline.
    // Setting @State on a struct outside a View body is a no-op — SwiftUI manages the storage.

    // MARK: - Preset Selection

    func testDefaultPresetSelectionIsShort() {
        let view = makeView()
        XCTAssertEqual(view.presetSelection, .short, "Default preset selection should be .short")
    }

    func testPresetLabelForShortPresetIsNonEmpty() {
        let view = makeView()
        XCTAssertFalse(view.presetLabel(for: .short).isEmpty, "Short preset label should not be empty")
    }

    func testPresetLabelForLongPresetIsNonEmpty() {
        let view = makeView()
        XCTAssertFalse(view.presetLabel(for: .long).isEmpty, "Long preset label should not be empty")
    }

    func testPresetLabelsAreDifferent() {
        let view = makeView()
        XCTAssertNotEqual(
            view.presetLabel(for: .short),
            view.presetLabel(for: .long),
            "Short and long preset labels should differ"
        )
    }
}
