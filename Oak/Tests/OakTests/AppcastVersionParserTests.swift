import XCTest
@testable import Oak

internal final class AppcastVersionParserTests: XCTestCase {
    func testParsesHighestShortVersionStringAsLatest() {
        let appcast = """
        <rss>
          <channel>
            <item>
              <sparkle:shortVersionString>0.4.3</sparkle:shortVersionString>
            </item>
            <item>
              <sparkle:shortVersionString>0.4.10</sparkle:shortVersionString>
            </item>
            <item>
              <sparkle:shortVersionString>0.4.1</sparkle:shortVersionString>
            </item>
          </channel>
        </rss>
        """

        let version = AppcastVersionParser.latestShortVersion(in: appcast)

        XCTAssertEqual(version, "0.4.10")
    }

    func testIgnoresNonSemanticVersionsAndParsesLatestSemver() {
        let appcast = """
        <rss>
          <channel>
            <item>
              <sparkle:shortVersionString>4009</sparkle:shortVersionString>
            </item>
            <item>
              <sparkle:shortVersionString>0.4.7-beta</sparkle:shortVersionString>
            </item>
            <item>
              <sparkle:shortVersionString>0.4.9</sparkle:shortVersionString>
            </item>
            <item>
              <sparkle:shortVersionString>0.4.10</sparkle:shortVersionString>
            </item>
          </channel>
        </rss>
        """

        let version = AppcastVersionParser.latestShortVersion(in: appcast)

        XCTAssertEqual(version, "0.4.10")
    }

    func testReturnsNilWhenVersionIsMissing() {
        let appcast = """
        <rss>
          <channel>
            <item>
              <title>Oak</title>
            </item>
          </channel>
        </rss>
        """

        let version = AppcastVersionParser.latestShortVersion(in: appcast)

        XCTAssertNil(version)
    }

    func testReturnsNilWhenNoSemanticVersionExists() {
        let appcast = """
        <rss>
          <channel>
            <item>
              <sparkle:shortVersionString>4009</sparkle:shortVersionString>
            </item>
            <item>
              <sparkle:shortVersionString>0.4.9-beta</sparkle:shortVersionString>
            </item>
          </channel>
        </rss>
        """

        let version = AppcastVersionParser.latestShortVersion(in: appcast)

        XCTAssertNil(version)
    }
}
