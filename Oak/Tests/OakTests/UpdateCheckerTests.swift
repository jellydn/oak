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
        // Create mock session that returns 403
        let mockSession = MockURLSession(statusCode: 403, data: Data())
        let checker = UpdateChecker(
            repositoryOwner: "test",
            repositoryName: "test",
            userDefaults: userDefaults,
            session: mockSession
        )
        
        // Create expectation for async call
        let expectation = self.expectation(description: "Update check completes")
        
        Task {
            checker.checkForUpdatesOnLaunch()
            // Give it time to complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify no prompt was shown (no userDefaults were set)
        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }
    
    func testHandles429RateLimitResponse() async throws {
        // Create mock session that returns 429
        let mockSession = MockURLSession(statusCode: 429, data: Data())
        let checker = UpdateChecker(
            repositoryOwner: "test",
            repositoryName: "test",
            userDefaults: userDefaults,
            session: mockSession
        )
        
        // Create expectation for async call
        let expectation = self.expectation(description: "Update check completes")
        
        Task {
            checker.checkForUpdatesOnLaunch()
            // Give it time to complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify no prompt was shown (no userDefaults were set)
        XCTAssertNil(userDefaults.string(forKey: "oak.lastPromptedUpdateVersion"))
    }
    
    // MARK: - URL Validation Tests
    // Note: These tests verify host validation only. Scheme (http vs https) is not validated
    // as GitHub API responses always use HTTPS URLs.
    
    func testValidatesGitHubURL() {
        // Valid github.com URLs
        let validURLs = [
            URL(string: "https://github.com/jellydn/oak/releases/tag/v1.0.0")!,
            URL(string: "https://api.github.com/repos/jellydn/oak/releases")!,
            URL(string: "https://raw.githubusercontent.com/jellydn/oak/main/README.md")!
        ]
        
        for url in validURLs {
            XCTAssertTrue(url.host?.hasSuffix("github.com") == true, "Expected \(url) to be a valid GitHub URL")
        }
    }
    
    func testRejectsMaliciousURLs() {
        // Invalid URLs that should be rejected (non-GitHub hosts)
        let invalidURLs = [
            URL(string: "https://evil.com/releases")!,
            URL(string: "https://github.com.evil.com/releases")!,
            URL(string: "https://notgithub.com/releases")!
        ]
        
        for url in invalidURLs {
            let isGitHub = url.host?.hasSuffix("github.com") == true
            XCTAssertFalse(isGitHub, "Expected \(url) to be rejected as non-GitHub URL")
        }
    }
}

// MARK: - Mock URLSession

private class MockURLSession: URLSession {
    let statusCode: Int
    let mockData: Data
    
    init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.mockData = data
    }
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else {
            throw URLError(.badURL)
        }
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        return (mockData, response)
    }
}
