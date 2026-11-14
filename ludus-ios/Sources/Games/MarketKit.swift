import SwiftUI

// MARK: - Market helpers — small juice shared by The Fig Stall and Porcus the Piggy Bank

#if DEBUG
/// Runs `body` many times at every Gradus from I to XI (for the generators' self-tests).
@MainActor func marketSweep(_ m: ArcadeModel, _ body: () -> Void) {
    let keep = m.level
    for lv in 1...11 { m.level = lv; for _ in 0..<400 { body() } }
    m.level = keep
}

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

// MARK: - US money (the real-world target: American coins and bills)
//
// Real sizes, real colours: the dime is the SMALLEST coin (17.91 mm) though worth more than the
// penny (19.05) and nickel (21.21); the quarter is the biggest (24.26). Penny = copper, the rest
// silver; dimes and quarters have a ridged (reeded) edge, pennies and nickels are smooth.
// Portraits on the coins: Lincoln (penny, faces right), Jefferson (nickel), Roosevelt (dime) and
// Washington (quarter) all face left. The drawings are simple silhouettes, not likenesses.

enum USMoney: Int, CaseIterable, Hashable, Comparable {
    case penny = 1, nickel = 5, dime = 10, quarter = 25, one = 100, five = 500, ten = 1000, twenty = 2000
    static func < (a: USMoney, b: USMoney) -> Bool { a.rawValue < b.rawValue }
    var cents: Int { rawValue }
    var isBill: Bool { rawValue >= 100 }
    var name: String {
        switch self {
        case .penny: return "penny"
        case .nickel: return "nickel"
        case .dime: return "dime"
        case .quarter: return "quarter"
        case .one: return "one-dollar bill"
        case .five: return "five-dollar bill"
        case .ten: return "ten-dollar bill"
        case .twenty: return "twenty-dollar bill"
        }
    }
    var plural: String { self == .penny ? "pennies" : name + "s" }
    /// The face value as written: 1¢, 25¢, $1, $20.
    var label: String { isBill ? "$\(rawValue / 100)" : "\(rawValue)¢" }
    /// Diameter relative to the quarter (real proportions).
    var sizeRatio: CGFloat {
        switch self {
        case .dime: return 17.91 / 24.26
        case .penny: return 19.05 / 24.26
        case .nickel: return 21.21 / 24.26
        default: return 1
        }
    }
    var reeded: Bool { self == .dime || self == .quarter }
    static let coins: [USMoney] = [.penny, .nickel, .dime, .quarter]
}

/// An amount the way a child sees it on a price tag: 45¢ under a dollar, $1.25 from a dollar up.
func usMoney(_ cents: Int) -> String {
    if cents < 100 { return "\(cents)¢" }
    return cents % 100 == 0 ? "$\(cents / 100)" : String(format: "$%d.%02d", cents / 100, cents % 100)
}

/// Always dollars-and-cents ($0.45, $12.00).
func usDollars(_ cents: Int) -> String { String(format: "$%d.%02d", cents / 100, cents % 100) }

/// The fewest pieces that make `cents` from `kinds` (US denominations are greedy-optimal).
func usFewest(_ cents: Int, from kinds: [USMoney] = USMoney.allCases) -> [USMoney] {
    var left = cents, out: [USMoney] = []
    for k in kinds.sorted(by: >) { while left >= k.cents { out.append(k); left -= k.cents } }
    return out + Array(repeating: .penny, count: left)
}

/// A drawn US coin (or bill). `showValue` puts the face value on it in a little badge — fade it
/// out as the child learns the coins by size and colour.
struct USMoneyView: View {
    let kind: USMoney
    /// The quarter's diameter; the other coins scale to real proportions. A bill is `size` × 0.9 tall.
    var size: CGFloat = 60
    var showValue = true
    var body: some View {
        if kind.isBill { bill } else { coin }
    }

    private var coin: some View {
        let d = size * kind.sizeRatio
        let copper = kind == .penny
        let hi: UInt = copper ? 0xf2b48a : 0xfbfbf8
        let mid: UInt = copper ? 0xc0703f : 0xc3c6cc
        let lo: UInt = copper ? 0x7c3c1c : 0x80848c
        return ZStack {
            Circle().fill(RadialGradient(colors: [Color(hex: hi), Color(hex: mid), Color(hex: lo)],
                                         center: UnitPoint(x: 0.34, y: 0.3), startRadius: 1, endRadius: d * 0.72))
            if kind.reeded {
                Circle().inset(by: d * 0.025)
                    .stroke(Color(hex: lo), style: StrokeStyle(lineWidth: max(1.5, d * 0.05), dash: [1.2, 1.5]))
            }
            Circle().inset(by: d * 0.1).stroke(Color(hex: lo).opacity(0.55), lineWidth: max(1, d * 0.025))
            // The portrait in low relief.
            USProfile().fill(Color(hex: lo).opacity(0.4))
                .frame(width: d * 0.42, height: d * 0.54)
                .scaleEffect(x: copper ? -1 : 1)
                .offset(x: d * (copper ? -0.02 : 0.03), y: d * 0.02)
            if showValue {
                Text(kind.label)
                    .font(luFont(d * 0.36, .black))
                    .foregroundStyle(Color(hex: copper ? 0x4a200c : 0x262a31))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, d * 0.06)
                    .background(Capsule().fill(Color.white.opacity(0.75)))
                    .frame(maxWidth: d * 0.86)
            }
        }
        .frame(width: d, height: d)
        .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 2)
    }

    private var bill: some View {
        let h = size * 0.9, w = h * 2.35
        let n = "\(kind.cents / 100)"
        return ZStack {
            RoundedRectangle(cornerRadius: h * 0.06)
                .fill(LinearGradient(colors: [Color(hex: 0xe6eed8), Color(hex: 0xc3d3b1)], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: h * 0.04).inset(by: h * 0.07)
                .stroke(Color(hex: 0x3f6b4a), lineWidth: max(1.5, h * 0.05))
            Ellipse().fill(Color(hex: 0xb5c7a1)).frame(width: h * 0.6, height: h * 0.7)
                .overlay(Ellipse().stroke(Color(hex: 0x3f6b4a), lineWidth: max(1, h * 0.03)))
                .overlay(USProfile().fill(Color(hex: 0x3f6b4a).opacity(0.75)).frame(width: h * 0.3, height: h * 0.42).offset(y: h * 0.05))
            ForEach(0..<4, id: \.self) { c in
                Text(n).font(luFont(h * 0.24, .black)).foregroundStyle(Color(hex: 0x2d5238))
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: [Alignment.topLeading, .topTrailing, .bottomLeading, .bottomTrailing][c])
                    .padding(.horizontal, h * 0.15).padding(.vertical, h * 0.1)
            }
            if showValue {
                Text(kind.label).font(luFont(h * 0.32, .black)).foregroundStyle(Color(hex: 0x1f3d29))
                    .padding(.horizontal, h * 0.08)
                    .background(Capsule().fill(Color.white.opacity(0.75)))
                    .offset(x: -w * 0.27)
            }
        }
        .frame(width: w, height: h)
        .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 2)
    }
}

/// A simple head-and-shoulders profile facing left, for coins and bills.
struct USProfile: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * w, y: r.minY + y * h) }
        p.move(to: pt(0.55, 0.02))
        p.addCurve(to: pt(0.96, 0.38), control1: pt(0.82, 0.0), control2: pt(1.0, 0.18))
        p.addCurve(to: pt(0.72, 0.70), control1: pt(0.94, 0.56), control2: pt(0.84, 0.66))
        p.addLine(to: pt(0.78, 0.80))
        p.addCurve(to: pt(1.0, 1.0), control1: pt(0.92, 0.86), control2: pt(1.0, 0.92))
        p.addLine(to: pt(0.0, 1.0))
        p.addCurve(to: pt(0.36, 0.80), control1: pt(0.04, 0.9), control2: pt(0.2, 0.84))
        p.addLine(to: pt(0.36, 0.70))
        p.addCurve(to: pt(0.16, 0.56), control1: pt(0.26, 0.68), control2: pt(0.18, 0.64))
        p.addLine(to: pt(0.06, 0.50))
        p.addLine(to: pt(0.16, 0.44))
        p.addLine(to: pt(0.08, 0.34))
        p.addCurve(to: pt(0.55, 0.02), control1: pt(0.12, 0.12), control2: pt(0.3, 0.03))
        p.closeSubpath()
        return p
    }
}

// MARK: - Drag helper

/// Frames of named drop targets, collected in a coordinate space.
struct MarketFrames: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue()) { $1 } }
}

extension View {
    /// Reports this view's frame (in coordinate space `space`) under `name` via `MarketFrames`.
    func marketFrame(_ name: String, in space: String) -> some View {
        background(GeometryReader { g in Color.clear.preference(key: MarketFrames.self, value: [name: g.frame(in: .named(space))]) })
    }
}

/// Something a child can drag onto a target (or just tap). `drop` gets the release point in
/// `space` and says whether it landed (then it snaps home invisibly); otherwise it springs back.
struct MarketDraggable<Content: View>: View {
    let space: String
    var enabled = true
    var onDrag: (CGPoint?) -> Void = { _ in }
    let drop: (CGPoint) -> Bool
    let tap: () -> Void
    @ViewBuilder let content: Content
    @State private var drag: CGSize = .zero
    @State private var lifted = false
    var body: some View {
        content
            .scaleEffect(lifted ? 1.15 : 1)
            .shadow(color: .black.opacity(lifted ? 0.35 : 0), radius: 8, y: 6)
            .offset(drag)
            .zIndex(lifted ? 10 : 0)
            .gesture(DragGesture(minimumDistance: 6, coordinateSpace: .named(space))
                .onChanged { v in
                    guard enabled else { return }
                    if !lifted { lifted = true; Haptics.light() }
                    drag = v.translation; onDrag(v.location)
                }
                .onEnded { v in
                    guard lifted else { return }
                    onDrag(nil)
                    lifted = false
                    if enabled && drop(v.location) { drag = .zero }
                    else { withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { drag = .zero } }
                })
            .simultaneousGesture(TapGesture().onEnded { if enabled { tap() } })
    }
}

/// Soft clouds for the outdoor Market scenes.
struct MarketCloud: View {
    var w: CGFloat = 120
    var body: some View {
        ZStack {
            Ellipse().frame(width: w, height: w * 0.36).offset(y: w * 0.06)
            Circle().frame(width: w * 0.42).offset(x: -w * 0.18, y: -w * 0.04)
            Circle().frame(width: w * 0.52).offset(x: w * 0.08, y: -w * 0.1)
        }
        .foregroundStyle(Color.white.opacity(0.85))
        .frame(width: w, height: w * 0.6)
    }
}
