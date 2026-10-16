import SwiftUI

// MARK: - Map travel — the authored road + the traveling character
//
// The home map is "the world" and the child is a traveler who walks its road between landmark
// worlds. The road and each landmark's stop are AUTHORED data (traced from a hand-drawn overlay),
// not derived by geometry — each stop is a road vertex, so arrival is exact and never projected.
// When the map art changes, re-trace `roadXY` + each landmark's `stop` (in HomeView); nothing here
// moves.
//
// Two rules make the motion smooth (learned the hard way):
//   1. The chip follows the curved road via `AlongRoad`, an *animatable* GeometryEffect — so it
//      traces the polyline as `t` animates instead of sliding in a straight line to the target.
//   2. The camera is driven from the SAME `withAnimation` that drives `t` (one timeline), so the
//      chip never jitters against an independently-timed scroll.

/// A road as normalized (0…1) points over the map image, ordered along the journey. Positions are
/// parameterized by arc-length fraction `t` (0 = first point, 1 = last) for an even walking pace.
struct RoadPath {
    let points: [CGPoint]
    let aspect: CGFloat            // image height / width, so distances respect the tall canvas
    private let cum: [CGFloat]     // cumulative arc-length fraction at each point (0…1)

    init(_ pts: [CGPoint], aspect: CGFloat) {
        let safe = pts.isEmpty ? [CGPoint(x: 0.5, y: 0.5)] : pts
        self.points = safe
        self.aspect = aspect
        var lens: [CGFloat] = [0]
        var total: CGFloat = 0
        for i in 1..<safe.count {
            let dx = safe[i].x - safe[i - 1].x
            let dy = (safe[i].y - safe[i - 1].y) * aspect
            total += (dx * dx + dy * dy).squareRoot()
            lens.append(total)
        }
        cum = total > 0 ? lens.map { $0 / total } : lens.map { _ in 0 }
    }

    /// The normalized point at arc-length fraction `t`.
    func point(at t: CGFloat) -> CGPoint {
        guard points.count > 1 else { return points[0] }
        let tt = min(1, max(0, t))
        for i in 1..<cum.count where tt <= cum[i] {
            let span = cum[i] - cum[i - 1]
            let f = span > 0 ? (tt - cum[i - 1]) / span : 0
            return CGPoint(x: points[i - 1].x + (points[i].x - points[i - 1].x) * f,
                           y: points[i - 1].y + (points[i].y - points[i - 1].y) * f)
        }
        return points.last!
    }
    /// The arc-length fraction of vertex `i` — so a stop authored as a vertex is hit exactly.
    func t(atVertex i: Int) -> CGFloat { cum[min(max(i, 0), cum.count - 1)] }
}

/// Places a view's center on the road at arc-length `t`, scaled to the map, plus a small stand
/// offset. `animatableData = t` is the crux: SwiftUI re-evaluates this at every interpolated `t`
/// during a `withAnimation`, so the chip traces the *curve* of the road rather than cutting a
/// straight line to the destination.
struct AlongRoad: GeometryEffect {
    var t: CGFloat
    let road: RoadPath
    let w: CGFloat, h: CGFloat
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var animatableData: CGFloat {
        get { t }
        set { t = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let p = road.point(at: t)
        let tx = p.x * w + dx - size.width / 2
        let ty = p.y * h + dy - size.height / 2
        return ProjectionTransform(CGAffineTransform(translationX: tx, y: ty))
    }
}

/// A drop shadow drawn as a radial gradient (no blur filter), so the render server composites it as
/// an ordinary layer instead of re-blurring it offscreen every frame while the map animates.
struct SoftShadow: View {
    var opacity: Double
    var body: some View {
        GeometryReader { g in
            let r = max(g.size.width, g.size.height) / 2
            Circle()
                .fill(RadialGradient(colors: [.black.opacity(opacity), .black.opacity(opacity * 0.45), .clear],
                                     center: .center, startRadius: 0, endRadius: r))
                .frame(width: 2 * r, height: 2 * r)
                .scaleEffect(x: g.size.width / (2 * r), y: g.size.height / (2 * r))
                .frame(width: g.size.width, height: g.size.height)
        }
        .allowsHitTesting(false)
    }
}

/// The child: a crimson standard (signum) planted on the road, one gilt honour disc per rank above
/// Tiro (Consul's is wreathed) — the same discs as the bar's rank pips. Baked art (Standard0…3); it
/// sways about its foot while walking. Never mirrored (the "L" on the cloth would read backwards).
struct Traveler: View {
    var walking: Bool
    var rank: Int
    @State private var sway = false

    static let size = CGSize(width: 42 * 0.92, height: 62 * 0.92)
    static let foot: CGFloat = 58.0 / 62.0              // road-contact point, as a fraction of the height
    /// AlongRoad offset that puts the foot (not the center) on the road point.
    static let centerToFoot: CGFloat = -(foot - 0.5) * size.height

    var body: some View {
        Image("Standard\(min(max(rank, 0), 3))").resizable()
            .frame(width: Self.size.width, height: Self.size.height)
            .rotationEffect(.degrees(walking ? (sway ? 4 : -4) : 0), anchor: UnitPoint(x: 0.5, y: Self.foot))
            .offset(y: walking && sway ? -1.5 : 0)
            .onChange(of: walking) { sway = $0 }
            .animation(walking ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true)
                               : .easeOut(duration: 0.15), value: sway)
            .animation(.easeOut(duration: 0.15), value: walking)
            .allowsHitTesting(false)
    }
}
