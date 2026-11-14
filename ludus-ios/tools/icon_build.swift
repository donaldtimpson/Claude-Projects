// Renders the Ludus app icon (1024×1024) from the painted province + a crimson wax seal with a gilt
// Cinzel "L" inside a gold laurel wreath.
//
//   swift tools/icon_build.swift <province.png> <Cinzel-Black.ttf> <out.png> [cropY 0…1]
//
// Run from ludus-ios/:  swift tools/icon_build.swift tools/art/province_original.png \
//   Resources/Fonts/Cinzel-Black.ttf Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png 0.62
import AppKit
import CoreText

let args = CommandLine.arguments
let provincePath = args[1], fontPath = args[2], outPath = args[3]
let cropY = args.count > 4 ? Double(args[4])! : 0.62

let S: CGFloat = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
func rgb(_ h: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((h >> 16) & 0xff) / 255, green: CGFloat((h >> 8) & 0xff) / 255,
            blue: CGFloat(h & 0xff) / 255, alpha: a)
}

// 1. Painted province, square crop centered at cropY.
let prov = NSImage(contentsOfFile: provincePath)!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let pw = CGFloat(prov.width), ph = CGFloat(prov.height)
let side = pw * 0.94
let cy = max(0, min(ph - side, ph * cropY - side / 2))
let crop = prov.cropping(to: CGRect(x: (pw - side) / 2, y: cy, width: side, height: side))!
ctx.interpolationQuality = .high
ctx.draw(crop, in: CGRect(x: 0, y: 0, width: S, height: S))

// 2. Warm vignette so the seal pops and the edges sink.
let vig = CGGradient(colorsSpace: cs, colors: [rgb(0x000000, 0), rgb(0x2a0d08, 0.35), rgb(0x1a0604, 0.88)] as CFArray,
                     locations: [0.25, 0.6, 1])!
ctx.drawRadialGradient(vig, startCenter: CGPoint(x: S / 2, y: S / 2), startRadius: 0,
                       endCenter: CGPoint(x: S / 2, y: S / 2), endRadius: S * 0.72, options: .drawsAfterEndLocation)

let c = CGPoint(x: S / 2, y: S / 2 - 6)

// 3. Gold laurel wreath (SF Symbols laurels, rendered large, gilt by gradient mask).
func symbol(_ name: String, size: CGFloat) -> CGImage {
    let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)
    let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)!.withSymbolConfiguration(cfg)!
    var r = CGRect(origin: .zero, size: img.size)
    return img.cgImage(forProposedRect: &r, context: nil, hints: nil)!
}
func gilt(_ mask: CGImage, in rect: CGRect) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 18, color: rgb(0x000000, 0.55))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.clip(to: rect, mask: mask)
    let g = CGGradient(colorsSpace: cs, colors: [rgb(0xfff1b8), rgb(0xf1c95a), rgb(0xc58b25), rgb(0x8a5a12)] as CFArray,
                       locations: [0, 0.35, 0.7, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}
let lead = symbol("laurel.leading", size: 520), trail = symbol("laurel.trailing", size: 520)
let lh: CGFloat = 700, lw = lh * CGFloat(lead.width) / CGFloat(lead.height)
gilt(lead, in: CGRect(x: c.x - 345 - lw / 2 + 40, y: c.y - lh / 2, width: lw, height: lh))
gilt(trail, in: CGRect(x: c.x + 345 - lw / 2 - 40, y: c.y - lh / 2, width: lw, height: lh))

// 4. Crimson wax seal — a wobbly disc with a raised rim and an inner pressed ring.
func waxPath(r: CGFloat, wobble: CGFloat, lobes: Int) -> CGPath {
    let p = CGMutablePath()
    for i in 0...360 {
        let a = CGFloat(i) * .pi / 180
        let rr = r + wobble * sin(a * CGFloat(lobes)) + wobble * 0.5 * sin(a * CGFloat(lobes * 2 + 1) + 1.3)
        let pt = CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a))
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath()
    return p
}
let R: CGFloat = 268
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -16), blur: 30, color: rgb(0x000000, 0.6))
ctx.addPath(waxPath(r: R, wobble: 9, lobes: 7)); ctx.setFillColor(rgb(0x7d1c16)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(waxPath(r: R, wobble: 9, lobes: 7)); ctx.clip()
let wax = CGGradient(colorsSpace: cs, colors: [rgb(0xd2483a), rgb(0xa82a22), rgb(0x6e1611)] as CFArray, locations: [0, 0.55, 1])!
ctx.drawRadialGradient(wax, startCenter: CGPoint(x: c.x - 80, y: c.y + 90), startRadius: 10,
                       endCenter: c, endRadius: R + 20, options: .drawsAfterEndLocation)
ctx.restoreGState()
// pressed inner ring
for (r, col, w) in [(R * 0.80, rgb(0x5a100c, 0.75), CGFloat(10)), (R * 0.80 - 7, rgb(0xe8604f, 0.45), CGFloat(4))] {
    ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    ctx.setStrokeColor(col); ctx.setLineWidth(w); ctx.strokePath()
}

// 5. The gilt "L" in Cinzel Black.
CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: fontPath) as CFURL, .process, nil)
let font = CTFontCreateWithName("Cinzel-Black" as CFString, 440, nil)
let line = CTLineCreateWithAttributedString(NSAttributedString(string: "L", attributes: [.font: font]))
let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
let glyphs = CTLineGetGlyphRuns(line) as! [CTRun]
let run = glyphs[0]
var g = CGGlyph(); CTRunGetGlyphs(run, CFRange(location: 0, length: 1), &g)
let path = CTFontCreatePathForGlyph(font, g, nil)!
var t = CGAffineTransform(translationX: c.x - b.midX, y: c.y - b.midY)
let placed = path.copy(using: &t)!
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 6, color: rgb(0x3a0806, 0.8))
ctx.addPath(placed); ctx.setFillColor(rgb(0x8a5a12)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(placed); ctx.clip()
let gold = CGGradient(colorsSpace: cs, colors: [rgb(0xfff4c4), rgb(0xf3cb5c), rgb(0xc78c24), rgb(0xf0c556)] as CFArray,
                      locations: [0, 0.4, 0.75, 1])!
ctx.drawLinearGradient(gold, start: CGPoint(x: c.x, y: c.y + b.height / 2), end: CGPoint(x: c.x, y: c.y - b.height / 2), options: [])
ctx.restoreGState()

let out = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: out)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
