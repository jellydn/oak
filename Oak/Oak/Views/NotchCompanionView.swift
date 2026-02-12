import SwiftUI

struct NotchCompanionView: View {
    @StateObject var viewModel = FocusSessionViewModel()
    
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 280, height: 60)
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
            Text(viewModel.displayTime)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundColor(viewModel.isPaused ? .orange : .primary)
            
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
}
