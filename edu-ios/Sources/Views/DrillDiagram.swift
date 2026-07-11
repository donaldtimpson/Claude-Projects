import SwiftUI

// EXPERIMENT — inline diagrams for the geometry-flavored drills, drawn with
// Canvas (no assets). A unit-circle dial with the angle's radius + the asked
// component highlighted, and a vector arrow with its x/y component called out.
struct DrillDiagram: View {
    let spec: DrillDiagramSpec
    var size: CGFloat = 168

    var body: some View {
        Canvas { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let r = min(sz.width, sz.height) / 2 - 16
            switch spec {
            case let .unitCircle(deg, fn): drawUnitCircle(&ctx, c, r, deg, fn)
            case let .vector(deg, comp): drawVector(&ctx, c, r, deg, comp)
            }
        }
        .frame(width: size, height: size)
    }

    private func point(_ c: CGPoint, _ deg: Double, _ r: CGFloat) -> CGPoint {
        let a = deg * .pi / 180
        return CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y - r * CGFloat(sin(a))) // y up
    }

    private func line(_ ctx: inout GraphicsContext, _ p1: CGPoint, _ p2: CGPoint,
                      _ color: Color, _ w: CGFloat, dashed: Bool = false) {
        var path = Path()
        path.move(to: p1); path.addLine(to: p2)
        let style = dashed ? StrokeStyle(lineWidth: w, dash: [4, 3]) : StrokeStyle(lineWidth: w, lineCap: .round)
        ctx.stroke(path, with: .color(color), style: style)
    }

    private func axes(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat) {
        line(&ctx, CGPoint(x: c.x - r - 8, y: c.y), CGPoint(x: c.x + r + 8, y: c.y), Theme.line, 1)
        line(&ctx, CGPoint(x: c.x, y: c.y - r - 8), CGPoint(x: c.x, y: c.y + r + 8), Theme.line, 1)
    }

    private func dot(_ ctx: inout GraphicsContext, _ p: CGPoint, _ color: Color, _ rad: CGFloat = 4) {
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2)), with: .color(color))
    }

    private func arrowhead(_ ctx: inout GraphicsContext, from: CGPoint, to: CGPoint, _ color: Color) {
        let ang = atan2(to.y - from.y, to.x - from.x)
        let len: CGFloat = 9, spread = CGFloat.pi / 7
        for s in [spread, -spread] {
            let p = CGPoint(x: to.x - len * cos(ang - s), y: to.y - len * sin(ang - s))
            line(&ctx, to, p, color, 2.5)
        }
    }

    private func drawUnitCircle(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat, _ deg: Double, _ fn: String) {
        axes(&ctx, c, r)
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                   with: .color(Theme.inkSoft.opacity(0.5)), lineWidth: 1.5)
        let p = point(c, deg, r)
        line(&ctx, c, p, Theme.ink, 2)                    // radius
        let accent = Theme.gold300
        if fn == "cos" {
            line(&ctx, c, CGPoint(x: p.x, y: c.y), accent, 3)          // horizontal component
            line(&ctx, p, CGPoint(x: p.x, y: c.y), accent.opacity(0.6), 1.5, dashed: true)
        } else if fn == "sin" {
            line(&ctx, c, CGPoint(x: c.x, y: p.y), accent, 3)          // vertical component
            line(&ctx, p, CGPoint(x: c.x, y: p.y), accent.opacity(0.6), 1.5, dashed: true)
        }
        dot(&ctx, p, accent, 4.5)
    }

    private func drawVector(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat, _ deg: Double, _ comp: String) {
        axes(&ctx, c, r)
        let p = point(c, deg, r)
        line(&ctx, c, p, Theme.ink, 2.5)                  // the vector
        arrowhead(&ctx, from: c, to: p, Theme.ink)
        let accent = Theme.gold300
        if comp == "x" {
            line(&ctx, c, CGPoint(x: p.x, y: c.y), accent, 3.5)
            line(&ctx, p, CGPoint(x: p.x, y: c.y), accent.opacity(0.6), 1.5, dashed: true)
        } else {
            line(&ctx, c, CGPoint(x: c.x, y: p.y), accent, 3.5)
            line(&ctx, p, CGPoint(x: c.x, y: p.y), accent.opacity(0.6), 1.5, dashed: true)
        }
        dot(&ctx, p, accent, 4)
    }
}
