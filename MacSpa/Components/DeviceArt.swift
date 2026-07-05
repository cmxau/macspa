import SwiftUI

/// Which device a cleaning illustration depicts.
enum DeviceKind { case keyboard, trackpad, display }

/// A simple vector illustration of a Mac input surface, used behind the wipe
/// cloth in both the Guided cards and the live Session overlay. Scales to fill
/// whatever frame the parent gives it.
struct DeviceArt: View {
    let kind: DeviceKind
    var accent: Color = .spaPrimary

    var body: some View {
        switch kind {
        case .keyboard: KeyboardArt(accent: accent)
        case .trackpad: TrackpadArt(accent: accent)
        case .display:  DisplayArt(accent: accent)
        }
    }
}

/// The microfiber wipe cloth that sweeps over a device. Draws a soft, slightly
/// raised cloth with a dashed thread hem and a stitched ring wrapping the Apple
/// logo - so it reads as real fabric with visible stitching rather than a flat card.
struct CleaningClothView: View {
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat = 24
    var logoSize: CGFloat = 18
    var tint: Color = .spaPrimary

    // A thin hem sitting a hair inside the edge, following the same corner curve.
    private var hemInset: CGFloat { 3 }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(colors: [.white, Color.white.opacity(0.92)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            // Fine dashed thread hem hugging the cloth edge.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius - hemInset, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 0.8, lineCap: .round, dash: [3, 3]))
                    .foregroundStyle(tint.opacity(0.45))
                    .padding(hemInset)
            )
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "apple.logo")
                    .font(.system(size: logoSize, weight: .medium))
                    .foregroundStyle(tint.opacity(0.55))
                    .padding(logoSize * 0.7)
            }
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}

private struct KeyboardArt: View {
    let accent: Color

    /// A key: its width weight, an optional SF Symbol glyph, and whether to
    /// emphasise it (used for the ⌘ command keys).
    private struct Cap { let w: CGFloat; let symbol: String?; let strong: Bool
        init(_ w: CGFloat, _ symbol: String? = nil, strong: Bool = false) {
            self.w = w; self.symbol = symbol; self.strong = strong
        }
    }

    // Uniform top rows + a realistic bottom row with modifiers and a spacebar.
    private var rows: [[Cap]] {
        [
            (0..<12).map { _ in Cap(1) },
            (0..<12).map { _ in Cap(1) },
            (0..<11).map { _ in Cap(1) },
            [Cap(1, "control"), Cap(1, "option"), Cap(1.3, "command", strong: true),
             Cap(5.5), // spacebar
             Cap(1.3, "command", strong: true), Cap(1, "option")]
        ]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white)
            .overlay(
                GeometryReader { geo in
                    let gap: CGFloat = 4
                    let count = rows.count
                    let rowH = (geo.size.height - gap * CGFloat(count - 1)) / CGFloat(count)
                    VStack(spacing: gap) {
                        ForEach(rows.indices, id: \.self) { r in
                            keyRow(rows[r], totalWidth: geo.size.width, height: rowH, gap: gap)
                        }
                    }
                }
                .padding(12)
            )
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(accent.opacity(0.18), lineWidth: 1))
    }

    private func keyRow(_ caps: [Cap], totalWidth: CGFloat, height: CGFloat, gap: CGFloat) -> some View {
        let sum = caps.reduce(0) { $0 + $1.w }
        let unit = (totalWidth - gap * CGFloat(caps.count - 1)) / sum
        return HStack(spacing: gap) {
            ForEach(caps.indices, id: \.self) { i in
                let cap = caps[i]
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(accent.opacity(cap.strong ? 0.30 : 0.16))
                    .frame(width: unit * cap.w, height: height)
                    .overlay {
                        if let s = cap.symbol {
                            Image(systemName: s)
                                .font(.system(size: height * 0.5, weight: .semibold))
                                .foregroundStyle(accent)
                        }
                    }
            }
        }
    }
}

private struct TrackpadArt: View {
    let accent: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.30), lineWidth: 2))
                    .padding(14)
            )
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(accent.opacity(0.18), lineWidth: 1))
    }
}

private struct DisplayArt: View {
    let accent: Color
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .overlay(
                    VStack(alignment: .leading, spacing: 5) {
                        Capsule().fill(accent.opacity(0.35)).frame(width: 40, height: 4) // menu bar
                        RoundedRectangle(cornerRadius: 4).fill(accent.opacity(0.10)).frame(height: 10)
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 4).fill(accent.opacity(0.14))
                            RoundedRectangle(cornerRadius: 4).fill(accent.opacity(0.08))
                        }
                    }
                    .padding(12)
                )
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(accent.opacity(0.20), lineWidth: 1.5))
                .aspectRatio(1.6, contentMode: .fit)

            // Stand
            Rectangle().fill(accent.opacity(0.22)).frame(width: 18, height: 8)
            RoundedRectangle(cornerRadius: 2).fill(accent.opacity(0.22)).frame(width: 54, height: 5)
        }
    }
}
