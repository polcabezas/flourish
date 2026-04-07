import SwiftUI
import AppKit

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - flourish SwiftUI Colors (Wispr Flow aesthetic — warm neutrals, forest green)

extension Color {
    /// Main background: warm off-white
    static let flourishSurface = Color(hex: "#F8F7F4")

    /// Sidebar background: slightly darker warm tone
    static let flourishSidebarSurface = Color(hex: "#EFEDE7")

    /// Raised surface: active sidebar items, hover states, toolbar
    static let flourishSurfaceRaised = Color(hex: "#E7E5DF")

    /// Dark hero card background
    static let flourishSurfaceHero = Color(hex: "#1E2C1A")

    /// All borders: subtle warm dividers and input outlines
    static let flourishBorder = Color(hex: "#DDD9D1")

    /// Primary text: near-black
    static let flourishTextPrimary = Color(hex: "#17170D")

    /// Secondary text: warm medium gray — placeholders, labels, metadata
    static let flourishTextSecondary = Color(hex: "#6E6C65")

    /// Tertiary text: light warm gray — timestamps, subtle info
    static let flourishTextTertiary = Color(hex: "#A09E98")

    /// Accent: muted forest green — loader dots, active items, logo
    static let flourishAccent = Color(hex: "#5B7B4E")

    /// Primary button background: forest green
    static let flourishButtonBg = Color(hex: "#5B7B4E")

    /// Primary button label: white
    static let flourishButtonLabel = Color(hex: "#FFFFFF")
}

// MARK: - flourish AppKit Colors

extension NSColor {
    static let flourishSurface        = NSColor(hex: "#F8F7F4")
    static let flourishSidebarSurface = NSColor(hex: "#EFEDE7")
    static let flourishSurfaceRaised  = NSColor(hex: "#E7E5DF")
    static let flourishSurfaceHero    = NSColor(hex: "#1E2C1A")
    static let flourishBorder         = NSColor(hex: "#DDD9D1")
    static let flourishTextPrimary    = NSColor(hex: "#17170D")
    static let flourishTextSecondary  = NSColor(hex: "#6E6C65")
    static let flourishTextTertiary   = NSColor(hex: "#A09E98")
    static let flourishAccent         = NSColor(hex: "#5B7B4E")

    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        self.init(calibratedRed: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Pointer Cursor

extension View {
    /// Shows the pointing-hand cursor on hover. Apply to all interactive views.
    func pointerCursor() -> some View {
        onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
