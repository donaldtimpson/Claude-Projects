import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024
let fontsDir = "/Users/donnytimpsonjc/Sources/Claude-Projects/edu-reading/ios/Resources/Fonts"
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func loadFont(_ file: String, size: CGFloat) -> CTFont {
    let url = URL(fileURLWithPath: "\(fontsDir)/\(file)") as CFURL
    guard let provider = CGDataProvider(url: url), let cg = CGFont(provider) else {
        fatalError("cannot load \(file)")
    }
    return CTFontCreateWithGraphicsFont(cg, size, nil, nil)
}

func rgb(_ hex: UInt) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xff)/255, green: CGFloat((hex >> 8) & 0xff)/255,
            blue: CGFloat(hex & 0xff)/255, alpha: 1)
}
let INK    = rgb(0x1B2A33)
let VOWEL  = rgb(0xC8433A)
let CREAM  = rgb(0xFFF6E4)
let BUTTER = rgb(0xFFCF5C)
let PAPER  = rgb(0xFFFFFF)
let GREEN  = rgb(0x2E7D6E)

func ctx() -> CGContext {
    let c = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.setAllowsAntialiasing(true); c.setShouldAntialias(true)
    return c
}

/// Warm radial ground — the app's own palette is a cool classroom grey, which reads
/// drab on a home screen. The icon runs warm so it stands out and reads "for a child".
func sunGround(_ c: CGContext, inner: CGColor, outer: CGColor) {
    let sp = CGColorSpaceCreateDeviceRGB()
    let g = CGGradient(colorsSpace: sp, colors: [inner, outer] as CFArray, locations: [0, 1])!
    c.drawRadialGradient(g, startCenter: CGPoint(x: S/2, y: S*0.60), startRadius: 0,
                         endCenter: CGPoint(x: S/2, y: S*0.45), endRadius: S*0.78,
                         options: [.drawsAfterEndLocation])
}

/// Draws a string centred on its true glyph outline (not the font's line box), so a
/// lone letter sits optically dead centre instead of floating high.
func drawCentered(_ c: CGContext, runs: [(String, CGColor)], font: CTFont,
                  dy: CGFloat = 0, dx: CGFloat = 0) {
    let attr = NSMutableAttributedString()
    for (s, color) in runs {
        attr.append(NSAttributedString(string: s, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: font,
            kCTForegroundColorAttributeName as NSAttributedString.Key: color,
        ]))
    }
    let line = CTLineCreateWithAttributedString(attr)
    let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    c.textPosition = CGPoint(x: S/2 - b.width/2 - b.minX + dx,
                             y: S/2 - b.height/2 - b.minY + dy)
    CTLineDraw(line, c)
}

func save(_ c: CGContext, _ name: String) {
    let img = c.makeImage()!
    let url = URL(fileURLWithPath: "\(outDir)/\(name).png") as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(name).png")
}

let bold = loadFont("Andika-Bold.ttf", size: S * 0.72)

// A — the thesis, alone. Andika's single-storey 'a' is a circle with a stem: the
// letterform that makes the app defensible is also the roundest, most toy-like
// shape in the alphabet.
do {
    let c = ctx()
    sunGround(c, inner: CREAM, outer: BUTTER)
    drawCentered(c, runs: [("a", VOWEL)], font: bold)
    save(c, "icon-a")
}

// B — the app's whole colour system in two letters: consonants ink, vowels red.
// "at" is also the rime the blending deck is built on.
do {
    let c = ctx()
    sunGround(c, inner: CREAM, outer: BUTTER)
    let f = loadFont("Andika-Bold.ttf", size: S * 0.56)
    drawCentered(c, runs: [("a", VOWEL), ("t", INK)], font: f)
    save(c, "icon-at")
}

// C — letter plus sound. Says "sound it out" rather than merely "letter", using the
// universally-read speaker arcs.
do {
    let c = ctx()
    sunGround(c, inner: CREAM, outer: BUTTER)
    let f = loadFont("Andika-Bold.ttf", size: S * 0.62)
    drawCentered(c, runs: [("a", VOWEL)], font: f, dx: -S * 0.10)
    c.setStrokeColor(INK); c.setLineCap(.round)
    for (i, r) in [S*0.15, S*0.245, S*0.34].enumerated() {
        c.setLineWidth(S * 0.038)
        c.setAlpha(1.0 - Double(i) * 0.22)
        c.addArc(center: CGPoint(x: S*0.46, y: S*0.5), radius: r,
                 startAngle: -.pi/4.4, endAngle: .pi/4.4, clockwise: false)
        c.strokePath()
    }
    c.setAlpha(1)
    save(c, "icon-say")
}

// D — the letter inside a speech bubble. Friendliest shape, most obviously "for
// children"; also the busiest at 60pt.
do {
    let c = ctx()
    sunGround(c, inner: BUTTER, outer: rgb(0xF2A93B))
    let r = CGRect(x: S*0.13, y: S*0.24, width: S*0.74, height: S*0.60)
    let bubble = CGPath(roundedRect: r, cornerWidth: S*0.16, cornerHeight: S*0.16, transform: nil)
    c.setFillColor(PAPER); c.addPath(bubble); c.fillPath()
    c.move(to: CGPoint(x: S*0.38, y: S*0.27))
    c.addLine(to: CGPoint(x: S*0.33, y: S*0.10))
    c.addLine(to: CGPoint(x: S*0.55, y: S*0.27))
    c.closePath(); c.fillPath()
    let f = loadFont("Andika-Bold.ttf", size: S * 0.46)
    drawCentered(c, runs: [("a", VOWEL)], font: f, dy: S*0.045)
    save(c, "icon-bubble")
}

// E — control: green ground, to check the warm ground is actually the better call.
do {
    let c = ctx()
    sunGround(c, inner: rgb(0x3E9A88), outer: GREEN)
    drawCentered(c, runs: [("a", CREAM)], font: bold)
    save(c, "icon-green")
}
