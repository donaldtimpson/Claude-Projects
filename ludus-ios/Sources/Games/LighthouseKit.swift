import SwiftUI

// MARK: - LighthouseKit — shared map plumbing for the Globe Trotters (Lighthouse) games
//
// The bundled atlas (`GeoAtlas`) is Web-Mercator in "map units": x = (lon + 180)·1000/360,
// y = 500.1 − 159.15·ln tan(45° + lat/2). It stops at ~56° S, so Antarctica is drawn as a stylised
// ice band below the Southern Ocean (`LH.iceTop`). Everything here is map-space maths, a camera that
// fits a map rect into a view, the 7-continent model the games share, and ocean classification.

enum LH {
    // MARK: Projection
    static func point(lat: Double, lon: Double) -> CGPoint { GeoAtlas.point(lat: lat, lon: lon) }
    static func lon(_ x: CGFloat) -> Double { Double(x) * 360 / 1000 - 180 }
    static func lat(_ y: CGFloat) -> Double {
        let m = (500.1 - Double(y)) / 159.15
        return (2 * atan(exp(m)) - .pi / 2) * 180 / .pi
    }
    /// A lat/lon box as a map rect.
    static func box(lat: ClosedRange<Double>, lon: ClosedRange<Double>) -> CGRect {
        let a = point(lat: lat.upperBound, lon: lon.lowerBound), b = point(lat: lat.lowerBound, lon: lon.upperBound)
        return CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y)
    }

    /// The whole world as drawn (Arctic to the Antarctic ice band).
    static let world = CGRect(x: -6, y: 40, width: 1012, height: 760)
    /// Top of the Antarctic ice band (≈ 66° S); the Southern Ocean lies between the land data and it.
    static let iceTop: CGFloat = 742

    static let antarctica: Path = {
        var p = Path()
        p.move(to: CGPoint(x: -20, y: iceTop + 12))
        var x: CGFloat = -20, i = 0
        while x < 1030 {
            x += 26; i += 1
            let dip: CGFloat = [0, 7, 2, 10, 4, 1, 8, 3][i % 8]
            p.addLine(to: CGPoint(x: x, y: iceTop + dip))
        }
        p.addLine(to: CGPoint(x: 1030, y: 2400)); p.addLine(to: CGPoint(x: -20, y: 2400)); p.closeSubpath()
        return p
    }()

    // MARK: Continents (7-continent school model; Oceania = Australia & the Pacific islands)
    static let continents = ["Africa", "Asia", "Europe", "North America", "South America", "Oceania", "Antarctica"]

    static func icon(_ c: String) -> String {
        switch c {
        case "Africa": return "🦁"; case "Asia": return "🐼"; case "Europe": return "🏰"
        case "North America": return "🦅"; case "South America": return "🦜"; case "Oceania": return "🦘"
        default: return "🐧"
        }
    }
    static func hex(_ c: String) -> UInt {
        switch c {
        case "Africa": return 0xe8973a
        case "Asia": return 0xe0684f
        case "Europe": return 0xa96fd6
        case "North America": return 0x63b96b
        case "South America": return 0xf5c542
        case "Oceania": return 0x4fa6cf
        default: return 0xe6f2f8
        }
    }
    /// Where a continent's badge / answer pin sits.
    static func anchor(_ c: String) -> CGPoint {
        switch c {
        case "Africa": return point(lat: 6, lon: 20)
        case "Asia": return point(lat: 42, lon: 92)
        case "Europe": return point(lat: 50, lon: 16)
        case "North America": return point(lat: 45, lon: -100)
        case "South America": return point(lat: -10, lon: -57)
        case "Oceania": return point(lat: -25, lon: 134)
        default: return CGPoint(x: 500, y: iceTop + 30)
        }
    }
    /// The map region a continent's countries are asked in.
    static func region(_ c: String) -> CGRect {
        switch c {
        case "Africa": return box(lat: -36...38, lon: -20...55)
        case "Asia": return box(lat: -11...56, lon: 25...150)
        case "Europe": return box(lat: 34...71, lon: -25...45)
        case "North America": return box(lat: 7...72, lon: -170...(-50))
        case "South America": return box(lat: -56...13, lon: -82...(-34))
        case "Oceania": return box(lat: -48...0, lon: 110...180)
        default: return world
        }
    }
    /// The continent a country (or, for Russia, which half of it) belongs to.
    static func continent(of c: AtlasCountry, at p: CGPoint? = nil) -> String {
        if c.name == "Russia" { return (p?.x ?? 0) > GeoAtlas.uralsX ? "Asia" : "Europe" }
        return c.continent
    }

    // MARK: Hit testing
    static func country(at p: CGPoint) -> AtlasCountry? {
        GeoAtlas.countries.first { $0.box.insetBy(dx: -1, dy: -1).contains(p) && $0.path.contains(p) }
    }
    /// The country under `p`, or failing that the nearest one within `tol` map units (coast taps).
    static func countryNear(_ p: CGPoint, tol: CGFloat) -> AtlasCountry? {
        if let c = country(at: p) { return c }
        for r in [tol * 0.5, tol] {
            for k in 0..<12 {
                let a = Double(k) / 12 * 2 * .pi
                if let c = country(at: CGPoint(x: p.x + CGFloat(cos(a)) * r, y: p.y + CGFloat(sin(a)) * r)) { return c }
            }
        }
        return nil
    }
    /// The biggest piece of a country's outline (its mainland), for pins and labels.
    static func mainBox(_ c: AtlasCountry) -> CGRect {
        var best = CGRect.null, cur = CGRect.null
        func close() { if cur.width * cur.height > best.width * best.height || best.isNull { best = cur }; cur = .null }
        c.path.forEach { e in
            switch e {
            case .move(let p): if !cur.isNull { close() }; cur = CGRect(origin: p, size: .zero)
            case .line(let p): cur = cur.union(CGRect(origin: p, size: .zero))
            default: break
            }
        }
        if !cur.isNull { close() }
        return best.isNull ? c.box : best
    }
    static func pin(_ c: AtlasCountry) -> CGPoint {
        let b = mainBox(c)
        let mid = CGPoint(x: b.midX, y: b.midY)
        if c.path.contains(mid) { return mid }
        // Long, bent countries: walk in from the box centre to the first point inside.
        for f in stride(from: 0.1, through: 0.5, by: 0.1) {
            for q in [CGPoint(x: b.midX, y: b.minY + b.height * f), CGPoint(x: b.midX, y: b.maxY - b.height * f),
                      CGPoint(x: b.minX + b.width * f, y: b.midY), CGPoint(x: b.maxX - b.width * f, y: b.midY)]
            where c.path.contains(q) { return q }
        }
        return mid
    }

    // MARK: Oceans
    /// Each ocean (and the named seas that are NOT counted as a whole ocean here) is a cloud of
    /// anchor points; open water is classified by the nearest anchor. Seas are "neutral".
    struct Water { let name: String; let ocean: Bool; let pts: [(Double, Double)] }
    static let waters: [Water] = [
        Water(name: "Pacific Ocean", ocean: true, pts: [(0, -140), (0, -110), (20, -150), (30, -130), (-20, -120), (-30, -100),
              (-40, -140), (40, 170), (30, 150), (10, 160), (0, 170), (-20, 170), (-40, -160), (50, -150), (15, -100),
              (-10, -85), (20, 130), (-45, -90), (50, 170), (5, -95), (-5, -82), (40, -130), (55, -140), (-10, -170), (10, -170)]),
        Water(name: "Atlantic Ocean", ocean: true, pts: [(30, -40), (0, -25), (-20, -15), (-35, -30), (45, -30), (55, -35),
              (15, -50), (-45, -40), (32, -70), (10, -30), (-10, -30), (40, -60), (60, -20), (-30, 5), (20, -25), (45, -10),
              (5, -5), (-50, -55), (-50, -20), (25, -60)]),
        Water(name: "Indian Ocean", ocean: true, pts: [(-10, 75), (-25, 80), (-30, 60), (-15, 55), (0, 65), (10, 65),
              (-35, 100), (-20, 100), (-10, 95), (15, 88), (-40, 80), (-40, 50), (-20, 40), (-35, 115), (-15, 110), (12, 55), (5, 80)]),
        Water(name: "Arctic Ocean", ocean: true, pts: [(82, 0), (82, 90), (82, -90), (82, 180), (76, -160), (76, 40), (76, 120),
              (73, -140), (78, 10), (74, 160), (80, -40), (75, 70)]),
        Water(name: "Southern Ocean", ocean: true, pts: [(-63, -180), (-63, -135), (-63, -90), (-63, -45), (-63, 0), (-63, 45),
              (-63, 90), (-63, 135), (-63, 180), (-61, -65)]),
        Water(name: "Mediterranean Sea", ocean: false, pts: [(35, 18), (38, 5), (34, 28), (40, 25), (37, 12)]),
        Water(name: "Caribbean Sea", ocean: false, pts: [(15, -75), (15, -80), (14, -68)]),
        Water(name: "Gulf of Mexico", ocean: false, pts: [(25, -90), (26, -86)]),
        Water(name: "Black Sea", ocean: false, pts: [(43, 34)]),
        Water(name: "Caspian Sea", ocean: false, pts: [(42, 51)]),
        Water(name: "Baltic Sea", ocean: false, pts: [(58, 20), (55, 16)]),
        Water(name: "North Sea", ocean: false, pts: [(56, 3)]),
        Water(name: "Hudson Bay", ocean: false, pts: [(60, -85)]),
        Water(name: "Red Sea", ocean: false, pts: [(20, 38)]),
        Water(name: "Persian Gulf", ocean: false, pts: [(27, 51)]),
        Water(name: "South China Sea", ocean: false, pts: [(12, 113)]),
        Water(name: "Sea of Japan", ocean: false, pts: [(40, 135)]),
        Water(name: "Baffin Bay", ocean: false, pts: [(73, -65)]),
        Water(name: "Norwegian Sea", ocean: false, pts: [(68, 3)]),
        Water(name: "Bay of Bengal", ocean: false, pts: [(15, 88.5)]),
    ]
    /// The water at a map point (call only where there is no land).
    static func water(at p: CGPoint) -> Water {
        let la = p.y > iceTop - 30 ? -63 : lat(p.y), lo = lon(p.x)
        var best = waters[0], bd = Double.infinity
        for w in waters {
            for (a, b) in w.pts {
                var dl = abs(lo - b); if dl > 180 { dl = 360 - dl }
                let d = (la - a) * (la - a) + dl * dl * pow(cos((la + a) / 2 * .pi / 180), 2)
                if d < bd { bd = d; best = w }
            }
        }
        // The Bay of Bengal is part of the Indian Ocean: report the ocean, name the bay.
        return best
    }
    /// An open-ocean point for an ocean's pin.
    static func oceanPin(_ name: String) -> CGPoint {
        switch name {
        case "Pacific Ocean": return point(lat: 5, lon: -140)
        case "Atlantic Ocean": return point(lat: 25, lon: -40)
        case "Indian Ocean": return point(lat: -20, lon: 78)
        case "Arctic Ocean": return point(lat: 82.5, lon: 10)
        default: return point(lat: -61, lon: 20)
        }
    }

    // MARK: Drawing
    /// Fits a map rect into a view (aspect-fill around its centre, so the rect is always fully shown).
    struct Camera {
        let rect: CGRect      // map rect requested
        let size: CGSize
        let scale: CGFloat
        let origin: CGPoint   // map point at the view's top-left
        init(_ r: CGRect, _ size: CGSize) {
            self.rect = r; self.size = size
            let s = min(size.width / max(r.width, 1), size.height / max(r.height, 1))
            scale = s
            origin = CGPoint(x: r.midX - size.width / 2 / s, y: r.midY - size.height / 2 / s)
        }
        func view(_ p: CGPoint) -> CGPoint { CGPoint(x: (p.x - origin.x) * scale, y: (p.y - origin.y) * scale) }
        func map(_ v: CGPoint) -> CGPoint { CGPoint(x: v.x / scale + origin.x, y: v.y / scale + origin.y) }
        var visible: CGRect { CGRect(x: origin.x, y: origin.y, width: size.width / scale, height: size.height / scale) }
        func apply(_ ctx: inout GraphicsContext) {
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -origin.x, y: -origin.y)
        }
    }

    static func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: a.minX + (b.minX - a.minX) * t, y: a.minY + (b.minY - a.minY) * t,
               width: a.width + (b.width - a.width) * t, height: a.height + (b.height - a.height) * t)
    }
    static func smooth(_ t: Double) -> CGFloat { let x = max(0, min(1, t)); return CGFloat(x * x * (3 - 2 * x)) }

    /// Fills each country (Russia twice, clipped at the Urals) with the colour `style` picks.
    static func drawLand(_ ctx: GraphicsContext, visible: CGRect, line: CGFloat,
                         stroke: Color = .black.opacity(0.28),
                         style: (AtlasCountry, String) -> Color?) {
        for c in GeoAtlas.countries where c.box.intersects(visible) {
            if c.name == "Russia" {
                for east in [false, true] {
                    var cx = ctx
                    cx.clip(to: Path(east ? CGRect(x: GeoAtlas.uralsX, y: 0, width: 1100, height: 900)
                                          : CGRect(x: -100, y: 0, width: GeoAtlas.uralsX + 100, height: 900)))
                    if let col = style(c, east ? "Asia" : "Europe") { cx.fill(c.path, with: .color(col)) }
                    cx.stroke(c.path, with: .color(stroke), lineWidth: line)
                }
            } else {
                if let col = style(c, c.continent) { ctx.fill(c.path, with: .color(col)) }
                ctx.stroke(c.path, with: .color(stroke), lineWidth: line)
            }
        }
    }

    /// Lat/long grid lines every `step` degrees (equator and prime meridian a little stronger).
    static func drawGrid(_ ctx: GraphicsContext, step: Double, alpha: Double, line: CGFloat, color: Color) {
        var lat = -60.0
        while lat <= 80 {
            var p = Path()
            p.move(to: point(lat: lat, lon: -180)); p.addLine(to: point(lat: lat, lon: 180))
            ctx.stroke(p, with: .color(color.opacity(lat == 0 ? alpha * 1.8 : alpha)), lineWidth: lat == 0 ? line * 1.6 : line)
            lat += step
        }
        var lon = -180.0
        while lon <= 180 {
            var p = Path()
            p.move(to: point(lat: 84, lon: lon)); p.addLine(to: CGPoint(x: point(lat: 0, lon: lon).x, y: iceTop))
            ctx.stroke(p, with: .color(color.opacity(lon == 0 ? alpha * 1.8 : alpha)), lineWidth: lon == 0 ? line * 1.6 : line)
            lon += step
        }
    }
}

// MARK: - Shared little scene pieces

/// A soft cartoon cloud.
struct LHCloud: View {
    var color: Color = .white
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Ellipse().frame(width: w * 0.55, height: h * 0.75).position(x: w * 0.36, y: h * 0.55)
                Ellipse().frame(width: w * 0.5, height: h * 0.95).position(x: w * 0.6, y: h * 0.45)
                Ellipse().frame(width: w * 0.42, height: h * 0.6).position(x: w * 0.8, y: h * 0.65)
                Capsule().frame(width: w * 0.92, height: h * 0.42).position(x: w * 0.5, y: h * 0.76)
            }
            .foregroundStyle(color)
        }
    }
}

/// The parchment card games put their "call" on (dark ink on warm paper — readable everywhere).
struct LHParchment: View {
    var radius: CGFloat = 16
    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(LinearGradient(colors: [Color(hex: 0xfbf0d6), Color(hex: 0xefdcb2)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color(hex: 0x9c7b33), lineWidth: 2))
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }
}

let lhInk: UInt = 0x3b2410        // dark sepia ink
let lhInkSoft: UInt = 0x7a5a36

/// A countdown sliver for a card's bottom edge.
struct LHPatienceBar: View {
    let left: Double, total: Double
    var body: some View {
        GeometryReader { g in
            let f = total > 0 ? max(0, min(1, left / total)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.12))
                Capsule().fill(Color(hex: f < 0.3 ? Lu.coral : 0x4f8f5a)).frame(width: g.size.width * f)
            }
        }
        .frame(height: 6)
    }
}
