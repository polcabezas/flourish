import SwiftUI

// MARK: - Hand-drawn stroke "f" mark
//
// Matches the SVG logo files (logo_mark_transparent.svg).
// ViewBox origin: x=12, y=-7; content size: 110×181.
// Two stroke paths: stem+hook (continuous) and crossbar.
// stroke-width: 16 (in SVG coords), scaled proportionally at render time.

// MARK: - Shape (Canvas-based, stroke rendering)

struct FlourishFShape: View {
    var color: Color = .flourishAccent

    var body: some View {
        Canvas { ctx, size in
            // SVG viewBox: "12 -7 110 181"
            let vbX: CGFloat = 12,  vbY: CGFloat = -7
            let vbW: CGFloat = 110, vbH: CGFloat = 181

            let scale   = min(size.width / vbW, size.height / vbH)
            let offsetX = (size.width  - vbW * scale) / 2
            let offsetY = (size.height - vbH * scale) / 2

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: offsetX + (x - vbX) * scale,
                        y: offsetY + (y - vbY) * scale)
            }

            // ── Stem + hook (single continuous stroke) ──────────────────────
            var stem = Path()
            stem.move(to: pt(57, 148))
            stem.addCurve(to: pt(54,  74), control1: pt(57, 131), control2: pt(55, 103))
            stem.addCurve(to: pt(60,  31), control1: pt(53,  54), control2: pt(55,  40))
            stem.addCurve(to: pt(90,  25), control1: pt(65,  21), control2: pt(79,  19))
            stem.addCurve(to: pt(88,  35), control1: pt(96,  30), control2: pt(93,  37))

            // ── Crossbar ────────────────────────────────────────────────────
            var crossbar = Path()
            crossbar.move(to: pt(38, 102))
            crossbar.addCurve(to: pt(80, 101), control1: pt(50, 100), control2: pt(58, 100))

            let style = StrokeStyle(lineWidth: 16 * scale, lineCap: .round, lineJoin: .round)
            ctx.stroke(stem,     with: .color(color), style: style)
            ctx.stroke(crossbar, with: .color(color), style: style)
        }
    }
}

// MARK: - Symbol View (scalable, single colour)

struct FlourishLogoSymbol: View {
    var size:  CGFloat = 32
    var color: Color   = .flourishAccent

    var body: some View {
        FlourishFShape(color: color)
            .frame(width: size * (110.0 / 181.0), height: size)
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

// MARK: - Full Wordmark (all 8 letters as stroked paths, matches logo_horizontal_transparent.svg)

struct FlourishWordmarkView: View {
    var height: CGFloat = 20
    var color:  Color   = .flourishAccent

    // SVG viewBox: 0 0 500 185
    private let vbW: CGFloat = 500
    private let vbH: CGFloat = 185

    var body: some View {
        Canvas { ctx, size in
            let scale   = min(size.width / vbW, size.height / vbH)
            let offsetX = (size.width  - vbW * scale) / 2
            let offsetY = (size.height - vbH * scale) / 2

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: offsetX + x * scale, y: offsetY + y * scale)
            }

            var paths: [Path] = []

            // ── f ── stem + hook
            var f = Path()
            f.move(to: pt(57, 148))
            f.addCurve(to: pt(54,  74), control1: pt(57, 131), control2: pt(55, 103))
            f.addCurve(to: pt(60,  31), control1: pt(53,  54), control2: pt(55,  40))
            f.addCurve(to: pt(90,  25), control1: pt(65,  21), control2: pt(79,  19))
            f.addCurve(to: pt(88,  35), control1: pt(96,  30), control2: pt(93,  37))
            paths.append(f)

            // ── f crossbar ──
            var fc = Path()
            fc.move(to: pt(38, 102))
            fc.addCurve(to: pt(80, 101), control1: pt(50, 100), control2: pt(58, 100))
            paths.append(fc)

            // ── l ──
            var l = Path()
            l.move(to: pt(106, 27))
            l.addCurve(to: pt(105, 117), control1: pt(105,  52), control2: pt(105,  86))
            l.addCurve(to: pt(108, 148), control1: pt(105, 133), control2: pt(106, 144))
            paths.append(l)

            // ── o ──
            var o = Path()
            o.move(to: pt(151, 75))
            o.addCurve(to: pt(123, 110), control1: pt(136,  75), control2: pt(123,  91))
            o.addCurve(to: pt(152, 145), control1: pt(123, 129), control2: pt(136, 145))
            o.addCurve(to: pt(179, 110), control1: pt(168, 145), control2: pt(180, 129))
            o.addCurve(to: pt(153,  75), control1: pt(178,  91), control2: pt(165,  75))
            paths.append(o)

            // ── u ──
            var u = Path()
            u.move(to: pt(199, 75))
            u.addCurve(to: pt(198, 136), control1: pt(198, 101), control2: pt(197, 123))
            u.addCurve(to: pt(220, 156), control1: pt(199, 147), control2: pt(208, 156))
            u.addCurve(to: pt(239, 136), control1: pt(232, 156), control2: pt(239, 147))
            u.addCurve(to: pt(237,  75), control1: pt(239, 123), control2: pt(238, 100))
            paths.append(u)

            // ── r stem ──
            var r = Path()
            r.move(to: pt(259, 148))
            r.addCurve(to: pt(259, 75), control1: pt(259, 131), control2: pt(259, 105))
            paths.append(r)

            // ── r shoulder ──
            var rs = Path()
            rs.move(to: pt(259, 98))
            rs.addCurve(to: pt(286, 77), control1: pt(263, 88), control2: pt(273, 80))
            rs.addCurve(to: pt(304, 84), control1: pt(294, 74), control2: pt(301, 77))
            paths.append(rs)

            // ── i ──
            var i = Path()
            i.move(to: pt(322, 75))
            i.addCurve(to: pt(322, 141), control1: pt(322,  97), control2: pt(322, 120))
            i.addCurve(to: pt(322, 149), control1: pt(322, 145), control2: pt(322, 148))
            paths.append(i)

            // ── s ──
            var s = Path()
            s.move(to: pt(388, 86))
            s.addCurve(to: pt(361, 77), control1: pt(382,  78), control2: pt(371,  74))
            s.addCurve(to: pt(353, 102), control1: pt(351,  80), control2: pt(347,  92))
            s.addCurve(to: pt(380, 124), control1: pt(359, 112), control2: pt(373, 115))
            s.addCurve(to: pt(380, 152), control1: pt(388, 132), control2: pt(387, 146))
            s.addCurve(to: pt(351, 155), control1: pt(373, 158), control2: pt(361, 159))
            s.addCurve(to: pt(341, 143), control1: pt(345, 152), control2: pt(342, 147))
            paths.append(s)

            // ── h stem ──
            var h = Path()
            h.move(to: pt(411, 27))
            h.addCurve(to: pt(411, 125), control1: pt(411,  58), control2: pt(411,  96))
            h.addCurve(to: pt(411, 148), control1: pt(411, 137), control2: pt(411, 145))
            paths.append(h)

            // ── h arch ──
            var ha = Path()
            ha.move(to: pt(411, 109))
            ha.addCurve(to: pt(439,  89), control1: pt(415,  99), control2: pt(426,  91))
            ha.addCurve(to: pt(462, 106), control1: pt(452,  87), control2: pt(460,  94))
            ha.addCurve(to: pt(462, 142), control1: pt(464, 114), control2: pt(463, 130))
            ha.addCurve(to: pt(461, 151), control1: pt(461, 147), control2: pt(461, 150))
            paths.append(ha)

            let sw    = 16 * scale
            let style = StrokeStyle(lineWidth: sw, lineCap: .round, lineJoin: .round)
            for path in paths {
                ctx.stroke(path, with: .color(color), style: style)
            }

            // ── i dot ──
            let r8 = 8 * scale
            let dot = CGRect(x: offsetX + 322 * scale - r8,
                             y: offsetY +  56 * scale - r8,
                             width: r8 * 2, height: r8 * 2)
            ctx.fill(Path(ellipseIn: dot), with: .color(color))
        }
        .frame(width: height * (vbW / vbH), height: height)
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
