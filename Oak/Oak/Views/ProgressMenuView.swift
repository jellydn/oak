import SwiftUI

internal struct ProgressMenuView: View {
    @ObservedObject var viewModel: FocusSessionViewModel
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
                        Text(completedSessionsText)
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
                        Text(
                            "\(viewModel.streakDays) day\(viewModel.streakDays == 1 ? "" : "s")"
                        )
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

            if !viewModel.todaySessions.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Timeline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.todaySessions.sorted { $0.startTime > $1.startTime }) { session in
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
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(session.durationMinutes)m")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
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
    }

    private func colorForSessionType(_ type: SessionType) -> Color {
        switch type {
        case .work: .blue
        case .shortBreak: .green
        case .longBreak: .orange
        }
    }

    private func titleForSessionType(_ type: SessionType) -> String {
        switch type {
        case .work: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }

    private func timeRangeString(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
