import SwiftUI

internal struct CircularProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let ringColor: Color
    let backgroundColor: Color

    init(
        progress: Double,
        lineWidth: CGFloat = 3,
        ringColor: Color = .white,
        backgroundColor: Color = .white.opacity(0.2)
    ) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.ringColor = ringColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
        }
    }
}
