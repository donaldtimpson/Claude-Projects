import SwiftUI

// MARK: - Vesuvius drag kit — shared by the Science world's drag-to-character games
//
// Dress Marcus and Zookeeper's Breakfast both have the child drag a chunky picture card onto a
// character (or a pen). The pieces: drop zones that report their frames, a generous hit test,
// a draggable card that springs home when refused (a tap counts too — easiest for a 7-year-old),
// and a few reaction bits: a speech bubble, a shake, a puff of emoji sparks.

/// Frames of the drop zones in the game's named coordinate space, keyed by zone id.
struct VesDropZones: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    /// Marks this view as drop zone `id` (frame measured in coordinate space `space`).
    func vesDropZone(_ id: Int, in space: String) -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: VesDropZones.self, value: [id: g.frame(in: .named(space))])
        })
    }
}

/// The zone a drop at `p` lands in. Generous: anywhere within `slop` pt of a zone counts, and
/// the nearest centre wins when padded zones overlap.
func vesZoneHit(_ p: CGPoint, zones: [Int: CGRect], slop: CGFloat = 30) -> Int? {
    func d(_ r: CGRect) -> CGFloat { hypot(r.midX - p.x, r.midY - p.y) }
    return zones.filter { $0.value.insetBy(dx: -slop, dy: -slop).contains(p) }
        .min { d($0.value) < d($1.value) }?.key
}

/// A card the child drags (finger location reported in `space`) or taps. `onRelease` returns
/// whether the drop was taken; if not, the card springs back home.
struct VesDragToken<Content: View>: View {
    let space: String
    var enabled = true
    let onRelease: (CGPoint) -> Bool
    var onTap: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    @State private var offset: CGSize = .zero
    @State private var lifted = false

    var body: some View {
        content()
            .scaleEffect(lifted ? 1.12 : 1)
            .offset(offset)
            .zIndex(lifted ? 1 : 0)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
                    .onChanged { v in
                        guard enabled else { return }
                        if !lifted {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { lifted = true }
                        }
                        offset = v.translation
                    }
                    .onEnded { v in
                        var taken = false
                        if enabled {
                            if hypot(v.translation.width, v.translation.height) < 10 { onTap?() }
                            else { taken = onRelease(v.location) }
                        }
                        if taken { offset = .zero; lifted = false }
                        else {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.55)) { offset = .zero; lifted = false }
                        }
                    }
            )
    }
}

/// A rounded speech bubble with a little tail (bottom-left).
struct VesBubble: View {
    let text: String
    var hex: UInt = Lu.ink
    var body: some View {
        Text(text)
            .font(luFont(19, .heavy))
            .foregroundStyle(Color(hex: Lu.inkDark))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16).fill(Color(hex: hex))
                    VesTail().fill(Color(hex: hex)).frame(width: 16, height: 12)
                        .rotationEffect(.degrees(180)).offset(x: 18, y: 10)
                }
            )
            .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 3)
    }
}

private struct VesTail: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
    }
}

/// Side-to-side shake: animate `beats` up by 1 to play one shake.
struct VesShake: GeometryEffect {
    var amount: CGFloat = 8
    var shakes: CGFloat = 3
    var beats: CGFloat
    var animatableData: CGFloat {
        get { beats }
        set { beats = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(beats * .pi * 2 * shakes), y: 0))
    }
}

/// A one-shot puff of emoji flying outward each time `trigger` changes.
struct VesBurst: View {
    let trigger: Int
    let emojis: [String]
    var radius: CGFloat = 95
    var size: CGFloat = 26

    private struct Bit: Identifiable {
        let id = UUID()
        let glyph: String
        let angle: Double
        var out = false
    }
    @State private var bits: [Bit] = []

    var body: some View {
        ZStack {
            ForEach(bits) { b in
                Text(b.glyph).font(.system(size: size))
                    .scaleEffect(b.out ? 1.15 : 0.3)
                    .offset(x: b.out ? cos(b.angle) * radius : 0, y: b.out ? sin(b.angle) * radius : 0)
                    .opacity(b.out ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _ in
            let n = 7
            bits = (0..<n).map { i in
                Bit(glyph: emojis.randomElement() ?? "✨",
                    angle: Double(i) / Double(n) * 2 * .pi + Double.random(in: -0.3...0.3))
            }
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.75)) { for i in bits.indices { bits[i].out = true } }
            }
        }
    }
}

/// A delayed step for a run: dropped if the run it belongs to has ended or restarted.
@MainActor
final class VesRunClock {
    private var token = 0
    func reset() { token += 1 }
    func after(_ s: Double, _ f: @escaping () -> Void) {
        let t = token
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.token == t else { return }
            f()
        }
    }
}

// MARK: - Scenery shared by the Vesuvius games (each game composes its own place from these)

/// Vesuvius on the horizon: a two-humped cone (Somma + the main cone), optional smoke plume.
struct VesMountain: View {
    var smoke = true
    var tint: UInt = 0x7a6a78
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                if smoke {
                    TimelineView(.animation(minimumInterval: 1.0 / 20)) { tl in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        ZStack {
                            ForEach(0..<5, id: \.self) { i in
                                let k = (t * 0.08 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
                                Circle().fill(Color.white.opacity(0.55 * (1 - k)))
                                    .frame(width: 26 + k * 70, height: 26 + k * 70)
                                    .position(x: W * 0.56 + CGFloat(k) * W * 0.18 + CGFloat(sin(t + Double(i))) * 4,
                                              y: H * 0.08 - CGFloat(k) * H * 0.7)
                            }
                        }
                    }
                }
                Path { p in
                    p.move(to: CGPoint(x: 0, y: H))
                    p.addCurve(to: CGPoint(x: W * 0.3, y: H * 0.28), control1: CGPoint(x: W * 0.14, y: H * 0.8), control2: CGPoint(x: W * 0.22, y: H * 0.34))
                    p.addLine(to: CGPoint(x: W * 0.38, y: H * 0.34))
                    p.addLine(to: CGPoint(x: W * 0.5, y: H * 0.06))
                    p.addLine(to: CGPoint(x: W * 0.62, y: H * 0.08))
                    p.addCurve(to: CGPoint(x: W, y: H), control1: CGPoint(x: W * 0.76, y: H * 0.4), control2: CGPoint(x: W * 0.86, y: H * 0.86))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color(hex: tint), luShade(tint, -30)], startPoint: .top, endPoint: .bottom))
            }
        }
    }
}

/// A Roman mosaic strip (alternating tesserae on a cream ground).
struct VesMosaicBand: View {
    var a: UInt = 0x2f5d8a
    var b: UInt = 0xb5523b
    var body: some View {
        GeometryReader { g in
            let n = Int(g.size.width / 18) + 1
            HStack(spacing: 2) {
                ForEach(0..<n, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: i % 2 == 0 ? a : b))
                        .frame(width: 16, height: g.size.height)
                }
            }
            .frame(width: g.size.width, alignment: .leading)
            .clipped()
            .background(Color(hex: 0xf3e7cc))
        }
    }
}

/// A fluted marble column with capital and base.
struct VesColumn: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xf2ead9)).frame(height: 12)
            ZStack {
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xd8cdb6), Color(hex: 0xfaf4e6), Color(hex: 0xcfc3aa)], startPoint: .leading, endPoint: .trailing))
                HStack(spacing: 5) { ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color(hex: 0xbdb096).opacity(0.6)).frame(width: 1.5) } }
            }
            .padding(.horizontal, 4)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xe6dcc7)).frame(height: 14)
        }
    }
}
