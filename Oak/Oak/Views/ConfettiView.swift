import SwiftUI

internal struct ConfettiView: View {
    static let animationDuration: Double = 1.2
    
    let count: Int
    @State private var animating = false
    
    init(count: Int = 30) {
        self.count = count
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ConfettiPiece(index: index)
                    .offset(
                        x: animating ? randomX() : 0,
                        y: animating ? randomY() : 0
                    )
                    .opacity(animating ? 0 : 1)
                    .scaleEffect(animating ? 0 : 1)
                    .rotationEffect(.degrees(animating ? Double.random(in: 0...360) : 0))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: ConfettiView.animationDuration)) {
                animating = true
            }
        }
    }
    
    private func randomX() -> CGFloat {
        CGFloat.random(in: -150...150)
    }
    
    private func randomY() -> CGFloat {
        CGFloat.random(in: -100...200)
    }
}

private struct ConfettiPiece: View {
    let index: Int
    private let colors: [Color] = [
        .green, .blue, .orange, .pink, .purple, .yellow, .red
    ]
    
    var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: 6, height: 6)
    }
}
