import SwiftUI

// MARK: - Drawing kit for the Counting Room and the Music Room
//
// Every piece in these two wings is drawn in a UNIT square (0…1 both ways, feet at y = 1) and scaled
// into the bottom-centred square of whatever frame it gets — the room's `WingSpot` box or a shop card.
// Strokes are turned into outlines in unit space (`coLine`), so line weights scale with the drawing
// and a lyre string is as fine on a card as in the room. Names carry a `CO` prefix (shared by the two
// wing files only).

/// A path built in unit space, scaled into the bottom-centred square of its frame.
struct COPath: Shape {
    let make: (inout Path) -> Void
    init(_ make: @escaping (inout Path) -> Void) { self.make = make }
    func path(in r: CGRect) -> Path {
        var p = Path()
        make(&p)
        let s = min(r.width, r.height)
        return p.applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: r.midX - s / 2, ty: r.maxY - s))
    }
}

func coPt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

extension Path {
    /// A polyline of width `lw` (unit space), added as a filled outline.
    mutating func coLine(_ pts: [CGPoint], _ lw: CGFloat, cap: CGLineCap = .round) {
        var q = Path()
        q.addLines(pts)
        addPath(q.strokedPath(StrokeStyle(lineWidth: lw, lineCap: cap, lineJoin: .round)))
    }
    /// A quadratic curve of width `lw`.
    mutating func coQuad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ lw: CGFloat, cap: CGLineCap = .round) {
        var q = Path()
        q.move(to: a); q.addQuadCurve(to: b, control: c)
        addPath(q.strokedPath(StrokeStyle(lineWidth: lw, lineCap: cap)))
    }
    /// A cubic curve of width `lw`.
    mutating func coCurve(_ a: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ b: CGPoint, _ lw: CGFloat) {
        var q = Path()
        q.move(to: a); q.addCurve(to: b, control1: c1, control2: c2)
        addPath(q.strokedPath(StrokeStyle(lineWidth: lw, lineCap: .round)))
    }
    mutating func coOval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        addEllipse(in: CGRect(x: x, y: y, width: w, height: h))
    }
    /// An oval by its centre and radii.
    mutating func coDot(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat? = nil) {
        let ry = ry ?? rx
        addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }
    mutating func coBox(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat = 0) {
        let rect = CGRect(x: x, y: y, width: w, height: h)
        if r > 0 { addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r)) } else { addRect(rect) }
    }
    mutating func coPoly(_ pts: [CGPoint]) {
        addLines(pts); closeSubpath()
    }
    /// The outline of an oval (a ring of width `lw`).
    mutating func coRing(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ lw: CGFloat) {
        var q = Path()
        q.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        addPath(q.strokedPath(StrokeStyle(lineWidth: lw)))
    }
}

/// The shared materials: bronze, iron, woods, ivory and cane, in the garden's fresco key.
enum COC {
    static let bronze = Color(hex: 0xb7843f)
    static let bronzeLt = Color(hex: 0xe3b866)
    static let bronzeDk = Color(hex: 0x7a5024)
    static let iron = Color(hex: 0x4a423c)
    static let ironLt = Color(hex: 0x7d7268)
    static let wood = Color(hex: 0x8d5a31)
    static let woodLt = Color(hex: 0xb47c48)
    static let woodDk = Color(hex: 0x5b371d)
    static let ivory = Color(hex: 0xf1e5c6)
    static let cane = Color(hex: 0xdcb86c)
    static let caneDk = Color(hex: 0xa7823f)
    static let red = Color(hex: 0xb8322a)
    static let blue = Color(hex: 0x3f6f8f)
    static let shadow = Color.black.opacity(0.17)
    static func bronzeFill(_ a: UnitPoint = .topLeading, _ b: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: [bronzeLt, bronze, bronzeDk], startPoint: a, endPoint: b)
    }
    static var marbleFill: LinearGradient {
        LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing)
    }
}

/// A shop-card picture: the drawing scaled so its unit-space bounds `box` fill the tile, centred.
struct COThumb<D: View>: View {
    let box: CGRect
    @ViewBuilder let drawing: D
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            let s = min(W * 0.96 / box.width, H * 0.96 / box.height)
            drawing
                .frame(width: s, height: s)
                .position(x: W / 2 + (0.5 - box.midX) * s, y: H / 2 + (0.5 - box.midY) * s)
        }
    }
}

/// A soft four-point sparkle (for glints on bronze).
struct COGlint: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), a = r.width / 2, b = r.width * 0.09
        p.move(to: CGPoint(x: c.x, y: c.y - a))
        p.addQuadCurve(to: CGPoint(x: c.x + a, y: c.y), control: CGPoint(x: c.x + b, y: c.y - b))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + a), control: CGPoint(x: c.x + b, y: c.y + b))
        p.addQuadCurve(to: CGPoint(x: c.x - a, y: c.y), control: CGPoint(x: c.x - b, y: c.y + b))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - a), control: CGPoint(x: c.x - b, y: c.y - b))
        return p
    }
}
