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
