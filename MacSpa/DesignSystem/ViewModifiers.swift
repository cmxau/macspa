import SwiftUI

// MARK: - Surface
// Every card/surface uses a solid `spaSurface` fill (opaque, like the achievement
// cards). Only the app's window background stays frosted glass. Increased Contrast
// strengthens the border.

struct AccessibleSurface: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    var cornerRadius: CGFloat = 16
    var strong: Bool = false      // retained for call-site compatibility; all surfaces are solid
    /// Draw the hairline edge. Forced on under increased contrast regardless.
    var border: Bool = true

    private var highContrast: Bool { contrast == .increased }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(shape.fill(Color.spaSurface))
            .overlay {
                if border || highContrast {
                    shape.stroke(Color.spaHairline, lineWidth: highContrast ? 1.5 : 1)
                }
            }
    }
}

struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content.modifier(AccessibleSurface(cornerRadius: cornerRadius, strong: false, border: true))
    }
}

struct GlassStrongModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    func body(content: Content) -> some View {
        content.modifier(AccessibleSurface(cornerRadius: cornerRadius, strong: true, border: false))
    }
}

// MARK: - Hover Lift

struct HoverLiftModifier: ViewModifier {
    // Static resting elevation only - no hover scale or shadow change.
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

// MARK: - Soft In transition

struct SoftInModifier: ViewModifier {
    @AppStorage("reducedMotion") private var reducedMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var appeared = false
    private var reduce: Bool { reducedMotion || systemReduce }
    @ViewBuilder func body(content: Content) -> some View {
        if reduce {
            content
        } else {
            content
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .scaleEffect(appeared ? 1 : 0.98)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
                }
        }
    }
}

// MARK: - Breathe

struct BreatheModifier: ViewModifier {
    @AppStorage("reducedMotion") private var reducedMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var phase = false
    private var reduce: Bool { reducedMotion || systemReduce }
    @ViewBuilder func body(content: Content) -> some View {
        if reduce {
            content
        } else {
            content
                .scaleEffect(phase ? 1.05 : 1.0)
                .opacity(phase ? 1.0 : 0.9)
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        phase = true
                    }
                }
        }
    }
}

// MARK: - Sparkle

struct SparkleModifier: ViewModifier {
    var delay: Double = 0
    @AppStorage("reducedMotion") private var reducedMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var phase = false
    private var reduce: Bool { reducedMotion || systemReduce }
    @ViewBuilder func body(content: Content) -> some View {
        if reduce {
            content   // steady, fully visible
        } else {
            content
                .opacity(phase ? 1 : 0)
                .scaleEffect(phase ? 1 : 0.6)
                .rotationEffect(.degrees(phase ? 20 : 0))
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(delay)) {
                        phase = true
                    }
                }
        }
    }
}

// MARK: - Wipe (cloth animation)

struct WipeModifier: ViewModifier {
    @AppStorage("reducedMotion") private var reducedMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var offset: CGFloat = -80
    private var reduce: Bool { reducedMotion || systemReduce }
    @ViewBuilder func body(content: Content) -> some View {
        if reduce {
            content
        } else {
            content
                .offset(x: offset)
                .rotationEffect(.degrees(offset > 0 ? 4 : -4))
                .onAppear {
                    withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                        offset = 80
                    }
                }
        }
    }
}

// MARK: - Float

struct FloatModifier: ViewModifier {
    @AppStorage("reducedMotion") private var reducedMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var up = false
    private var reduce: Bool { reducedMotion || systemReduce }
    @ViewBuilder func body(content: Content) -> some View {
        if reduce {
            content
        } else {
            content
                .offset(y: up ? -6 : 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { up = true }
                }
        }
    }
}

// MARK: - View extensions

extension View {
    func glass(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassModifier(cornerRadius: cornerRadius))
    }
    func glassStrong(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassStrongModifier(cornerRadius: cornerRadius))
    }
    /// Accessible material fill without a hairline - for surfaces that draw their
    /// own border. Still honors Reduce Transparency / Increased Contrast.
    func surfaceMaterial(cornerRadius: CGFloat = 16, strong: Bool = false) -> some View {
        modifier(AccessibleSurface(cornerRadius: cornerRadius, strong: strong, border: false))
    }
    func hoverLift() -> some View { modifier(HoverLiftModifier()) }
    func softIn() -> some View { modifier(SoftInModifier()) }
    func breathe() -> some View { modifier(BreatheModifier()) }
    func sparkle(delay: Double = 0) -> some View { modifier(SparkleModifier(delay: delay)) }
    func wipe() -> some View { modifier(WipeModifier()) }
    func float() -> some View { modifier(FloatModifier()) }
}
