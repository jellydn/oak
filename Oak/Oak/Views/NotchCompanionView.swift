import SwiftUI

struct NotchCompanionView: View {
    let onExpansionChanged: (Bool) -> Void

    @StateObject var viewModel = FocusSessionViewModel()
    @State private var showAudioMenu = false
    @State private var showProgressMenu = false
    @State private var animateCompletion: Bool = false
    @State private var isHovering = false
    @State private var isPinnedExpanded = false

    init(onExpansionChanged: @escaping (Bool) -> Void = { _ in }) {
        self.onExpansionChanged = onExpansionChanged
    }

    private var isExpanded: Bool {
        isPinnedExpanded || isHovering || showAudioMenu || showProgressMenu
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.isSessionComplete ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: viewModel.isSessionComplete ? 2 : 1)
                )

            HStack(spacing: 8) {
                if isExpanded {
                    if viewModel.canStart {
                        startView
                    } else {
                        sessionView
                    }

                    Spacer()

                    audioButton
                    progressButton
                } else {
                    compactView
                }

                expandToggleButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .scaleEffect(animateCompletion ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateCompletion)
        }
        .frame(width: isExpanded ? 300 : 132, height: 48)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onChange(of: isExpanded) { expanded in
            DispatchQueue.main.async {
                onExpansionChanged(expanded)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                onExpansionChanged(isExpanded)
            }
        }
        .onChange(of: viewModel.isSessionComplete) { isComplete in
            if isComplete {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    animateCompletion = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateCompletion = false
                    }
                }
            }
        }
        .popover(isPresented: $showAudioMenu) {
            AudioMenuView(audioManager: viewModel.audioManager)
                .frame(width: 200)
        }
        .popover(isPresented: $showProgressMenu) {
            ProgressMenuView(viewModel: viewModel)
                .frame(width: 200)
        }
    }

    private var compactView: some View {
        HStack(spacing: 8) {
            if viewModel.canStart {
                Text(viewModel.selectedPreset.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Button(action: {
                    viewModel.startSession()
                }) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                Text(viewModel.displayTime)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.isPaused ? .orange : .primary)
            }
        }
    }

    private var startView: some View {
        HStack(spacing: 8) {
            Picker("", selection: $viewModel.selectedPreset) {
                ForEach(Preset.allCases, id: \.self) { preset in
                    Text(preset.displayName)
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 90)

            Button(action: {
                viewModel.startSession()
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var sessionView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.displayTime)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.isPaused ? .orange : .primary)

                Text(viewModel.currentSessionType)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if viewModel.canPause {
                Button(action: {
                    viewModel.pauseSession()
                }) {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
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
                        .frame(width: 26, height: 26)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else if viewModel.canStartNext {
                Button(action: {
                    viewModel.startNextSession()
                }) {
                    Image(systemName: "forward.fill")
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.blue)
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
                    .frame(width: 24, height: 24)

                Image(systemName: viewModel.audioManager.selectedTrack.systemImageName)
                    .foregroundColor(viewModel.audioManager.isPlaying ? .blue : .secondary)
                    .font(.system(size: 12))
            }
        }
        .buttonStyle(.plain)
    }

    private var progressButton: some View {
        Button(action: {
            showProgressMenu.toggle()
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.streakDays > 0 ? Color.orange.opacity(0.2) : Color.clear)
                    .frame(width: 24, height: 24)

                if viewModel.streakDays > 0 {
                    Text("\(viewModel.streakDays)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var expandToggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                isPinnedExpanded.toggle()
            }
        }) {
            Image(systemName: isExpanded ? "chevron.compact.left" : "chevron.compact.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 16, height: 24)
        }
        .buttonStyle(.plain)
        .help(isExpanded ? "Collapse" : "Expand")
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

struct ProgressMenuView: View {
    @ObservedObject var viewModel: FocusSessionViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .padding(.top, 8)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.todayFocusMinutes) min")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Focus Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.todayCompletedSessions) session\(viewModel.todayCompletedSessions == 1 ? "" : "s")")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.streakDays) day\(viewModel.streakDays == 1 ? "" : "s")")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding()
    }
}
