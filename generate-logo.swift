#!/usr/bin/env swift
import AppKit
import Foundation

// MARK: - Brand Colors (matching generate-icons.swift exactly)
let bgTop     = NSColor(calibratedRed: 248/255, green: 247/255, blue: 244/255, alpha: 1) // #F8F7F4
let bgBottom  = NSColor(calibratedRed: 231/255, green: 229/255, blue: 223/255, alpha: 1) // #E7E5DF
let green     = NSColor(calibratedRed:  91/255, green: 123/255, blue:  78/255, alpha: 1) // #5B7B4E
let greenMid  = NSColor(calibratedRed: 127/255, green: 163/255, blue: 110/255, alpha: 0.70)

// MARK: - Floral 'f' Path (identical to generate-icons.swift)

func flourishFPath(in rect: CGRect) -> NSBezierPath {
    let w  = rect.width;  let h  = rect.height
    let ox = rect.minX;   let oy = rect.minY
    let sx = w / 100.0;   let sy = h / 100.0

    func pt(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: ox + x * sx, y: oy + (100 - y) * sy)
    }

    let path = NSBezierPath()

    // Arch + Stem
    path.move(to: pt(37, 92))
    path.curve(to: pt(38, 30), controlPoint1: pt(34, 68), controlPoint2: pt(37, 48))
    path.curve(to: pt(52,  7), controlPoint1: pt(37, 18), controlPoint2: pt(43,  7))
    path.curve(to: pt(76, 13), controlPoint1: pt(64,  5), controlPoint2: pt(78,  5))
    path.curve(to: pt(64, 20), controlPoint1: pt(78, 20), controlPoint2: pt(70, 21))
    path.curve(to: pt(47, 30), controlPoint1: pt(52, 13), controlPoint2: pt(47, 22))
    path.curve(to: pt(48, 92), controlPoint1: pt(47, 52), controlPoint2: pt(48, 74))
    path.curve(to: pt(37, 92), controlPoint1: pt(48, 97), controlPoint2: pt(37, 97))
    path.close()

    // Crossbar
    path.move(to: pt(20, 44))
    path.line(to: pt(62, 44))
    path.curve(to: pt(75, 49), controlPoint1: pt(70, 41), controlPoint2: pt(78, 44))
    path.curve(to: pt(62, 54), controlPoint1: pt(78, 54), controlPoint2: pt(70, 55))
    path.line(to: pt(20, 54))
    path.curve(to: pt(20, 44), controlPoint1: pt(13, 54), controlPoint2: pt(13, 44))
    path.close()

    return path
}

func budDot(cx: CGFloat, cy: CGFloat, r: CGFloat, in frame: CGRect) -> NSBezierPath {
    let sx = frame.width  / 100.0
    let sy = frame.height / 100.0
    let ox = frame.minX;  let oy = frame.minY
    let x  = ox + cx * sx
    let y  = oy + (100 - cy) * sy
    let rx = r * sx;  let ry = r * sy
    return NSBezierPath(ovalIn: NSRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
}

// MARK: - Draw horizontal logo

func drawLogo(scale: CGFloat, transparent: Bool = false) -> NSImage {
    // Design space in points (scale is applied when rendering pixels)
    let height:  CGFloat = 200
    let fMargin: CGFloat = height * 0.18   // same margin ratio as the icon
    let fSize:   CGFloat = height - 2 * fMargin
    let gap:     CGFloat = 40              // space between "f" and wordmark
    let rPad:    CGFloat = 40              // right padding
    let fontSize: CGFloat = height * 0.50  // 100 pt at height = 200

    // Wordmark font — Palatino matches the warm, organic feel of the floral 'f'
    guard let font = NSFont(name: "Palatino-Roman", size: fontSize) else {
        fatalError("Palatino-Roman not found")
    }

    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: green,
    ]
    let wordmark = NSAttributedString(string: "Flourish", attributes: textAttrs)
    let textSize = wordmark.size()

    let totalW = height + gap + textSize.width + rPad
    let totalH = height

    // Render at pixel resolution
    let pw = Int(totalW * scale)
    let ph = Int(totalH * scale)

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pw, pixelsHigh: ph,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Work in points; scale handles pixel density
    let xform = NSAffineTransform()
    xform.scale(by: scale)
    xform.concat()

    if transparent {
        NSColor.clear.setFill()
        NSBezierPath.fill(NSRect(x: 0, y: 0, width: totalW, height: totalH))
    } else {
        // Same diagonal gradient as the app icon
        let gradient = NSGradient(starting: bgTop, ending: bgBottom)!
        gradient.draw(in: NSRect(x: 0, y: 0, width: totalW, height: totalH), angle: -50)
    }

    // ── Floral "f" (same margin / path as the app icon) ──────────────────────
    let fRect = CGRect(x: fMargin, y: fMargin, width: fSize, height: fSize)

    green.setFill()
    flourishFPath(in: fRect).fill()

    greenMid.setFill()
    budDot(cx: 76, cy: 13, r: 3.0, in: fRect).fill()
    budDot(cx: 75, cy: 49, r: 2.2, in: fRect).fill()

    // ── Wordmark ──────────────────────────────────────────────────────────────
    let textX = height + gap
    let textY = (totalH - textSize.height) / 2.0
    wordmark.draw(at: NSPoint(x: textX, y: textY))

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: CGFloat(pw), height: CGFloat(ph)))
    image.addRepresentation(rep)
    return image
}

// MARK: - Save PNG

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep  = NSBitmapImageRep(data: tiff),
          let png  = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: could not encode \(path)"); return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("  ✓ \(URL(fileURLWithPath: path).lastPathComponent)")
    } catch { print("ERROR writing \(path): \(error)") }
}

// MARK: - Main

let outDir = "docs"
print("Generating Flourish horizontal logo…")

// With background (matches icon aesthetic)
savePNG(drawLogo(scale: 1),         to: "\(outDir)/logo_horizontal.png")
savePNG(drawLogo(scale: 2),         to: "\(outDir)/logo_horizontal@2x.png")

// Transparent background (versatile for dark/light contexts)
savePNG(drawLogo(scale: 1, transparent: true), to: "\(outDir)/logo_horizontal_transparent.png")
savePNG(drawLogo(scale: 2, transparent: true), to: "\(outDir)/logo_horizontal_transparent@2x.png")

print("Done — 4 files written to \(outDir)/")
