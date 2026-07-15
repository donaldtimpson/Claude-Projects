import SwiftUI

// Renders a bundled vector atlas with one region highlighted, for the map drills.
// All shapes are cached SwiftUI Paths (GeoAtlas) drawn in a single Canvas — no image
// assets. Fits the atlas viewBox into the available width, preserving aspect ratio.
struct GeoMapDiagram: View {
    let kind: GeoMapKind
    let highlightId: String
    // Zoom to a window around the target (so small countries are legible). Off = whole
    // atlas, for the future tap-to-locate mode where finding it is the challenge.
    var focus: Bool = true

    private var map: GeoMap {
        switch kind {
        case .world: return GeoAtlas.world
        case .usStates: return GeoAtlas.world   // placeholder until the US atlas ships
        }
    }

    // Muted land on a dark "sea"; the target pops in bright gold.
    private let sea = Theme.parchmentDeep
    private let land = Theme.inkSoft.opacity(0.30)
    private let border = Theme.parchment.opacity(0.85)
    private let highlight = Theme.gold300
    private let highlightStroke = Theme.gold500

    var body: some View {
        let port = viewport
        Canvas { ctx, size in
            guard port.width > 0, port.height > 0 else { return }
            let scale = min(size.width / port.width, size.height / port.height)
            let tx = (size.width - port.width * scale) / 2 - port.minX * scale
            let ty = (size.height - port.height * scale) / 2 - port.minY * scale
            let t = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: tx, ty: ty)

            for region in map.regions where region.id != highlightId {
                let p = region.path.applying(t)
                ctx.fill(p, with: .color(land))
                ctx.stroke(p, with: .color(border), lineWidth: 0.4)
            }
            guard let target = map.region(highlightId) else { return }
            let p = target.path.applying(t)
            ctx.fill(p, with: .color(highlight))
            ctx.stroke(p, with: .color(highlightStroke), lineWidth: 1)

            // A locator ring so a tiny highlighted country is still findable.
            let b = p.boundingRect
            if min(b.width, b.height) < 30 {
                let c = CGPoint(x: b.midX, y: b.midY)
                let rad = max(b.width, b.height) / 2 + 13
                let ring = Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2))
                ctx.stroke(ring, with: .color(highlight), lineWidth: 1.5)
            }
        }
        .aspectRatio(port.width / port.height, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(sea)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
    }

    // The rectangle of the atlas actually drawn. Whole atlas unless focusing on a
    // target, in which case a padded window around it (clamped inside the atlas),
    // sized relative to the target so tiny countries zoom in more than large ones.
    private var viewport: CGRect {
        let vb = map.viewBox
        guard focus, let target = map.region(highlightId) else { return vb }
        let aspect: CGFloat = 1.5
        let b = target.focus                             // largest landmass, not exclaves
        var w = max(b.width, b.height * aspect) * 3.5   // ~3.5× the target = room for neighbors
        w = min(max(w, vb.width * 0.16), vb.width)      // not too tight, not past the atlas
        var h = w / aspect
        if h > vb.height { h = vb.height; w = min(h * aspect, vb.width) }
        let x = min(max(b.midX - w / 2, vb.minX), vb.maxX - w)
        let y = min(max(b.midY - h / 2, vb.minY), vb.maxY - h)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
