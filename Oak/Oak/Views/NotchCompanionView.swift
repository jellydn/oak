import SwiftUI

struct NotchCompanionView: View {
    @StateObject var viewModel = FocusSessionViewModel()
    @State private var showAudioMenu = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            HStack(spacing: 16) {
                if viewModel.canStart {
                    startView
                } else {
                    sessionView
                }
                
                audioButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 340, height: 60)
        .popover(isPresented: $showAudioMenu) {
            AudioMenuView(audioManager: viewModel.audioManager)
                .frame(width: 200)
        }
    }
    
    private var startView: some View {
        HStack(spacing: 12) {
            Picker("", selection: $viewModel.selectedPreset) {
                ForEach(Preset.allCases, id: \.self) { preset in
                    Text(preset.displayName)
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            
            Button(action: {
                viewModel.startSession()
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private var sessionView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.displayTime)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.isPaused ? .orange : .primary)
                
                Text(viewModel.currentSessionType)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if viewModel.canPause {
                Button(action: {
                    viewModel.pauseSession()
                }) {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else if viewModel.canResume {
                Button(action: {
                    viewModel.resumeSession()
                }) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var audioButton: some View {
        Button(action: {
            showAudioMenu.toggle()
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.audioManager.isPlaying ? Color.blue.opacity(0.2) : Color.clear)
                    .frame(width: 32, height: 32)
                
                Image(systemName: viewModel.audioManager.selectedTrack.systemImageName)
                    .foregroundColor(viewModel.audioManager.isPlaying ? .blue : .secondary)
                    .font(.system(size: 14))
            }
        }
        .buttonStyle(.plain)
    }
}

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
