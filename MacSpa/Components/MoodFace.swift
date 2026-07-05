import SwiftUI

/// Three drawn expressions - used because SF Symbols has no frown/sad face.
enum MoodExpression { case grin, smile, sad }

/// A simple round-faced mood glyph: two eyes + a mouth that grins (with teeth),
/// smiles, or turns down (sad). Scales to fill its frame.
struct MoodFace: View {
    var expression: MoodExpression
    var color: Color = .spaPrimary

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Eyes
                HStack(spacing: s * 0.22) {
                    eye(s); eye(s)
                }
                .offset(y: -s * 0.14)

                // Mouth
                MouthShape(expression: expression)
                    .stroke(color, style: StrokeStyle(lineWidth: s * 0.085, lineCap: .round, lineJoin: .round))
                    .frame(width: s * 0.52, height: s * 0.30)
                    .offset(y: s * 0.15)
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func eye(_ s: CGFloat) -> some View {
        Circle().fill(color).frame(width: s * 0.11, height: s * 0.11)
    }
}

/// The mouth curve for each expression. Grin adds a short teeth line.
private struct MouthShape: Shape {
    let expression: MoodExpression

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let left = CGPoint(x: rect.minX, y: rect.midY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)

        switch expression {
        case .grin:
            // Deep upward curve (open grin) + a teeth line across the top.
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                           control: CGPoint(x: rect.midX, y: rect.maxY * 1.5))
            p.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.14))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.minY + rect.height * 0.14))
        case .smile:
            p.move(to: left)
            p.addQuadCurve(to: right, control: CGPoint(x: rect.midX, y: rect.maxY * 1.35))
        case .sad:
            // Downturned curve.
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                           control: CGPoint(x: rect.midX, y: rect.minY * -0.1))
        }
        return p
    }
}

extension DeviceMood {
    /// Mapped to the three drawn expressions (best → worst).
    var expression: MoodExpression {
        switch self {
        case .fresh:                      .grin
        case .happy, .dusty:              .smile
        case .needsAttention, .sendHelp:  .sad
        }
    }
}
