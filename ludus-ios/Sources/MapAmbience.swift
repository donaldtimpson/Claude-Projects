import SwiftUI
import UIKit

// MARK: - Map ambience — the painting, gently alive, at ~zero CPU
//
// Every effect moves the art's OWN pixels and is played by Core Animation (the render server drives
// it; the app does no per-frame work — the old TimelineView/Metal layers over the whole map idled at
// ~75% CPU). All assets + the constants below come from tools/ambient_build.py:
//   • smoke, waterfall, river, spring — cinemagraph loops (the art's own pixels in motion), played as
//     flipbooks by stepping `contentsRect` over a sprite sheet
//   • lamp, lava       — a brightened copy of the lit pixels (+ a light halo), faded in and out
//   • ships            — cutouts rocked about their waterline (painted out of `ProvinceMap`)
// Everything is laid out in ProvinceMap pixels (724 wide) scaled to the rendered map width.

private struct Flipbook {
    let image: String
    let frames: Int, cols: Int
    let cellW: CGFloat, cellH: CGFloat, gutter: CGFloat, frameW: CGFloat, frameH: CGFloat
    let mapX: CGFloat, mapY: CGFloat
    let loop: CFTimeInterval
}
private struct Glow {
    let image: String
    let mapX: CGFloat, mapY: CGFloat, w: CGFloat, h: CGFloat
    let opacity: [Float], keyTimes: [NSNumber], period: CFTimeInterval
}
private struct Ship {
    let mapX: CGFloat, mapY: CGFloat, w: CGFloat, h: CGFloat
    let ax: CGFloat, ay: CGFloat              // waterline pivot, unit coords within the sprite
    let degrees: Double, period: CFTimeInterval, phase: Double
    var bob: CGFloat = 1.5                    // heave, map px (a quarter-cycle off the roll)
}

private let flipbooks: [Flipbook] = [
    .init(image: "SmokeSheet", frames: 90, cols: 10, cellW: 134, cellH: 105, gutter: 2,
          frameW: 130, frameH: 101, mapX: 466, mapY: 612, loop: 6),
    .init(image: "WaterfallSheet", frames: 60, cols: 10, cellW: 119, cellH: 109, gutter: 2,
          frameW: 115, frameH: 105, mapX: 310, mapY: 1616, loop: 4),
    .init(image: "RiverSheet", frames: 60, cols: 10, cellW: 116, cellH: 146, gutter: 2,
          frameW: 112, frameH: 142, mapX: 322, mapY: 1862, loop: 4),
    .init(image: "SpringSheet", frames: 60, cols: 10, cellW: 89, cellH: 44, gutter: 2,
          frameW: 85, frameH: 40, mapX: 354, mapY: 2062, loop: 4),
]
private let glows: [Glow] = [
    // Lighthouse: a beacon — quick bright flash, slow fade, dark pause.
    .init(image: "LampGlow", mapX: 55, mapY: 1246, w: 263, h: 229,
          opacity: [0.1, 0.1, 1, 0.35, 0.1], keyTimes: [0, 0.45, 0.55, 0.75, 1], period: 4),
    // Lava: an even pulse — on and off for equal time.
    .init(image: "LavaGlow", mapX: 446, mapY: 675, w: 75, h: 92,
          opacity: [0, 1, 0], keyTimes: [0, 0.5, 1], period: 3.2),
]
// Top→bottom. The two docked in the market harbour (3, 5) rock less.
private let ships: [Ship] = [
    .init(mapX: 656, mapY: 551,  w: 27, h: 41, ax: 0.491, ay: 0.854, degrees: 5.0, period: 2.8, phase: 0.10),
    .init(mapX: 644, mapY: 673,  w: 34, h: 48, ax: 0.515, ay: 0.896, degrees: 5.0, period: 3.2, phase: 0.55),
    .init(mapX: 670, mapY: 926,  w: 29, h: 44, ax: 0.510, ay: 0.841, degrees: 4.5, period: 2.6, phase: 0.30),
    .init(mapX: 621, mapY: 1363, w: 70, h: 66, ax: 0.385, ay: 0.833, degrees: 3.0, period: 3.6, phase: 0.80, bob: 1),
    .init(mapX: 51,  mapY: 1410, w: 37, h: 63, ax: 0.478, ay: 0.778, degrees: 5.0, period: 3.0, phase: 0.45),
    .init(mapX: 513, mapY: 1421, w: 57, h: 51, ax: 0.468, ay: 0.824, degrees: 3.0, period: 3.4, phase: 0.15, bob: 1),
    .init(mapX: 648, mapY: 1531, w: 37, h: 50, ax: 0.473, ay: 0.820, degrees: 5.0, period: 2.7, phase: 0.65),
    .init(mapX: 55,  mapY: 1822, w: 45, h: 66, ax: 0.493, ay: 0.879, degrees: 4.5, period: 3.1, phase: 0.95),
    .init(mapX: 620, mapY: 1972, w: 35, h: 63, ax: 0.476, ay: 0.825, degrees: 5.0, period: 2.9, phase: 0.35),
]

/// Overlay sized to the whole rendered map (`w` × `h`), above the art and below the seals.
struct MapAmbience: View {
    let w: CGFloat, h: CGFloat
    var body: some View {
        AmbienceLayers().frame(width: w, height: h).allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct AmbienceLayers: UIViewRepresentable {
    func makeUIView(context: Context) -> AmbienceView { AmbienceView() }
    func updateUIView(_ view: AmbienceView, context: Context) {}
}

private final class AmbienceView: UIView {
    private let flipLayers = flipbooks.map { f -> CALayer in
        let l = CALayer(); l.contents = UIImage(named: f.image)?.cgImage; l.contentsGravity = .resize
        l.contentsRect = cellRect(f, 0); return l
    }
    private let glowLayers = glows.map { g -> CALayer in
        let l = CALayer(); l.contents = UIImage(named: g.image)?.cgImage; l.opacity = 0; return l
    }
    private let shipLayers = ships.indices.map { i -> CALayer in
        let l = CALayer(); l.contents = UIImage(named: "Ship\(i)")?.cgImage
        l.anchorPoint = CGPoint(x: ships[i].ax, y: ships[i].ay); return l
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        (flipLayers + glowLayers + shipLayers).forEach(layer.addSublayer)   // ships above the glows
    }
    required init?(coder: NSCoder) { fatalError() }

    /// Unit-space rect of cell `i` in a flipbook sheet, excluding its transparent gutter.
    private static func cellRect(_ f: Flipbook, _ i: Int) -> CGRect {
        let rows = (f.frames + f.cols - 1) / f.cols
        let sw = f.cellW * CGFloat(f.cols), sh = f.cellH * CGFloat(rows)
        let r = i / f.cols, c = i % f.cols
        return CGRect(x: (CGFloat(c) * f.cellW + f.gutter) / sw, y: (CGFloat(r) * f.cellH + f.gutter) / sh,
                      width: f.frameW / sw, height: f.frameH / sh)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let k = bounds.width / 724
        CATransaction.begin(); CATransaction.setDisableActions(true)
        for (l, f) in zip(flipLayers, flipbooks) {
            l.frame = CGRect(x: f.mapX * k, y: f.mapY * k, width: f.frameW * k, height: f.frameH * k)
        }
        for (l, g) in zip(glowLayers, glows) {
            l.frame = CGRect(x: g.mapX * k, y: g.mapY * k, width: g.w * k, height: g.h * k)
        }
        for (l, s) in zip(shipLayers, ships) {
            l.bounds = CGRect(x: 0, y: 0, width: s.w * k, height: s.h * k)
            l.position = CGPoint(x: (s.mapX + s.ax * s.w) * k, y: (s.mapY + s.ay * s.h) * k)
        }
        CATransaction.commit()
        if needsStart, window != nil, k > 0 { needsStart = false; startAnimations(k: k) }
    }

    private var needsStart = false

    // Animate only while on screen (UIKit detaches the home view while a game is pushed). Under
    // Reduce Motion the painting stays still: overlays hidden, ships shown but not rocking. The
    // animations start on the next layout pass, once the map scale (for the ships' bob) is known.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        (flipLayers + glowLayers + shipLayers).forEach { $0.removeAllAnimations() }
        let still = UIAccessibility.isReduceMotionEnabled
        (flipLayers + glowLayers).forEach { $0.isHidden = still }
        needsStart = window != nil && !still
        setNeedsLayout()
    }

    private func startAnimations(k: CGFloat) {
        // One shared 15 fps clock: every animation starts at the same instant and every step lands
        // on the same 1/15 s grid, so the screen changes at most 15 times a second in total.
        // (Unaligned clocks made the effects' steps interleave into ~60 redraws/s — 8x the cost.)
        let t0 = layer.convertTime(CACurrentMediaTime(), from: nil)
        func start(_ a: CAAnimation, on l: CALayer, _ key: String) { a.beginTime = t0; l.add(forever(a), forKey: key) }

        for (l, f) in zip(flipLayers, flipbooks) {
            let a = CAKeyframeAnimation(keyPath: "contentsRect")
            a.values = (0..<f.frames).map { NSValue(cgRect: Self.cellRect(f, $0)) }
            a.calculationMode = .discrete
            a.duration = f.loop                       // frames / loop == 15 fps (ambient_build.py)
            start(a, on: l, "flipbook")
        }
        for (l, g) in zip(glowLayers, glows) {
            start(stepped("opacity", period: g.period) { t in
                Self.eased(g.opacity.map(Double.init), g.keyTimes.map(\.doubleValue), t)
            }, on: l, "glow")
        }
        for (l, s) in zip(shipLayers, ships) {
            // Roll about the waterline, plus a heave a quarter-cycle behind it (rises as it levels).
            let r = s.degrees * .pi / 180, b = Double(s.bob * k)
            let roll = stepped("transform.rotation.z", period: s.period) { t in -r * cos(2 * .pi * t) }
            let heave = stepped("transform.translation.y", period: s.period) { t in -b * sin(2 * .pi * t) }
            for a in [roll, heave] { a.timeOffset = (s.phase * a.duration * 15).rounded() / 15 }
            start(roll, on: l, "roll"); start(heave, on: l, "heave")
        }
    }

    /// Smooth motion sampled at 15 fps as a DISCRETE keyframe animation (duration snapped to whole
    /// 1/15 s steps) so it shares the flipbooks' clock; at these slow speeds 15 steps/s reads smooth.
    private func stepped(_ keyPath: String, period: CFTimeInterval, _ value: (Double) -> Double) -> CAKeyframeAnimation {
        let n = max(2, Int((period * 15).rounded()))
        let a = CAKeyframeAnimation(keyPath: keyPath)
        a.values = (0..<n).map { value(Double($0) / Double(n)) }
        a.calculationMode = .discrete
        a.duration = Double(n) / 15
        return a
    }

    /// Piecewise ease-in-out through `values` at `times` (0…1), evaluated at `t`.
    private static func eased(_ values: [Double], _ times: [Double], _ t: Double) -> Double {
        guard let i = times.lastIndex(where: { $0 <= t }), i < values.count - 1 else { return values.last ?? 0 }
        let u = (t - times[i]) / (times[i + 1] - times[i])
        let e = u * u * (3 - 2 * u)
        return values[i] + (values[i + 1] - values[i]) * e
    }

    private func forever(_ a: CAAnimation) -> CAAnimation {
        a.repeatCount = .infinity; a.isRemovedOnCompletion = false; return a
    }
}
