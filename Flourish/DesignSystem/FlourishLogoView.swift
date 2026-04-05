import SwiftUI

// MARK: - Floral lowercase 'f' Logo
//
// Design: A stylised lowercase 'f' where the letterform doubles as a plant.
// • The stem curves gently at the base, like a stalk rising from soil.
// • The arch (hook at the top) sweeps right and ends in a teardrop leaf tip.
// • The crossbar ends in a smaller matching leaf on the right.
// • Two seed-bud dots accent each leaf tip.
//
// All geometry uses SwiftUI coordinates: origin top-left, y increases downward.
// 100×100 design space, scaled to any target rect.

// MARK: - Shape

struct FlourishFShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width  / 100
        let sy = rect.height / 100

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var p = Path()

        // ── Arch + Stem (single closed contour, clockwise) ────────────────────
        // Start at stem base-left; trace up the left edge, through the arch,
        // back down the right edge, then close across the base.

        // Stem: x=37–47 (10 units wide, matching original capital F stroke weight)
        p.move(to: pt(37, 92))

        // Left stem edge rising upward (slight organic S-curve)
        p.addCurve(to: pt(38, 30),
                   control1: pt(34, 68),
                   control2: pt(37, 48))

        // Outer arch: stem top sweeps up-and-right
        p.addCurve(to: pt(52,  7),
                   control1: pt(37, 18),
                   control2: pt(43,  7))

        // Arch apex → leaf tip (teardrop pointing right)
        p.addCurve(to: pt(76, 13),
                   control1: pt(64,  5),
                   control2: pt(78,  5))

        // Leaf back: teardrop curves down-left (shallower so arch stays thin)
        p.addCurve(to: pt(64, 20),
                   control1: pt(78, 20),
                   control2: pt(70, 21))

        // Inner arch: follows outer at ~10 unit offset — peaks near (52, 17)
        p.addCurve(to: pt(47, 30),
                   control1: pt(52, 13),
                   control2: pt(47, 22))

        // Right stem edge descending
        p.addCurve(to: pt(48, 92),
                   control1: pt(47, 52),
                   control2: pt(48, 74))

        // Stem base (organic flare)
        p.addCurve(to: pt(37, 92),
                   control1: pt(48, 97),
                   control2: pt(37, 97))

        p.closeSubpath()

        // ── Crossbar ──────────────────────────────────────────────────────────
        p.move(to: pt(20, 44))
        p.addLine(to: pt(62, 44))

        // Right leaf tip
        p.addCurve(to: pt(75, 49),
                   control1: pt(70, 41),
                   control2: pt(78, 44))
        p.addCurve(to: pt(62, 54),
                   control1: pt(78, 54),
                   control2: pt(70, 55))

        p.addLine(to: pt(20, 54))
        // Rounded left cap — bezier semicircle from bottom-left to top-left
        p.addCurve(to: pt(20, 44),
                   control1: pt(13, 54),
                   control2: pt(13, 44))
        p.closeSubpath()

        // ── Seed bud — arch leaf ───────────────────────────────────────────────
        let b1r = 3.0 * sx
        p.addEllipse(in: CGRect(x: pt(76, 13).x - b1r, y: pt(76, 13).y - b1r,
                                width: b1r * 2, height: b1r * 2))

        // ── Seed bud — crossbar leaf ───────────────────────────────────────────
        let b2r = 2.2 * sx
        p.addEllipse(in: CGRect(x: pt(75, 49).x - b2r, y: pt(75, 49).y - b2r,
                                width: b2r * 2, height: b2r * 2))

        return p
    }
}

// MARK: - Symbol View (scalable, single colour)

struct FlourishLogoSymbol: View {
    var size:  CGFloat = 32
    var color: Color   = .flourishAccent

    var body: some View {
        FlourishFShape()
            .fill(color)
            .frame(width: size * 0.65, height: size)
    }
}

// MARK: - Full Logotype (symbol + wordmark)

struct FlourishLogoView: View {
    var size:  CGFloat = 32
    var color: Color   = .flourishAccent

    var body: some View {
        HStack(spacing: size * 0.28) {
            FlourishLogoSymbol(size: size, color: color)
            Text("Flourish")
                .font(.system(size: size * 0.55, weight: .semibold, design: .default))
                .foregroundColor(color)
                .tracking(-0.3)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        FlourishLogoView(size: 40)
        FlourishLogoView(size: 28, color: .white)
            .padding(16)
            .background(Color(hex: "#1E2C1A"))
            .cornerRadius(14)
        FlourishLogoSymbol(size: 20)
    }
    .padding(32)
}
