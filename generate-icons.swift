#!/usr/bin/env swift
import AppKit
import Foundation

// MARK: - Brand Colors (Wispr Flow aesthetic — forest green)
let bgTop     = NSColor(calibratedRed: 248/255, green: 247/255, blue: 244/255, alpha: 1) // #F8F7F4 warm off-white
let bgBottom  = NSColor(calibratedRed: 231/255, green: 229/255, blue: 223/255, alpha: 1) // #E7E5DF raised surface
let green     = NSColor(calibratedRed:  91/255, green: 123/255, blue:  78/255, alpha: 1) // #5B7B4E forest green
let greenMid  = NSColor(calibratedRed: 127/255, green: 163/255, blue: 110/255, alpha: 0.70) // #7FA36E bud accent

// MARK: - Floral lowercase 'f' Path (100×100 design space, screen coords: y=0 at top)
//
// AppKit uses y=0 at BOTTOM, so every y value is flipped via (100 - y).
// This makes the path match the SwiftUI version exactly.

func flourishFPath(in rect: CGRect) -> NSBezierPath {
    let w  = rect.width;  let h  = rect.height
    let ox = rect.minX;   let oy = rect.minY
    let sx = w / 100.0;   let sy = h / 100.0

    // Flip y so design coords (y=0 top) map correctly into AppKit (y=0 bottom)
    func pt(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: ox + x * sx, y: oy + (100 - y) * sy)
    }

    let path = NSBezierPath()

    // ── Arch + Stem (single closed contour) ──────────────────────────────────
    // Stem: x=37–47 (10 units wide, matching original capital F stroke weight)
    path.move(to: pt(37, 92))

    // Left stem edge rising upward
    path.curve(to: pt(38, 30),
               controlPoint1: pt(34, 68),
               controlPoint2: pt(37, 48))

    // Outer arch: stem top sweeps up-and-right
    path.curve(to: pt(52,  7),
               controlPoint1: pt(37, 18),
               controlPoint2: pt(43,  7))

    // Arch apex → leaf tip (teardrop pointing right)
    path.curve(to: pt(76, 13),
               controlPoint1: pt(64,  5),
               controlPoint2: pt(78,  5))

    // Leaf back: teardrop curves down-left (shallower so arch stays thin)
    path.curve(to: pt(64, 20),
               controlPoint1: pt(78, 20),
               controlPoint2: pt(70, 21))

    // Inner arch: follows outer at ~10 unit offset — peaks near (52, 17)
    path.curve(to: pt(47, 30),
               controlPoint1: pt(52, 13),
               controlPoint2: pt(47, 22))

    // Right stem edge descending
    path.curve(to: pt(48, 92),
               controlPoint1: pt(47, 52),
               controlPoint2: pt(48, 74))

    // Stem base (organic flare)
    path.curve(to: pt(37, 92),
               controlPoint1: pt(48, 97),
               controlPoint2: pt(37, 97))
    path.close()

    // ── Crossbar ─────────────────────────────────────────────────────────────
    path.move(to: pt(20, 44))
    path.line(to: pt(62, 44))

    // Right leaf tip
    path.curve(to: pt(75, 49),
               controlPoint1: pt(70, 41),
               controlPoint2: pt(78, 44))
    path.curve(to: pt(62, 54),
               controlPoint1: pt(78, 54),
               controlPoint2: pt(70, 55))

    path.line(to: pt(20, 54))
    // Rounded left cap — bezier semicircle from bottom-left to top-left
    path.curve(to: pt(20, 44),
               controlPoint1: pt(13, 54),
               controlPoint2: pt(13, 44))
    path.close()

    return path
}

// MARK: - Seed-bud dots

func budDot(cx: CGFloat, cy: CGFloat, r: CGFloat, in frame: CGRect) -> NSBezierPath {
    let sx = frame.width  / 100.0
    let sy = frame.height / 100.0
    let ox = frame.minX;  let oy = frame.minY
    let x  = ox + cx * sx
    let y  = oy + (100 - cy) * sy  // flip y to match path coordinates
    let rx = r * sx;  let ry = r * sy
    return NSBezierPath(ovalIn: NSRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
}

// MARK: - Draw one icon frame
// Uses NSBitmapImageRep so drawing happens at exact pixel dimensions
// regardless of the host display's Retina scale factor.

func drawIcon(size s: CGFloat) -> NSImage {
    let px = Int(s)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Background: diagonal warm gradient
    let gradient = NSGradient(starting: bgTop, ending: bgBottom)!
    gradient.draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -50)

    // Compute a padded rect for the F — 18% margin all around
    let margin = s * 0.18
    let fRect  = CGRect(x: margin, y: margin, width: s - 2 * margin, height: s - 2 * margin)

    // Draw the floral F in forest green
    let fPath = flourishFPath(in: fRect)
    green.setFill()
    fPath.fill()

    // Arch leaf bud
    let archBud = budDot(cx: 76, cy: 13, r: 3.0, in: fRect)
    greenMid.setFill()
    archBud.fill()

    // Crossbar leaf bud
    let cbBud = budDot(cx: 75, cy: 49, r: 2.2, in: fRect)
    greenMid.setFill()
    cbBud.fill()

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: s, height: s))
    image.addRepresentation(rep)
    return image
}

// MARK: - Save PNG

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep  = NSBitmapImageRep(data: tiff),
          let png  = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: could not encode \(path)")
        return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("  ✓ \(URL(fileURLWithPath: path).lastPathComponent)")
    } catch {
        print("ERROR writing \(path): \(error)")
    }
}

// MARK: - Main

let outDir = "Flourish/Assets.xcassets/AppIcon.appiconset"

let specs: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

// MARK: - Menu bar icon (just the F, no background, black fill for template rendering)

func drawMenuBarIcon(size s: CGFloat) -> NSImage {
    let px  = Int(s)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Transparent background
    NSColor.clear.setFill()
    NSBezierPath.fill(NSRect(x: 0, y: 0, width: s, height: s))

    // Draw F with a small inset margin so it doesn't touch the edges
    let margin = s * 0.08
    let fRect  = CGRect(x: margin, y: margin, width: s - 2 * margin, height: s - 2 * margin)
    let fPath  = flourishFPath(in: fRect)
    NSColor.black.setFill()
    fPath.fill()

    // Buds
    let archBud = budDot(cx: 76, cy: 13, r: 3.0, in: fRect)
    NSColor.black.setFill()
    archBud.fill()
    let cbBud = budDot(cx: 75, cy: 49, r: 2.2, in: fRect)
    NSColor.black.setFill()
    cbBud.fill()

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: s, height: s))
    image.addRepresentation(rep)
    image.isTemplate = true
    return image
}

// MARK: - Main

print("Generating Flourish icons (floral F)…")
for (px, name) in specs {
    let img = drawIcon(size: CGFloat(px))
    savePNG(img, to: "\(outDir)/\(name)")
}
print("Done — \(specs.count) files written to \(outDir)/")

// Menu bar icons
let mbDir = "Flourish/Assets.xcassets/MenuBarIcon.imageset"
print("\nGenerating menu bar icons…")
let mbSpecs: [(Int, String)] = [
    (18, "menubar_icon.png"),
    (36, "menubar_icon@2x.png"),
]
for (px, name) in mbSpecs {
    let img = drawMenuBarIcon(size: CGFloat(px))
    savePNG(img, to: "\(mbDir)/\(name)")
}
print("Done — \(mbSpecs.count) files written to \(mbDir)/")
