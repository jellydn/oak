import SwiftUI

internal struct ProgressMenuView: View {
    @ObservedObject var viewModel: FocusSessionViewModel
    private var palette: ThemePalette {
        viewModel.presetSettings.theme.palette
    }

    private var completedSessionsText: String {
        let suffix = viewModel.todayCompletedSessions == 1 ? "" : "s"
        return "\(viewModel.todayCompletedSessions) session\(suffix)"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .padding(.top, 8)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(palette.accent)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.todayFocusMinutes) min")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Focus Time")
                            .font(.caption)
                            .foregroundColor(palette.secondaryForeground)
                    }
                    Spacer()
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(palette.success)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(completedSessionsText)
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(palette.secondaryForeground)
                    }
                    Spacer()
                }

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(palette.warning)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            "\(viewModel.streakDays) day\(viewModel.streakDays == 1 ? "" : "s")"
                        )
                        .font(.body)
                        .fontWeight(.semibold)
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(palette.secondaryForeground)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 8)

            if !viewModel.todaySessions.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Timeline", comment: "Progress menu timeline section title"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(palette.secondaryForeground)
                        .padding(.horizontal, 8)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.todaySessions) { session in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(colorForSessionType(session.type))
                                        .frame(width: 8, height: 8)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(titleForSessionType(session.type))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(timeRangeString(start: session.startTime, end: session.endTime))
                                            .font(.caption2)
                                            .foregroundColor(palette.secondaryForeground)
                                    }

                                    Spacer()

                                    Text("\(session.durationMinutes)m")
                                        .font(.caption)
                                        .foregroundColor(palette.secondaryForeground)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(palette.controlBackground)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 200)
                }
            } else {
                Spacer()
            }
        }
        .padding()
        .foregroundColor(palette.foreground)
        .tint(palette.accent)
        .background(palette.background)
        .preferredColorScheme(palette.colorScheme)
    }

    private func colorForSessionType(_ type: SessionType) -> Color {
        switch type {
        case .work: palette.accent
        case .shortBreak: palette.success
        case .longBreak: palette.warning
        }
    }

    private func titleForSessionType(_ type: SessionType) -> String {
        switch type {
        case .work:
            String(localized: "Focus", comment: "Timeline label for a focus session")
        case .shortBreak:
            String(localized: "Short Break", comment: "Timeline label for a short break session")
        case .longBreak:
            String(localized: "Long Break", comment: "Timeline label for a long break session")
        }
    }

    private func timeRangeString(start: Date, end: Date) -> String {
        "\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }
}
