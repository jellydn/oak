import Foundation

/// Generates procedural ambient noise samples for each audio track.
/// Marked `@unchecked Sendable` because instances are created inside `AVAudioSourceNode`
/// render callbacks (audio thread), but each instance is owned exclusively by its render
/// callback—there is no cross-thread sharing of state.
internal final class NoiseGenerator: @unchecked Sendable {
    private var randomState: UInt64
    private var brownNoiseLast: Float = 0
    private var rainPhase: Float = 0

    internal init(seed: UInt64? = nil) {
        if let seed {
            randomState = seed == 0 ? 0xA5A5_5A5A_1234_5678 : seed
        } else {
            var generator = SystemRandomNumberGenerator()
            let generatedSeed = generator.next()
            randomState = generatedSeed == 0 ? 0xA5A5_5A5A_1234_5678 : generatedSeed
        }
    }

    internal func generateBrownNoise() -> Float {
        let white = nextFloat(in: -1 ... 1)
        brownNoiseLast = (brownNoiseLast + (0.02 * white)) / 1.02
        brownNoiseLast *= 3.5
        brownNoiseLast = max(-1, min(1, brownNoiseLast))
        return brownNoiseLast * 0.15
    }

    internal func generateRainNoise() -> Float {
        rainPhase += 0.01
        let maxPhase = Float.pi * 2000
        if rainPhase > maxPhase {
            rainPhase -= maxPhase
        }
        let noise = nextFloat(in: -0.3 ... 0.3)
        let modulation = sin(rainPhase * 2.0) * 0.5 + 0.5
        return noise * modulation
    }

    internal func generateForestNoise() -> Float {
        let noise = nextFloat(in: -0.4 ... 0.4)
        let modulation = sin(nextFloat(in: 0 ... Float.pi * 2)) * 0.3
        return (noise + modulation) * 0.5
    }

    internal func generateCafeNoise() -> Float {
        let base = nextFloat(in: -0.2 ... 0.2)
        let chatter = sin(nextFloat(in: 0 ... Float.pi * 10)) * 0.15
        return base + chatter
    }

    internal func generateLofiNoise() -> Float {
        let noise = nextFloat(in: -0.25 ... 0.25)
        let vinyl = nextFloat(in: -0.05 ... 0.05)
        return noise + vinyl
    }

    internal func generate(_ track: AudioTrack) -> Float {
        switch track {
        case .brownNoise:
            generateBrownNoise()
        case .rain:
            generateRainNoise()
        case .forest:
            generateForestNoise()
        case .cafe:
            generateCafeNoise()
        case .lofi:
            generateLofiNoise()
        case .none:
            0
        }
    }

    private func nextFloat(in range: ClosedRange<Float>) -> Float {
        randomState ^= randomState >> 12
        randomState ^= randomState << 25
        randomState ^= randomState >> 27
        let unit = Float(randomState >> 40) / Float(0x00FF_FFFF)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}
