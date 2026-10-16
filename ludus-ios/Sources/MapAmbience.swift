import SwiftUI
import UIKit

// MARK: - Map ambience — the painting, gently alive, at ~zero CPU
//
// Every effect moves the art's OWN pixels and is played by Core Animation (the render server drives
// it; the app does no per-frame work — the old TimelineView/Metal layers over the whole map idled at
// ~75% CPU). All assets + the constants below come from tools/ambient_build.py:
//   • smoke, waterfall, river, spring, surf — cinemagraph loops (the art's own pixels in motion), played as
//     flipbooks by stepping `contentsRect` over a sprite sheet
//   • lamp, lava       — a brightened copy of the lit pixels (+ a light halo), faded in and out
//   • sea glitter      — groups of the painting's own light flecks, twinkling in turn
//   • sheens           — sunlight sweeping across the landmarks' marble now and then
//   • clouds           — the painting's clouds drifting right, behind the peaks, wrapping at the tear
//   • ships            — cutouts rocked about their waterline (painted out of `ProvinceMap`);
//                        two of them sail off the map and back (`voyages`)
// Everything is laid out in ProvinceMap pixels (724 wide) scaled to the rendered map width.

struct Flipbook {
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

private let flipbooks: [Flipbook] = Flipbook.surf + [
    // Volcano: painted-smoke puffs billowing out of the crater; loop = 3 lava periods (puffs swell after each glow).
    .init(image: "SmokeSheet", frames: 144, cols: 10, cellW: 236, cellH: 156, gutter: 2,
          frameW: 232, frameH: 152, mapX: 423, mapY: 581, loop: 9.6),
    .init(image: "WaterfallSheet", frames: 60, cols: 10, cellW: 119, cellH: 109, gutter: 2,
          frameW: 115, frameH: 105, mapX: 310, mapY: 1616, loop: 4),
    .init(image: "RiverSheet", frames: 60, cols: 10, cellW: 116, cellH: 146, gutter: 2,
          frameW: 112, frameH: 142, mapX: 322, mapY: 1862, loop: 4),
    .init(image: "SpringSheet", frames: 60, cols: 10, cellW: 89, cellH: 49, gutter: 2,
          frameW: 85, frameH: 45, mapX: 354, mapY: 2057, loop: 4),
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

/// Sea glitter: the painting's own light flecks, split into groups (tools/ambient_build.py); each
/// group twinkles twice per 16 s loop at its own moments (slow fades), so some part of the sea always catches light.
private struct GlintRegion { let name: String; let mapX: CGFloat, mapY: CGFloat, w: CGFloat, h: CGFloat }
private let glintRegions: [GlintRegion] = [
    .init(name: "GlintEast", mapX: 470, mapY: 520, w: 250, h: 1590),
    .init(name: "GlintWest", mapX: 5, mapY: 1240, w: 265, h: 720),
]
private let glintGroups = 6, glintLoop: CFTimeInterval = 16

/// Sunlight now and then sweeping across a landmark's marble and gold: a static highlight image of
/// its own bright stone (tools/ambient_build.py), revealed through a soft gradient band that slides
/// across it once per period. Staggered so only one landmark gleams at a time.
private struct Sheen { let image: String; let mapX: CGFloat, mapY: CGFloat, w: CGFloat, h: CGFloat; let offset: Double }
private let sheens: [Sheen] = [
    .init(image: "SheenLibrary",   mapX: 288, mapY: 318,  w: 240, h: 114, offset: 4),
    .init(image: "SheenColosseum", mapX: 98,  mapY: 866,  w: 210, h: 128, offset: 14),
    .init(image: "SheenTemple",    mapX: 292, mapY: 1022, w: 171, h: 90,  offset: 24),
]
private let sheenPeriod: CFTimeInterval = 30, sheenSweep: CFTimeInterval = 2.8

/// One of the painting's clouds drifting right (tools/ambient_build.py → MapAmbienceClouds.swift). It
/// travels from just off the left of `cloudClip` to just off its right and wraps, inside a clip of the
/// painted sky above the skyline — so it passes behind the peaks and disappears behind the tear.
/// The painted clouds stay put in the map; this drifting layer passes over them at this opacity.
private let cloudOpacity: Float = 0.6

struct CloudDrift { let image: String; let mapX: CGFloat, mapY: CGFloat, w: CGFloat, h: CGFloat; let period: Double, start: Double, flip: Bool }

/// A ship that sails off the map and back, bow-first. Points are its waterline pivot in map px. It
/// rests at home facing as painted (+1, bow down-left); a mirrored leg (-1) means it first comes about
/// (narrows to 45% width, mirrors at the narrowest instant, widens — see `turnFacing`) or comes back about after returning. The direction flip
/// between legs happens off-map, unseen. It's drawn inside a clip of the painted area (`clip`), so it
/// disappears behind the torn edge and never draws on the parchment (tools/ambient_build.py checks
/// every visible hull pixel along both legs is over open sea).
private struct Voyage {
    let ship: Int
    let clip: String, clipX: CGFloat, clipY: CGFloat, clipW: CGFloat, clipH: CGFloat
    let out: CGPoint, back: CGPoint                 // off-map points it sails to / returns from
    let outFacing: CGFloat, backFacing: CGFloat
    let rest: Double, sailOut: Double, hidden: Double, sailBack: Double, after: Double, offset: Double
    static let turn = 1.6
}
private let voyages: [Voyage] = [
    // Right-hand sea: swings round, sails out to the east, slips back in from higher up.
    .init(ship: 2, clip: "SailClipRight", clipX: 590, clipY: 860, clipW: 134, clipH: 220,
          out: CGPoint(x: 742, y: 1003), back: CGPoint(x: 742, y: 925), outFacing: -1, backFacing: 1,
          rest: 8, sailOut: 10, hidden: 3, sailBack: 10, after: 4, offset: 0),
    // Lighthouse bay: sails out to the west as painted, returns from higher up and swings back round.
    .init(ship: 4, clip: "SailClipLeft", clipX: 0, clipY: 1360, clipW: 150, clipH: 200,
          out: CGPoint(x: -28, y: 1500), back: CGPoint(x: -28, y: 1420), outFacing: 1, backFacing: -1,
          rest: 12, sailOut: 11, hidden: 3, sailBack: 11, after: 6, offset: 20),
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
    private let glintLayers = glintRegions.flatMap { r in (0..<glintGroups).map { g -> CALayer in
        let l = CALayer(); l.contents = UIImage(named: "\(r.name)\(g)")?.cgImage; l.opacity = 0; return l
    } }
    private let sheenLayers = sheens.map { s -> CALayer in
        let l = CALayer(); l.contents = UIImage(named: s.image)?.cgImage
        let band = CAGradientLayer()                                  // soft diagonal band of light
        band.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0).cgColor]
        band.startPoint = CGPoint(x: 0, y: 0.2); band.endPoint = CGPoint(x: 1, y: 0.8)
        l.mask = band; return l
    }
    private let cloudClipLayer: CALayer = {
        let c = CALayer(), m = CALayer()
        m.contents = UIImage(named: "CloudClip")?.cgImage; m.contentsGravity = .resize
        c.mask = m
        c.opacity = cloudOpacity                     // drifting layer faded over the painted clouds
        return c
    }()
    private let cloudLayers = cloudDrifts.map { d -> CALayer in
        let l = CALayer(); l.contents = UIImage(named: d.image)?.cgImage
        if d.flip { l.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1)) }
        return l
    }
    private let clipLayers = voyages.map { v -> CALayer in
        let c = CALayer(), m = CALayer()
        m.contents = UIImage(named: v.clip)?.cgImage; m.contentsGravity = .resize
        c.mask = m; return c
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        cloudLayers.forEach(cloudClipLayer.addSublayer)
        layer.addSublayer(cloudClipLayer)                                  // sky: beneath everything else
        (flipLayers + glowLayers + glintLayers + sheenLayers).forEach(layer.addSublayer)
        for (i, l) in shipLayers.enumerated() where !voyages.contains(where: { $0.ship == i }) {
            layer.addSublayer(l)                                            // ships above the glows
        }
        for (c, v) in zip(clipLayers, voyages) { c.addSublayer(shipLayers[v.ship]); layer.addSublayer(c) }
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
        cloudClipLayer.frame = CGRect(x: cloudClip.minX * k, y: cloudClip.minY * k, width: cloudClip.width * k, height: cloudClip.height * k)
        cloudClipLayer.mask?.frame = cloudClipLayer.bounds
        for (l, d) in zip(cloudLayers, cloudDrifts) {
            l.bounds = CGRect(x: 0, y: 0, width: d.w * k, height: d.h * k)
            l.position = CGPoint(x: (d.mapX - cloudClip.minX + d.w / 2) * k, y: (d.mapY - cloudClip.minY + d.h / 2) * k)
        }
        for (l, s) in zip(sheenLayers, sheens) {
            l.frame = CGRect(x: s.mapX * k, y: s.mapY * k, width: s.w * k, height: s.h * k)
            l.mask?.bounds = CGRect(x: 0, y: 0, width: l.bounds.width * 0.55, height: l.bounds.height)
            l.mask?.position = CGPoint(x: -l.bounds.width * 0.3, y: l.bounds.height / 2)   // parked off the left
        }
        for (i, l) in glintLayers.enumerated() {
            let r = glintRegions[i / glintGroups]
            l.frame = CGRect(x: r.mapX * k, y: r.mapY * k, width: r.w * k, height: r.h * k)
        }
        for (l, s) in zip(shipLayers, ships) {
            l.bounds = CGRect(x: 0, y: 0, width: s.w * k, height: s.h * k)
            l.position = CGPoint(x: (s.mapX + s.ax * s.w) * k, y: (s.mapY + s.ay * s.h) * k)
        }
        for (c, v) in zip(clipLayers, voyages) {                 // sailing ships live in clip space
            c.frame = CGRect(x: v.clipX * k, y: v.clipY * k, width: v.clipW * k, height: v.clipH * k)
            c.mask?.frame = c.bounds
            let l = shipLayers[v.ship]
            l.position = CGPoint(x: l.position.x - v.clipX * k, y: l.position.y - v.clipY * k)
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
        (flipLayers + glowLayers + glintLayers + shipLayers + cloudLayers).forEach { $0.removeAllAnimations() }
        sheenLayers.forEach { $0.mask?.removeAllAnimations() }
        let still = UIAccessibility.isReduceMotionEnabled
        (flipLayers + glowLayers + glintLayers + sheenLayers).forEach { $0.isHidden = still }
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
        for (l, d) in zip(cloudLayers, cloudDrifts) {
            // Linear drift across the clip plus one cloud-width either side, wrapping off-map.
            let from = Double(-d.w / 2), to = Double(cloudClip.width + d.w / 2)
            let a = stepped("position.x", period: d.period) { t in Double(k) * (from + (to - from) * (t + d.start).truncatingRemainder(dividingBy: 1)) }
            start(a, on: l, "drift")
        }
        for (l, s) in zip(sheenLayers, sheens) {
            // The band rests off the left edge, then sweeps across (eased) once per period.
            guard let band = l.mask else { continue }
            let W = Double(l.bounds.width), from = -W * 0.3, to = W * 1.3
            let a = stepped("position.x", period: sheenPeriod) { t in
                let u = (t * sheenPeriod - s.offset) / sheenSweep
                guard u > 0, u < 1 else { return from }
                return from + (to - from) * u * u * (3 - 2 * u)
            }
            start(a, on: band, "sweep")
        }
        for (i, l) in glintLayers.enumerated() {
            // Two quick twinkles per loop; groups (and the two seas) staggered so it never pulses as one.
            let g = i % glintGroups, region = i / glintGroups
            let centers = [0.0, 0.5].map { ($0 + (Double(g) + 0.37 * Double(region)) / Double(glintGroups)).truncatingRemainder(dividingBy: 1) }
            start(stepped("opacity", period: glintLoop) { t in
                centers.map { c -> Double in let d = min(abs(t - c), 1 - abs(t - c)); return exp(-pow(d / 0.06, 2)) }.max() ?? 0
            }, on: l, "twinkle")
        }
        for (l, s) in zip(shipLayers, ships) {
            // Roll about the waterline, plus a heave a quarter-cycle behind it (rises as it levels).
            let r = s.degrees * .pi / 180, b = Double(s.bob * k)
            let roll = stepped("transform.rotation.z", period: s.period) { t in -r * cos(2 * .pi * t) }
            let heave = stepped("transform.translation.y", period: s.period) { t in -b * sin(2 * .pi * t) }
            for a in [roll, heave] { a.timeOffset = (s.phase * a.duration * 15).rounded() / 15 }
            start(roll, on: l, "roll"); start(heave, on: l, "heave")
        }
        for v in voyages {
            let s = ships[v.ship], l = shipLayers[v.ship]
            let home = CGPoint(x: s.mapX + s.ax * s.w, y: s.mapY + s.ay * s.h)
            let turnOut = v.outFacing < 0 ? Voyage.turn : 0, turnBack = v.backFacing < 0 ? Voyage.turn : 0
            let marks = [v.rest, turnOut, v.sailOut, v.hidden, v.sailBack, turnBack, v.after]
            let T = marks.reduce(0, +), n = Int((T * 15).rounded())
            func ease(_ u: Double) -> CGFloat { CGFloat(u * u * (3 - 2 * u)) }
            func lerp(_ a: CGPoint, _ b: CGPoint, _ u: CGFloat) -> CGPoint { CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u) }
            // (map-px position, facing) at time t along: rest, turn, out, hidden, back, turn, rest
            func at(_ t: Double) -> (CGPoint, CGFloat) {
                var t = t
                if t < v.rest { return (home, 1) }; t -= v.rest
                // Turning: the hull narrows (never below `minWidth`, so it's never paper-thin), swaps to
                // its mirror image at the narrowest instant, and widens again — while it glides a few px
                // along its new course, the way a ship comes about in an arc.
                let lead: CGFloat = 0.03                                     // fraction of the leg spent in the turn arc
                if t < turnOut {
                    let u = t / turnOut
                    return (lerp(home, v.out, lead * CGFloat(u * u)), Self.turnFacing(from: 1, u))
                }; t -= turnOut
                let start = turnOut > 0 ? lerp(home, v.out, lead) : home
                if t < v.sailOut { return (lerp(start, v.out, ease(t / v.sailOut)), v.outFacing) }; t -= v.sailOut
                if t < v.hidden { return (v.back, v.backFacing) }; t -= v.hidden          // flips off-map
                let end = turnBack > 0 ? lerp(v.back, home, 1 - lead) : home
                if t < v.sailBack { return (lerp(v.back, end, ease(t / v.sailBack)), v.backFacing) }; t -= v.sailBack
                if t < turnBack {
                    let u = t / turnBack
                    return (lerp(end, home, CGFloat(1 - (1 - u) * (1 - u))), Self.turnFacing(from: -1, u))
                }
                return (home, 1)
            }
            let samples = (0..<n).map { at(Double($0) / 15) }
            let pos = CAKeyframeAnimation(keyPath: "position")
            pos.values = samples.map { NSValue(cgPoint: CGPoint(x: ($0.0.x - v.clipX) * k, y: ($0.0.y - v.clipY) * k)) }
            let face = CAKeyframeAnimation(keyPath: "transform.scale.x")
            face.values = samples.map { Double($0.1) }
            for a in [pos, face] {
                a.calculationMode = .discrete; a.duration = Double(n) / 15
                a.timeOffset = (v.offset * 15).rounded() / 15
                start(a, on: l, a === pos ? "sail" : "face")
            }
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

    /// Horizontal scale through a turn (u: 0…1) starting from facing `from` (±1): the width eases down
    /// to `minWidth`, the sprite mirrors at the midpoint, and eases back out — a 2D stand-in for a yaw.
    private static func turnFacing(from: CGFloat, _ u: Double) -> CGFloat {
        let minWidth = 0.45, c = cos(.pi * u)
        return from * CGFloat((c >= 0 ? 1 : -1) * (minWidth + (1 - minWidth) * abs(c)))
    }

    private func forever(_ a: CAAnimation) -> CAAnimation {
        a.repeatCount = .infinity; a.isRemovedOnCompletion = false; return a
    }
}
