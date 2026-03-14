/// Generates procedural ambient noise samples for each audio track.
/// Marked `@unchecked Sendable` because instances are created inside `AVAudioSourceNode`
/// render callbacks (audio thread), but each instance is owned exclusively by its render
/// callback—there is no cross-thread sharing of state.
internal final class NoiseGenerator: @unchecked Sendable {
    private var brownNoiseLast: Float = 0
    private var rainSeed: Float = 0

    func generateBrownNoise() -> Float {
        let white = Float.random(in: -1 ... 1)
        brownNoiseLast = (brownNoiseLast + (0.02 * white)) / 1.02
        brownNoiseLast *= 3.5
        brownNoiseLast = max(-1, min(1, brownNoiseLast))
        return brownNoiseLast * 0.15
    }

    func generateRainNoise() -> Float {
        rainSeed += 0.01
        let maxSeed = Float.pi * 2000
        if rainSeed > maxSeed {
            rainSeed -= maxSeed
        }
        let noise = Float.random(in: -0.3 ... 0.3)
        let modulation = sin(rainSeed * 2.0) * 0.5 + 0.5
        return noise * modulation
    }

    func generateForestNoise() -> Float {
        let noise = Float.random(in: -0.4 ... 0.4)
        let modulation = sin(Float.random(in: 0 ... Float.pi * 2)) * 0.3
        return (noise + modulation) * 0.5
    }

    func generateCafeNoise() -> Float {
        let base = Float.random(in: -0.2 ... 0.2)
        let chatter = sin(Float.random(in: 0 ... Float.pi * 10)) * 0.15
        return base + chatter
    }

    func generateLofiNoise() -> Float {
        let noise = Float.random(in: -0.25 ... 0.25)
        let vinyl = Float.random(in: -0.05 ... 0.05)
        return noise + vinyl
    }
}
