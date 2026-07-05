import SwiftUI

struct RingView: View {
    var value: Double        // 0–100
    var label: String
    var sublabel: String = "Wellness Score"
    var size: CGFloat = 180
    var lineWidth: CGFloat = 16
    /// Semantic wellness color - drives the ring so its hue signals state.
    var tint: Color = .spaPrimary

    @State private var animatedValue: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedValue / 100)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.75), tint, tint.opacity(0.75)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(sublabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) {
                animatedValue = value
            }
        }
    }
}
