import XCTest
@testable import Oak

/// Tests for the legacy manual UpdateChecker service (now deprecated).
/// These tests verify the manual update checking functionality for backward compatibility.
/// New auto-update functionality is provided by SparkleUpdater.
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
