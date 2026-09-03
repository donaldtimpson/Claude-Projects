import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024
let fontsDir = "/Users/donnytimpsonjc/Sources/Claude-Projects/edu-reading/ios/Resources/Fonts"
let outDir = CommandLine.arguments[1]

func loadFont(_ f: String, _ size: CGFloat) -> CTFont {
    let u = URL(fileURLWithPath: "\(fontsDir)/\(f)") as CFURL
    let cg = CGFont(CGDataProvider(url: u)!)!
    return CTFontCreateWithGraphicsFont(cg, size, nil, nil)
}
func rgb(_ h: UInt) -> CGColor {
    CGColor(red: CGFloat((h >> 16) & 0xff)/255, green: CGFloat((h >> 8) & 0xff)/255,
            blue: CGFloat(h & 0xff)/255, alpha: 1)
}
let INK = rgb(0x1B2A33), VOWEL = rgb(0xC8433A), CREAM = rgb(0xFFF6E4)
let AMBER = rgb(0xF6B93B), DEEPAMBER = rgb(0xE89A22), PAPER = rgb(0xFFFFFF)

func ctx() -> CGContext {
    let c = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.setShouldAntialias(true); return c
}
func ground(_ c: CGContext, _ inner: CGColor, _ outer: CGColor) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [inner, outer] as CFArray, locations: [0, 1])!
    c.drawRadialGradient(g, startCenter: CGPoint(x: S/2, y: S*0.62), startRadius: 0,
                         endCenter: CGPoint(x: S/2, y: S*0.45), endRadius: S*0.8,
                         options: [.drawsAfterEndLocation])
}
func centered(_ c: CGContext, _ runs: [(String, CGColor)], _ font: CTFont,
              dy: CGFloat = 0, dx: CGFloat = 0) {
    let a = NSMutableAttributedString()
    for (s, col) in runs {
        a.append(NSAttributedString(string: s, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: font,
            kCTForegroundColorAttributeName as NSAttributedString.Key: col]))
    }
    let l = CTLineCreateWithAttributedString(a)
    let b = CTLineGetBoundsWithOptions(l, .useGlyphPathBounds)
    c.textPosition = CGPoint(x: S/2 - b.width/2 - b.minX + dx, y: S/2 - b.height/2 - b.minY + dy)
    CTLineDraw(l, c)
}
func save(_ c: CGContext, _ n: String) {
    let d = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/\(n).png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, c.makeImage()!, nil); CGImageDestinationFinalize(d)
    print("wrote \(n)")
}

// F — inverted: the app's vowel red becomes the whole identity, cream letter on top.
// Highest possible contrast, and unmissable against any wallpaper.
do { let c = ctx(); ground(c, rgb(0xD9564C), rgb(0xB8352C))
     centered(c, [("a", CREAM)], loadFont("Andika-Bold.ttf", S*0.72)); save(c, "r2-red") }

// G — the original, but with the ground pushed to a real amber so the tile has weight.
do { let c = ctx(); ground(c, AMBER, DEEPAMBER)
     centered(c, [("a", rgb(0xA8302A))], loadFont("Andika-Bold.ttf", S*0.72)); save(c, "r2-amber") }

// H — ink ground, red letter. The app's own two colours, nothing else.
do { let c = ctx(); ground(c, rgb(0x2A3E4A), rgb(0x14212A))
     centered(c, [("a", rgb(0xE8615A))], loadFont("Andika-Bold.ttf", S*0.72)); save(c, "r2-ink") }

// I — bubble, bigger letter and a heavier tail so it survives 60pt.
do {
    let c = ctx(); ground(c, AMBER, DEEPAMBER)
    let r = CGRect(x: S*0.11, y: S*0.26, width: S*0.78, height: S*0.58)
    c.setFillColor(PAPER)
    c.addPath(CGPath(roundedRect: r, cornerWidth: S*0.15, cornerHeight: S*0.15, transform: nil))
    c.fillPath()
    c.move(to: CGPoint(x: S*0.36, y: S*0.29)); c.addLine(to: CGPoint(x: S*0.30, y: S*0.08))
    c.addLine(to: CGPoint(x: S*0.58, y: S*0.29)); c.closePath(); c.fillPath()
    centered(c, [("a", VOWEL)], loadFont("Andika-Bold.ttf", S*0.50), dy: S*0.055)
    save(c, "r2-bubble")
}

// J — "at" on amber: the two-colour system, with enough ground contrast to read small.
do { let c = ctx(); ground(c, AMBER, DEEPAMBER)
     centered(c, [("a", rgb(0xA8302A)), ("t", INK)], loadFont("Andika-Bold.ttf", S*0.56))
     save(c, "r2-at") }
