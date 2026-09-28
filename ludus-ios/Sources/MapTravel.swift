import SwiftUI

// MARK: - Map travel — the authored road + the traveling character
//
// The home map is "the world" and the child is a traveler who walks its road between landmark
// worlds. The road and each landmark's stop are AUTHORED data (traced from a hand-drawn overlay),
// not derived by geometry — so arrival is always exact and the path never mis-projects. When the
// map art changes, re-trace `roadPoints` + the per-landmark `arriveAt` (in HomeView); nothing here
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

/// The child, as a small gilt traveler-token that stands on the road and bobs while walking.
/// A deliberate placeholder — no frame-by-frame character art yet — but distinct from the
/// coloured landmark seals so it never reads as another destination.
struct Traveler: View {
    var walking: Bool
    var faceLeft: Bool = false
    @State private var bob = false

    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.3)).frame(width: 24, height: 7)
                .offset(y: 17).blur(radius: 1.5)
            Image(systemName: "figure.walk")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color(hex: 0x3a2708))
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(RadialGradient(
                        colors: [Color(hex: 0xf7d774), Color(hex: 0xc9922f)],
                        center: UnitPoint(x: 0.38, y: 0.32), startRadius: 1, endRadius: 22))
                        .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 2))
                        .overlay(Circle().stroke(Color(hex: 0x8a6a22), lineWidth: 0.5).padding(3))
                        .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 2))
                .scaleEffect(x: faceLeft ? -1 : 1)
                .offset(y: bob ? -3 : 0)
        }
        .onChange(of: walking) { bob = $0 }
        .animation(walking ? .easeInOut(duration: 0.26).repeatForever(autoreverses: true)
                           : .easeOut(duration: 0.15), value: bob)
    }
}
