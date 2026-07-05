import SwiftUI

/// The primary content container - a solid `spaSurface` card with a crisp
/// hairline edge and soft resting shadow (matches the achievement cards).
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 22
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(cornerRadius: cornerRadius)   // solid surface + border
        .hoverLift()
    }
}

