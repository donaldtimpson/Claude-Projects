import SwiftUI

// MARK: - Lane Sorter — the shared "drop it in the right bin" engine (GameKit)
//
// One tile falls at a time; the child taps the bin it belongs in. A right bin gulps it (bounce +
// sparks); a wrong bin — or a tile that reaches the floor — sends the tile to the RIGHT bin and
// shows a one-line lesson ("A bat is a MAMMAL"), so a miss always teaches. Each game supplies its
// bins per level (they grow with the ladder), an item deck per level and a fall time per level.
// Used by Word Sort and Critter Sort.

struct SortBin: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let tint: UInt
    var hint = ""             // a few plain words under the title ("a thing")
}

struct SortItem: Equatable {
    var emoji = ""            // picture ("" = words only)
    var hue = 0.0             // hue-rotates the picture (e.g. a 🦎 recoloured as a pink axolotl)
    let text: String          // may mark one word as *word* (highlighted)
    let bin: String           // the right bin's id
    let lesson: String        // shown after a miss; may contain *marks*
}

@MainActor
final class LaneSortModel: ArcadeModel {
    enum TileState: Equatable { case falling, sorted(String), taught(String) }
    struct Tile: Identifiable, Equatable {
        let id = UUID()
        let item: SortItem
        let fall: Double
        var state: TileState = .falling
    }
    struct Spark: Identifiable { let id = UUID(); let bin: String }

    @Published var bins: [SortBin] = []
    @Published var tile: Tile?
    @Published var lesson: String?
    @Published var news: String?
    @Published var sparks: [Spark] = []
    @Published var goodBin: String?
    @Published var goodPulse = 0
    @Published var wrongBin: String?
    @Published var wrongPulse = 0

    private let binsFor: (Int) -> [SortBin]
    private let make: (Int) -> SortItem
    private let fallTime: (Int) -> Double
    private var recent: [String] = []
    private var timeout: DispatchWorkItem?
    private var serveToken = UUID()

    init(key: String, bins: @escaping (Int) -> [SortBin], make: @escaping (Int) -> SortItem,
         fall: @escaping (Int) -> Double) {
        binsFor = bins; self.make = make; fallTime = fall
        super.init(key: key)
    }

    override func onBegin() {
        timeout?.cancel()
        bins = binsFor(level)
        tile = nil; lesson = nil; news = nil; sparks = []; recent = []
        serve(after: 0.5)
    }

    override func onLevelUp() {
        let next = binsFor(level)
        guard next.map(\.id) != bins.map(\.id) else { return }
        let added = next.filter { !bins.contains($0) }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { bins = next }
        if let a = added.first {
            news = "New bin: \(a.icon) \(a.title)!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in self?.news = nil }
        }
    }

    /// The child tapped a bin.
    func choose(_ bin: String) {
        guard phase == .playing, let t = tile, t.state == .falling else { return }
        timeout?.cancel()
        if bin == t.item.bin {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) { tile?.state = .sorted(bin) }
            goodBin = bin; goodPulse += 1
            let s = Spark(bin: bin)
            sparks.append(s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in self?.sparks.removeAll { $0.id == s.id } }
            let up = hit()
            serve(after: up ? 1.5 : 0.55)
        } else {
            wrongBin = bin; wrongPulse += 1
            teach(t)
        }
    }

    private func landed(_ id: UUID) {
        guard phase == .playing, let t = tile, t.id == id, t.state == .falling else { return }
        teach(t)
    }

    /// A miss: the tile flies to its right bin and the lesson line shows.
    private func teach(_ t: Tile) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { tile?.state = .taught(t.item.bin) }
        goodBin = t.item.bin; goodPulse += 1
        lesson = t.item.lesson
        miss(delay: 1.8)
        serve(after: 1.9)
    }

    private func serve(after d: Double) {
        let token = UUID(); serveToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
            guard let self, self.serveToken == token, self.phase == .playing, !self.dying else { return }
            self.lesson = nil
            var item = self.make(self.level)
            for _ in 0..<12 where self.recent.contains(item.text) { item = self.make(self.level) }
            self.recent.append(item.text)
            if self.recent.count > 6 { self.recent.removeFirst() }
            let fall = self.fallTime(self.level)
            let t = Tile(item: item, fall: fall)
            self.tile = t
            let w = DispatchWorkItem { [weak self] in self?.landed(t.id) }
            self.timeout = w
            DispatchQueue.main.asyncAfter(deadline: .now() + fall + 0.05, execute: w)
        }
    }

    override func botAct(correct: Bool) {
        guard let t = tile, t.state == .falling else { return }
        let wrong = bins.map(\.id).filter { $0 != t.item.bin }
        choose(correct || wrong.isEmpty ? t.item.bin : wrong.randomElement()!)
    }
}

/// `s` with its *marked* word highlighted.
func luMarked(_ s: String, base: UInt, mark: UInt) -> Text {
    var out = Text("")
    for (i, part) in s.components(separatedBy: "*").enumerated() where !part.isEmpty {
        out = out + (i % 2 == 1 ? Text(part).foregroundColor(Color(hex: mark)).underline(true, color: Color(hex: mark))
                                : Text(part).foregroundColor(Color(hex: base)))
    }
    return out
}

/// Bin rectangles: one row for 2–3 bins, 2×2 for 4, 3 + 2 for 5. Tall enough for small fingers.
private func laneBinFrames(_ n: Int, in size: CGSize) -> [CGRect] {
    guard n > 0 else { return [] }
    let side: CGFloat = 12, gap: CGFloat = 10, bottom: CGFloat = 14
    let rows: [Int] = n <= 3 ? [n] : (n == 4 ? [2, 2] : [3, n - 3])
    let h: CGFloat = rows.count == 1 ? 118 : 92
    var out: [CGRect] = []
    for (r, count) in rows.enumerated() {
        let w = (size.width - side * 2 - gap * CGFloat(count - 1)) / CGFloat(count)
        let y = size.height - bottom - CGFloat(rows.count - r) * h - CGFloat(rows.count - 1 - r) * gap
        for c in 0..<count {
            out.append(CGRect(x: side + CGFloat(c) * (w + gap), y: y, width: w, height: h))
        }
    }
    return out
}

/// The play area of a lane-sort game, inside the GameKit shell.
struct LaneSorterView: View {
    @ObservedObject var model: LaneSortModel
    let spec: GameSpec
    var accent: UInt = Lu.gold
    let prompt: String
    let onClose: () -> Void

    var body: some View {
        ArcadeShell(model: model, spec: spec, accent: accent, onClose: onClose) {
            GeometryReader { geo in
                let frames = laneBinFrames(model.bins.count, in: geo.size)
                let binsTop = frames.map(\.minY).min() ?? geo.size.height
                let centers = Dictionary(uniqueKeysWithValues: zip(model.bins.map(\.id), frames))
                ZStack {
                    VStack(spacing: 6) {
                        Text(prompt).font(luSerif(15, .bold)).textCase(.uppercase).tracking(2)
                            .foregroundStyle(Color(hex: Lu.inkDim))
                        ZStack {
                            if model.combo >= 2 {
                                Text("COMBO ×\(model.combo)!").font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                                    .id(model.combo)
                                    .transition(.scale(scale: 1.3).combined(with: .opacity))
                            }
                        }
                        .frame(height: 22)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: model.combo)
                    }
                    .position(x: geo.size.width / 2, y: 86)

                    ForEach(Array(model.bins.enumerated()), id: \.element.id) { i, b in
                        let f = frames[i]
                        LaneBinButton(bin: b,
                                      bounce: model.goodBin == b.id ? model.goodPulse : 0,
                                      shake: model.wrongBin == b.id ? model.wrongPulse : 0,
                                      compact: frames.count > 3) { model.choose(b.id) }
                            .frame(width: f.width, height: f.height)
                            .position(x: f.midX, y: f.midY)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if model.phase == .playing, let t = model.tile {
                        LaneTileView(tile: t,
                                     start: CGPoint(x: geo.size.width / 2, y: 150),
                                     floor: CGPoint(x: geo.size.width / 2, y: binsTop - 110),
                                     bins: centers, maxWidth: geo.size.width - 36)
                            .id(t.id)
                            .transition(.opacity)
                    }

                    ForEach(model.sparks) { s in
                        if let f = centers[s.bin] { LaneSparkBurst().position(x: f.midX, y: f.minY + 10) }
                    }

                    if model.phase == .playing, let text = model.lesson ?? model.news {
                        luMarked(text, base: Lu.inkDark, mark: 0x9c2a14)
                            .font(luFont(21, .heavy))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 18).padding(.vertical, 12)
                            .background(Capsule().fill(Color(hex: model.lesson != nil ? Lu.mint : Lu.gold))
                                .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 2)))
                            .padding(.horizontal, 16)
                            .position(x: geo.size.width / 2, y: (150 + binsTop) / 2)
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                            .allowsHitTesting(false)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.lesson)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.news)
            }
        }
    }
}

private struct LaneTileView: View {
    let tile: LaneSortModel.Tile
    let start: CGPoint
    let floor: CGPoint
    let bins: [String: CGRect]
    let maxWidth: CGFloat

    @State private var fallen = false
    @State private var wobble = false

    private var pos: CGPoint {
        switch tile.state {
        case .falling: return fallen ? floor : start
        case .sorted(let b): return bins[b].map { CGPoint(x: $0.midX, y: $0.midY) } ?? floor
        case .taught(let b): return bins[b].map { CGPoint(x: $0.midX, y: $0.minY - 40) } ?? floor
        }
    }

    var body: some View {
        let item = tile.item
        let taught: Bool = { if case .taught = tile.state { return true }; return false }()
        let sorted: Bool = { if case .sorted = tile.state { return true }; return false }()
        VStack(spacing: 4) {
            if !item.emoji.isEmpty {
                Text(item.emoji).font(.system(size: 62)).hueRotation(.degrees(item.hue))
            }
            luMarked(item.text, base: Lu.inkDark, mark: 0xb4361c)
                .font(luFont(item.text.count > 14 ? 26 : 32))
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 22).padding(.vertical, 14)
        .frame(maxWidth: maxWidth)
        .fixedSize(horizontal: item.text.count <= 14, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [.white, Color(hex: Lu.silver)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(hex: taught ? Lu.mint : Lu.grape), lineWidth: taught ? 5 : 3))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 6)
        )
        .rotationEffect(.degrees(tile.state == .falling ? (wobble ? 4 : -4) : 0))
        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: wobble)
        .scaleEffect(sorted ? 0.2 : (taught ? 0.72 : 1))
        .opacity(sorted ? 0 : 1)
        .position(pos)
        .onAppear {
            withAnimation(.linear(duration: tile.fall)) { fallen = true }
            wobble = true
        }
    }
}

private struct LaneBinButton: View {
    let bin: SortBin
    let bounce: Int
    let shake: Int
    let compact: Bool
    let action: () -> Void

    @State private var pop = false
    @State private var shakes: CGFloat = 0

    var body: some View {
        Button(action: action) {
            VStack(spacing: compact ? 2 : 6) {
                Text(bin.icon).font(.system(size: compact ? 30 : 40))
                Text(bin.title).font(luFont(compact ? 17 : 22)).foregroundStyle(Color(hex: Lu.inkDark))
                    .lineLimit(1).minimumScaleFactor(0.5)
                if !bin.hint.isEmpty {
                    Text(bin.hint).font(luFont(compact ? 12 : 15, .bold)).foregroundStyle(Color(hex: Lu.inkDark).opacity(0.75))
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: [Color(hex: bin.tint), luShade(bin.tint, -40)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.45), lineWidth: 2))
                    .background(RoundedRectangle(cornerRadius: 22).fill(luShade(bin.tint, -70)).offset(y: 6))
            )
            .scaleEffect(pop ? 1.1 : 1)
            .modifier(ShakeEffect(shakes: shakes))
        }
        .buttonStyle(LanePressStyle())
        .onChange(of: bounce) { v in
            guard v > 0 else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) { pop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pop = false }
            }
        }
        .onChange(of: shake) { v in
            guard v > 0 else { return }
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
        }
    }
}

/// Side-to-side wobble: one `shakes` step = three quick swings.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(shakes * .pi * 6), y: 0))
    }
}

private struct LanePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A little puff of stars that flies out and fades (one-shot).
struct LaneSparkBurst: View {
    var glyphs = ["✨", "⭐️", "✨", "🌟", "✨", "⭐️"]
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(glyphs.indices, id: \.self) { i in
                let a = Double(i) / Double(glyphs.count) * 2 * .pi - .pi / 2
                Text(glyphs[i]).font(.system(size: 22))
                    .offset(x: go ? cos(a) * 62 : 0, y: go ? sin(a) * 52 - 20 : 0)
                    .scaleEffect(go ? 1.1 : 0.4)
                    .opacity(go ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { go = true } }
    }
}
