import SwiftUI

// MARK: - Section header (eyebrow + big title)

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    var accent: Color = .spaPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(accent)
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.5)
        }
    }
}

// MARK: - Tinted icon tile

struct IconTile: View {
    let systemName: String
    var color: Color = .spaPrimary
    var size: CGFloat = 40
    var symbolSize: CGFloat = 17

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(color.opacity(0.14))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: symbolSize, weight: .semibold))
                    .foregroundStyle(color)
            )
    }
}

// MARK: - Tinted tag / eyebrow chip

struct TintedTag: View {
    let text: String
    var systemName: String? = nil
    var color: Color = .spaPrimary

    var body: some View {
        HStack(spacing: 5) {
            if let systemName {
                Image(systemName: systemName).font(.caption2.weight(.bold))
            }
            Text(text.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.0)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Card eyebrow (small labelled header inside a card)

struct CardEyebrow: View {
    let systemName: String
    let title: String
    var hint: String? = nil
    var color: Color = .spaPrimary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Spacer()
            if let hint {
                Text(hint).font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Calendar date badge (Apple Calendar-style tile showing a date)

struct CalendarDateBadge: View {
    let date: Date
    var tint: Color = .spaPrimary
    var size: CGFloat = 46
    private static let month = { let f = DateFormatter(); f.dateFormat = "MMM"; return f }()

    private var monthText: String { Self.month.string(from: date).uppercased() }
    private var dayText: String { "\(Calendar.current.component(.day, from: date))" }

    var body: some View {
        VStack(spacing: 0) {
            Text(monthText)
                .font(.system(size: size * 0.22, weight: .bold)).tracking(0.5)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, size * 0.065)
                .background(tint)
            Text(dayText)
                .font(.system(size: size * 0.43, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size, height: size)
        .background(Color.spaSurface)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }
}

// MARK: - Primary gradient button style

struct PrimaryButtonStyle: ButtonStyle {
    var icon: String? = "sparkles"
    var size: Size = .regular
    /// Stretches the filled body to the available width (e.g. a card-width CTA).
    var fullWidth: Bool = false
    enum Size { case regular, large }

    func makeBody(configuration: Configuration) -> some View {
        let hPad: CGFloat = size == .large ? 26 : 20
        let vPad: CGFloat = size == .large ? 15 : 12
        let radius: CGFloat = size == .large ? 16 : 14
        return HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon).font((size == .large ? Font.body : .subheadline).weight(.bold))
            }
            configuration.label
        }
        .font((size == .large ? Font.body : .subheadline).weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .background(GradientPrimary(), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        // Subtle top-edge highlight + a light shadow that matches the flat cards
        // (no heavy colored glow).
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .blendMode(.overlay)
        )
        .shadow(color: .black.opacity(configuration.isPressed ? 0.06 : 0.12),
                radius: configuration.isPressed ? 2 : 6, y: configuration.isPressed ? 1 : 3)
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Trackpad glyph tile (no SF Symbol exists for a trackpad)

/// A tinted tile drawing an actual trackpad - outer body + inset rounded surface -
/// used where an SF Symbol would otherwise stand in for the trackpad device.
struct TrackpadGlyphTile: View {
    var color: Color = .spaPrimary
    var size: CGFloat = 42
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(color.opacity(0.14))
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                    .stroke(color, lineWidth: size * 0.05)
                    .background(
                        RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                            .fill(color.opacity(0.10))
                    )
                    .frame(width: size * 0.56, height: size * 0.44)
            )
    }
}
