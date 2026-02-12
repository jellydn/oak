import SwiftUI

struct NotchCompanionView: View {
    let onExpansionChanged: (Bool) -> Void

    @StateObject var viewModel = FocusSessionViewModel()
    @State private var showAudioMenu = false
    @State private var showProgressMenu = false
    @State private var animateCompletion: Bool = false
    @State private var isExpandedByToggle = false
    @State private var presetSelection: Preset = .short
    private let collapsedWidth: CGFloat = 132
    private let expandedWidth: CGFloat = 360
    private let notchHeight: CGFloat = 33
    private let horizontalPadding: CGFloat = 6
    private let verticalPadding: CGFloat = 4
    private let contentSpacing: CGFloat = 8
    private let controlSize: CGFloat = 18

    init(onExpansionChanged: @escaping (Bool) -> Void = { _ in }) {
        self.onExpansionChanged = onExpansionChanged
    }

    private var isExpanded: Bool {
        isExpandedByToggle
    }

    private var containerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
    }

    var body: some View {
        ZStack {
            containerShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.78),
                            Color(red: 0.13, green: 0.14, blue: 0.18).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    containerShape
                        .stroke(
                            viewModel.isSessionComplete ? Color.green.opacity(0.45) : Color.white.opacity(0.14),
                            lineWidth: viewModel.isSessionComplete ? 1.4 : 1
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)

            HStack(spacing: contentSpacing) {
                if isExpanded {
                    if viewModel.canStart {
                        startView
                    } else {
                        sessionView
                    }
                    
                    audioButton
                    progressButton
                } else {
                    compactView
                }

                expandToggleButton
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .scaleEffect(animateCompletion ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateCompletion)
        }
        .frame(width: isExpanded ? expandedWidth : collapsedWidth, height: notchHeight)
        .contentShape(Rectangle())
        .onChange(of: isExpanded) { expanded in
            DispatchQueue.main.async {
                onExpansionChanged(expanded)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                onExpansionChanged(isExpanded)
            }
            presetSelection = viewModel.selectedPreset
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
        HStack(spacing: contentSpacing) {
            if viewModel.canStart {
                Text(presetSelection.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.62))

                Button(action: {
                    viewModel.startSession(using: presetSelection)
                }) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.85))
                        )
                }
                .buttonStyle(.plain)
            } else {
                Text(viewModel.displayTime)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.isPaused ? Color.orange.opacity(0.95) : Color.white.opacity(0.95))
            }
        }
    }

    private var startView: some View {
        HStack(spacing: 6) {
            presetSelector

            Button(action: {
                viewModel.startSession(using: presetSelection)
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: controlSize, height: controlSize)
                    .background(Color.green.opacity(0.88))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var sessionView: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.displayTime)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.isPaused ? Color.orange.opacity(0.95) : Color.white.opacity(0.95))

                Text(viewModel.currentSessionType)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.52))
            }

            if viewModel.canPause {
                Button(action: {
                    viewModel.pauseSession()
                }) {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: controlSize, height: controlSize)
                            .background(Color.orange.opacity(0.88))
                            .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else if viewModel.canResume {
                Button(action: {
                    viewModel.resumeSession()
                }) {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: controlSize, height: controlSize)
                            .background(Color.green.opacity(0.88))
                            .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else if viewModel.canStartNext {
                Button(action: {
                    viewModel.startNextSession()
                }) {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: controlSize, height: controlSize)
                            .background(Color.blue.opacity(0.88))
                            .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Button(action: {
                viewModel.resetSession()
            }) {
                Image(systemName: "stop.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 18, height: 18)
                    .background(Color.red.opacity(0.88))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Stop and reset")
        }
    }

    private var audioButton: some View {
        Button(action: {
            showAudioMenu.toggle()
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.audioManager.isPlaying ? Color.blue.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: controlSize, height: controlSize)

                Image(systemName: viewModel.audioManager.selectedTrack.systemImageName)
                    .foregroundColor(viewModel.audioManager.isPlaying ? .blue : .white.opacity(0.7))
                    .font(.system(size: 9))
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
                    .fill(viewModel.streakDays > 0 ? Color.orange.opacity(0.24) : Color.white.opacity(0.08))
                    .frame(width: controlSize, height: controlSize)

                if viewModel.streakDays > 0 {
                    Text("\(viewModel.streakDays)")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 9))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var expandToggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                let shouldExpand = !isExpandedByToggle
                isExpandedByToggle = shouldExpand

                if !shouldExpand {
                    showAudioMenu = false
                    showProgressMenu = false
                }
            }
        }) {
            Image(systemName: isExpanded ? "chevron.compact.left" : "chevron.compact.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
                .frame(width: controlSize, height: controlSize)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(isExpanded ? "Collapse" : "Expand")
    }

    private var presetSelector: some View {
        HStack(spacing: 2) {
            presetChip(.short)
            presetChip(.long)
        }
        .padding(2)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func presetChip(_ preset: Preset) -> some View {
        let isSelected = presetSelection == preset

        return Button(action: {
            presetSelection = preset
        }) {
            Text(preset.displayName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.62))
                .frame(width: 42, height: 18)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.16) : Color.clear)
                )
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
