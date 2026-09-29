import SwiftUI

internal struct FocusSessionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = FocusSessionViewModel()

    private let background = Color(red: 0.04, green: 0.06, blue: 0.05)
    private let surface = Color(red: 0.09, green: 0.12, blue: 0.10)
    private let accent = Color(red: 0.55, green: 0.76, blue: 0.48)

    internal var body: some View {
        ZStack {
            background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    header
                    presetPicker
                    timer
                    sessionControls
                    AmbientAudioView(
                        audioService: viewModel.audioService,
                        accent: accent,
                        surface: surface,
                        selectTrack: viewModel.selectTrack
                    )
                    progressSummary
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .preferredColorScheme(.dark)
        .tint(accent)
        .onChange(of: scenePhase) { newPhase in
            DispatchQueue.main.async {
                if newPhase == .active {
                    viewModel.becameActive()
                } else {
                    viewModel.becameInactive()
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Oak")
                    .font(.largeTitle.bold())
                Text("Make space for deep work")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(accent)
                .accessibilityHidden(true)
        }
    }

    private var presetPicker: some View {
        Picker("Preset", selection: presetBinding) {
            ForEach(FocusPreset.allCases) { preset in
                Text(preset.title).tag(preset)
            }
        }
        .pickerStyle(.segmented)
        .disabled(viewModel.session.phase != .idle)
    }

    private var presetBinding: Binding<FocusPreset> {
        Binding(
            get: { viewModel.session.selectedPreset },
            set: viewModel.selectPreset
        )
    }

    private var timer: some View {
        ZStack {
            Circle()
                .stroke(surface, lineWidth: 16)
            Circle()
                .trim(from: 0, to: viewModel.session.progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: viewModel.session.progress)

            VStack(spacing: 8) {
                Text(sessionLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
                    .textCase(.uppercase)
                Text(viewModel.session.displayTime)
                    .font(.system(size: 58, weight: .medium, design: .rounded))
                    .monospacedDigit()
                roundIndicator
            }
        }
        .frame(width: 250, height: 250)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sessionLabel)
        .accessibilityValue(viewModel.session.displayTime)
    }

    private var sessionLabel: String {
        switch viewModel.session.phase {
        case .idle:
            "Ready"
        case .running:
            viewModel.session.intervalKind.title
        case .paused:
            "Paused"
        case .completed:
            "\(viewModel.session.intervalKind.title) Complete"
        }
    }

    private var roundIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 4, id: \.self) { index in
                Circle()
                    .fill(index < viewModel.session.completedFocusRounds ? accent : Color.white.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel("\(viewModel.session.completedFocusRounds) of 4 focus rounds")
    }

    @ViewBuilder
    private var sessionControls: some View {
        switch viewModel.session.phase {
        case .idle:
            primaryButton("Start Focus", systemImage: "play.fill", action: viewModel.startSession)
        case .running:
            HStack(spacing: 14) {
                primaryButton("Pause", systemImage: "pause.fill", action: viewModel.pauseSession)
                secondaryButton("Reset", systemImage: "arrow.counterclockwise", action: viewModel.resetSession)
            }
        case .paused:
            HStack(spacing: 14) {
                primaryButton("Resume", systemImage: "play.fill", action: viewModel.resumeSession)
                secondaryButton("Reset", systemImage: "arrow.counterclockwise", action: viewModel.resetSession)
            }
        case .completed:
            HStack(spacing: 14) {
                primaryButton(nextActionTitle, systemImage: "arrow.right", action: viewModel.startNextSession)
                secondaryButton("Done", systemImage: "checkmark", action: viewModel.resetSession)
            }
        }
    }

    private var nextActionTitle: String {
        viewModel.session.intervalKind.isFocus ? "Start Break" : "Start Focus"
    }

    private func primaryButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private func secondaryButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.headline)
            HStack {
                stat(value: "\(viewModel.progressSummary.focusMinutes)", label: "Minutes")
                Divider()
                stat(value: "\(viewModel.progressSummary.completedSessions)", label: "Sessions")
                Divider()
                stat(value: "\(viewModel.progressSummary.streakDays)", label: "Day streak")
            }
            .frame(height: 54)
        }
        .padding(20)
        .background(surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AmbientAudioView: View {
    @ObservedObject var audioService: FocusAudioService
    let accent: Color
    let surface: Color
    let selectTrack: (FocusAmbientTrack) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ambient Audio")
                    .font(.headline)
                Spacer()
                Image(systemName: audioService.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundStyle(audioService.isPlaying ? accent : .secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FocusAmbientTrack.allCases) { track in
                        Button {
                            selectTrack(track)
                        } label: {
                            Label(track.rawValue, systemImage: track.systemImageName)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    audioService.selectedTrack == track
                                        ? accent.opacity(0.25)
                                        : Color.white.opacity(0.06),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(audioService.selectedTrack == track ? .isSelected : [])
                    }
                }
            }

            HStack {
                Image(systemName: "speaker.fill")
                    .accessibilityHidden(true)
                Slider(value: $audioService.volume, in: 0 ... 1)
                    .accessibilityLabel("Ambient Audio volume")
                Image(systemName: "speaker.wave.3.fill")
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
