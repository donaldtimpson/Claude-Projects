import SwiftUI

// Map palette — EXPERIMENT: "natural Earth" look. Land is tinted by a latitude-driven
// biome gradient (lush tropics → tan desert belts → temperate green → icy poles), an
// approximation of real terrain with no elevation data. Ocean blue, gold highlight.
private enum MapPalette {
    static let sea = Color(hex: 0x24506b)              // realistic ocean
    static let border = Color(hex: 0x2c2416).opacity(0.30)  // faint terrain outlines
    static let frame = Color(hex: 0x14202b)            // card outline
    static let highlight = Theme.gold300               // the target country
    static let highlightStroke = Theme.gold500
    static let river = Color(hex: 0x2f6fa8)             // river centerlines
    static let neighbor = Color(hex: 0x6f747a)          // context countries (Canada/Mexico)
    static let neighborBorder = Color(hex: 0x4a4e52)
    static let graticule: Color? = nil
    // Biome color by latitude (°); land is filled with a vertical gradient of these.
    // Deserts land ~15–35° N/S; tropics green; poles icy. Mountains/interior deserts
    // can't be placed without elevation data.
    static let biome: [(lat: Double, hex: UInt)] = [
        (90, 0xe9edee), (72, 0x93a074), (52, 0x5d7d46), (37, 0x8f9457),
        (26, 0xcdb679), (15, 0x9aa653), (2, 0x3c7a3a), (-16, 0x93a24d),
        (-27, 0xc4af6d), (-45, 0x5d7d46), (-60, 0x828f6d),
    ]
    // Deep-ocean (main): sea=0x123a4d, flat land=0x4a7856, border/frame=0x0c2733, gold highlight.
}

// Renders a bundled vector atlas with one region highlighted, for the map drills.
// All shapes are cached SwiftUI Paths (GeoAtlas) drawn in a single Canvas — no image
// assets. When the highlighted country changes, the view flies from the previous
// location to the new one — zoom out, travel across the globe, zoom back in — so the
// player sees where each country sits relative to the last (spatial context).
struct GeoMapDiagram: View {
    let kind: GeoMapKind
    var highlightId: String = ""
    // Zoom/animate to a window around the target (so small countries are legible).
    // Off = whole atlas (tap-to-locate, where finding it is the point).
    var focus: Bool = true
    // Multi-region fills (id → color). When set, overrides the single gold highlight and
    // suppresses the locator ring/fly — used by tap-to-locate to color target vs. tapped.
    var highlights: [String: Color]? = nil
    // When true, taps are hit-tested to a region id and reported (tap-to-locate).
    var interactive: Bool = false
    var onTapRegion: ((String?) -> Void)? = nil
    // Tap-to-locate: zoom to an approximate regional window around this target (static, no
    // fly). The target is placed OFF-center (deterministically) so it's tappable-large but
    // not given away by being centered.
    var locateTargetId: String? = nil
    // Frame aspect (width : height) for the card layout. Identify keeps the portrait-friendly
    // 1.6; unused when `fillFrame` is set (the port then matches the measured frame exactly).
    var aspect: CGFloat = 1.6
    // Fill the given frame edge-to-edge (the port matches the measured frame aspect, so there
    // is no letterbox / flat sea-colored margin) and enable pan + pinch. For the full-screen
    // landscape tap-to-locate map. Off = the bordered fixed-aspect card used by identify.
    var fillFrame: Bool = false

    @State private var displayed: CGRect = .zero   // the viewport currently drawn (animated)
    @State private var mapSize: CGSize = .zero     // rendered size, for reverse hit-testing
    @State private var frameAspect: CGFloat = 0    // measured w/h in fill mode
    @State private var gestureBase: CGRect?        // viewport at the start of a pan/pinch

    // Aspect actually used to build the viewport: the measured frame in fill mode, else the
    // fixed card aspect. Keeps the port's shape identical to the frame → no letterbox.
    private var aspectE: CGFloat { fillFrame && frameAspect > 0 ? frameAspect : aspect }
    // The target this map is framed on (locate passes locateTargetId; identify uses highlightId).
    private var targetId: String { locateTargetId ?? highlightId }

    private var map: GeoMap {
        switch kind {
        case .world: return GeoAtlas.world
        case .usStates: return GeoAtlas.usStates
        }
    }

    // Effective fills + ring: locate mode passes `highlights`; identify defaults to the
    // single gold target (with the small-country locator ring).
    private var fills: [String: Color] { highlights ?? [highlightId: MapPalette.highlight] }
    private var ringId: String? { highlights == nil ? highlightId : nil }

    // The viewport actually drawn. Both modes fly between questions via `displayed`;
    // before the first layout it's the settled/locate window for the starting target.
    private var currentPort: CGRect {
        if displayed != .zero { return displayed }
        if let id = locateTargetId { return locatePort(id) }
        return settledPort(highlightId)
    }

    var body: some View {
        canvas
            .background(MapPalette.sea)
            .background(GeometryReader { g in Color.clear
                .onAppear { measure(g.size) }
                .onChange(of: g.size) { _, s in measure(s) } })
            .clipShape(RoundedRectangle(cornerRadius: fillFrame ? 0 : 10))
            .overlay {
                if !fillFrame {
                    RoundedRectangle(cornerRadius: 10).stroke(MapPalette.frame, lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
            .gesture(interactive ? panZoom : nil)
            .simultaneousGesture(SpatialTapGesture().onEnded { v in if interactive { handleTap(v.location) } },
                                 including: interactive ? .gesture : .none)
            .onAppear { if displayed == .zero { displayed = currentPort } }
            .onChange(of: highlightId) { oldId, newId in flyBetween(oldId, newId, settle: settledPort) }
            // Locate mode: fly between the off-center regional windows so the player keeps
            // spatial context across questions instead of jump-cutting to a new region.
            .onChange(of: locateTargetId) { oldId, newId in
                if let newId { flyBetween(oldId ?? "", newId, settle: locatePort) }
            }
    }

    @ViewBuilder private var canvas: some View {
        let c = MapCanvas(port: currentPort, viewBox: map.viewBox, regions: map.regions, rivers: map.rivers,
                          lakes: map.lakes, neighbors: map.neighbors, fills: fills, ringId: ringId)
        if fillFrame {
            c.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            c.aspectRatio(aspect, contentMode: .fit).frame(maxWidth: .infinity)
        }
    }

    // Record the rendered size (for hit-testing) and, in fill mode, the frame aspect. When the
    // measured aspect first arrives (or changes), re-seat the viewport on the target so the port
    // shape matches the frame exactly — otherwise the initial displayed rect (built with the
    // fallback aspect) would letterbox.
    private func measure(_ s: CGSize) {
        mapSize = s
        guard fillFrame, s.height > 0 else { return }
        let a = s.width / s.height
        if abs(a - frameAspect) > 0.001 {
            frameAspect = a
            if gestureBase == nil { displayed = portFor(targetId) }
        }
    }

    // Reverse the port→screen transform, then point-in-polygon test each region.
    private func handleTap(_ loc: CGPoint) {
        let port = currentPort
        guard mapSize.width > 0, mapSize.height > 0, port.width > 0, port.height > 0 else { return }
        let scale = min(mapSize.width / port.width, mapSize.height / port.height)
        let tx = (mapSize.width - port.width * scale) / 2 - port.minX * scale
        let ty = (mapSize.height - port.height * scale) / 2 - port.minY * scale
        let atlas = CGPoint(x: (loc.x - tx) / scale, y: (loc.y - ty) / scale)
        onTapRegion?(map.regions.first { $0.path.contains(atlas) }?.id)
    }

    // Drag to pan, pinch to zoom — so the map never feels frozen and you can look around
    // beyond the auto-framed window. Both work off the viewport captured when the gesture
    // began (`gestureBase`) and stay clamped to the atlas.
    private var panZoom: some Gesture {
        let pan = DragGesture(minimumDistance: 8)
            .onChanged { v in
                let base = gestureBase ?? displayed
                if gestureBase == nil { gestureBase = base }
                guard mapSize.width > 0 else { return }
                let scale = min(mapSize.width / base.width, mapSize.height / base.height)
                let r = base.offsetBy(dx: -v.translation.width / scale, dy: -v.translation.height / scale)
                displayed = clampToAtlas(r)
            }
            .onEnded { _ in gestureBase = nil }
        let zoom = MagnificationGesture()
            .onChanged { m in
                let base = gestureBase ?? displayed
                if gestureBase == nil { gestureBase = base }
                let k = (1 / max(m, 0.2))
                var w = (base.width * k).clamped(map.viewBox.width * 0.05, map.viewBox.width)
                var h = w / aspectE
                if h > map.viewBox.height { h = map.viewBox.height; w = h * aspectE }
                let cx = base.midX, cy = base.midY
                displayed = clampToAtlas(CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h))
            }
            .onEnded { _ in gestureBase = nil }
        return pan.simultaneously(with: zoom)
    }

    // Keep a viewport within the atlas: shrink to fit if larger, then slide inside the bounds.
    private func clampToAtlas(_ r: CGRect) -> CGRect {
        let vb = map.viewBox
        let w = min(r.width, vb.width), h = min(r.height, vb.height)
        let x = w >= vb.width ? vb.minX : min(max(r.minX, vb.minX), vb.maxX - w)
        let y = h >= vb.height ? vb.minY : min(max(r.minY, vb.minY), vb.maxY - h)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // The framed viewport for a target, per mode (locate = off-center window, identify = settled).
    private func portFor(_ id: String) -> CGRect {
        locateTargetId != nil ? locatePort(id) : settledPort(id)
    }

    // MARK: viewports

    // The settled window around a target: padded room for neighbors, clamped to the
    // atlas, fixed aspect. Whole atlas when not focusing.
    private func settledPort(_ id: String) -> CGRect {
        guard focus, let target = map.region(id) else { return map.viewBox }
        return window(around: target.focus, pad: 3.5)
    }

    // Tap-to-locate viewport: a regional window around the target, big enough to give
    // orienting neighbors without being a giveaway. The window is sized from the TARGET's
    // own span (not a fraction of the whole atlas) so far-flung insets — Alaska, Hawaii —
    // no longer inflate every other state's zoom. Per-map min/max keep tiny regions
    // tappable and huge ones (Russia, Alaska) framed with margin. Target placed OFF-center
    // at a deterministic spot in [0.3, 0.7] so it's never given away by being centered.
    private func locatePort(_ id: String) -> CGRect {
        let vb = map.viewBox
        guard let f = map.region(id)?.focus else { return vb }
        let z = Self.locateZoom[kind] ?? (min: vb.width * 0.18, max: vb.width, mult: 6)
        var w = (max(f.width, f.height * aspectE) * z.mult).clamped(z.min, z.max)
        w = min(w, vb.width)
        var h = w / aspectE
        if h > vb.height { h = vb.height; w = min(h * aspectE, vb.width) }
        let px = 0.30 + 0.40 * seededFrac(id, 1)
        let py = 0.30 + 0.40 * seededFrac(id, 2)
        let x = w >= vb.width ? vb.minX : min(max(f.midX - px * w, vb.minX), vb.maxX - w)
        let y = h >= vb.height ? vb.minY : min(max(f.midY - py * h, vb.minY), vb.maxY - h)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // Locate zoom knobs per atlas, in viewBox units (see locatePort). `mult` scales the
    // target span into a window; min/max clamp it. Tuned so a mid region shows a few
    // neighbors, tiny ones stay tappable, and outliers (Alaska/Russia) still fit.
    private static let locateZoom: [GeoMapKind: (min: CGFloat, max: CGFloat, mult: CGFloat)] = [
        .world: (min: 120, max: 520, mult: 2.5),      // viewBox ~1012 wide
        .usStates: (min: 42, max: 210, mult: 2.5),    // viewBox ~317 wide; Lower 48 ~148
    ]

    // Deterministic 0..1 from a string (FNV-1a) — stable across launches, unlike hashValue.
    private func seededFrac(_ s: String, _ salt: Int) -> Double {
        var h: UInt64 = 1469598103934665603 &+ UInt64(salt) &* 1099511628211
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return Double(h % 1000) / 1000.0
    }

    // A window of the frame aspect around `rect`, scaled by `pad`, centered and clamped.
    private func window(around rect: CGRect, pad: CGFloat) -> CGRect {
        let vb = map.viewBox
        var w = max(rect.width, rect.height * aspectE) * pad
        w = min(max(w, vb.width * 0.16), vb.width)
        let h = min(w / aspectE, vb.height)
        let w2 = min(w, h * aspectE)   // keep aspect if height was capped
        let cx = rect.midX, cy = rect.midY
        let x = w2 >= vb.width ? vb.minX : min(max(cx - w2 / 2, vb.minX), vb.maxX - w2)
        let y = h >= vb.height ? vb.minY : min(max(cy - h / 2, vb.minY), vb.maxY - h)
        return CGRect(x: x, y: y, width: w2, height: h)
    }

    // Fly old → (zoom out over both) → new. `settle` gives the final resting window for a
    // target: identify uses `settledPort` (centered), locate uses `locatePort` (off-center).
    private func flyBetween(_ oldId: String, _ newId: String, settle: (String) -> CGRect) {
        let target = settle(newId)
        guard let a = map.region(oldId)?.focus, let b = map.region(newId)?.focus else {
            withAnimation(.easeInOut(duration: 0.4)) { displayed = target }
            return
        }
        let bridge = window(around: a.union(b), pad: 1.25)   // shows both locations
        withAnimation(.easeIn(duration: 0.42)) { displayed = bridge }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.easeOut(duration: 0.46)) { displayed = target }
        }
    }
}

// The Canvas is wrapped in an Animatable view so SwiftUI interpolates the viewport
// rect frame-by-frame (a plain Canvas reading @State wouldn't redraw mid-animation),
// keeping the vector map crisp at every zoom level.
private struct MapCanvas: View, Animatable {
    var port: CGRect
    let viewBox: CGRect
    let regions: [GeoRegion]
    let rivers: [GeoRiver]
    let lakes: [Path]
    let neighbors: [Path]
    let fills: [String: Color]     // region id → fill color (target/tapped); others get biome land
    let ringId: String?            // draw a locator ring around this region (identify mode)

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { .init(.init(port.origin.x, port.origin.y), .init(port.size.width, port.size.height)) }
        set { port = CGRect(x: newValue.first.first, y: newValue.first.second,
                            width: max(newValue.second.first, 1), height: max(newValue.second.second, 1)) }
    }

    private let border = MapPalette.border
    private let highlightStroke = MapPalette.highlightStroke

    var body: some View {
        Canvas { ctx, size in
            guard port.width > 0, port.height > 0 else { return }
            let scale = min(size.width / port.width, size.height / port.height)
            let tx = (size.width - port.width * scale) / 2 - port.minX * scale
            let ty = (size.height - port.height * scale) / 2 - port.minY * scale
            let t = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: tx, ty: ty)

            // Context countries (Canada/Mexico) at the bottom, flat gray.
            for n in neighbors {
                let p = n.applying(t)
                ctx.fill(p, with: .color(MapPalette.neighbor))
                ctx.stroke(p, with: .color(MapPalette.neighborBorder), lineWidth: 0.4)
            }

            // Graticule (lat/long grid) drawn first, so land covers it and it reads only
            // over the sea — the hallmark of an old chart.
            if let grid = MapPalette.graticule {
                var g = Path()
                var x = viewBox.minX
                while x <= viewBox.maxX { g.move(to: CGPoint(x: x, y: viewBox.minY)); g.addLine(to: CGPoint(x: x, y: viewBox.maxY)); x += 84 }  // ~30° lon
                var y = viewBox.minY
                while y <= viewBox.maxY { g.move(to: CGPoint(x: viewBox.minX, y: y)); g.addLine(to: CGPoint(x: viewBox.maxX, y: y)); y += 56 }  // ~20° lat
                ctx.stroke(g.applying(t), with: .color(grid), lineWidth: 0.5)
            }

            // Biome land tint: a vertical gradient keyed to latitude. Path coords are in
            // Web Mercator, so convert each biome latitude to its Mercator y and place the
            // stops accordingly; the gradient tracks the current zoom/pan via the transform.
            func mercY(_ lat: Double) -> Double {
                let l = min(max(lat, -83), 83) * Double.pi / 180
                return (Double.pi - log(tan(Double.pi / 4 + l / 2))) * (1000 / (2 * Double.pi))
            }
            let mY0 = mercY(90), mY1 = mercY(-90)
            let stops = MapPalette.biome
                .map { Gradient.Stop(color: Color(hex: $0.hex), location: (mercY($0.lat) - mY0) / (mY1 - mY0)) }
                .sorted { $0.location < $1.location }
            let landShading = GraphicsContext.Shading.linearGradient(
                Gradient(stops: stops),
                startPoint: CGPoint(x: 0, y: mY0 * scale + ty),
                endPoint: CGPoint(x: 0, y: mY1 * scale + ty))
            for region in regions where fills[region.id] == nil {
                let p = region.path.applying(t)
                ctx.fill(p, with: landShading)
                ctx.stroke(p, with: .color(border), lineWidth: 0.4)
            }

            // Filled/highlighted regions (single gold target, or target/tapped in locate).
            for region in regions {
                guard let color = fills[region.id] else { continue }
                let p = region.path.applying(t)
                ctx.fill(p, with: .color(color))
                ctx.stroke(p, with: .color(highlightStroke), lineWidth: 1)
            }

            // Lakes as water, over land AND fills — carves the lake area out of states
            // whose polygons wrongly include it (fixes Michigan's blob).
            for lake in lakes {
                let p = lake.applying(t)
                ctx.fill(p, with: .color(MapPalette.sea))
                ctx.stroke(p, with: .color(MapPalette.sea.opacity(0.9)), lineWidth: 0.3)
            }

            // Rivers over the water/land as a context clue.
            for river in rivers {
                ctx.stroke(river.path.applying(t), with: .color(MapPalette.river), lineWidth: 1.4)
            }

            // A locator ring so a tiny highlighted region is still findable (identify mode).
            guard let ringId, let target = regions.first(where: { $0.id == ringId }) else { return }
            let b = target.path.applying(t).boundingRect
            if min(b.width, b.height) < 30 {
                let c = CGPoint(x: b.midX, y: b.midY)
                let rad = max(b.width, b.height) / 2 + 13
                let ring = Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2))
                ctx.stroke(ring, with: .color(highlightStroke), lineWidth: 1.5)
            }
        }
    }
}

// A tap-to-locate card: the whole map, no highlight — the player taps the named region.
// After answering, the correct region is colored green and a wrong tap red. The enclosing
// mode view owns `revealed`/`tappedId` and grades inside `onTap`.
struct MapTapCard: View {
    let kind: GeoMapKind
    let targetId: String
    let revealed: Bool
    let tappedId: String?
    var aspect: CGFloat = 1.6
    var fillFrame: Bool = false
    let onTap: (String?) -> Void

    private var fills: [String: Color] {
        guard revealed else { return [:] }
        var f: [String: Color] = [targetId: Theme.success]          // correct location
        if let tappedId, tappedId != targetId { f[tappedId] = Theme.danger }  // your wrong tap
        return f
    }

    var body: some View {
        GeoMapDiagram(kind: kind, focus: false, highlights: fills,
                      interactive: !revealed, onTapRegion: onTap, locateTargetId: targetId,
                      aspect: aspect, fillFrame: fillFrame)
            .frame(maxWidth: .infinity, maxHeight: fillFrame ? .infinity : nil)
    }
}

private extension CGFloat {
    func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { Swift.min(Swift.max(self, lo), hi) }
}
