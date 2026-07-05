import SwiftUI

/// MacSpa brand mark: a lotus bloom on an iris-violet squircle. Scales to any
/// size; used for onboarding, the About panel, and the rendered dock icon.
struct AppLogo: View {
    /// When true, draws only the bloom (no squircle background) for inline use.
    var glyphOnly = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                if !glyphOnly {
                    RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.62, green: 0.55, blue: 0.96),
                                     Color(red: 0.36, green: 0.30, blue: 0.81)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: s * 0.72)
                        .blur(radius: s * 0.06)
                        .offset(y: -s * 0.04)
                }
                bloom(size: s)
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func bloom(size s: CGFloat) -> some View {
        let petalColor = glyphOnly ? Color.spaPrimary : Color.white
        return ZStack {
            ForEach(0..<6, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(petalColor.opacity(0.92))
                    .frame(width: s * 0.12, height: s * 0.34)
                    .offset(y: -s * 0.13)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
            Circle()
                .fill(petalColor)
                .frame(width: s * 0.135)
        }
    }
}
