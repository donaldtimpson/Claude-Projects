import SwiftUI

// MARK: - Dress Marcus (Vesuvius · Science)
//
// Look out of the window, then drag (or tap) the right clothes onto Marcus. Dressed right, he
// beams and strolls out of the door; dressed wrong he shivers blue, sweats red or gets soaked —
// then the right gear flies onto him, so every miss teaches. One outfit = one answer.
//
// Ladder
//   I    picture weather only (☀️ hot · 🌧️ · ❄️): pick 1 of 2.
//   II   pick 1 of 3; words under the pictures.
//   III  pick 2 of 4; a picture thermometer (°C) joins the window.
//   IV   the thermometer decides — a sunny or cloudy day may be hot OR freezing; windy days.
//   V    mixed weather (cold rain, hot rain, windy snow): pick 3 of 5.
//   VI   digital thermometer only, in °C or °F: pick 3 of 6.
//   VII+ "why" rounds (light vs dark colours, waterproof stuff, layers) between bigger outfits:
//        3 of 7 at VII, 4 of 8 from VIII on. No clock at any level.
//
// Uniqueness: every gear item is rated need / wrong / unsure for the day's weather; a round offers
// only `need` items (all of them right) and `wrong` items, never an `unsure` one — so exactly the
// right set is pickable. `dmSelfCheck` (DEBUG) re-verifies thousands of generated rounds.

// MARK: Weather + gear

private enum Sky { case sunny, cloudy, rain, snow }
private enum Heat { case hot, mild, cold }
private enum Gauge { case none, bar, digitalC, digitalF }

private struct Weather: Equatable {
    var sky: Sky
    var heat: Heat
    var windy = false
    var celsius = 15
    var gauge: Gauge = .none
    var fahrenheit: Int { Int((Double(celsius) * 9 / 5 + 32).rounded()) }
}

private enum Slot { case head, eyes, neck, body, hands, legs, feet, umbrella }

private enum Gear: CaseIterable {
    case umbrella, sunglasses, sunhat, tshirt, shorts, sandals, coat, scarf, gloves, boots
    var emoji: String {
        switch self {
        case .umbrella: return "☂️"
        case .sunglasses: return "🕶️"
        case .sunhat: return "👒"
        case .tshirt: return "👕"
        case .shorts: return "🩳"
        case .sandals: return "🩴"
        case .coat: return "🧥"
        case .scarf: return "🧣"
        case .gloves: return "🧤"
        case .boots: return "🥾"
        }
    }
    var name: String {
        switch self {
        case .umbrella: return "umbrella"
        case .sunglasses: return "sunglasses"
        case .sunhat: return "sun hat"
        case .tshirt: return "T-shirt"
        case .shorts: return "shorts"
        case .sandals: return "flip-flops"
        case .coat: return "coat"
        case .scarf: return "scarf"
        case .gloves: return "gloves"
        case .boots: return "boots"
        }
    }
    var slot: Slot {
        switch self {
        case .umbrella: return .umbrella
        case .sunglasses: return .eyes
        case .sunhat: return .head
        case .tshirt, .coat: return .body
        case .shorts: return .legs
        case .sandals, .boots: return .feet
        case .scarf: return .neck
        case .gloves: return .hands
        }
    }
    /// Warm gear makes Marcus sweat on a hot day; summer gear leaves him shivering on a cold one.
    var warm: Bool { [.coat, .scarf, .gloves, .boots].contains(self) }
    var summery: Bool { [.tshirt, .shorts, .sandals, .sunhat].contains(self) }
}

private enum Fit { case need, wrong, unsure }

/// Does Marcus need this today? `unsure` items are never offered (no arguable answers).
private func fit(_ g: Gear, _ w: Weather) -> Fit {
    let wet = w.sky == .rain
    let dry = w.sky == .sunny || w.sky == .cloudy
    switch g {
    case .umbrella:
        if wet { return w.windy ? .unsure : .need }      // wind turns umbrellas inside out
        return dry ? .wrong : .unsure                     // umbrellas in snow: people differ
    case .sunglasses:
        if w.sky == .sunny { return w.heat == .hot ? .need : .unsure }   // snow glare: arguable
        return .wrong
    case .sunhat:
        if w.sky == .sunny { return w.heat == .hot ? .need : (w.heat == .mild ? .unsure : .wrong) }
        return .wrong
    case .tshirt, .shorts:
        return w.heat == .hot ? .need : (w.heat == .cold ? .wrong : .unsure)
    case .sandals:
        if w.heat == .hot { return dry ? .need : .unsure }
        return w.heat == .cold ? .wrong : .unsure
    case .coat, .scarf, .gloves:
        return w.heat == .cold ? .need : (w.heat == .hot ? .wrong : .unsure)
    case .boots:
        if wet || w.sky == .snow { return .need }
        return w.heat == .hot ? .wrong : .unsure
    }
}

private enum Mood { case calm, happy, cold, hot, soaked }

/// How Marcus reacts to going out in the wrong gear.
private func reaction(_ g: Gear?, _ w: Weather) -> Mood {
    if let g, g.warm, w.heat == .hot { return .hot }
    if let g, g.summery, w.heat == .cold { return .cold }
    if w.sky == .rain { return .soaked }
    if w.heat == .cold || w.sky == .snow { return .cold }
    return .hot
}

// MARK: Rounds

private struct DMItem: Identifiable, Equatable {
    let id: Int
    let glyph: String           // emoji (unused when `shirt` is set)
    var shirt: UInt? = nil      // drawn as a T-shirt in this colour (the colour questions)
    let label: String
    let slot: Slot
    let right: Bool
    var gear: Gear? = nil
}

private struct DMRound {
    var weather: Weather
    var items: [DMItem]
    var need: Int
    var ask: String? = nil       // a "why" round's question
    var because: String? = nil   // …and the science behind its answer
}

private struct WhyQ {
    let weather: Weather
    let ask: String
    let right: (String, UInt?, String, Slot)
    let wrong: (String, UInt?, String, Slot)
    let because: String
}

private let whiteShirt: UInt = 0xfbfaf4, blackShirt: UInt = 0x1d1b22

private let whyQs: [WhyQ] = [
    WhyQ(weather: Weather(sky: .sunny, heat: .hot, celsius: 33), ask: "Which shirt keeps him COOLER in the sun?",
         right: ("", whiteShirt, "white shirt", .body), wrong: ("", blackShirt, "black shirt", .body),
         because: "Light colours bounce sunlight away"),
    WhyQ(weather: Weather(sky: .sunny, heat: .cold, celsius: -2), ask: "Which shirt soaks up MORE of the sun's warmth?",
         right: ("", blackShirt, "black shirt", .body), wrong: ("", whiteShirt, "white shirt", .body),
         because: "Dark colours soak up sunlight"),
    WhyQ(weather: Weather(sky: .rain, heat: .mild, celsius: 14), ask: "Which one keeps him DRY?",
         right: ("🧥", nil, "rubber raincoat", .body), wrong: ("🧶", nil, "wool jumper", .body),
         because: "Rubber is waterproof — wool soaks up rain"),
    WhyQ(weather: Weather(sky: .snow, heat: .cold, celsius: -4), ask: "Which shoes keep his feet DRY?",
         right: ("🥾", nil, "waterproof boots", .feet), wrong: ("👟", nil, "cloth trainers", .feet),
         because: "Waterproof boots keep melting snow out"),
    WhyQ(weather: Weather(sky: .cloudy, heat: .cold, celsius: -3), ask: "Which keeps him WARMER?",
         right: ("👕🧶🧥", nil, "3 layers", .body), wrong: ("👕", nil, "1 thin shirt", .body),
         because: "Layers trap warm air next to the body"),
    WhyQ(weather: Weather(sky: .sunny, heat: .hot, celsius: 31), ask: "What stops his skin getting SUNBURNT?",
         right: ("🧴", nil, "sunscreen", .hands), wrong: ("🕶️", nil, "sunglasses", .eyes),
         because: "Sunscreen blocks the sun's UV rays on skin"),
    WhyQ(weather: Weather(sky: .cloudy, heat: .cold, windy: true, celsius: 1), ask: "Which top blocks the cold WIND?",
         right: ("🧥", nil, "windproof jacket", .body), wrong: ("🎽", nil, "mesh vest", .body),
         because: "Tightly woven cloth stops the wind; holes let it in"),
]

private func temp(_ h: Heat) -> Int {
    switch h {
    case .hot: return Int.random(in: 28...35)
    case .mild: return Int.random(in: 12...17)
    case .cold: return Int.random(in: -5...3)
    }
}

/// The day's weather for a level (see the ladder above).
private func dmWeather(_ level: Int) -> Weather {
    var w: Weather
    switch level {
    case ...3:
        w = [Weather(sky: .sunny, heat: .hot), Weather(sky: .rain, heat: .mild), Weather(sky: .snow, heat: .cold)].randomElement()!
    case 4:
        if Int.random(in: 0..<5) == 0 {
            w = Weather(sky: .snow, heat: .cold, windy: Bool.random())
        } else {
            let h: Heat = Bool.random() ? .hot : .cold
            w = Weather(sky: Bool.random() ? .sunny : .cloudy, heat: h, windy: h == .cold && Bool.random())
        }
    default:
        w = [Weather(sky: .sunny, heat: .hot), Weather(sky: .sunny, heat: .cold),
             Weather(sky: .cloudy, heat: .hot), Weather(sky: .cloudy, heat: .cold, windy: true),
             Weather(sky: .rain, heat: .hot), Weather(sky: .rain, heat: .cold),
             Weather(sky: .snow, heat: .cold, windy: Bool.random())].randomElement()!
    }
    w.celsius = temp(w.heat)
    w.gauge = level <= 2 ? .none : level <= 5 ? .bar : (Bool.random() ? .digitalC : .digitalF)
    return w
}

/// An outfit round: `need` items Marcus needs + wrong ones, `offer` in all.
private func outfit(_ w: Weather, need: Int, offer: Int, simple: Bool, base: Int) -> DMRound {
    // Level I keeps to the most picture-obvious gear (feet items read less clearly).
    let pool = Gear.allCases.filter { !simple || ($0 != .boots && $0 != .sandals) }
    let needs = pool.filter { fit($0, w) == .need }.shuffled()
    let wrongs = pool.filter { fit($0, w) == .wrong }.shuffled()
    let n = min(need, needs.count)
    let k = min(max(offer - n, 1), wrongs.count)
    let picks = (needs.prefix(n).map { ($0, true) } + wrongs.prefix(k).map { ($0, false) }).shuffled()
    let items = picks.enumerated().map { i, p in
        DMItem(id: base + i, glyph: p.0.emoji, label: p.0.name, slot: p.0.slot, right: p.1, gear: p.0)
    }
    return DMRound(weather: w, items: items, need: n)
}

private func whyRound(base: Int) -> DMRound {
    let q = whyQs.randomElement()!
    var w = q.weather
    w.gauge = Bool.random() ? .digitalC : .digitalF
    let a = DMItem(id: base, glyph: q.right.0, shirt: q.right.1, label: q.right.2, slot: q.right.3, right: true)
    let b = DMItem(id: base + 1, glyph: q.wrong.0, shirt: q.wrong.1, label: q.wrong.2, slot: q.wrong.3, right: false)
    return DMRound(weather: w, items: [a, b].shuffled(), need: 1, ask: q.ask, because: q.because)
}

private func dmRound(_ level: Int, count: Int, base: Int) -> DMRound {
    switch level {
    case 1: return outfit(dmWeather(1), need: 1, offer: 2, simple: true, base: base)
    case 2: return outfit(dmWeather(2), need: 1, offer: 3, simple: false, base: base)
    case 3, 4: return outfit(dmWeather(level), need: 2, offer: 4, simple: false, base: base)
    case 5: return outfit(dmWeather(5), need: 3, offer: 5, simple: false, base: base)
    case 6: return outfit(dmWeather(6), need: 3, offer: 6, simple: false, base: base)
    default:
        if count % 2 == 1 { return whyRound(base: base) }
        let need = level >= 8 ? 4 : 3
        let offer = min(8, 6 + (level - 6))
        return outfit(dmWeather(level), need: need, offer: offer, simple: false, base: base)
    }
}

#if DEBUG
/// Every generated round is solvable with exactly one right set: the offered right items are
/// all `need`, the rest all `wrong`, the count to pick equals the right ones offered, and at
/// least one wrong item is offered. Returns a failure description, or nil.
private func dmSelfCheck() -> String? {
    for level in 1...12 {
        for i in 0..<300 {
            let r = dmRound(level, count: i, base: 0)
            let rights = r.items.filter(\.right)
            if rights.count != r.need || r.need < 1 { return "L\(level): need \(r.need) vs \(rights.count) right" }
            if r.items.count == rights.count { return "L\(level): no wrong item" }
            if Set(r.items.map(\.label)).count != r.items.count { return "L\(level): duplicate item" }
            if r.weather.sky == .snow && r.weather.heat != .cold { return "L\(level): warm snow" }
            if r.ask == nil {
                for it in r.items {
                    guard let g = it.gear else { return "L\(level): gear-less outfit item" }
                    let f = fit(g, r.weather)
                    if f == .unsure || (f == .need) != it.right { return "L\(level): \(g) misrated" }
                }
                if level == 1 && r.items.count != 2 { return "L1: \(r.items.count) items" }
            }
        }
    }
    return nil
}
#endif

// MARK: Model

@MainActor
private final class DressModel: ArcadeModel {
    @Published var round = DMRound(weather: Weather(sky: .sunny, heat: .hot), items: [], need: 1)
    @Published var placed: [Int] = []      // item ids on Marcus, in the order put on
    @Published var mood: Mood = .calm
    @Published var beat = 0                // bumps on every reaction (drives shake / hop)
    @Published var revealing = false       // after a miss: the right gear is on him
    @Published var roundID = 0
    @Published var bubble: String?
    @Published var wrongID: Int?
    @Published var cheers = 0              // bumps on each finished outfit (sparkle puff)
    private var locked = false
    private var served = 0
    private let clock = VesRunClock()
    #if DEBUG
    private static let checked: Bool = {
        if let bad = dmSelfCheck() { assertionFailure("Dress Marcus self-check: \(bad)") }
        return true
    }()
    #endif

    init() {
        super.init(key: GameID.dressMarcus.rawValue)
        #if DEBUG
        _ = DressModel.checked
        #endif
    }

    override func onBegin() {
        clock.reset()
        served = 0
        newRound()
    }

    /// What Marcus has on right now.
    var worn: [DMItem] {
        if revealing { return round.items.filter(\.right) }
        return placed.compactMap { id in round.items.first { $0.id == id } }
    }

    /// The child dropped (or tapped) `item` onto Marcus. True = he keeps it on.
    @discardableResult
    func dress(_ item: DMItem) -> Bool {
        guard phase == .playing, !locked, !placed.contains(item.id) else { return false }
        guard item.right else { fail(item); return false }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { placed.append(item.id) }
        if placed.count >= round.need {
            locked = true
            mood = .happy; beat += 1; cheers += 1
            bubble = round.because.map { "✓ " + $0 } ?? ["Perfect!", "Just right!", "Bene!", "Off I go!"].randomElement()!
            hit()
            clock.after(round.because == nil ? 1.2 : 2.0) { self.next() }
        } else {
            Haptics.tap(0.45)
            beat += 1
        }
        return true
    }

    private func fail(_ item: DMItem) {
        locked = true
        wrongID = item.id
        let m = reaction(item.gear, round.weather)
        mood = m; beat += 1
        bubble = m == .cold ? "Brrr! 🥶" : m == .hot ? "Too hot! 🥵" : "I'm soaked! 💦"
        let last = miss(delay: 2.6)
        clock.after(0.9) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                self.revealing = true
                let rights = self.round.items.filter(\.right).map { $0.shirt == nil ? $0.glyph : $0.label }
                self.bubble = self.round.because ?? ("I need " + rights.joined(separator: " "))
            }
        }
        if !last { clock.after(2.7) { self.next() } }
    }

    private func next() {
        guard phase == .playing else { return }
        withAnimation(.easeInOut(duration: 0.5)) { newRound() }
    }

    private func newRound() {
        locked = false; placed = []; revealing = false; mood = .calm; bubble = nil; wrongID = nil
        roundID += 1
        var r = dmRound(level, count: served, base: roundID * 100)
        // Don't serve the same sky + heat twice running at the picture levels.
        if level <= 3, r.weather.sky == round.weather.sky, r.weather.heat == round.weather.heat {
            r = dmRound(level, count: served, base: roundID * 100)
        }
        round = r
        served += 1
    }

    override func botAct(correct: Bool) {
        guard !locked else { return }
        let open = round.items.filter { !placed.contains($0.id) }
        if correct, let r = open.first(where: \.right) { dress(r) }
        else if let w = open.first(where: { !$0.right }) { dress(w) }
    }
}

// MARK: Views

struct DressMarcusView: View {
    let onClose: () -> Void
    @StateObject private var model = DressModel()
    @State private var zones: [Int: CGRect] = [:]
    private let space = "dressMarcus"

    var body: some View {
        ArcadeShell(model: model, spec: GameID.dressMarcus.spec ?? GameSpec(title: "Dress Marcus", mechanic: "", premise: "", game: .dressMarcus),
                    accent: Lu.tangerine, onClose: onClose) {
            VStack(spacing: 8) {
                Color.clear.frame(height: 54)
                WeatherWindow(w: model.round.weather, live: model.phase == .playing)
                    .frame(height: 138)
                if let ask = model.round.ask {
                    Text(ask).font(luFont(18, .heavy)).foregroundStyle(Color(hex: Lu.gold))
                        .multilineTextAlignment(.center).minimumScaleFactor(0.7).lineLimit(2)
                        .transition(.opacity)
                }
                stage
                pips
                tray
            }
            .padding(.horizontal, 14).padding(.bottom, 6)
            .coordinateSpace(name: space)
            .onPreferenceChange(VesDropZones.self) { zones = $0 }
        }
    }

    /// Marcus by his door. The whole stage is the drop zone — anywhere on him counts.
    private var stage: some View {
        GeometryReader { geo in
            let scale = min(1.3, geo.size.height / 262)
            ZStack {
                Text("🚪").font(.system(size: 84 * scale))
                    .position(x: geo.size.width - 40, y: geo.size.height - 52 * scale)
                ZStack {
                    MarcusFigure(worn: model.worn, mood: model.mood, beat: model.beat, glow: model.revealing)
                        .scaleEffect(scale)
                    VesBurst(trigger: model.cheers, emojis: ["✨", "🎶", "⭐️", "💛"])
                }
                .id(model.roundID)
                .transition(.asymmetric(insertion: .offset(x: -geo.size.width).combined(with: .opacity),
                                        removal: .offset(x: geo.size.width).combined(with: .opacity)))
                .position(x: geo.size.width * 0.46, y: geo.size.height / 2)
                if let b = model.bubble {
                    VesBubble(text: b, hex: model.mood == .happy ? Lu.ink : (model.revealing ? Lu.gold : 0xf3c4b8))
                        .frame(maxWidth: geo.size.width * 0.62)
                        .position(x: geo.size.width * 0.66, y: 26)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                        .id(b)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 200)
        .vesDropZone(0, in: space)
    }

    /// One slot per item to put on — they fill as Marcus dresses.
    private var pips: some View {
        HStack(spacing: 8) {
            ForEach(0..<model.round.need, id: \.self) { i in
                let w = model.worn
                ZStack {
                    Circle().stroke(Color(hex: Lu.gold).opacity(0.7), style: StrokeStyle(lineWidth: 2.5, dash: [5, 4]))
                    if i < w.count { GearGlyph(item: w[i], size: 22) }
                }
                .frame(width: 36, height: 36)
            }
        }
        .frame(height: 38)
    }

    private var tray: some View {
        let items = model.round.items
        let big = items.count <= 2
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: big ? 2 : min(4, items.count))
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(items) { item in
                let used = model.placed.contains(item.id) || (model.revealing && item.right)
                VesDragToken(space: space, enabled: !used,
                             onRelease: { p in vesZoneHit(p, zones: zones) == 0 && model.dress(item) },
                             onTap: { model.dress(item) }) {
                    GearCard(item: item, big: big, showLabel: model.level >= 2 || item.shirt != nil,
                             wrong: model.wrongID == item.id)
                }
                .opacity(used ? 0.15 : 1)
                .id(item.id)
            }
        }
        .zIndex(2)
    }
}

/// A gear item's picture (emoji, or a drawn T-shirt in a colour).
private struct GearGlyph: View {
    let item: DMItem
    let size: CGFloat
    var body: some View {
        if let hex = item.shirt {
            Image(systemName: "tshirt.fill").font(.system(size: size * 0.92, weight: .bold))
                .foregroundStyle(Color(hex: hex))
                .shadow(color: .black.opacity(0.45), radius: 0, x: 0, y: 1)
                .overlay(Image(systemName: "tshirt").font(.system(size: size * 0.92, weight: .bold))
                    .foregroundStyle(Color(hex: Lu.inkDim).opacity(0.7)))
        } else {
            Text(item.glyph).font(.system(size: size)).lineLimit(1).minimumScaleFactor(0.4)
        }
    }
}

private struct GearCard: View {
    let item: DMItem
    let big: Bool
    let showLabel: Bool
    let wrong: Bool
    var body: some View {
        VStack(spacing: 2) {
            GearGlyph(item: item, size: big ? 66 : 46)
            if showLabel {
                Text(item.label).font(luFont(13, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, minHeight: big ? 120 : 84)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color(hex: Lu.panel2), Color(hex: Lu.panel)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: wrong ? Lu.coral : Lu.goldLine), lineWidth: wrong ? 3 : 2))
        )
        .contentShape(Rectangle())
    }
}

/// Marcus: a simple drawn boy (emoji face, terracotta tunic) wearing whatever is on him.
private struct MarcusFigure: View {
    let worn: [DMItem]
    let mood: Mood
    let beat: Int
    let glow: Bool

    @State private var shake: CGFloat = 0
    @State private var hop = false

    private var face: String {
        switch mood {
        case .calm: return "🙂"
        case .happy: return "😄"
        case .cold: return "🥶"
        case .hot: return "🥵"
        case .soaked: return "😖"
        }
    }
    private var tint: Color {
        switch mood {
        case .cold: return Color(hex: 0x9cc8ff)
        case .hot: return Color(hex: 0xff9f86)
        case .soaked: return Color(hex: 0x9db4cf)
        default: return .white
        }
    }
    private let skin = Color(hex: 0xe8b48a)

    var body: some View {
        ZStack {
            Group {
                Capsule().fill(skin).frame(width: 18, height: 62).position(x: 77, y: 210)
                Capsule().fill(skin).frame(width: 18, height: 62).position(x: 103, y: 210)
                Capsule().fill(skin).frame(width: 16, height: 66).rotationEffect(.degrees(16)).position(x: 42, y: 146)
                Capsule().fill(skin).frame(width: 16, height: 66).rotationEffect(.degrees(-16)).position(x: 138, y: 146)
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Color(hex: 0xd9603f), Color(hex: 0xa8432c)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 88, height: 96).position(x: 90, y: 146)
                Rectangle().fill(Color(hex: Lu.gold)).frame(width: 88, height: 8).position(x: 90, y: 168)
            }
            .colorMultiply(tint)
            Text(face).font(.system(size: 80)).position(x: 90, y: 52)
            ForEach(worn) { item in
                gear(item)
                    .transition(.scale(scale: 2.2).combined(with: .opacity))
            }
            moodBits
        }
        .frame(width: 180, height: 250)
        .modifier(VesShake(amount: mood == .cold ? 5 : 9, shakes: mood == .cold ? 8 : 3, beats: shake))
        .offset(y: hop ? -16 : 0)
        .onChange(of: beat) { _ in
            switch mood {
            case .cold, .hot, .soaked:
                withAnimation(.linear(duration: mood == .cold ? 0.9 : 0.5)) { shake += 1 }
            default:
                withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { hop = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { hop = false }
                }
            }
        }
    }

    /// A worn item on its slot; after a miss the revealed gear gets a green halo.
    private func g(_ item: DMItem, _ size: CGFloat) -> some View {
        GearGlyph(item: item, size: size)
            .background(glow ? Circle().fill(Color(hex: Lu.mint).opacity(0.45)).frame(width: size * 1.15, height: size * 1.15) : nil)
    }

    @ViewBuilder private func gear(_ item: DMItem) -> some View {
        switch item.slot {
        case .head: g(item, 62).position(x: 90, y: 12)
        case .eyes: g(item, 46).position(x: 90, y: 46)
        case .neck: g(item, 46).position(x: 90, y: 100)
        case .body: g(item, item.glyph.count > 1 ? 34 : 94).position(x: 90, y: 146)
        case .legs: g(item, 58).position(x: 90, y: 198)
        case .hands:
            g(item, 38).position(x: 30, y: 182)
        case .feet:
            HStack(spacing: 0) { g(item, 34); g(item, 34).scaleEffect(x: -1) }
                .position(x: 90, y: 238)
        case .umbrella: g(item, 78).position(x: 150, y: 22)
        }
    }

    /// Little emoji around Marcus that say how he feels.
    @ViewBuilder private var moodBits: some View {
        switch mood {
        case .cold:
            ForEach(0..<3, id: \.self) { i in
                Text("❄️").font(.system(size: 22)).position(x: [16, 168, 158][i], y: [40, 70, 196][i])
            }
        case .hot:
            ForEach(0..<3, id: \.self) { i in
                Text("💦").font(.system(size: 22)).position(x: [24, 160, 150][i], y: [32, 40, 110][i])
            }
        case .soaked:
            ForEach(0..<5, id: \.self) { i in
                Text("💧").font(.system(size: 20)).position(x: [20, 60, 120, 165, 90][i], y: [20, 4, 8, 30, 120][i])
            }
        case .happy:
            Text("🎶").font(.system(size: 28)).position(x: 158, y: 70)
        case .calm:
            EmptyView()
        }
    }
}

/// The window: the sky (with rain, snow and wind drawn live while playing) + a thermometer from III.
private struct WeatherWindow: View {
    let w: Weather
    let live: Bool

    private var skyColors: [Color] {
        switch w.sky {
        case .sunny: return [Color(hex: 0x4fa6e8), Color(hex: 0xa8dcf5)]
        case .cloudy: return [Color(hex: 0x7c8797), Color(hex: 0xb8c0cb)]
        case .rain: return [Color(hex: 0x3f4d63), Color(hex: 0x76859b)]
        case .snow: return [Color(hex: 0x8ea3bd), Color(hex: 0xdde6f0)]
        }
    }
    private var big: String {
        switch w.sky {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rain: return "🌧️"
        case .snow: return "🌨️"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
                VStack { Spacer(); Rectangle().fill(w.sky == .snow ? Color.white : Color(hex: 0x5c9e4e)).frame(height: 18) }
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !live)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    ZStack {
                        Canvas { c, size in precipitation(c, size, t) }
                        Text(big).font(.system(size: 70))
                            .rotationEffect(.degrees(w.sky == .sunny ? (t * 12).truncatingRemainder(dividingBy: 360) : 0))
                            .offset(x: w.sky == .cloudy || w.sky == .rain ? sin(t * 0.8) * 8 : 0, y: -6)
                        if w.windy {
                            HStack {
                                Text("🌬️").font(.system(size: 34)).offset(x: sin(t * 2) * 4)
                                Spacer()
                                Text("🌳").font(.system(size: 52))
                                    .rotationEffect(.degrees(-10 + sin(t * 3.2) * 9), anchor: .bottom)
                            }
                            .padding(.horizontal, 10)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 6)
                        }
                    }
                }
                // window bars
                Rectangle().fill(Color(hex: Lu.goldLine)).frame(width: 4)
                Rectangle().fill(Color(hex: Lu.goldLine)).frame(height: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: Lu.goldLine), lineWidth: 5))
            if w.gauge != .none {
                Thermometer(w: w).frame(width: 84)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func precipitation(_ c: GraphicsContext, _ size: CGSize, _ t: Double) {
        let drift = w.windy ? 40.0 : 0
        switch w.sky {
        case .rain:
            for i in 0..<34 {
                let x0 = Double((i * 73) % 400) / 400 * size.width
                let sp = 260.0 + Double(i % 5) * 30
                let y = (t * sp + Double(i * 37)).truncatingRemainder(dividingBy: size.height + 20) - 10
                let x = (x0 + y * 0.18).truncatingRemainder(dividingBy: size.width)
                var p = Path()
                p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x - 3, y: y + 12))
                c.stroke(p, with: .color(.white.opacity(0.65)), lineWidth: 2)
            }
        case .snow:
            for i in 0..<30 {
                let x0 = Double((i * 97) % 400) / 400 * size.width
                let sp = 26.0 + Double(i % 4) * 9
                let y = (t * sp + Double(i * 41)).truncatingRemainder(dividingBy: size.height + 10) - 5
                let x = (x0 + sin(t * 1.3 + Double(i)) * 6 + y * drift / 100)
                    .truncatingRemainder(dividingBy: size.width)
                let r = 2.0 + Double(i % 3)
                c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.9)))
            }
        default:
            if w.windy {
                for i in 0..<5 {
                    let y = Double(18 + i * 22)
                    let x = (t * 160 + Double(i * 90)).truncatingRemainder(dividingBy: size.width + 80) - 60
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x + 46, y: y))
                    c.stroke(p, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
            }
        }
    }
}

/// A red-liquid thermometer marked at 0° and 30° (III–V), or a digital readout in °C / °F (VI+).
private struct Thermometer: View {
    let w: Weather
    var body: some View {
        VStack(spacing: 4) {
            if w.gauge == .bar {
                let tube: CGFloat = 92
                let frac = CGFloat(min(max(Double(w.celsius + 10) / 50, 0.04), 1))
                ZStack(alignment: .bottomLeading) {
                    Capsule().fill(Color.white.opacity(0.92)).frame(width: 20, height: tube)
                    Capsule().fill(Color(hex: 0xd8352a)).frame(width: 10, height: tube * frac)
                        .padding(.bottom, 2).padding(.leading, 5)
                    Circle().fill(Color(hex: 0xd8352a)).frame(width: 26, height: 26).offset(x: -3, y: 12)
                    ForEach([0, 30], id: \.self) { mark in
                        HStack(spacing: 2) {
                            Rectangle().fill(Color(hex: Lu.ink)).frame(width: 8, height: 2)
                            Text("\(mark)°").font(luFont(12, .heavy)).foregroundStyle(Color(hex: Lu.inkDim))
                        }
                        .fixedSize()
                        .offset(x: 22, y: -tube * CGFloat(Double(mark + 10) / 50) + 8)
                    }
                }
                .frame(width: 56, height: tube, alignment: .bottomLeading)
                .padding(.bottom, 12)
                Text("\(w.celsius)°C").font(luFont(20)).monospacedDigit()
                    .foregroundStyle(Color(hex: w.heat == .hot ? Lu.coral : (w.heat == .cold ? Lu.sky : Lu.ink)))
            } else {
                Text("🌡️").font(.system(size: 34))
                Text(w.gauge == .digitalF ? "\(w.fahrenheit)°F" : "\(w.celsius)°C")
                    .font(luFont(24)).monospacedDigit().foregroundStyle(Color(hex: Lu.ink))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x10241a)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(luPanelShape(18))
    }
}
