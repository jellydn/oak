import XCTest
@testable import Oak

final class NotchLayoutTests: XCTestCase {
    func testContentDimensions() {
        XCTAssertEqual(NotchLayout.contentWidth, 132)
        XCTAssertEqual(NotchLayout.contentExpandedWidth, 360)
        XCTAssertEqual(NotchLayout.height, 33)
    }

    func testWindowPadding() {
        XCTAssertEqual(NotchLayout.windowPadding, 12)
    }

    func testWindowDimensionsIncludePadding() {
        XCTAssertEqual(
            NotchLayout.collapsedWidth,
            NotchLayout.contentWidth + NotchLayout.windowPadding,
            "Collapsed window width should equal content width plus padding"
        )

        XCTAssertEqual(
            NotchLayout.expandedWidth,
            NotchLayout.contentExpandedWidth + NotchLayout.windowPadding,
            "Expanded window width should equal content width plus padding"
        )
    }

    func testWindowDimensionsMatchExpectedValues() {
        XCTAssertEqual(NotchLayout.collapsedWidth, 144, "Collapsed window width should be 144")
        XCTAssertEqual(NotchLayout.expandedWidth, 372, "Expanded window width should be 372")
    }
}
