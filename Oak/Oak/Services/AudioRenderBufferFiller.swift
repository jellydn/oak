import AVFoundation
import Foundation

internal enum AudioRenderBufferFiller {
    internal static func fill(
        _ outputBuffer: UnsafeMutablePointer<AudioBufferList>,
        generator: NoiseGenerator,
        track: AudioTrack
    ) {
        let bufferList = UnsafeMutableAudioBufferListPointer(outputBuffer)
        for buffer in bufferList {
            guard let mData = buffer.mData else { continue }
            let frameCount = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
            let samples = mData.assumingMemoryBound(to: Float.self)

            for index in 0 ..< frameCount {
                samples[index] = generator.generate(track)
            }
        }
    }
}
