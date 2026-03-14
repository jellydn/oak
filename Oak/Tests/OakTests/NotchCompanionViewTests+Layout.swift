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

    func testAudioMenuPopoverFlagCanBeSetTrue() {
        let view = makeView()
        view.showAudioMenu = true
        XCTAssertTrue(view.showAudioMenu, "showAudioMenu flag should be true after being set")
    }

    func testProgressMenuPopoverFlagCanBeSetTrue() {
        let view = makeView()
        view.showProgressMenu = true
        XCTAssertTrue(view.showProgressMenu, "showProgressMenu flag should be true after being set")
    }

    func testSettingsMenuPopoverFlagCanBeSetTrue() {
        let view = makeView()
        view.showSettingsMenu = true
        XCTAssertTrue(view.showSettingsMenu, "showSettingsMenu flag should be true after being set")
    }

    func testAllPopoverFlagsAreIndependent() {
        let view = makeView()
        view.showAudioMenu = true
        view.showProgressMenu = true
        view.showSettingsMenu = true
        XCTAssertTrue(view.showAudioMenu, "Audio menu flag should be independent")
        XCTAssertTrue(view.showProgressMenu, "Progress menu flag should be independent")
        XCTAssertTrue(view.showSettingsMenu, "Settings menu flag should be independent")
    }

    func testPopoverFlagCanBeResetToFalse() {
        let view = makeView()
        view.showAudioMenu = true
        view.showAudioMenu = false
        XCTAssertFalse(view.showAudioMenu, "showAudioMenu should be resettable to false")
    }

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
