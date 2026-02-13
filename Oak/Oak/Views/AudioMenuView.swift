import SwiftUI

struct AudioMenuView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var showVolumeControl = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Ambient Sound")
                .font(.headline)
                .padding(.top, 8)

            VStack(spacing: 8) {
                ForEach(AudioTrack.allCases) { track in
                    Button(action: {
                        if audioManager.selectedTrack == track {
                            audioManager.stop()
                        } else {
                            audioManager.play(track: track)
                        }
                    }) {
                        HStack {
                            Image(systemName: track.systemImageName)
                                .frame(width: 24)
                            Text(track.rawValue)
                                .font(.body)
                            Spacer()
                            if audioManager.selectedTrack == track && audioManager.isPlaying {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(audioManager.selectedTrack == track ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Slider(value: $audioManager.volume, in: 0...1)
                        .frame(height: 20)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                Text("\(Int(audioManager.volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}
