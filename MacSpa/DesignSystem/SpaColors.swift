import SwiftUI
import AppKit

// MARK: - Lumen palette
// Warm-calm wellness identity. Iris violet primary, terracotta secondary,
// jade wellness, honey warning, rose-coral accent. Neutrals adapt to the
// active appearance (light cream ⇄ deep indigo-charcoal) so Dark theme reads
// with proper contrast; brand accents stay consistent across both.

// MARK: - Selectable accent palette

/// User-choosable brand accent. Each option carries three shades: `base` (the
/// primary tint), `soft` (lighter, for gradient starts) and `deep` (darker, for
/// gradient ends). Persisted under the "accentColor" default; `iris` is default.
enum SpaAccent: String, CaseIterable, Identifiable {
    case iris, blue, teal, green, coral

    var id: String { rawValue }
    var label: String {
        switch self {
        case .iris: "Iris"; case .blue: "Blue"; case .teal: "Teal"
        case .green: "Green"; case .coral: "Coral"
        }
    }

    private var rgb: (base: (Double, Double, Double), soft: (Double, Double, Double), deep: (Double, Double, Double)) {
        switch self {
        case .iris:  return ((0.451, 0.388, 0.882), (0.596, 0.529, 0.953), (0.365, 0.302, 0.808))
        case .blue:  return ((0.204, 0.478, 0.925), (0.400, 0.624, 0.976), (0.129, 0.376, 0.816))
        case .teal:  return ((0.098, 0.627, 0.663), (0.278, 0.761, 0.784), (0.051, 0.502, 0.549))
        case .green: return ((0.243, 0.659, 0.400), (0.420, 0.780, 0.549), (0.157, 0.541, 0.322))
        case .coral: return ((0.929, 0.400, 0.549), (0.969, 0.561, 0.678), (0.831, 0.302, 0.463))
        }
    }

    private static func c(_ t: (Double, Double, Double)) -> Color { Color(red: t.0, green: t.1, blue: t.2) }
    var base: Color { Self.c(rgb.base) }
    var soft: Color { Self.c(rgb.soft) }
    var deep: Color { Self.c(rgb.deep) }

    /// The accent currently stored in preferences (defaults to blue).
    static var current: SpaAccent {
        SpaAccent(rawValue: UserDefaults.standard.string(forKey: "accentColor") ?? "blue") ?? .blue
    }
}

extension Color {
    // Brand accent - resolves from the user's chosen SpaAccent at read time.
    static var spaPrimary: Color     { SpaAccent.current.base }
    static var spaPrimarySoft: Color { SpaAccent.current.soft }
    static var spaPrimaryDeep: Color { SpaAccent.current.deep }

    // Status palette - limited to four meanings: blue (info), green (good),
    // yellow (caution), red (problem). Legacy names map onto these four.
    static let spaSecondary   = Color(red: 0.204, green: 0.478, blue: 0.925) // blue (info)
    static let spaSuccess     = Color(red: 0.243, green: 0.659, blue: 0.400) // green (good)
    static let spaWarning     = Color(red: 0.965, green: 0.784, blue: 0.235) // yellow (caution)
    static let spaCoral       = Color(red: 0.898, green: 0.310, blue: 0.310) // red (problem)
    static let spaCritical    = Color(red: 0.851, green: 0.243, blue: 0.259) // red (problem, strong)

    // Neutrals / surfaces - dynamic per appearance
    static let spaCanvas = dynamic(
        light: (0.976, 0.973, 0.988),   // warm cream
        dark:  (0.086, 0.082, 0.114))   // deep indigo charcoal
    static let spaSurface = dynamic(
        light: (1.000, 1.000, 1.000),   // white
        dark:  (0.145, 0.141, 0.176))   // raised charcoal
    static let spaHairline = dynamic(
        light: (0.906, 0.894, 0.933),   // faint light edge
        dark:  (0.271, 0.259, 0.318))   // faint dark edge

    /// Builds a Color that resolves its RGB from the active NSAppearance.
    /// RGB literals are captured as value tuples (Sendable) to satisfy Swift 6.
    static func dynamic(light: (Double, Double, Double),
                        dark: (Double, Double, Double)) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let (r, g, b) = isDark ? dark : light
            return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
        })
    }
}

// MARK: - Primary gradient (iris → violet)

struct GradientPrimary: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        let accent = SpaAccent.current
        return LinearGradient(
            colors: [accent.soft, accent.deep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension ShapeStyle where Self == GradientPrimary {
    static var gradientPrimary: GradientPrimary { GradientPrimary() }
}

// MARK: - Warm aurora background

struct HeroBackground: View {
    // Solid canvas (opaque - no desktop show-through) with a faint accent glow in
    // two opposite corners for a little depth. Recolors with the selected accent.
    private var accent: SpaAccent { SpaAccent.current }

    var body: some View {
        ZStack {
            Color.spaCanvas
            RadialGradient(colors: [accent.base.opacity(0.10), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 640)
            RadialGradient(colors: [accent.deep.opacity(0.08), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 580)
        }
        .ignoresSafeArea()
    }
}
