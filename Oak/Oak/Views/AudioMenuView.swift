import SwiftUI
import UniformTypeIdentifiers

internal struct AudioMenuView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var isImporting = false
    @State private var importError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sound Library")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    soundSection(title: "Built-in") {
                        ForEach(AudioTrack.allCases) { track in
                            soundRow(.builtIn(track))
                        }
                    }

                    soundSection(title: "My Sounds") {
                        if audioManager.customAssets.isEmpty {
                            Text("Import audio to add a personal sound.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                        } else {
                            ForEach(audioManager.customAssets) { asset in
                                soundRow(.custom(asset), removableAsset: asset)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)

            Button(
                action: { isImporting = true },
                label: {
                    Label("Import Audio…", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
            )
            .accessibilityHint("Copies an audio file into your personal Oak sound library")

            if let error = importError ?? audioManager.audioError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Slider(value: $audioManager.volume, in: 0 ... 1)
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
        }
        .padding()
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let sourceURL = try result.get().first else { return }
                importError = nil
                Task {
                    if let asset = await audioManager.importCustomAudio(from: sourceURL) {
                        audioManager.play(sound: .custom(asset))
                    }
                }
            } catch {
                importError = error.localizedDescription
            }
        }
    }

    private func soundSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            content()
        }
    }

    private func soundRow(
        _ sound: AudioSelection,
        removableAsset: CustomAudioAsset? = nil
    ) -> some View {
        let isSelected = audioManager.selectedSound == sound

        return HStack(spacing: 4) {
            Button(
                action: {
                    if isSelected && audioManager.isPlaying {
                        audioManager.stop()
                    } else {
                        audioManager.play(sound: sound)
                    }
                },
                label: {
                    HStack {
                        Image(systemName: sound.systemImageName)
                            .frame(width: 24)
                        Text(sound.name)
                            .font(.body)
                            .lineLimit(1)
                        Spacer()
                        if isSelected && audioManager.isPlaying {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            )
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected && audioManager.isPlaying ? "Stop \(sound.name)" : "Play \(sound.name)")

            if let removableAsset {
                Button(
                    action: {
                        Task {
                            await audioManager.removeCustomAudio(removableAsset)
                        }
                    },
                    label: {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                )
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(removableAsset.name)")
                .help("Remove from My Sounds")
            }
        }
    }
}
