import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class ConfettiViewTests: XCTestCase {
    // MARK: - View Initialization

    func testConfettiViewInitialization() {
        let view = ConfettiView()
        XCTAssertNotNil(view)
    }

    func testConfettiViewWithCustomCount() {
        let view = ConfettiView(count: 50)
        XCTAssertNotNil(view)
    }

    func testDefaultCountIs30() {
        let view = ConfettiView()
        XCTAssertEqual(view.count, 30)
    }

    func testCustomCountPreservesValue() {
        let view = ConfettiView(count: 100)
        XCTAssertEqual(view.count, 100)
    }

    func testZeroCountCreatesView() {
        let view = ConfettiView(count: 0)
        XCTAssertNotNil(view)
    }

    func testLargeCountCreatesView() {
        let view = ConfettiView(count: 1000)
        XCTAssertNotNil(view)
    }

    // MARK: - Animation Duration

    func testAnimationDurationIsPositive() {
        XCTAssertGreaterThan(ConfettiView.animationDuration, 0)
    }

    func testAnimationDurationMatchesDesignConstant() {
        XCTAssertEqual(ConfettiView.animationDuration, 1.2, accuracy: 0.01)
    }

    // MARK: - Particle Generation

    func testGenerateParticlesProducesCorrectCount() {
        let particles = ConfettiParticle.generate(count: 30)
        XCTAssertEqual(particles.count, 30)
    }

    func testGenerateParticlesWithCustomCount() {
        let particles = ConfettiParticle.generate(count: 50)
        XCTAssertEqual(particles.count, 50)
    }

    func testGenerateParticlesWithZeroCount() {
        let particles = ConfettiParticle.generate(count: 0)
        XCTAssertTrue(particles.isEmpty)
    }

    func testGenerateParticlesHaveUniqueIDs() {
        let particles = ConfettiParticle.generate(count: 30)
        let ids = Set(particles.map(\.id))
        XCTAssertEqual(ids.count, 30, "All particles should have unique IDs")
    }

    func testGenerateParticlesHaveTargetsInExpectedRanges() {
        let particles = ConfettiParticle.generate(count: 100)
        for particle in particles {
            XCTAssertGreaterThanOrEqual(particle.targetX, -150)
            XCTAssertLessThanOrEqual(particle.targetX, 150)
            XCTAssertGreaterThanOrEqual(particle.targetY, -100)
            XCTAssertLessThanOrEqual(particle.targetY, 200)
        }
    }

    func testGenerateParticlesHaveRotationsInRange() {
        let particles = ConfettiParticle.generate(count: 100)
        for particle in particles {
            XCTAssertGreaterThanOrEqual(particle.rotation, 0)
            XCTAssertLessThanOrEqual(particle.rotation, 360)
        }
    }

    func testParticleColorsCycleThroughPalette() {
        let particles = ConfettiParticle.generate(count: 14)
        let colorCount = ConfettiPiece.colors.count
        // First particle uses colors[0], particle at index == colorCount uses colors[0] again
        XCTAssertEqual(particles[0].color, ConfettiPiece.colors[0])
        XCTAssertEqual(particles[colorCount].color, ConfettiPiece.colors[0])
    }

    func testParticlesAreDeterministicForSameCount() {
        // Two separate generations should differ due to random targets
        let particles1 = ConfettiParticle.generate(count: 10)
        let particles2 = ConfettiParticle.generate(count: 10)
        // IDs and colors should be the same (deterministic indexing)
        for index in 0 ..< 10 {
            XCTAssertEqual(particles1[index].id, particles2[index].id)
            XCTAssertEqual(particles1[index].color, particles2[index].color)
        }
    }

    // MARK: - ConfettiPiece Colors

    func testConfettiPieceHasSevenColors() {
        XCTAssertEqual(ConfettiPiece.colors.count, 7)
    }

    func testConfettiPieceColorsAreDistinct() {
        let uniqueColors = Set(ConfettiPiece.colors)
        XCTAssertEqual(uniqueColors.count, ConfettiPiece.colors.count, "All colors should be distinct")
    }

    func testConfettiPieceIncludesGreen() {
        XCTAssertTrue(ConfettiPiece.colors.contains(.green))
    }

    func testConfettiPieceIncludesBlue() {
        XCTAssertTrue(ConfettiPiece.colors.contains(.blue))
    }

    func testConfettiPieceIncludesRed() {
        XCTAssertTrue(ConfettiPiece.colors.contains(.red))
    }

    func testConfettiPieceRenders() {
        let piece = ConfettiPiece(color: .green)
        XCTAssertNotNil(piece)
    }

    // MARK: - ConfettiParticle Identifiable

    func testConfettiParticleConformsToIdentifiable() {
        let particle = ConfettiParticle(id: 0, targetX: 10, targetY: 20, rotation: 45, color: .green)
        XCTAssertEqual(particle.id, 0)
    }
}
