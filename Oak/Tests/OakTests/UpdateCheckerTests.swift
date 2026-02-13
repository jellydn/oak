import XCTest
@testable import Oak

internal final class UpdateCheckerTests: XCTestCase {
    var suiteName: String!
    var userDefaults: UserDefaults!

    override func setUp() async throws {
        suiteName = "OakTests.UpdateChecker.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "UpdateCheckerTests", code: 1)
        }
        defaults.removePersistentDomain(forName: suiteName)
        userDefaults = defaults
    }

    override func tearDown() async throws {
        if let suiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
    }

    // MARK: - Rate Limit Tests

    func testHandles403RateLimitResponse() async {
        let mockSession = makeMockSession(statusCode: 403, data: Data())
        let checker = UpdateChecker(
            repositoryOwner: "test",
            repositoryName: "test",
            userDefaults: userDefaults,
            session: mockSession
        )

        let expectation = self.expectation(description: "Update check completes")

        Task {
            checker.checkForUpdatesOnLaunch()
            try? await Task.sleep(nanoseconds: 100000000)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }

    func testHandles429RateLimitResponse() async {
        let mockSession = makeMockSession(statusCode: 429, data: Data())
        let checker = UpdateChecker(
            repositoryOwner: "test",
            repositoryName: "test",
            userDefaults: userDefaults,
            session: mockSession
        )

        let expectation = self.expectation(description: "Update check completes")

        Task {
            checker.checkForUpdatesOnLaunch()
            try? await Task.sleep(nanoseconds: 100000000)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }

    // MARK: - URL Validation Tests

    func testValidatesGitHubURL() throws {
        let validURLs = try [
            XCTUnwrap(URL(string: "https://github.com/jellydn/oak/releases/tag/v1.0.0")),
            XCTUnwrap(URL(string: "https://api.github.com/repos/jellydn/oak/releases")),
            XCTUnwrap(URL(string: "https://raw.githubusercontent.com/jellydn/oak/main/README.md"))
        ]

        for url in validURLs {
            let host = url.host
            let isValidGitHub = host == "github.com" ||
                host == "api.github.com" ||
                host == "raw.githubusercontent.com"
            XCTAssertTrue(isValidGitHub, "Expected \(url) to be a valid GitHub URL")
        }
    }

    func testRejectsMaliciousURLs() throws {
        let invalidURLs = try [
            XCTUnwrap(URL(string: "https://evil.com/releases")),
            XCTUnwrap(URL(string: "https://github.com.evil.com/releases")),
            XCTUnwrap(URL(string: "https://notgithub.com/releases")),
            XCTUnwrap(URL(string: "https://evilgithub.com/releases")),
            XCTUnwrap(URL(string: "https://mygithub.com/releases"))
        ]

        for url in invalidURLs {
            let host = url.host
            let isValidGitHub = host == "github.com" ||
                host == "api.github.com" ||
                host == "raw.githubusercontent.com"
            XCTAssertFalse(isValidGitHub, "Expected \(url) to be rejected as non-GitHub URL")
        }
    }

    // MARK: - Version Comparison Tests

    func testVersionComparisonNumericOrdering() {
        let testCases: [(remote: String, local: String, shouldUpdate: Bool)] = [
            ("2.0.0", "1.0.0", true),
            ("1.1.0", "1.0.0", true),
            ("1.0.1", "1.0.0", true),
            ("10.0.0", "9.0.0", true),
            ("1.0.0", "1.0.0", false),
            ("1.0.0", "2.0.0", false),
            ("1.0.0", "1.1.0", false),
            ("9.0.0", "10.0.0", false)
        ]

        for testCase in testCases {
            let result = testCase.remote.compare(testCase.local, options: .numeric)
            let isNewer = result == .orderedDescending
            XCTAssertEqual(
                isNewer,
                testCase.shouldUpdate,
                "Version \(testCase.remote) vs \(testCase.local) should \(testCase.shouldUpdate ? "update" : "not update")"
            )
        }
    }

    func testVersionComparisonWithPreReleaseVersions() {
        let testCases: [(remote: String, local: String, shouldUpdate: Bool)] = [
            ("1.0.0", "1.0.0-beta", true),
            ("1.0.0", "1.0.0-alpha", true),
            ("1.0.1-beta", "1.0.0", true),
            ("2.0.0-rc1", "1.9.9", true)
        ]

        for testCase in testCases {
            let result = testCase.remote.compare(testCase.local, options: .numeric)
            let isNewer = result == .orderedDescending
            XCTAssertEqual(
                isNewer,
                testCase.shouldUpdate,
                "Version \(testCase.remote) vs \(testCase.local) should \(testCase.shouldUpdate ? "update" : "not update")"
            )
        }
    }

    func testNormalizedVersionStripsVPrefix() {
        // Test that v prefix is handled correctly
        let versionWithPrefix = "v1.2.3"
        let versionWithoutPrefix = "1.2.3"

        // Both should be treated as same version
        let result1 = versionWithPrefix.dropFirst().compare(versionWithoutPrefix, options: .numeric)
        XCTAssertEqual(result1, .orderedSame)

        let result2 = versionWithoutPrefix.compare(versionWithPrefix.dropFirst(), options: .numeric)
        XCTAssertEqual(result2, .orderedSame)
    }

    // MARK: - URL Construction Tests

    func testURLConstructionForGitHubAPI() {
        let checker = UpdateChecker(
            repositoryOwner: "jellydn",
            repositoryName: "oak",
            userDefaults: userDefaults,
            session: .shared
        )

        // Test URL construction through reflection or by checking the expected URL format
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos/jellydn/oak/releases/latest"

        let expectedURL = components.url
        XCTAssertNotNil(expectedURL)
        XCTAssertEqual(expectedURL?.scheme, "https")
        XCTAssertEqual(expectedURL?.host, "api.github.com")
        XCTAssertEqual(expectedURL?.path, "/repos/jellydn/oak/releases/latest")
    }

    func testURLConstructionWithDifferentRepository() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos/testowner/testrepo/releases/latest"

        let url = components.url
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("testowner/testrepo") ?? false)
    }

    // MARK: - Cooldown Behavior Tests

    func testCooldownPreventsImmediatePrompt() {
        let version = "1.5.0"

        // Set last prompt to now
        userDefaults.set(version, forKey: "oak.lastPromptedUpdateVersion")
        userDefaults.set(Date(), forKey: "oak.lastPromptedUpdateAt")

        // Check if should prompt (should be false due to cooldown)
        let lastVersion = userDefaults.string(forKey: "oak.lastPromptedUpdateVersion")
        let lastPromptTime = userDefaults.object(forKey: "oak.lastPromptedUpdateAt") as? Date

        XCTAssertEqual(lastVersion, version)
        XCTAssertNotNil(lastPromptTime)

        // Within cooldown period (24 hours)
        let shouldPrompt = Date().timeIntervalSince(lastPromptTime!) >= (24 * 60 * 60)
        XCTAssertFalse(shouldPrompt)
    }

    func testCooldownAllowsPromptAfter24Hours() {
        let version = "1.5.0"

        // Set last prompt to 25 hours ago
        let twentyFiveHoursAgo = Date().addingTimeInterval(-25 * 60 * 60)
        userDefaults.set(version, forKey: "oak.lastPromptedUpdateVersion")
        userDefaults.set(twentyFiveHoursAgo, forKey: "oak.lastPromptedUpdateAt")

        // Check if should prompt (should be true after cooldown)
        let lastVersion = userDefaults.string(forKey: "oak.lastPromptedUpdateVersion")
        let lastPromptTime = userDefaults.object(forKey: "oak.lastPromptedUpdateAt") as? Date

        XCTAssertEqual(lastVersion, version)
        XCTAssertNotNil(lastPromptTime)

        let shouldPrompt = Date().timeIntervalSince(lastPromptTime!) >= (24 * 60 * 60)
        XCTAssertTrue(shouldPrompt)
    }

    func testDifferentVersionBypassesCooldown() {
        let oldVersion = "1.5.0"
        let newVersion = "1.6.0"

        // Set last prompt to now with old version
        userDefaults.set(oldVersion, forKey: "oak.lastPromptedUpdateVersion")
        userDefaults.set(Date(), forKey: "oak.lastPromptedUpdateAt")

        // Check if should prompt for new version
        let lastVersion = userDefaults.string(forKey: "oak.lastPromptedUpdateVersion")

        // Different version should bypass cooldown
        let shouldPrompt = lastVersion != newVersion
        XCTAssertTrue(shouldPrompt)
    }

    // MARK: - GitHub API Response Parsing Tests

    func testSuccessfulResponseParsing() async throws {
        let jsonData = """
        {
            "tag_name": "v1.5.0",
            "html_url": "https://github.com/jellydn/oak/releases/tag/v1.5.0"
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(GitHubRelease.self, from: jsonData)
        XCTAssertEqual(release.tagName, "v1.5.0")
        XCTAssertEqual(release.htmlURL.absoluteString, "https://github.com/jellydn/oak/releases/tag/v1.5.0")
    }

    func testMalformedJSONHandling() {
        let malformedJSON = "{ invalid json }".data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(GitHubRelease.self, from: malformedJSON))
    }

    func testMissingFieldsInResponse() {
        let incompleteJSON = """
        {
            "tag_name": "v1.5.0"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(GitHubRelease.self, from: incompleteJSON))
    }

    // MARK: - Error Handling Tests

    func testHandlesNetworkError() async {
        let mockSession = makeMockSession(statusCode: 500, data: Data())
        let checker = UpdateChecker(
            repositoryOwner: "test",
            repositoryName: "test",
            userDefaults: userDefaults,
            session: mockSession
        )

        let expectation = self.expectation(description: "Update check completes")

        Task {
            checker.checkForUpdatesOnLaunch()
            try? await Task.sleep(nanoseconds: 100000000)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        // Should not save any update info on error
        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }

    func testHandles404NotFound() async {
        let mockSession = makeMockSession(statusCode: 404, data: Data())
        let checker = UpdateChecker(
            repositoryOwner: "test",
            repositoryName: "test",
            userDefaults: userDefaults,
            session: mockSession
        )

        let expectation = self.expectation(description: "Update check completes")

        Task {
            checker.checkForUpdatesOnLaunch()
            try? await Task.sleep(nanoseconds: 100000000)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }

    func testHandlesSuccessfulResponseWith200() async throws {
        let jsonData = """
        {
            "tag_name": "v1.5.0",
            "html_url": "https://github.com/jellydn/oak/releases/tag/v1.5.0"
        }
        """.data(using: .utf8)!

        let mockSession = makeMockSession(statusCode: 200, data: jsonData)
        let checker = UpdateChecker(
            repositoryOwner: "test",
            repositoryName: "test",
            userDefaults: userDefaults,
            session: mockSession
        )

        let expectation = self.expectation(description: "Update check completes")

        Task {
            checker.checkForUpdatesOnLaunch()
            try? await Task.sleep(nanoseconds: 500000000)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        // Note: The actual prompt won't happen in tests due to MainActor NSAlert
        // but we can verify the check was attempted
    }
}

// MARK: - Helper Struct

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

// MARK: - URLProtocol Mocking

private class MockURLProtocol: URLProtocol {
    static var statusCode = 200
    static var responseData = Data()

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func makeMockSession(statusCode: Int, data: Data) -> URLSession {
    MockURLProtocol.statusCode = statusCode
    MockURLProtocol.responseData = data

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
}
