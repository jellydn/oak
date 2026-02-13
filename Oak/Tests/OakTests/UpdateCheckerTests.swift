import XCTest
@testable import Oak

final class UpdateCheckerTests: XCTestCase {
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
    
    func testHandles403RateLimitResponse() async throws {
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
            try? await Task.sleep(nanoseconds: 100_000_000)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }
    
    func testHandles429RateLimitResponse() async throws {
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
            try? await Task.sleep(nanoseconds: 100_000_000)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }
    
    // MARK: - URL Validation Tests
    
    func testValidatesGitHubURL() {
        let validURLs = [
            URL(string: "https://github.com/jellydn/oak/releases/tag/v1.0.0")!,
            URL(string: "https://api.github.com/repos/jellydn/oak/releases")!,
            URL(string: "https://raw.githubusercontent.com/jellydn/oak/main/README.md")!
        ]
        
        for url in validURLs {
            let host = url.host
            let isValidGitHub = host == "github.com" ||
                               host == "api.github.com" ||
                               host == "raw.githubusercontent.com"
            XCTAssertTrue(isValidGitHub, "Expected \(url) to be a valid GitHub URL")
        }
    }
    
    func testRejectsMaliciousURLs() {
        let invalidURLs = [
            URL(string: "https://evil.com/releases")!,
            URL(string: "https://github.com.evil.com/releases")!,
            URL(string: "https://notgithub.com/releases")!,
            URL(string: "https://evilgithub.com/releases")!,
            URL(string: "https://mygithub.com/releases")!
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

private final class MockURLProtocol: URLProtocol {
    static var statusCode = 200
    static var responseData = Data()

    override class func canInit(with request: URLRequest) -> Bool {
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
