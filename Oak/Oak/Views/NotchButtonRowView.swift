import SwiftUI

internal struct NotchButtonRowView: View {
    @ObservedObject var viewModel: FocusSessionViewModel
    let controlSize: CGFloat
    let onAudioToggle: () -> Void
    let onProgressToggle: () -> Void
    let onSettingsToggle: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            audioButton
            progressButton
            settingsButton
        }
    }

    private var audioButton: some View {
        Button(
            action: {
                onAudioToggle()
            },
            label: {
                ZStack {
                    Circle()
                        .fill(viewModel.audioManager.isPlaying ? Color.blue.opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: controlSize, height: controlSize)

                    Image(systemName: viewModel.audioManager.selectedTrack.systemImageName)
                        .foregroundColor(viewModel.audioManager.isPlaying ? .blue : .white.opacity(0.7))
                        .font(.system(size: 9))
                }
            }
        )
        .buttonStyle(.plain)
    }

    private var progressButton: some View {
        Button(
            action: {
                onProgressToggle()
            },
            label: {
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
        )
        .buttonStyle(.plain)
    }

    private var settingsButton: some View {
        Button(
            action: {
                onSettingsToggle()
            },
            label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: controlSize, height: controlSize)

                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 9))
                }
            }
        )
        .buttonStyle(.plain)
        .help("Settings")
    }
}
