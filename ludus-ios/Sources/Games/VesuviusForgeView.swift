import SwiftUI

// MARK: - Vulcan's Forge (Vesuvius · Science — states of matter)
//
// Deep inside Vesuvius, Vulcan's crucible sits over a fire. Each order says what to make: "Make it
// LIQUID", "Turn it to STEAM", "Freeze it SOLID". HOLD the bellows and the fire roars, the
// thermometer climbs, and the stuff in the pot really changes — the ice cube shrinks into a puddle,
// the water bubbles and steams away, the gold ingot slumps into a glowing pool. HOLD the snow
// bucket to cool things down (water freezes, lava crusts into rock). Keep it in the asked-for state
// until the ring fills.
//
// The physics is honest: a substance sits AT its melting / boiling point while it changes state
// (the heat goes into melting, not warming), every material has its own real melting point, and
// heat leaks away toward room temperature when the fire is low.
//
// Misses: water boiled clean away when you wanted liquid, water frozen when you wanted liquid, or
// (from d≈3, generous at first) the fire's fuel running out. A miss shows the answer: the right
// band of the thermometer lights up, the pot is brought to the right state, and the fact is said.
//
// Continuous difficulty (all off `d`):
//   • content tiers: melting (ice, chocolate) → water's other changes (boil, freeze, condense) →
//     metals (tin, lead, gold, iron; melt and cast) → Vesuvius itself (rock ↔ lava).
//   • the fire answers the bellows more and more lazily (heat "momentum" 0.15 s → 0.9 s), so
//     stopping in time takes planning;
//   • the hold-ring time grows 0.8 s → 2.6 s;
//   • the target band on the thermometer fades out from d≈4 to d≈7 (watch the pot, know the facts);
//   • fuel for the fire: none below d≈3 (after the boil / freeze / condense orders and the snow
//     bucket have settled in, so the clock never lands with them), then 45 s easing to 13 s. The
//     log counter waits until the order has been SAID (or the first press), sitting full.
//
// Each order is read aloud for pre-readers (🔊 on the card repeats it); the words on the card
// are the words spoken.

// MARK: Materials

private enum FState: Int { case solid, liquid, gas
    var word: String { ["SOLID", "LIQUID", "GAS"][rawValue] }
    /// The order card's picture of this state for `mat` — an ice cube means ice, not solid gold.
    func icon(_ mat: FMat) -> String {
        switch self {
        case .gas: return "♨️"
        case .liquid: return mat.key == "water" ? "💧" : (mat.key == "chocolate" ? "🫗" : "🔥")
        case .solid:
            switch mat.key {
            case "water": return "🧊"
            case "chocolate": return "🍫"
            case "wax": return "🕯️"
            case "rock": return "🪨"
            default: return "🧱"
            }
        }
    }
}

private struct FMat {
    let key: String
    let name: String              // "gold"
    let solid: String, liquid: String, gas: String
    let melt: Double
    let boil: Double?             // only water boils inside the game's range
    let lo: Double, hi: Double    // thermometer range
    let solidHex: UInt, liquidHex: UInt
    let glows: Bool               // red-hot glow (metals, rock)
    let fact: String              // shown after the round
    var span: Double { hi - lo }
}

private let fWater = FMat(key: "water", name: "water", solid: "ice", liquid: "water", gas: "steam",
                          melt: 0, boil: 100, lo: -30, hi: 130, solidHex: 0xc9ecff, liquidHex: 0x3f9be0, glows: false,
                          fact: "Ice melts at 0°C and water boils at 100°C")
private let fMats: [String: FMat] = [
    "water": fWater,
    "chocolate": FMat(key: "chocolate", name: "chocolate", solid: "chocolate bar", liquid: "melted chocolate", gas: "",
                      melt: 34, boil: nil, lo: 0, hi: 70, solidHex: 0x6b3b1f, liquidHex: 0x7a4425, glows: false,
                      fact: "Chocolate melts at about 34°C — just under body heat, so it melts in your mouth"),
    "wax": FMat(key: "wax", name: "candle wax", solid: "candle", liquid: "melted wax", gas: "",
                melt: 60, boil: nil, lo: 0, hi: 110, solidHex: 0xf4ead2, liquidHex: 0xe9d9a8, glows: false,
                fact: "Candle wax melts at about 60°C"),
    "tin": FMat(key: "tin", name: "tin", solid: "tin bar", liquid: "molten tin", gas: "",
                melt: 232, boil: nil, lo: 0, hi: 400, solidHex: 0xbfc4c9, liquidHex: 0xdfe4ea, glows: false,
                fact: "Tin melts at 232°C"),
    "lead": FMat(key: "lead", name: "lead", solid: "lead bar", liquid: "molten lead", gas: "",
                 melt: 327, boil: nil, lo: 0, hi: 500, solidHex: 0x8d939c, liquidHex: 0xb3b9c2, glows: false,
                 fact: "Lead melts at 327°C — Romans made water pipes from it (Latin: plumbum)"),
    "gold": FMat(key: "gold", name: "gold", solid: "gold bar", liquid: "molten gold", gas: "",
                 melt: 1064, boil: nil, lo: 0, hi: 1400, solidHex: 0xf2c230, liquidHex: 0xffd75a, glows: true,
                 fact: "Gold melts at 1064°C"),
    "iron": FMat(key: "iron", name: "iron", solid: "iron bar", liquid: "molten iron", gas: "",
                 melt: 1538, boil: nil, lo: 0, hi: 2000, solidHex: 0x6d6f75, liquidHex: 0xff9a3c, glows: true,
                 fact: "Iron melts at 1538°C — hotter than gold"),
    "rock": FMat(key: "rock", name: "rock", solid: "basalt rock", liquid: "lava", gas: "",
                 melt: 1150, boil: nil, lo: 0, hi: 1500, solidHex: 0x4a4646, liquidHex: 0xff6a1a, glows: true,
                 fact: "Rock melts at about 1000–1200°C into magma; out of a volcano it's called lava"),
]

private struct FOrder {
    var mat: FMat
    var start: FState
    var target: FState
    var startT: Double
    var say: String                // the order card's words
    var done: String               // the cheer line
}

/// One order from content tier `t`.
private func fOrder(tier t: Int, d: Double) -> FOrder {
    func m(_ k: String) -> FMat { fMats[k]! }
    switch t {
    case 0:
        let mat = Bool.random() ? fWater : m("chocolate")
        return FOrder(mat: mat, start: .solid, target: .liquid, startT: mat.key == "water" ? -12 : 14,
                      say: "Melt the \(mat.solid)!", done: mat.key == "water" ? "Ice → water!" : "Melted chocolate! 😋")
    case 1:
        switch Int.random(in: 0..<(d > 3.2 ? 4 : 3)) {
        case 0: return FOrder(mat: fWater, start: .liquid, target: .gas, startT: 20,
                              say: "Boil the water into steam!", done: "Water → steam!")
        case 1: return FOrder(mat: fWater, start: .liquid, target: .solid, startT: 18,
                              say: "Freeze the water into ice!", done: "Water → ice!")
        case 2: return FOrder(mat: m("wax"), start: .solid, target: .liquid, startT: 20,
                              say: "Melt the candle wax!", done: "Melted wax!")
        default: return FOrder(mat: fWater, start: .gas, target: .liquid, startT: 118,
                               say: "Cool the steam back into water!", done: "Steam → water drops!")
        }
    case 2:
        let k = ["tin", "lead", "gold", "iron"].randomElement()!
        let mat = m(k)
        if Bool.random() {
            return FOrder(mat: mat, start: .solid, target: .liquid, startT: 20,
                          say: "Melt the \(mat.name)!", done: "Molten \(mat.name)!")
        }
        return FOrder(mat: mat, start: .liquid, target: .solid, startT: mat.melt + mat.span * 0.08,
                      say: "Cast the \(mat.name) — cool it SOLID!", done: "A \(mat.name) bar!")
    default:
        let mat = m("rock")
        if Bool.random() {
            return FOrder(mat: mat, start: .solid, target: .liquid, startT: 25,
                          say: "Melt the rock into lava!", done: "Rock → lava! 🌋")
        }
        return FOrder(mat: mat, start: .liquid, target: .solid, startT: 1260,
                      say: "Cool the lava into rock!", done: "Lava → new rock (basalt)!")
    }
}

// MARK: Heat physics (enthalpy, in thermometer degrees)

/// The heat a material holds, with plateaus at its melting / boiling points (latent heat).
private struct FHeat {
    let mat: FMat
    var L1: Double { mat.span * 0.22 }
    var L2: Double { mat.span * 0.28 }

    func h(forT t: Double, state: FState) -> Double {
        switch state {
        case .solid: return min(t, mat.melt)
        case .liquid: return max(mat.melt, min(t, mat.boil ?? .infinity)) + L1
        case .gas: return max(t, mat.boil ?? t) + L1 + L2
        }
    }
    /// Temperature, fraction melted (0…1) and fraction boiled (0…1) for heat `h`.
    func read(_ h: Double) -> (t: Double, melted: Double, boiled: Double) {
        if h < mat.melt { return (h, 0, 0) }
        if h < mat.melt + L1 { return (mat.melt, (h - mat.melt) / L1, 0) }
        guard let b = mat.boil else { return (h - L1, 1, 0) }
        if h < b + L1 { return (h - L1, 1, 0) }
        if h < b + L1 + L2 { return (b, 1, (h - b - L1) / L2) }
        return (h - L1 - L2, 1, 1)
    }
    func state(_ h: Double) -> FState? {
        let r = read(h)
        if r.boiled >= 1 { return .gas }
        if r.melted >= 1 && r.boiled <= 0 { return .liquid }
        if r.melted <= 0 { return .solid }
        return nil      // part-way through a change
    }
    /// A comfortable heat in the middle of a state's band (for showing the answer).
    func middle(of s: FState) -> Double {
        switch s {
        case .solid: return h(forT: max(mat.lo + mat.span * 0.1, mat.melt - mat.span * 0.15), state: .solid)
        case .liquid:
            let top = mat.boil ?? mat.hi
            return h(forT: (mat.melt + min(top, mat.melt + mat.span * 0.25)) / 2, state: .liquid)
        case .gas: return h(forT: min(mat.hi - 4, (mat.boil ?? mat.hi) + 15), state: .gas)
        }
    }
    var hMin: Double { mat.lo }
    var hMax: Double { mat.hi + L1 + (mat.boil == nil ? 0 : L2) }
}

// MARK: Model

@MainActor
private final class ForgeModel: ArcadeModel {
    enum Stage { case working, done, failed }
    @Published var order = FOrder(mat: fWater, start: .solid, target: .liquid, startT: -10, say: "", done: "")
    @Published var heat: Double = -10
    @Published var flame: Double = 0          // 0…1 — how hard the fire is burning
    @Published var cooling: Double = 0        // 0…1 — the snow bucket
    @Published var hold: Double = 0           // 0…1 — the "keep it there" ring
    @Published var stage: Stage = .working
    @Published var fuel: Double? = nil        // seconds left (nil = no limit)
    @Published var line: String?              // the cheer / the lesson
    @Published var roundID = 0
    @Published var cheers = 0
    @Published var oops = 0

    var bellows = false                       // finger on the bellows
    var snow = false                          // finger on the snow bucket
    private var botGoal: Double?
    private var timer: Timer?
    private var last = Date()
    private let clock = VesRunClock()
    private var lastState: FState?
    private var dwell: Double = 1
    private var lag: Double = 0.15
    private var fuelLit = false               // the fuel burns only once the order has been said

    init() { super.init(key: GameID.forge.rawValue) }

    var physics: FHeat { FHeat(mat: order.mat) }

    /// 🔊: say the order again (the fuel keeps waiting if it hasn't started).
    func sayAgain() { LibraryVoice.say(order.say) }
    var reading: (t: Double, melted: Double, boiled: Double) { physics.read(heat) }
    /// How visible the target band on the thermometer is (1 → 0 between d 4 and 7).
    var bandAlpha: Double { ramp(1, 0, from: 4, to: 7) }
    var needsSnow: Bool { order.target.rawValue < order.start.rawValue }
    var showSnow: Bool { needsSnow || d >= 2.5 }

    override func perLevel(_ level: Int) -> Int { 5 }

    override func onBegin() {
        clock.reset()
        newOrder()
        last = Date()
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] tm in
            guard let self else { tm.invalidate(); return }
            Task { @MainActor in self.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func newOrder() {
        roundID += 1
        let t = tier([1, 2.3, 3.8, 5.3])
        var o = fOrder(tier: t, d: d)
        if o.say == order.say { o = fOrder(tier: t, d: d) }
        order = o
        heat = FHeat(mat: o.mat).h(forT: o.startT, state: o.start)
        flame = 0; cooling = 0; hold = 0; line = nil
        stage = .working
        lastState = o.start
        dwell = ramp(0.8, 2.6, to: 9)
        lag = ramp(0.15, 0.9, to: 9)
        fuel = d < 3 ? nil : ramp(45, 13, from: 3, to: 9.5)
        fuelLit = false
        let id = roundID
        LibraryVoice.say(o.say) { [weak self] in
            guard let self, self.roundID == id else { return }
            self.fuelLit = true
        }
        botGoal = nil
    }

    private func tick() {
        let now = Date()
        let dt = min(0.1, now.timeIntervalSince(last))
        last = now
        guard phase == .playing else {
            if phase == .over { timer?.invalidate(); timer = nil }
            return
        }
        // The bot holds the buttons the way a finger would.
        if let g = botGoal, stage == .working {
            bellows = heat < g - physics.mat.span * 0.02
            snow = heat > g + physics.mat.span * 0.02
        }
        // The fire and the snow follow the buttons with some lag (momentum).
        let k = dt / max(0.05, lag)
        flame += ((bellows && stage == .working ? 1 : 0) - flame) * min(1, k)
        cooling += ((snow && stage == .working ? 1 : 0) - cooling) * min(1, dt / 0.15)
        guard stage == .working else { return }
        let m = order.mat
        let span = m.span
        let t = reading.t
        let room = 20.0
        var dh = span * 0.2 * flame - span * 0.28 * cooling
        dh -= (t - room) / span * span * 0.1          // heat leaks toward room temperature
        heat = max(physics.hMin, min(physics.hMax, heat + dh * dt))
        if fuelLit, let f = fuel {
            fuel = max(0, f - dt)
            if fuel == 0 { fail("The fire went out!"); return }
        }
        // State bookkeeping.
        let s = physics.state(heat)
        if let s, s != lastState {
            lastState = s
            Sfx.play(s == .gas ? .whoosh : (s == .solid ? .thud : .pop))
            Haptics.tap(0.6)
        }
        // Overshoot: water that was wanted LIQUID boiled away or froze solid.
        if order.target == .liquid, m.boil != nil {
            if s == .gas { fail("It all boiled away!"); return }
            if s == .solid && order.start == .gas { fail("Oops — it froze!"); return }
        }
        if s == order.target {
            hold = min(1, hold + dt / dwell)
            if hold >= 1 { succeed() }
        } else {
            hold = max(0, hold - dt / (dwell * 1.5))
        }
    }

    private func succeed() {
        stage = .done
        bellows = false; snow = false
        line = order.done
        cheers += 1
        Sfx.play(.sparkle)
        hit()
        clock.after(1.0) { self.line = self.order.mat.fact }
        clock.after(2.6) { self.next() }
    }

    private func fail(_ why: String) {
        stage = .failed
        bellows = false; snow = false
        line = why
        oops += 1
        let lastHeart = miss(delay: 3.6)
        // Show the answer: bring the pot to the asked-for state, and say the fact.
        clock.after(0.9) {
            withAnimation(.easeInOut(duration: 1.0)) { self.heat = self.physics.middle(of: self.order.target) }
            self.line = self.order.mat.fact
        }
        if !lastHeart { clock.after(3.6) { self.next() } }
    }

    private func next() {
        guard phase == .playing else { return }
        withAnimation(.easeInOut(duration: 0.3)) { newOrder() }
    }

    func press(_ which: String, _ down: Bool) {
        guard phase == .playing, stage == .working else { bellows = false; snow = false; return }
        if down { fuelLit = true }
        if which == "fire" {
            if down && !bellows { Sfx.play(.whoosh, volume: 0.5) }
            bellows = down
        } else {
            if down && !snow { Sfx.play(.tick) }
            snow = down
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .working, botGoal == nil else { return }
        if correct { botGoal = physics.middle(of: order.target) }
        else {
            // A wrong plan: overshoot (or undershoot) past the target state.
            switch order.target {
            case .liquid: botGoal = order.start == .gas ? physics.hMin : physics.hMax
            case .gas: botGoal = physics.hMin
            case .solid: botGoal = physics.hMax
            }
            if order.mat.boil == nil || order.target != .liquid { fuel = min(fuel ?? 3, 3) }
        }
    }
}

// MARK: Views

struct ForgeView: View {
    let onClose: () -> Void
    @StateObject private var model = ForgeModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.forge.spec ?? GameSpec(title: "Vulcan's Forge", mechanic: "", premise: "", game: .forge),
                    accent: Lu.tangerine, onClose: onClose,
                    backdrop: { ForgeCave() }) {
            ForgePlay(model: model)
        }
    }
}

private struct ForgePlay: View {
    @ObservedObject var model: ForgeModel

    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            VStack(spacing: 10) {
                HUDSpace(50)
                orderCard
                HStack(alignment: .center, spacing: 6) {
                    ForgeThermometer(model: model)
                        .frame(width: 78)
                    ZStack {
                        Crucible(model: model)
                        VesBurst(trigger: model.cheers, emojis: ["✨", "⭐️", "🔥", "💛"], radius: 120, size: 28)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                lineView
                controls(width: W)
                    .padding(.bottom, max(8, H * 0.01))
            }
            .padding(.horizontal, 14)
        }
    }

    private var orderCard: some View {
        let o = model.order
        return HStack(spacing: 12) {
            Text(o.target.icon(o.mat)).font(.system(size: 40))
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color(hex: 0x2a1410)))
                .overlay(Circle().trim(from: 0, to: model.hold)
                    .stroke(Color(hex: Lu.gold), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90)))
            VStack(alignment: .leading, spacing: 2) {
                Text("MAKE IT \(o.target.word)").font(luFont(13, .heavy)).tracking(1.5).foregroundStyle(Color(hex: Lu.gold))
                Text(o.say).font(luSerif(21, .black)).foregroundStyle(Color(hex: 0xfff1d6))
                    .lineLimit(2).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            LibrarySpeakerButton(size: 38) { model.sayAgain() }
            if let f = model.fuel {
                VStack(spacing: 0) {
                    Text("🪵").font(.system(size: 22))
                    Text("\(Int(f.rounded(.up)))").font(luFont(16)).monospacedDigit()
                        .foregroundStyle(Color(hex: f < 5 ? Lu.coral : 0xfff1d6))
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x1c0d0a).opacity(0.82))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: 0x9c5a2a), lineWidth: 2)))
        .id(model.roundID)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    @ViewBuilder private var lineView: some View {
        ZStack {
            if let l = model.line {
                Text(l).font(luFont(17, .heavy))
                    .foregroundStyle(Color(hex: model.stage == .failed ? 0xffd27a : Lu.mint))
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .id(l)
            }
        }
        .frame(height: 52)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.line)
    }

    private func controls(width: CGFloat) -> some View {
        HStack(spacing: 14) {
            HoldButton(label: "BLOW", sub: "the bellows", art: AnyView(BellowsArt(squeeze: model.flame)),
                       tint: 0xd8622a, active: model.bellows) { model.press("fire", $0) }
            if model.showSnow {
                HoldButton(label: "COOL", sub: "snow bucket", art: AnyView(Text("❄️").font(.system(size: 40))),
                           tint: 0x4f8fc9, active: model.snow) { model.press("snow", $0) }
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 112)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.showSnow)
    }
}

/// A big press-and-hold button.
private struct HoldButton: View {
    let label: String
    let sub: String
    let art: AnyView
    let tint: UInt
    let active: Bool
    let onPress: (Bool) -> Void
    @State private var down = false

    var body: some View {
        VStack(spacing: 2) {
            art.frame(width: 64, height: 52)
            Text(label).font(luSerif(22, .black)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
            Text(sub).font(luFont(11, .bold)).foregroundStyle(.white.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 22)
            .fill(LinearGradient(colors: [luShade(tint, active ? 30 : 10), luShade(tint, active ? -10 : -50)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(active ? 0.9 : 0.35), lineWidth: active ? 3 : 2)))
        .scaleEffect(down ? 0.95 : 1)
        .shadow(color: Color(hex: tint).opacity(active ? 0.8 : 0), radius: 16)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in if !down { down = true; Haptics.tap(0.5); onPress(true) } }
            .onEnded { _ in down = false; onPress(false) })
        .animation(.easeOut(duration: 0.1), value: down)
    }
}

/// A leather bellows that squeezes as the fire is blown.
private struct BellowsArt: View {
    let squeeze: Double
    var body: some View {
        ZStack {
            // nozzle
            Capsule().fill(Color(hex: 0x9a9aa2)).frame(width: 26, height: 8).offset(x: 26)
            // leather body
            Ellipse().fill(Color(hex: 0x8a4a22))
                .frame(width: 46, height: 46 - squeeze * 18)
            Ellipse().stroke(Color(hex: 0x4a220e), lineWidth: 2)
                .frame(width: 46, height: 46 - squeeze * 18)
            // wooden boards
            Capsule().fill(Color(hex: 0xc58b4e)).frame(width: 50, height: 7).offset(y: -(23 - squeeze * 9))
            Capsule().fill(Color(hex: 0xc58b4e)).frame(width: 50, height: 7).offset(y: 23 - squeeze * 9)
        }
    }
}

/// The thermometer: range labels, the material's melting / boiling marks, the target band.
private struct ForgeThermometer: View {
    @ObservedObject var model: ForgeModel
    var body: some View {
        GeometryReader { g in
            let H = g.size.height
            let m = model.order.mat
            let top: CGFloat = 14, bottom: CGFloat = 40
            let tubeH = max(40, H - top - bottom)
            let y: (Double) -> CGFloat = { v in top + tubeH * CGFloat(1 - (v - m.lo) / m.span) }
            let t = model.reading.t
            let band: (Double, Double) = {
                switch model.order.target {
                case .solid: return (m.lo, m.melt)
                case .liquid: return (m.melt, m.boil ?? m.hi)
                case .gas: return (m.boil ?? m.hi, m.hi)
                }
            }()
            let showBand = model.stage == .failed ? 1 : model.bandAlpha
            ZStack(alignment: .topLeading) {
                // target band
                Rectangle().fill(Color(hex: 0x7be07f).opacity(0.45 * showBand))
                    .frame(width: 34, height: max(0, y(band.0) - y(band.1)))
                    .position(x: 22, y: (y(band.0) + y(band.1)) / 2)
                // tube
                Capsule().fill(Color.white.opacity(0.9)).frame(width: 18, height: tubeH + 10).position(x: 22, y: top + tubeH / 2)
                Capsule().fill(Color(hex: 0xd8352a))
                    .frame(width: 9, height: max(6, y(m.lo) - y(max(m.lo, t)) + 6))
                    .position(x: 22, y: (y(max(m.lo, t)) + y(m.lo)) / 2 + 2)
                Circle().fill(Color(hex: 0xd8352a)).frame(width: 28, height: 28).position(x: 22, y: top + tubeH + 14)
                // marks
                ForEach(marks(m), id: \.self) { v in
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.white.opacity(0.8)).frame(width: 8, height: 2)
                        Text("\(Int(v))°").font(luFont(11, .heavy)).foregroundStyle(Color.white.opacity(0.85))
                            .fixedSize()
                    }
                    .position(x: 52, y: y(v))
                }
                // reading
                Text("\(Int(t.rounded()))°C").font(luFont(15)).monospacedDigit().foregroundStyle(Color(hex: 0xfff1d6))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(width: 74)
                    .position(x: 37, y: H - 6)
            }
        }
    }

    private func marks(_ m: FMat) -> [Double] {
        var v: [Double] = [m.melt]
        if let b = m.boil { v.append(b) }
        let step = m.span > 1000 ? 500.0 : (m.span > 300 ? 100.0 : (m.span > 100 ? 50 : 20))
        var x = (m.lo / step).rounded(.up) * step
        while x <= m.hi {
            if v.allSatisfy({ abs($0 - x) > m.span * 0.11 }) { v.append(x) }
            x += step
        }
        return v
    }
}

/// The crucible on its fire, with the material inside in whatever state it's in.
private struct Crucible: View {
    @ObservedObject var model: ForgeModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: model.phase != .playing)) { tl in
            let time = tl.date.timeIntervalSinceReferenceDate
            GeometryReader { g in
                let W = g.size.width, H = g.size.height
                let potW = min(W * 0.84, 250), potH = potW * 0.6
                let rimY = H * 0.36
                let potBottom = rimY + potH
                let m = model.order.mat
                let r = model.reading
                let heatGlow = m.glows ? max(0, min(1, (r.t - m.lo - m.span * 0.35) / (m.span * 0.4))) : 0
                let liquid = r.melted * (1 - r.boiled)
                let liquidColor = blend(m.liquidHex, 0xff7a1a, heatGlow * 0.5)
                let flameH = 46 + 110 * model.flame
                ZStack {
                    // flames lick up under the pot
                    Flames(power: model.flame, time: time)
                        .frame(width: potW * 0.95, height: flameH)
                        .position(x: W / 2, y: potBottom + 40 - flameH / 2)
                    // fire-pit stones
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { i in
                            Ellipse().fill(Color(hex: i % 2 == 0 ? 0x5a4c46 : 0x463a35)).frame(width: potW / 7.4, height: 24)
                        }
                    }
                    .position(x: W / 2, y: potBottom + 46)
                    // the pot's open mouth (dark inside, or the liquid's surface)
                    Ellipse().fill(Color(hex: 0x2a120a)).frame(width: potW - 6, height: 52).position(x: W / 2, y: rimY)
                    if liquid > 0.01 {
                        Ellipse().fill(LinearGradient(colors: [luShade(m.liquidHex, 45), liquidColor], startPoint: .top, endPoint: .bottom))
                            .overlay(Ellipse().stroke(Color.white.opacity(0.35), lineWidth: 2).padding(6))
                            .frame(width: (potW - 16) * CGFloat(0.6 + 0.4 * liquid), height: 42 * CGFloat(0.6 + 0.4 * liquid))
                            .overlay(bubbles(m: m, r: r, time: time, glow: heatGlow).offset(y: -6))
                            .shadow(color: heatGlow > 0.2 ? Color.orange.opacity(heatGlow) : .clear, radius: 14)
                            .position(x: W / 2, y: rimY + 2 + CGFloat(1 - liquid) * 8)
                    }
                    // the solid, sitting in the pot (its bottom hidden by the pot's front)
                    if r.melted < 0.99 {
                        SolidLump(mat: m, glow: heatGlow)
                            .frame(width: potW * 0.5, height: potH * 0.8)
                            .scaleEffect(CGFloat(0.25 + 0.75 * (1 - r.melted)), anchor: .bottom)
                            .position(x: W / 2, y: rimY + 14 - potH * 0.8 / 2)
                    }
                    // snow from the bucket
                    if model.cooling > 0.05 {
                        Canvas { c, size in
                            for i in 0..<26 {
                                let x = Double((i * 53) % 100) / 100 * size.width
                                let y = (time * 160 + Double(i * 29)).truncatingRemainder(dividingBy: size.height)
                                c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 7, height: 7)), with: .color(.white.opacity(0.95 * model.cooling)))
                            }
                        }
                        .frame(width: potW, height: rimY)
                        .position(x: W / 2, y: rimY / 2)
                    }
                    // the pot's front
                    PotShape(rim: 27).fill(LinearGradient(colors: [Color(hex: 0xb8643a), Color(hex: 0x7a3a1c), Color(hex: 0x4e220e)], startPoint: .top, endPoint: .bottom))
                        .overlay(PotShape(rim: 27).stroke(Color(hex: 0x3a1808), lineWidth: 2))
                        .overlay(Rectangle().fill(Color(hex: 0xe0a83e).opacity(0.75)).frame(width: potW * 0.86, height: 5).offset(y: -potH * 0.22))
                        .overlay(Rectangle().fill(Color(hex: 0xe0a83e).opacity(0.5)).frame(width: potW * 0.8, height: 2).offset(y: -potH * 0.12))
                        .frame(width: potW, height: potH)
                        .shadow(color: Color.orange.opacity(0.35 * model.flame), radius: 18, y: 10)
                        .position(x: W / 2, y: rimY + potH / 2)
                    // rim
                    Ellipse().stroke(Color(hex: 0xd27848), lineWidth: 7).frame(width: potW + 4, height: 54)
                        .position(x: W / 2, y: rimY)
                    // Sal the fire salamander, Vulcan's helper, watching from the hearth
                    Salamander(mood: model.stage == .done ? .cheer : (model.stage == .failed ? .worried : (model.flame > 0.6 ? .hot : .idle)),
                               time: time)
                        .frame(width: 96, height: 64)
                        .position(x: min(W - 50, W / 2 + potW * 0.42), y: potBottom + 92)
                    // steam
                    if m.boil != nil {
                        let steam = max(r.boiled, r.t > 70 ? (r.t - 70) / 60 : 0, model.order.start == .gas && r.boiled > 0 ? 1 : 0)
                        ForEach(0..<7, id: \.self) { i in
                            let k = (time * 0.5 + Double(i) / 7).truncatingRemainder(dividingBy: 1)
                            Circle().fill(Color.white.opacity(0.65 * (1 - k) * min(1, steam)))
                                .frame(width: 30 + 60 * k, height: 30 + 60 * k)
                                .position(x: W / 2 + CGFloat(sin(time * 1.3 + Double(i) * 2)) * 34, y: rimY - 14 - CGFloat(k) * rimY * 0.95)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bubbles(m: FMat, r: (t: Double, melted: Double, boiled: Double), time: Double, glow: Double) -> some View {
        if (m.boil.map { r.t > $0 - 25 } ?? (glow > 0.6)) {
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { i in
                    Circle().stroke(Color.white.opacity(0.7), lineWidth: 2)
                        .frame(width: 6 + CGFloat((Int(time * 7) + i * 2) % 4) * 3)
                }
            }
        }
    }

    private func blend(_ a: UInt, _ b: UInt, _ t: Double) -> Color {
        func c(_ x: UInt, _ s: UInt) -> Double { Double((x >> s) & 0xff) / 255 }
        let k = max(0, min(1, t))
        return Color(red: c(a, 16) * (1 - k) + c(b, 16) * k, green: c(a, 8) * (1 - k) + c(b, 8) * k, blue: c(a, 0) * (1 - k) + c(b, 0) * k)
    }
}

/// What a solid looks like: an ice cube, a chocolate bar, a candle, an ingot or a lump of basalt.
private struct SolidLump: View {
    let mat: FMat
    let glow: Double
    var body: some View {
        let base = Color(hex: mat.solidHex)
        ZStack {
            switch mat.key {
            case "water":
                RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [.white, base, Color(hex: 0x8fd0f5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 2))
                    .overlay(alignment: .topLeading) { Capsule().fill(.white.opacity(0.9)).frame(width: 30, height: 7).rotationEffect(.degrees(-30)).padding(10) }
                    .aspectRatio(1, contentMode: .fit)
            case "chocolate":
                RoundedRectangle(cornerRadius: 6).fill(base)
                    .overlay(GridLines().stroke(Color(hex: 0x4a2612), lineWidth: 3))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0x4a2612), lineWidth: 2))
                    .aspectRatio(0.8, contentMode: .fit)
            case "wax":
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 8).fill(base).frame(width: 46)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xc9b98a), lineWidth: 2))
                    Capsule().fill(Color(hex: 0x3a2a1a)).frame(width: 3, height: 12).offset(y: -10)
                }
            case "rock":
                RockShape().fill(LinearGradient(colors: [luShade(mat.solidHex, 30), base], startPoint: .top, endPoint: .bottom))
                    .overlay(RockShape().stroke(Color(hex: 0x2a2626), lineWidth: 2))
                    .overlay(RockCracks().stroke(Color(hex: 0xff7a1a).opacity(glow), lineWidth: 3))
            default:   // metal ingot
                IngotShape().fill(LinearGradient(colors: [luShade(mat.solidHex, 50), base, luShade(mat.solidHex, -40)], startPoint: .top, endPoint: .bottom))
                    .overlay(IngotShape().stroke(luShade(mat.solidHex, -70), lineWidth: 2))
                    .overlay(IngotShape().fill(Color(hex: 0xff5a1a).opacity(glow * 0.6)))
                    .frame(maxHeight: 64)
                    .shadow(color: Color.orange.opacity(glow), radius: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

private struct GridLines: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            for i in 1..<4 { let x = r.minX + r.width * CGFloat(i) / 4; p.move(to: CGPoint(x: x, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY)) }
            p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        }
    }
}

private struct IngotShape: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX + r.width * 0.14, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.14, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
    }
}

private struct RockShape: Shape {
    func path(in r: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [(0.05, 1), (0, 0.6), (0.15, 0.25), (0.42, 0.05), (0.7, 0.12), (0.92, 0.35), (1, 0.75), (0.9, 1)]
        return Path { p in
            p.move(to: CGPoint(x: r.minX + r.width * pts[0].0, y: r.minY + r.height * pts[0].1))
            for q in pts.dropFirst() { p.addLine(to: CGPoint(x: r.minX + r.width * q.0, y: r.minY + r.height * q.1)) }
            p.closeSubpath()
        }
    }
}

private struct RockCracks: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.3))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.45, y: r.minY + r.height * 0.6))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.4, y: r.minY + r.height * 0.9))
            p.move(to: CGPoint(x: r.minX + r.width * 0.45, y: r.minY + r.height * 0.6))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.75, y: r.minY + r.height * 0.55))
        }
    }
}

/// A round-bellied clay crucible (open at the top). Its top edge is the NEAR half of the rim
/// ellipse (`rim` = the ellipse's half-height), so the mouth and whatever is in it show whole.
private struct PotShape: Shape {
    var rim: CGFloat = 0
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.minY + rim * 2))
            p.addCurve(to: CGPoint(x: r.midX + r.width * 0.25, y: r.maxY),
                       control1: CGPoint(x: r.maxX + r.width * 0.02, y: r.minY + r.height * 0.6),
                       control2: CGPoint(x: r.maxX - r.width * 0.1, y: r.maxY))
            p.addLine(to: CGPoint(x: r.midX - r.width * 0.25, y: r.maxY))
            p.addCurve(to: CGPoint(x: r.minX, y: r.minY),
                       control1: CGPoint(x: r.minX + r.width * 0.1, y: r.maxY),
                       control2: CGPoint(x: r.minX - r.width * 0.02, y: r.minY + r.height * 0.6))
            p.closeSubpath()
        }
    }
}

/// Sal: a black-and-yellow fire salamander (the Romans thought salamanders could live in fire).
private struct Salamander: View {
    enum Mood { case idle, hot, cheer, worried }
    let mood: Mood
    let time: Double
    var body: some View {
        let hop = mood == .cheer ? abs(sin(time * 9)) * 12 : 0
        let blink = mood == .idle && (time.truncatingRemainder(dividingBy: 3.2)) < 0.12
        ZStack {
            // tail
            Path { p in
                p.move(to: CGPoint(x: 30, y: 40))
                p.addQuadCurve(to: CGPoint(x: 2, y: 30 + sin(time * 3) * 6), control: CGPoint(x: 8, y: 52))
            }
            .stroke(Color(hex: 0x1c1a1a), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            // legs
            ForEach([28.0, 58.0], id: \.self) { x in
                Capsule().fill(Color(hex: 0x1c1a1a)).frame(width: 7, height: 14).position(x: x, y: 52)
                Capsule().fill(Color(hex: 0x1c1a1a)).frame(width: 7, height: 14).position(x: x + 8, y: 52)
            }
            // body
            Ellipse().fill(Color(hex: 0x1c1a1a)).frame(width: 56, height: 26).position(x: 46, y: 40)
            ForEach(0..<4, id: \.self) { i in
                Ellipse().fill(Color(hex: 0xf5c518)).frame(width: 10, height: 7)
                    .position(x: 30 + CGFloat(i) * 11, y: i % 2 == 0 ? 34 : 44)
            }
            // head
            Ellipse().fill(Color(hex: 0x1c1a1a)).frame(width: 34, height: 28).position(x: 78, y: 32)
            Ellipse().fill(Color(hex: 0xf5c518)).frame(width: 10, height: 8).position(x: 72, y: 22)
            // eyes
            ForEach([72.0, 86.0], id: \.self) { x in
                ZStack {
                    Circle().fill(.white).frame(width: mood == .worried ? 13 : 11)
                    if !blink { Circle().fill(.black).frame(width: 5).offset(x: 1, y: mood == .worried ? -1 : 1) }
                }
                .frame(width: 12, height: blink ? 2 : 12).clipped()
                .position(x: x, y: 26)
            }
            // mouth
            Group {
                switch mood {
                case .cheer:
                    Ellipse().fill(Color(hex: 0xe05a5a)).frame(width: 12, height: 8)
                case .worried:
                    Capsule().fill(Color(hex: 0xe05a5a)).frame(width: 8, height: 4)
                case .hot:
                    Capsule().fill(Color(hex: 0xe05a5a)).frame(width: 10, height: 6).overlay(Capsule().fill(Color(hex: 0xff8a8a)).frame(width: 4, height: 6).offset(y: 3))
                case .idle:
                    Capsule().fill(Color(hex: 0xe05a5a)).frame(width: 12, height: 3)
                }
            }
            .position(x: 82, y: 39)
            if mood == .cheer { Text("✨").font(.system(size: 16)).position(x: 92, y: 6) }
            if mood == .worried { Text("💦").font(.system(size: 14)).position(x: 96, y: 12) }
        }
        .frame(width: 96, height: 64)
        .offset(y: -hop)
    }
}

/// Flickering flames; `power` 0…1 (a few embers at 0).
private struct Flames: View {
    let power: Double
    let time: Double
    var body: some View {
        Canvas { c, size in
            let n = 7
            for i in 0..<n {
                let fx = (Double(i) + 0.5) / Double(n)
                let flick = 0.75 + 0.25 * sin(time * (9 + Double(i)) + Double(i) * 1.7)
                let h = size.height * (0.25 + 0.75 * power) * flick * (1 - abs(fx - 0.5) * 0.9)
                let w = size.width / Double(n) * 1.5
                let x = size.width * fx
                let base = size.height
                var p = Path()
                p.move(to: CGPoint(x: x - w / 2, y: base))
                p.addQuadCurve(to: CGPoint(x: x + sin(time * 5 + Double(i)) * 4, y: base - h), control: CGPoint(x: x - w * 0.55, y: base - h * 0.5))
                p.addQuadCurve(to: CGPoint(x: x + w / 2, y: base), control: CGPoint(x: x + w * 0.55, y: base - h * 0.5))
                c.fill(p, with: .linearGradient(Gradient(colors: [Color(hex: 0xffe27a), Color(hex: 0xff8a1e), Color(hex: 0xd8341a).opacity(0.7)]),
                                                startPoint: CGPoint(x: x, y: base), endPoint: CGPoint(x: x, y: base - h)))
            }
            // embers
            for i in 0..<5 {
                let x = size.width * (0.15 + 0.7 * Double(i) / 4)
                c.fill(Path(ellipseIn: CGRect(x: x - 9, y: size.height - 10, width: 18, height: 10)),
                       with: .color(Color(hex: 0xff5a1a).opacity(0.6 + 0.3 * sin(time * 3 + Double(i)))))
            }
        }
    }
}

/// Vulcan's forge, deep in the volcano: dark basalt walls, glowing magma cracks, drifting embers.
private struct ForgeCave: View {
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x1a0e0c), Color(hex: 0x2e1712), Color(hex: 0x40160c)], startPoint: .top, endPoint: .bottom)
                // cave wall slabs
                ForEach(0..<7, id: \.self) { i in
                    let fx = CGFloat(i) / 6
                    RockShape().fill(Color(hex: i % 2 == 0 ? 0x2a1915 : 0x231410))
                        .frame(width: W * 0.42, height: H * 0.22)
                        .position(x: W * fx, y: H * (i % 2 == 0 ? 0.08 : 0.16))
                }
                // magma river at the bottom
                RadialGradient(colors: [Color(hex: 0xff7a1a).opacity(0.75), .clear], center: .bottom, startRadius: 0, endRadius: H * 0.4)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: H * 0.93))
                    p.addCurve(to: CGPoint(x: W, y: H * 0.9), control1: CGPoint(x: W * 0.3, y: H * 0.87), control2: CGPoint(x: W * 0.7, y: H * 0.97))
                    p.addLine(to: CGPoint(x: W, y: H)); p.addLine(to: CGPoint(x: 0, y: H)); p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color(hex: 0xffb347), Color(hex: 0xe8481a)], startPoint: .top, endPoint: .bottom))
                // glowing cracks up the walls
                Path { p in
                    p.move(to: CGPoint(x: W * 0.06, y: H * 0.9)); p.addLine(to: CGPoint(x: W * 0.1, y: H * 0.7)); p.addLine(to: CGPoint(x: W * 0.04, y: H * 0.52))
                    p.move(to: CGPoint(x: W * 0.95, y: H * 0.88)); p.addLine(to: CGPoint(x: W * 0.9, y: H * 0.66)); p.addLine(to: CGPoint(x: W * 0.97, y: H * 0.45))
                }
                .stroke(Color(hex: 0xff6a1a).opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .shadow(color: .orange, radius: 6)
                // embers drifting up
                TimelineView(.animation(minimumInterval: 1.0 / 20)) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    Canvas { c, size in
                        for i in 0..<18 {
                            let k = (t * (0.05 + Double(i % 4) * 0.015) + Double(i) * 0.137).truncatingRemainder(dividingBy: 1)
                            let x = (Double((i * 67) % 100) / 100 + sin(t * 0.7 + Double(i)) * 0.02) * size.width
                            let y = size.height * (1 - k)
                            c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 4)),
                                   with: .color(Color(hex: 0xffa040).opacity(0.8 * (1 - k))))
                        }
                    }
                }
                // anvil silhouette
                AnvilShape().fill(Color(hex: 0x120908)).frame(width: 90, height: 50).position(x: W * 0.86, y: H * 0.86)
            }
        }
    }
}

private struct AnvilShape: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.1, y: r.minY + r.height * 0.3))
            p.addLine(to: CGPoint(x: r.midX + r.width * 0.12, y: r.minY + r.height * 0.4))
            p.addLine(to: CGPoint(x: r.midX + r.width * 0.25, y: r.maxY))
            p.addLine(to: CGPoint(x: r.midX - r.width * 0.25, y: r.maxY))
            p.addLine(to: CGPoint(x: r.midX - r.width * 0.12, y: r.minY + r.height * 0.4))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + r.height * 0.3))
            p.closeSubpath()
        }
    }
}
