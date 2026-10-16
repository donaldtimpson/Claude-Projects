import SwiftUI

// MARK: - Market helpers — small juice shared by The Fig Stall and Porcus the Piggy Bank

#if DEBUG
/// Self-test output: printed and appended to Documents/market_selftest.txt (readable from the host).
func marketLog(_ s: String) {
    print(s)
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("market_selftest.txt")
    let old = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    try? (old + s + "\n").write(to: url, atomically: true, encoding: .utf8)
}
#endif

/// A horizontal wobble, three shakes per whole unit of `shakes` (animate it upward on a miss).
struct MarketShake: GeometryEffect {
    var amount: CGFloat = 9
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(shakes * .pi * 6), y: 0))
    }
}

/// A one-shot ring of emoji sparks. Bump `trigger` to fire it again (0 = never fired).
struct MarketSparks: View {
    let trigger: Int
    var glyphs = ["✨", "⭐️", "🪙"]
    var radius: CGFloat = 90
    var body: some View {
        ZStack {
            if trigger > 0 { SparkBurst(glyphs: glyphs, radius: radius).id(trigger) }
        }
        .allowsHitTesting(false)
    }
}

private struct SparkBurst: View {
    let glyphs: [String]
    let radius: CGFloat
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) / 8 * 2 * .pi + 0.3
                Text(glyphs[i % glyphs.count]).font(.system(size: 24))
                    .offset(x: go ? cos(a) * radius : 0, y: go ? sin(a) * radius : 0)
                    .scaleEffect(go ? 1.15 : 0.3)
                    .opacity(go ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { go = true } }
    }
}

/// A speech bubble with a little tail on its bottom-left (or right).
struct MarketBubble<Content: View>: View {
    var tailRight = false
    var fill: UInt = Lu.ink
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(Color(hex: fill))
                    .overlay(alignment: tailRight ? .bottomTrailing : .bottomLeading) {
                        BubbleTail().fill(Color(hex: fill)).frame(width: 18, height: 14)
                            .scaleEffect(x: tailRight ? -1 : 1)
                            .offset(x: tailRight ? -22 : 22, y: 12)
                    }
            )
    }
}

private struct BubbleTail: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.15, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A big, chunky answer button for the Market games (≥ 64 pt tall). `state`: nil while open,
/// then .right (green) / .wrong (terracotta) / .faded once the answer is revealed.
enum MarketChoiceState { case open, right, wrong, faded }

struct MarketChoiceButton: View {
    let text: String
    var state: MarketChoiceState = .open
    var height: CGFloat = 72
    let action: () -> Void
    private var fill: UInt {
        switch state {
        case .open, .faded: return Lu.panel2
        case .right: return Lu.mint
        case .wrong: return Lu.coral
        }
    }
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(luFont(text.count <= 6 ? 30 : 22))
                .foregroundStyle(Color(hex: state == .right || state == .wrong ? Lu.inkDark : Lu.ink))
                .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: height)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: fill))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: state == .open ? Lu.goldLine : Lu.line), lineWidth: 2)))
                .opacity(state == .faded ? 0.4 : 1)
                .scaleEffect(state == .right ? 1.04 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.55), value: state)
        }
        .buttonStyle(.plain)
        .disabled(state != .open)
    }
}
