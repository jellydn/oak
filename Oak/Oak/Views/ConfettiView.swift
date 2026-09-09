import SwiftUI

internal struct ConfettiView: View {
    static let animationDuration: Double = 1.2

    let count: Int
    internal let colors: [Color]
    @State private var animating = false
    @State private var particles: [ConfettiParticle] = []

    internal init(count: Int = 30, colors: [Color] = ConfettiPiece.colors) {
        self.count = count
        self.colors = colors
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiPiece(color: particle.color)
                    .offset(
                        x: animating ? particle.targetX : 0,
                        y: animating ? particle.targetY : 0
                    )
                    .opacity(animating ? 0 : 1)
                    .scaleEffect(animating ? 0 : 1)
                    .rotationEffect(.degrees(animating ? particle.rotation : 0))
            }
        }
        .onAppear {
            particles = ConfettiParticle.generate(count: count, colors: colors)

            withAnimation(.easeOut(duration: ConfettiView.animationDuration)) {
                animating = true
            }
        }
    }
}

internal struct ConfettiParticle: Identifiable {
    let id: Int
    let targetX: CGFloat
    let targetY: CGFloat
    let rotation: Double
    let color: Color

    internal static func generate(count: Int, colors: [Color] = ConfettiPiece.colors) -> [ConfettiParticle] {
        guard count > 0, !colors.isEmpty else { return [] }
        return (0 ..< count).map { index in
            ConfettiParticle(
                id: index,
                targetX: CGFloat.random(in: -150 ... 150),
                targetY: CGFloat.random(in: -100 ... 200),
                rotation: Double.random(in: 0 ... 360),
                color: colors[index % colors.count]
            )
        }
    }
}

internal struct ConfettiPiece: View {
    static let colors: [Color] = [
        .green, .blue, .orange, .pink, .purple, .yellow, .red
    ]

    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }
}
