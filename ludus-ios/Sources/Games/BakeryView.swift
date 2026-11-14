import SwiftUI

// MARK: - Ursa's Bakery (Market · Life skills) — measuring and recipes
//
// Ursa the baker bear reads out each step of her recipe. Press and HOLD the pour button: the
// flour (or milk, or honey…) streams into the glass measuring cup — slowly at first, then faster
// the longer you hold — and let go at the right line. Tap "Into the bowl!" to check. Pour past
// the top and it spills. A miss shows the line you needed.
//
// Difficulty (continuous, `d`): fill to the star (I) → ½ and 1 cup with labelled marks → ¼ ½ ¾
// → a 2-cup jug (1½, 1¼…) → the labels fade (just tick marks) → thirds (⅓, ⅔, 1⅓) → scaling a
// recipe (double ¾ = 1½, half of 1 = ½) → harder scaling (double ⅔, half of 1½, 1½ × 1 cup).
// The pour speeds up and the band you must hit narrows; from d≈5 Ursa's oven timer ticks.
//
// Amounts are kept in twelfths of a cup, so quarters (3/12) and thirds (4/12) share one ruler.

/// "¾ cup", "1½ cups", "2 cups", "⅓ cup".
func bkCups(_ twelfths: Int) -> String {
    let w = twelfths / 12, r = twelfths % 12
    let frac = [0: "", 3: "¼", 4: "⅓", 6: "½", 8: "⅔", 9: "¾"][r] ?? "?"
    let num = w == 0 ? frac : "\(w)\(frac)"
    return num + (twelfths <= 12 ? " cup" : " cups")
}

private struct BKIngredient {
    let name: String, color: UInt, liquid: Bool, speed: Double, holder: String
}
private let bkIngredients: [BKIngredient] = [
    .init(name: "flour", color: 0xf6f1e6, liquid: false, speed: 1.0, holder: "sack"),
    .init(name: "sugar", color: 0xfdfbf6, liquid: false, speed: 1.0, holder: "sack"),
    .init(name: "oats", color: 0xd9c08e, liquid: false, speed: 0.95, holder: "sack"),
    .init(name: "milk", color: 0xfafafa, liquid: true, speed: 1.15, holder: "bottle"),
    .init(name: "water", color: 0x8fd0f2, liquid: true, speed: 1.2, holder: "bottle"),
    .init(name: "honey", color: 0xf0a92e, liquid: true, speed: 0.7, holder: "jar"),
]
private let bkBakes = ["🥧", "🍪", "🧁", "🍞", "🥐", "🎂", "🥞", "🍩"]

struct BKTask {
    var ingredient: Int
    var target: Int               // twelfths of a cup
    var capacity: Int             // 12 or 24
    var grid: Int                 // 3 = quarters, 4 = thirds (twelfths per mark)
    var labels = true             // the marks carry their fractions
    var star = false              // Gradus I: a star marks the line
    var line = ""                 // the recipe step as written
    var say = ""
    var why = ""                  // the working, shown on a miss
}

@MainActor
private func bkTask(_ m: ArcadeModel) -> BKTask {
    let ing = Int.random(in: 0..<bkIngredients.count)
    let nm = bkIngredients[ing].name
    let labels = !m.chance(1, from: 5, to: 7.5)
    switch m.tier([1, 2, 3, 4.2, 5.4, 6.5, 7.8, 9]) {
    case 0:
        let t = [6, 9, 12, 3].randomElement()!
        return BKTask(ingredient: ing, target: t, capacity: 12, grid: 3, labels: false, star: true,
                      line: "Fill the cup to the ⭐️", say: "Pour the \(nm) up to the star!", why: "Up to the star!")
    case 1:
        let t = [6, 12].randomElement()!
        return BKTask(ingredient: ing, target: t, capacity: 12, grid: 3, labels: true,
                      line: "\(bkCups(t)) of \(nm)", say: "\(bkCups(t)) of \(nm), please!", why: "\(bkCups(t)) is this line")
    case 2:
        let t = [3, 6, 9].randomElement()!
        return BKTask(ingredient: ing, target: t, capacity: 12, grid: 3, labels: true,
                      line: "\(bkCups(t)) of \(nm)", say: "\(bkCups(t)) of \(nm), please!", why: "\(bkCups(t)) is this line")
    case 3:
        let t = [15, 18, 21, 24, 9].randomElement()!
        return BKTask(ingredient: ing, target: t, capacity: 24, grid: 3, labels: true,
                      line: "\(bkCups(t)) of \(nm)", say: "\(bkCups(t)) of \(nm), please!", why: "\(bkCups(t)) is this line")
    case 4:
        let t = 3 * Int.random(in: 1...8)
        return BKTask(ingredient: ing, target: t, capacity: 24, grid: 3, labels: labels && m.d < 6,
                      line: "\(bkCups(t)) of \(nm)", say: "\(bkCups(t)) of \(nm).", why: "\(bkCups(t)) is this line")
    case 5:
        let t = [4, 8, 16, 20, 12].randomElement()!
        return BKTask(ingredient: ing, target: t, capacity: 24, grid: 4, labels: labels,
                      line: "\(bkCups(t)) of \(nm)", say: "\(bkCups(t)) of \(nm).", why: "\(bkCups(t)) — count the thirds")
    case 6:
        // Scale a recipe: double or half (quarters).
        let opts: [(Int, Int, Int, String, String)] = [    // base, numerator, denominator, wording
            (9, 2, 1, "for 4 people", "Bake for 8!"), (6, 2, 1, "for 2 people", "Bake for 4!"),
            (12, 1, 2, "for 6 people", "Bake for 3!"), (3, 2, 1, "for 1 batch", "Make 2 batches!"),
            (6, 3, 1, "for 1 batch", "Make 3 batches!"), (18, 1, 2, "for 8 people", "Bake for 4!"),
            (24, 1, 2, "for 2 cakes", "Make just 1 cake!"),
        ]
        let o = opts.randomElement()!
        let t = o.0 * o.1 / o.2
        return BKTask(ingredient: ing, target: t, capacity: 24, grid: 3, labels: labels,
                      line: "Recipe \(o.3): \(bkCups(o.0)) of \(nm). \(o.4)", say: "The recipe \(o.3) needs \(bkCups(o.0)) of \(nm). \(o.4)",
                      why: o.2 == 2 ? "Half of \(bkCups(o.0)) = \(bkCups(t))" : "\(o.1) × \(bkCups(o.0)) = \(bkCups(t))")
    default:
        let opts: [(Int, Int, Int, String, Int)] = [      // base, ×num, ÷den, wording, grid
            (8, 2, 1, "Double it!", 4), (4, 4, 1, "Make 4 batches!", 4), (16, 1, 2, "Make half!", 4),
            (18, 1, 2, "Make half!", 3), (12, 3, 2, "Make 1½ batches!", 3), (8, 3, 2, "Make 1½ batches!", 4),
            (6, 3, 2, "Make 1½ batches!", 3), (4, 3, 1, "Triple it!", 4), (9, 2, 1, "Double it!", 3),
        ]
        let o = opts.randomElement()!
        let t = o.0 * o.1 / o.2
        let factor = o.2 == 2 && o.1 == 1 ? "½ ×" : o.2 == 2 ? "1½ ×" : "\(o.1) ×"
        return BKTask(ingredient: ing, target: t, capacity: 24, grid: o.4, labels: labels && m.d < 9,
                      line: "Recipe: \(bkCups(o.0)) of \(nm). \(o.3)", say: "The recipe needs \(bkCups(o.0)) of \(nm). \(o.3)",
                      why: "\(factor) \(bkCups(o.0)) = \(bkCups(t))")
    }
}

// MARK: - Model

@MainActor
private final class BakeryModel: ArcadeModel {
    enum Stage { case pouring, done }
    enum Mood { case calm, watching, happy, oops }
    @Published var task = BKTask(ingredient: 0, target: 6, capacity: 12, grid: 3, star: true)
    @Published var fill: Double = 0             // twelfths
    @Published var holding = false
    @Published var stage: Stage = .pouring
    @Published var mood: Mood = .calm
    @Published var right: Bool?
    @Published var spilled = false
    @Published var serial = 0
    @Published var bakes: [String] = []
    @Published var deadline: Date?
    @Published var patience: Double = 0
    private var holdStart: Date?
    private var lastTick: Date?
    private var timer: Timer?

    init() { super.init(key: GameID.bakery.rawValue) }
    override func perLevel(_ level: Int) -> Int { level == 1 ? 4 : 5 }

    /// Half-width of the band that counts, in twelfths: generous at first, tight later.
    var tolerance: Double { task.star ? 1.1 : ramp(0.9, 0.45, from: 2, to: 9) }
    /// Pour speed in twelfths per second at full flow.
    var speed: Double { ramp(4.5, 9, to: 9) * bkIngredients[task.ingredient].speed }

    override func onBegin() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFTEST"] != nil { selfTest() }
        #endif
        bakes = []
        next()
    }

    func next() {
        task = bkTask(self)
        fill = 0; holding = false; stage = .pouring; mood = .calm; right = nil; spilled = false
        serial += 1
        patience = d < 5 ? 0 : ramp(40, 18, from: 5, to: 10)
        deadline = patience > 0 ? Date().addingTimeInterval(patience) : nil
        if d < 7 { LibraryVoice.say(task.say) }
        let s = serial
        if patience > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + patience) { [weak self] in
                guard let self, self.serial == s, self.stage == .pouring, self.phase == .playing else { return }
                self.stopPour(); self.check(timeUp: true)
            }
        }
    }

    func sayAgain() { LibraryVoice.say(task.say) }

    func startPour() {
        guard phase == .playing, stage == .pouring, !holding else { return }
        holding = true; mood = .watching
        holdStart = Date(); lastTick = Date()
        Sfx.play(.whoosh, volume: 0.5)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stopPour() {
        holding = false
        timer?.invalidate(); timer = nil
        if stage == .pouring { mood = .calm }
    }

    private func tick() {
        guard holding, stage == .pouring, phase == .playing, let h = holdStart, let l = lastTick else { stopPour(); return }
        let now = Date()
        let held = now.timeIntervalSince(h), dt = now.timeIntervalSince(l)
        lastTick = now
        // Starts as a trickle and opens up over about half a second.
        pour(speed * min(1, 0.25 + held * 1.5) * dt)
    }

    /// Adds `amount` twelfths (the hold timer and the bot both come through here).
    func pour(_ amount: Double) {
        guard stage == .pouring else { return }
        fill += amount
        if fill > Double(task.capacity) + 0.4 {
            fill = Double(task.capacity) + 0.4
            spilled = true
            stopPour()
            check(timeUp: false)
        }
    }

    func check(timeUp: Bool = false) {
        guard phase == .playing, stage == .pouring else { return }
        stopPour()
        if fill <= 0.05 && !timeUp { return }
        stage = .done; deadline = nil
        let ok = !spilled && abs(fill - Double(task.target)) <= tolerance
        right = ok
        if ok {
            mood = .happy
            bakes.append(bkBakes.randomElement()!)
            Sfx.play(.sparkle, volume: 0.6)
            hit()
        } else {
            mood = .oops
            miss(delay: 2.8)
        }
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + (ok ? 1.4 : 3.1)) { [weak self] in
            guard let self, self.serial == s, self.phase == .playing, !self.dying else { return }
            self.next()
        }
    }

    private var botSerial = -1, botGood = true
    override func botAct(correct: Bool) {
        guard stage == .pouring else { return }
        if botSerial != serial { botSerial = serial; botGood = correct }
        let goal = Double(task.target) + (botGood ? 0 : (Bool.random() ? 1 : -1) * (tolerance + Double(task.grid) * 0.6))
        let left = goal - fill
        if abs(left) < 0.05 || left < 0 { check(); return }
        pour(min(left, Double(task.capacity) * 0.6))
    }

    #if DEBUG
    private func selfTest() {
        var errs: [String] = []
        marketSweep(self) {
            let t = bkTask(self)
            if t.target <= 0 || t.target > t.capacity { errs.append("target \(t.target)/\(t.capacity)") }
            if t.target % t.grid != 0 { errs.append("off-grid \(t.target) grid \(t.grid) \(t.line)") }
            if bkCups(t.target).contains("?") { errs.append("fmt \(t.target)") }
        }
        marketLog("BAKERY SELFTEST: \(errs.isEmpty ? "OK" : "\(errs.count) errors \(Array(Set(errs)).prefix(8))")")
    }
    #endif
}

// MARK: - Scene

/// A warm kitchen: blue-and-white tiles, a shelf of jars, a wooden worktop.
private struct BKKitchen: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                Color(hex: 0xf3e6cc)
                // Tiles
                VStack(spacing: 0) {
                    ForEach(0..<Int(h * 0.75 / 34) + 1, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<Int(w / 34) + 1, id: \.self) { c in
                                Rectangle().fill(Color(hex: (r + c) % 2 == 0 ? 0xf7efe0 : 0xdbe8f0))
                                    .frame(width: 34, height: 34)
                                    .overlay(Rectangle().stroke(Color(hex: 0xc9d6dc), lineWidth: 1))
                            }
                        }
                    }
                }
                // Shelf with jars
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(0..<4, id: \.self) { i in
                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 3).fill(Color(hex: [0xc0703f, 0x6aa36f, 0xd9a33a, 0x8a6bb0][i])).frame(width: 22, height: 8)
                                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.65))
                                    .overlay(RoundedRectangle(cornerRadius: 6).fill(Color(hex: [0xe8c48e, 0xb35a3a, 0xf3d36b, 0x6b3a2a][i])).padding(4).padding(.top, 10))
                                    .frame(width: 30, height: CGFloat([40, 34, 44, 30][i]))
                            }
                        }
                    }
                    Rectangle().fill(Color(hex: 0x8d5a2e)).frame(width: 190, height: 9)
                }
                .position(x: w - 110, y: h * 0.36)
                // Worktop
                VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient(colors: [Color(hex: 0xc48b55), Color(hex: 0x9a6334)], startPoint: .top, endPoint: .bottom)).frame(height: 18)
                    Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7a4b25), Color(hex: 0x4e2e15)], startPoint: .top, endPoint: .bottom))
                }
                .frame(height: h * 0.25)
                .offset(y: h * 0.75)
            }
        }
    }
}

/// Ursa: a round brown bear in a baker's hat and apron. `mood` drives her face.
private struct UrsaBear: View {
    let mood: BakeryModel.Mood
    @State private var blink = false
    private let fur = [Color(hex: 0xb07a4a), Color(hex: 0x7a4f2a)]
    var body: some View {
        ZStack {
            // Body + apron
            Ellipse().fill(LinearGradient(colors: fur, startPoint: .top, endPoint: .bottom)).frame(width: 120, height: 92).offset(y: 70)
            RoundedRectangle(cornerRadius: 14).fill(Color.white).frame(width: 64, height: 66).offset(y: 74)
                .overlay(Text("U").font(luSerif(22, .black)).foregroundStyle(Color(hex: Lu.coral)).offset(y: 74))
            // Ears
            ForEach([-1.0, 1.0], id: \.self) { s in
                Circle().fill(fur[1]).frame(width: 34).offset(x: 40 * s, y: -32)
                Circle().fill(Color(hex: 0xe6b98c)).frame(width: 16).offset(x: 40 * s, y: -32)
            }
            // Head
            Circle().fill(RadialGradient(colors: fur, center: UnitPoint(x: 0.4, y: 0.35), startRadius: 2, endRadius: 60)).frame(width: 106)
            // Hat
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(Color.white).frame(width: 70, height: 20).offset(y: 18)
                Circle().fill(Color.white).frame(width: 36).offset(x: -18)
                Circle().fill(Color.white).frame(width: 42).offset(y: -6)
                Circle().fill(Color.white).frame(width: 36).offset(x: 18)
            }
            .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
            .offset(y: -66)
            // Muzzle
            Ellipse().fill(Color(hex: 0xe6c39a)).frame(width: 52, height: 40).offset(y: 18)
            Ellipse().fill(Color(hex: 0x2a1a10)).frame(width: 18, height: 12).offset(y: 8)
            mouth.offset(y: 26)
            // Eyes
            ForEach([-1.0, 1.0], id: \.self) { s in
                Group {
                    if mood == .happy {
                        UrsaArc().stroke(Color(hex: 0x2a1a10), style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 14, height: 7)
                    } else {
                        Ellipse().fill(Color(hex: 0x2a1a10)).frame(width: 11, height: blink ? 2 : (mood == .watching ? 15 : 12))
                    }
                }
                .offset(x: 20 * s, y: -10)
            }
            if mood == .oops {
                Text("💦").font(.system(size: 20)).offset(x: 48, y: -28)
            }
            // Cheeks
            ForEach([-1.0, 1.0], id: \.self) { s in
                Circle().fill(Color(hex: 0xff8a8a).opacity(0.35)).frame(width: 16).offset(x: 34 * s, y: 12)
            }
        }
        .frame(width: 130, height: 180)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: mood)
        .onAppear { blinkLoop() }
    }

    @ViewBuilder private var mouth: some View {
        switch mood {
        case .happy: Ellipse().fill(Color(hex: 0x8a2e2e)).frame(width: 18, height: 12)
        case .oops: Ellipse().fill(Color(hex: 0x8a2e2e)).frame(width: 12, height: 14)
        case .watching: Capsule().fill(Color(hex: 0x8a2e2e)).frame(width: 10, height: 5)
        case .calm: UrsaArc().stroke(Color(hex: 0x2a1a10), style: StrokeStyle(lineWidth: 3, lineCap: .round)).frame(width: 16, height: 6).scaleEffect(y: -1)
        }
    }

    private func blinkLoop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...4.5)) {
            withAnimation(.easeInOut(duration: 0.08)) { blink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.easeInOut(duration: 0.08)) { blink = false }
                blinkLoop()
            }
        }
    }
}

private struct UrsaArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.8))
        return p
    }
}

// MARK: - View

struct BakeryView: View {
    let onClose: () -> Void
    @StateObject private var model = BakeryModel()
    var body: some View {
        ArcadeShell(model: model, spec: GameID.bakery.spec!, accent: Lu.tangerine,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { BKKitchen() }) {
            BKPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct BKPlay: View {
    @ObservedObject var model: BakeryModel
    private var t: BKTask { model.task }
    private var ing: BKIngredient { bkIngredients[t.ingredient] }

    var body: some View {
        VStack(spacing: 6) {
            Color.clear.frame(height: 54)
            HStack(alignment: .top, spacing: 4) {
                UrsaBear(mood: model.mood)
                    .overlay(MarketSparks(trigger: model.bakes.count, glyphs: ["✨", "⭐️", model.bakes.last ?? "🥧"]))
                recipeCard
            }
            patienceBar
            ZStack(alignment: .top) {
                station
            }
            .frame(maxHeight: .infinity)
            controls
        }
        .padding(.horizontal, 12).padding(.bottom, 6)
    }

    private var recipeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("RECIPE").font(luFont(11, .heavy)).tracking(2).foregroundStyle(Color(hex: 0x8a5a2e))
                Spacer()
                HStack(spacing: 0) { ForEach(Array(model.bakes.suffix(6).enumerated()), id: \.offset) { _, b in Text(b).font(.system(size: 16)) } }
            }
            if let r = model.right {
                Text(r ? "Mmm! Perfect!" : (model.spilled ? "Oh crumbs — it spilled!" : "Oh crumbs!"))
                    .font(luFont(20, .heavy)).foregroundStyle(Color(hex: r ? 0x2f7a3a : 0xa33a24))
                if !r {
                    Text(t.why).font(luFont(16, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                        .lineLimit(2).minimumScaleFactor(0.7)
                }
            } else {
                Text(t.line).font(luFont(t.line.count > 40 ? 17 : 22, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    .fixedSize(horizontal: false, vertical: true).lineLimit(4).minimumScaleFactor(0.7)
            }
            HStack {
                Spacer()
                LibrarySpeakerButton(size: 38) { model.sayAgain() }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xfffaf0))
                .overlay(VStack(spacing: 18) { ForEach(0..<6, id: \.self) { _ in Rectangle().fill(Color(hex: 0xb9d4e6)).frame(height: 1) } }.padding(.top, 34))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0xc9a46a), lineWidth: 2))
                .rotationEffect(.degrees(1.5))
                .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
        )
        .padding(.top, 8)
    }

    @ViewBuilder private var patienceBar: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: model.deadline == nil || model.phase != .playing)) { tl in
            let left = model.deadline.map { max(0, $0.timeIntervalSince(tl.date)) } ?? 0
            let f = model.patience > 0 ? CGFloat(left / model.patience) : 0
            HStack(spacing: 6) {
                Text("⏲️").font(.system(size: 14))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.15))
                        Capsule().fill(Color(hex: f < 0.3 ? Lu.coral : Lu.mint)).frame(width: max(0, g.size.width * f))
                    }
                }
                .frame(height: 8)
            }
        }
        .frame(height: 14)
        .opacity(model.deadline != nil ? 1 : 0)
    }

    /// The ingredient (tipping when you pour) above the glass measuring cup.
    private var station: some View {
        GeometryReader { g in
            let cupH = min(g.size.height - 70, 330.0), cupW = min(190.0, g.size.width * 0.5)
            let frac = CGFloat(min(model.fill, Double(t.capacity) + 0.4) / Double(t.capacity))
            ZStack(alignment: .bottom) {
                // Stream
                if model.holding {
                    Rectangle().fill(Color(hex: ing.color))
                        .frame(width: ing.liquid ? 12 : 16, height: max(0, cupH * (1 - min(1, frac)) + 70))
                        .overlay(Rectangle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                        .offset(x: -cupW * 0.12, y: -cupH * min(1, frac))
                        .transition(.opacity)
                }
                BKCup(fill: frac, color: ing.color, capacity: t.capacity, grid: t.grid, labels: t.labels,
                      star: t.star ? CGFloat(t.target) / CGFloat(t.capacity) : nil,
                      answer: model.right == false ? CGFloat(t.target) / CGFloat(t.capacity) : nil,
                      width: cupW, height: cupH)
                    .modifier(MarketShake(shakes: CGFloat(model.lastMiss)))
                    .animation(.linear(duration: 0.4), value: model.lastMiss)
                // The holder, tipping over the cup
                BKHolder(ing: ing)
                    .rotationEffect(.degrees(model.holding ? -110 : -20), anchor: .bottomLeading)
                    .offset(x: cupW * 0.12 + 14, y: -cupH + 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.holding)
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            // Press and hold to pour.
            Text(model.holding ? "Pouring…" : "Hold to pour")
                .font(luSerif(20, .black)).textCase(.uppercase).tracking(1)
                .foregroundStyle(Color(hex: 0x3a2708))
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(RoundedRectangle(cornerRadius: 18).fill(LinearGradient(
                    colors: model.holding ? [Color(hex: Lu.tangerine), Color(hex: 0xc0702a)] : [Color(hex: Lu.gold), Color(hex: Lu.tangerine)],
                    startPoint: .top, endPoint: .bottom)))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: 0xb96b1e), lineWidth: 3))
                .scaleEffect(model.holding ? 0.96 : 1)
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in model.startPour() }
                    .onEnded { _ in model.stopPour() })
                .opacity(model.stage == .pouring ? 1 : 0.5)
            Button(action: { model.check() }) {
                VStack(spacing: 0) {
                    Text("🥣").font(.system(size: 30))
                    Text("Into the bowl!").font(luFont(13, .heavy)).foregroundStyle(Color(hex: 0x1f3d29))
                }
                .frame(width: 120, height: 72)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: Lu.mint)))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: 0x2a6a33), lineWidth: 3))
            }
            .buttonStyle(.plain)
            .disabled(model.stage != .pouring || model.fill < 0.05)
            .opacity(model.stage == .pouring && model.fill >= 0.05 ? 1 : 0.5)
        }
    }
}

/// The ingredient's container: a sack, a bottle or a honey jar.
private struct BKHolder: View {
    let ing: BKIngredient
    var body: some View {
        ZStack {
            switch ing.holder {
            case "sack":
                RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(hex: 0xe2c690), Color(hex: 0xb8975c)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 70, height: 80)
                    .overlay(Text(ing.name.uppercased()).font(luFont(11, .heavy)).foregroundStyle(Color(hex: 0x6a4a1e)))
                Ellipse().fill(Color(hex: ing.color)).frame(width: 52, height: 14).offset(y: -38)
            case "bottle":
                RoundedRectangle(cornerRadius: 12).fill(Color(hex: ing.color).opacity(0.95))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.15), lineWidth: 2))
                    .frame(width: 52, height: 80)
                    .overlay(Text(ing.name.uppercased()).font(luFont(10, .heavy)).foregroundStyle(Color(hex: 0x2f5e8a)).rotationEffect(.degrees(-90)))
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: ing.color)).frame(width: 22, height: 26).offset(y: -50)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.15), lineWidth: 2).frame(width: 22, height: 26).offset(y: -50))
            default:
                RoundedRectangle(cornerRadius: 18).fill(Color(hex: ing.color))
                    .frame(width: 70, height: 66)
                    .overlay(Text("HONEY").font(luFont(11, .heavy)).foregroundStyle(Color(hex: 0x6a3a0e)))
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xd9a33a)).frame(width: 58, height: 12).offset(y: -36)
            }
        }
        .frame(width: 80, height: 90)
    }
}

/// The glass measuring cup with its marks. `star`: the line to fill to (Gradus I);
/// `answer`: the right line, shown in green after a miss.
private struct BKCup: View {
    let fill: CGFloat
    let color: UInt
    let capacity: Int, grid: Int
    let labels: Bool
    let star: CGFloat?
    let answer: CGFloat?
    let width: CGFloat, height: CGFloat

    var body: some View {
        let inner = height - 16
        ZStack(alignment: .bottom) {
            // Contents
            RoundedRectangle(cornerRadius: 10).fill(Color(hex: color))
                .overlay(RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)))
                .frame(width: width - 16, height: max(0, inner * min(1.02, fill)))
                .padding(.bottom, 8)
                .animation(.linear(duration: 0.05), value: fill)
            // Glass
            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.22))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.9), lineWidth: 4))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x6a8aa0).opacity(0.6), lineWidth: 1.5))
                .frame(width: width, height: height)
            // Handle
            RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.85), lineWidth: 10)
                .frame(width: 46, height: height * 0.5)
                .offset(x: width / 2 + 24, y: -height * 0.3)
            // Marks
            let n = capacity / grid
            ForEach(1...n, id: \.self) { i in
                let tw = i * grid
                let y = inner * CGFloat(tw) / CGFloat(capacity)
                let whole = tw % 12 == 0
                HStack(spacing: 4) {
                    Spacer()
                    if labels || whole {
                        Text(bkMark(tw)).font(luFont(whole ? 18 : 15, .heavy)).foregroundStyle(Color(hex: 0xb03a2e))
                            .padding(.horizontal, 3).background(Capsule().fill(Color.white.opacity(0.7)))
                    }
                    Rectangle().fill(Color(hex: 0xb03a2e)).frame(width: whole ? 44 : 28, height: whole ? 4 : 3)
                }
                .frame(width: width - 8)
                .offset(y: -(8 + y) + 2)
            }
            if let s = star {
                HStack(spacing: 2) {
                    Rectangle().fill(Color(hex: Lu.gold)).frame(height: 5)
                    Text("⭐️").font(.system(size: 30))
                }
                .frame(width: width + 30)
                .offset(x: 14, y: -(8 + inner * s) + 15)
            }
            if let a = answer {
                HStack(spacing: 2) {
                    Rectangle().fill(Color(hex: Lu.mint)).frame(height: 6)
                    Text("◀︎").font(luFont(22)).foregroundStyle(Color(hex: Lu.mint))
                }
                .frame(width: width + 30)
                .offset(x: 14, y: -(8 + inner * a) + 13)
                .transition(.opacity)
            }
        }
        .frame(width: width, height: height)
    }

    private func bkMark(_ tw: Int) -> String {
        let w = tw / 12, r = tw % 12
        let frac = [0: "", 3: "¼", 4: "⅓", 6: "½", 8: "⅔", 9: "¾"][r] ?? ""
        return w == 0 ? frac : "\(w)\(frac)"
    }
}
