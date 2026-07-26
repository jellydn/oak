import Combine
import SwiftUI
import XCTest
@testable import Oak

/// Regression test for the "Not Responding" freeze on startup.
///
/// Before the fix, `PresetSettingsStore.ensureDisplayIDsInitialized()` passed
/// its `@Published` properties as `inout` to `DisplayConfig`. Swift's copy-in
/// copy-out `inout` semantics always write the value back through the
/// `@Published` setter — even when unchanged — which fires `objectWillChange`
/// on every call. Since `preferredDisplayID(for:)` calls
/// `ensureDisplayIDsInitialized()` and is itself read during SwiftUI body
/// evaluation (`isInsideNotch`), every render invalidated the body → infinite
/// loop → Activity Monitor showed "Not Responding".
@MainActor
internal final class DisplayIDInitializationTests: XCTestCase {
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        let suiteName = "OakTests.DisplayIDInit.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "DisplayIDInitializationTests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        cancellables = []
        // Instantiating the store runs ensureDisplayIDsInitialized() in init,
        // resolving the display IDs once.
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() async throws {
        cancellables = nil
        presetSettings = nil
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
        }
    }

    /// Repeatedly calling `preferredDisplayID(for:)` after IDs are initialized
    /// must NOT emit `objectWillChange`. This is the exact path SwiftUI's body
    /// evaluates on every render via `isInsideNotch`.
    func testPreferredDisplayIDDoesNotEmitObjectWillChangeWhenInitialized() {
        // Given: IDs are already resolved during init (screens are available in tests)
        let target = presetSettings.displayTarget
        let firstID = presetSettings.preferredDisplayID(for: target)
        // If screens aren't available in CI, IDs may be nil; skip the assertion
        // but still verify no spurious notifications are sent.
        guard firstID != nil else {
            // Even with nil IDs, repeated calls must not churn notifications.
            assertNoChangeOnRepeatedPreferredDisplayIDCalls()
            return
        }

        assertNoChangeOnRepeatedPreferredDisplayIDCalls()
    }

    /// `setDisplayTarget` also calls `ensureDisplayIDsInitialized()`. Switching
    /// to the same target with no ID change must not emit notifications.
    func testSetDisplayTargetSameValueDoesNotEmitObjectWillChange() {
        let target = presetSettings.displayTarget

        var changeCount = 0
        presetSettings.objectWillChange
            .sink { _ in changeCount += 1 }
            .store(in: &cancellables)

        // Re-set the same target — should be a no-op with no notifications.
        presetSettings.setDisplayTarget(target)
        presetSettings.setDisplayTarget(target)

        // setDisplayTarget may legitimately publish when displayTarget changes,
        // but re-setting the same value should not churn.
        // Allow up to 1 for the internal didSet path, but the key invariant is
        // no repeated churn per call.
        XCTAssertLessThanOrEqual(
            changeCount, 1,
            "Re-setting the same display target should not emit repeated objectWillChange"
        )
    }

    // MARK: - Private helpers

    private func assertNoChangeOnRepeatedPreferredDisplayIDCalls() {
        let target = presetSettings.displayTarget

        var changeCount = 0
        presetSettings.objectWillChange
            .sink { _ in changeCount += 1 }
            .store(in: &cancellables)

        // Simulate SwiftUI body evaluations: many rapid calls to preferredDisplayID.
        for _ in 0 ..< 100 {
            _ = presetSettings.preferredDisplayID(for: target)
        }

        XCTAssertEqual(
            changeCount, 0,
            "preferredDisplayID(for:) must not emit objectWillChange once IDs are initialized. "
                + "This causes an infinite SwiftUI render loop → 'Not Responding'."
        )
    }
}
