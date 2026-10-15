import SwiftUI

// MARK: - Ambient life over the painted province ("living painting")
//
// Motion is created by slicing real pieces out of the art and moving those cutouts, plus a few
// atmospheric layers — never by drawing cartoons on top. Everything lives in the MAP's coordinate
// space so it scrolls/clips with the art, and pauses while a game is open. iOS 16-safe.
//   • ships   — real painted cutouts rocking at the waterline over `ProvinceBase` (ships painted out)
//   • water   — shimmer + glints, clipped to a sea-only mask
//   • smoke   — soft column rising from the Vesuvius crater
//   • clouds  — a wispy cloud texture drifting across
// Re-extract ships / rebuild base via scratchpad/ships_extract.py when the art changes.

private func hash01(_ i: Int, _ s: Int) -> CGFloat {
    let x = sin(Double(i) * 12.9898 + Double(s) * 78.233) * 43758.5453
    return CGFloat(x - floor(x))
}
private func frac(_ x: CGFloat) -> CGFloat { x - floor(x) }

// Per-layer toggle for isolated validation: SIMCTL_CHILD_LUDUS_LAYERS=ships (etc). Unset = all on.
private func layerOn(_ name: String) -> Bool {
    guard let env = ProcessInfo.processInfo.environment["LUDUS_LAYERS"], !env.isEmpty else { return true }
    return env.split(separator: ",").contains(Substring(name))
}

struct AmbientMap: View {
    let w: CGFloat
    let h: CGFloat
    var paused: Bool = false

    var body: some View {
        ZStack {
            if layerOn("water")  { WaterRipple(w: w, h: h, paused: paused) }
            if layerOn("river")  { RiverRipple(w: w, h: h, paused: paused) }
            if layerOn("ships")  { RockingShips(w: w, h: h, paused: paused) }
            if layerOn("smoke")  { VolcanoSmoke(w: w, h: h, paused: paused) }
            if layerOn("clouds") { DriftingClouds(w: w, h: h, paused: paused) }
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }
}

// MARK: Ships — real painted cutouts, rocking gently at their waterlines.

private struct RockingShips: View {
    let w: CGFloat; let h: CGFloat; var paused: Bool
    private struct Ship { let img: String; let cx, cy, wf, hf, amp, speed, phase: CGFloat }
    private let ships: [Ship] = [
        .init(img: "Ship0", cx: 0.8122, cy: 0.1107, wf: 0.0345, hf: 0.0147, amp: 2.8, speed: 1.9, phase: 0.2),
        .init(img: "Ship1", cx: 0.9095, cy: 0.2935, wf: 0.0608, hf: 0.0276, amp: 4.0, speed: 1.8, phase: 1.1),
        .init(img: "Ship2", cx: 0.9116, cy: 0.3943, wf: 0.0566, hf: 0.0285, amp: 4.0, speed: 1.6, phase: 2.0),
        .init(img: "Ship3", cx: 0.8957, cy: 0.5741, wf: 0.0718, hf: 0.0281, amp: 3.6, speed: 1.7, phase: 3.0),
        .init(img: "Ship4", cx: 0.8923, cy: 0.7834, wf: 0.1008, hf: 0.0460, amp: 4.0, speed: 1.4, phase: 0.9),
        .init(img: "Ship5", cx: 0.8943, cy: 0.8587, wf: 0.0663, hf: 0.0253, amp: 3.6, speed: 1.7, phase: 2.2),
    ]
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                ForEach(ships.indices, id: \.self) { i in
                    let s = ships[i]
                    let rock = sin(CGFloat(t) * s.speed + s.phase) * s.amp
                    let bob = sin(CGFloat(t) * s.speed * 0.8 + s.phase * 1.5) * 1.25
                    Image(s.img).resizable().interpolation(.high)
                        .frame(width: s.wf * w, height: s.hf * h)
                        .rotationEffect(.degrees(Double(rock)), anchor: .bottom)
                        .position(x: s.cx * w, y: s.cy * h + bob)
                }
            }
            .frame(width: w, height: h, alignment: .topLeading)
        }
    }
}

// MARK: Water — a Metal ripple that displaces the REAL painted sea pixels (iOS 17+). The sea copy
// of the base is rippled by the shader, then masked to the sea so only the water moves.

private struct WaterRipple: View {
    let w: CGFloat; let h: CGFloat; var paused: Bool
    var body: some View {
        if #available(iOS 17.0, *) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { tl in
                let t = Float(tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000))
                Image("ProvinceBase").resizable().frame(width: w, height: h)
                    .distortionEffect(ShaderLibrary.waterRipple(.float(t)),
                                      maxSampleOffset: CGSize(width: 4, height: 4))
                    .mask(Image("SeaMask").resizable().frame(width: w, height: h))
            }
        }
    }
}

// MARK: River — the same ripple shader on the painted river, masked to RiverMask (gentler than the sea).

private struct RiverRipple: View {
    let w: CGFloat; let h: CGFloat; var paused: Bool
    var body: some View {
        if #available(iOS 17.0, *) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { tl in
                let t = Float(tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000))
                Image("ProvinceBase").resizable().frame(width: w, height: h)
                    .distortionEffect(ShaderLibrary.waterRipple(.float(t)),
                                      maxSampleOffset: CGSize(width: 2.5, height: 2.5))
                    .mask(Image("RiverMask").resizable().frame(width: w, height: h))
            }
        }
    }
}

// MARK: Smoke — a Metal billow that flows the REAL painted plume upward (iOS 17+), masked to the
// crater column so only the smoke moves.

private struct VolcanoSmoke: View {
    let w: CGFloat; let h: CGFloat; var paused: Bool
    var body: some View {
        if #available(iOS 17.0, *) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { tl in
                let t = Float(tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000))
                let anchorY = Float(0.3071 * h)   // crater y, in the layer's coordinate space
                Image("ProvinceBase").resizable().frame(width: w, height: h)
                    .distortionEffect(ShaderLibrary.smokeBillow(.float(t), .float(anchorY)),
                                      maxSampleOffset: CGSize(width: 14, height: 14))
                    .mask(Image("SmokeMask").resizable().frame(width: w, height: h))
            }
        }
    }
}

// MARK: Clouds — a wispy cloud texture drifting slowly across the whole map.

private struct DriftingClouds: View {
    let w: CGFloat; let h: CGFloat; var paused: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: paused)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, _ in
                guard let img = ctx.resolveSymbol(id: 0) else { return }
                // One full-height tile (matches the map aspect → no vertical seams); two copies
                // side by side scroll horizontally for a seamless drift.
                let off = frac(CGFloat(t) * 0.03) * w
                ctx.draw(img, in: CGRect(x: -off, y: 0, width: w, height: h))
                ctx.draw(img, in: CGRect(x: -off + w, y: 0, width: w, height: h))
            } symbols: {
                Image("Clouds").resizable().tag(0)
            }
            .frame(width: w, height: h)
            .opacity(0.65)
        }
    }
}
