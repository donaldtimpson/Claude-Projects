import SwiftUI

// MARK: - Omnibus Driver (Temple · Math) — riders hop on and off the donkey-bus; how many now?
//
// Watch the bus pull up at each stop: riders walk from the kerb to the door one at a time (or a
// whole family / crowd at once later on) and others step off. Then the inspector asks a question
// and the child taps one of 2–3 big numbers. A miss lights the right number and spells out the
// sum (and, on the see-through bus, numbers every rider).
//
// Difficulty is continuous (GameKit `d`, 4 routes a Gradus): every knob ramps a little with each
// right answer —
//   • numbers: start riders 0–2 → up to 40, group sizes 1–2 → 3–15, the total cap 4 → 100;
//   • stops 1 → 4, events per stop 1 → 2, the walk pace 1.1 s → 0.35 s a rider;
//   • kinds fade in: getting OFF (~I½), on-and-off every route (~II½), misted windows — keep count
//     in your head (~II–III), families (~IV), crowds (~IV½), "3 families of 4" (~VI), "half get
//     off" (~VII), "25% get off" (~VIII);
//   • questions fade in via `tier`: how many now → how many got OFF in all (~V) → how many at the
//     START (~VI) → fares (~VII), with "how many now" always kept as review;
//   • 2 choices within ±2 at the very start, then 3; "watch again" until ~III½.

// MARK: - Routes

private struct OBEvent {
    var on: Bool
    var count: Int
    var label: String       // caption ("2 get on", "Half get off")
    var groups: [Int]       // how the riders move: [1,1] one by one, [4,4,4] three families, [9] a crowd
    var badge: String?      // tag on a group token (defaults to its size)
    var term: String        // its piece of the sum ("+ 3", "− 7 (½ of 14)")
}

private enum OBAsk: Equatable { case now, start, offTotal, fare(Int) }

private struct OBRoute {
    var start: Int
    var stops: [[OBEvent]]
    var ask: OBAsk
    var fog: Bool
    var final: Int
    var answer: Int
    var options: [Int]
    var sum: String
    var question: String {
        switch ask {
        case .now: return "How many are on the bus now?"
        case .start: return "How many were on at the START?"
        case .offTotal: return "How many got OFF in all?"
        case .fare(let f): return "Each new rider paid \(f) 🪙. How many coins?"
        }
    }
}

private struct OBTier {
    var stops: ClosedRange<Int>
    var perStop: ClosedRange<Int> = 1...2
    var each: ClosedRange<Int>
    var cap: Int
    var crowd = false        // a big group boards as one token with a number on it
    var family = false
    var multi = false        // "3 families of 4"
    var fraction = false     // half / a third / a quarter get off
}

/// Everything about the next route, read off the continuous difficulty `d` (re-rolled per try, so
/// kinds that are fading in show up a little more often each answer).
private struct OBKnobs {
    var tier: OBTier
    var start: ClosedRange<Int>
    var ask: OBAsk
    var fog: Bool            // the windows mist over: keep count in your head
    var offs: Bool           // riders may get off
    var both: Bool           // must have riders getting on AND off
    var percent: Bool        // "25% get off" opens the route
    var choices: Int
    var tight: Bool          // distractors within ±2 (the very start)
}

@MainActor
private func obKnobs(_ m: ArcadeModel) -> OBKnobs {
    let maxStops = m.rampInt(1, 4, from: 2.2, to: 8)
    let minStops = min(maxStops, m.rampInt(1, 3, from: 3, to: 7.5))
    let lo = m.rampInt(1, 3, from: 5, to: 9), hi = max(lo, m.rampInt(2, 15, to: 9))
    let t = OBTier(stops: minStops...maxStops, perStop: 1...m.rampInt(1, 2, from: 2, to: 3.5), each: lo...hi,
                   cap: m.rampInt(4, 100, to: 9),
                   crowd: m.chance(1, from: 4.3, to: 5.3), family: m.chance(1, from: 3.4, to: 4.4),
                   multi: m.chance(1, from: 5.4, to: 6.6), fraction: m.chance(1, from: 6.4, to: 7.6))
    let kinds: [OBAsk] = [.now, .offTotal, .start, .fare(Int.random(in: 2...m.rampInt(5, 9, from: 6.6, to: 9)))]
    let ask = kinds[m.tier([1, 4.6, 5.5, 6.6])]
    let sLo = m.rampInt(0, 5, from: 2, to: 7)
    let sHi = max(sLo + 2, m.rampInt(2, 40, to: 9))
    return OBKnobs(tier: t, start: sLo...sHi, ask: ask, fog: m.chance(0.9, from: 2.2, to: 3.4),
                   offs: m.chance(1, from: 1.4, to: 2.2), both: m.chance(1, from: 2.2, to: 3),
                   percent: m.chance(0.5, from: 7.5, to: 9.5), choices: m.d < 1.8 ? 2 : 3, tight: m.d < 1.8)
}

private struct OBGen {
    var start: Int
    var r: Int
    var stops: [[OBEvent]] = []
    var cur: [OBEvent] = []
    var onTotal = 0, offTotal = 0, offEvents = 0
    var usedFraction = false

    init(_ start: Int) { self.start = start; r = start }

    mutating func on(_ n: Int, label: String? = nil, groups: [Int]? = nil, badge: String? = nil, term: String? = nil, crowd: Bool = false) {
        r += n; onTotal += n
        cur.append(OBEvent(on: true, count: n, label: label ?? (n == 1 ? "1 gets on" : "\(n) get on"),
                           groups: groups ?? (crowd ? [n] : Array(repeating: 1, count: n)), badge: badge, term: term ?? "+ \(n)"))
    }
    mutating func off(_ n: Int, label: String? = nil, groups: [Int]? = nil, badge: String? = nil, term: String? = nil, crowd: Bool = false) {
        r -= n; offTotal += n; offEvents += 1
        cur.append(OBEvent(on: false, count: n, label: label ?? (n == 1 ? "1 gets off" : "\(n) get off"),
                           groups: groups ?? (crowd ? [n] : Array(repeating: 1, count: n)), badge: badge, term: term ?? "− \(n)"))
    }
    mutating func endStop() { stops.append(cur); cur = [] }

    /// One random on/off event within the tier's limits.
    mutating func random(_ t: OBTier, fractions: Bool) {
        let space = t.cap - r
        let wantOn = r == 0 || (space >= 1 && Double.random(in: 0..<1) < (r < t.cap / 3 ? 0.7 : 0.45))
        if wantOn {
            if t.multi && Double.random(in: 0..<1) < 0.35 {
                let k = Int.random(in: 2...3), g = Int.random(in: 3...5)
                if k * g <= space {
                    on(k * g, label: "\(k) families of \(g) get on", groups: Array(repeating: g, count: k),
                       badge: "\(g)", term: "+ \(k) × \(g)"); return
                }
            }
            if t.family && Double.random(in: 0..<1) < 0.35 {
                let g = Int.random(in: 3...5)
                if g <= space { on(g, label: "A family of \(g) gets on", groups: [g]); return }
            }
            let n = min(Int.random(in: t.each), space)
            on(n, crowd: t.crowd && n > 1)
        } else {
            if fractions && t.fraction && !usedFraction && Double.random(in: 0..<1) < 0.55 {
                let opts = [(2, "Half", "½"), (3, "A third", "⅓"), (4, "A quarter", "¼")].filter { r % $0.0 == 0 && r >= $0.0 * 2 }
                if let (d, name, sym) = opts.randomElement() {
                    usedFraction = true
                    off(r / d, label: "\(name) get off", groups: [r / d], badge: sym, term: "− \(r / d) (\(sym) of \(r))"); return
                }
            }
            let n = Int.random(in: min(t.each.lowerBound, r)...min(t.each.upperBound, r))
            off(n, crowd: t.crowd && n > 1)
        }
    }
}

@MainActor
private func obRoute(_ m: ArcadeModel) -> OBRoute {
    var tries = 0
    while true {
        tries += 1
        let k = obKnobs(m)
        let ask: OBAsk = tries > 150 ? .now : k.ask
        let pct = k.percent && ask != .start
        var g = OBGen(pct ? ([20, 40, 60, 80].filter { $0 <= max(20, k.tier.cap - 10) }.randomElement() ?? 20) : Int.random(in: k.start))
        for s in 0..<Int.random(in: k.tier.stops) {
            if s == 0 && pct {
                let p = [10, 20, 25, 50, 75].filter { g.r * $0 % 100 == 0 }.randomElement()!
                let n = g.r * p / 100
                g.off(n, label: "\(p)% get off", groups: [n], badge: "\(p)%", term: "− \(n) (\(p)% of \(g.r))")
            }
            for _ in 0..<Int.random(in: k.tier.perStop) {
                if k.offs { g.random(k.tier, fractions: ask != .start) }
                else { g.on(max(1, min(Int.random(in: k.tier.each), k.tier.cap - g.r))) }
            }
            g.endStop()
        }
        // Constraints that make each question worth asking.
        let events = g.stops.flatMap { $0 }
        if tries <= 300 {
            if k.both && (g.onTotal == 0 || g.offEvents == 0) { continue }
            if g.onTotal == 0 && g.offEvents == 0 { continue }
            if case .offTotal = ask, g.offEvents < 2 { continue }
            if case .fare = ask, g.onTotal < 2 || g.onTotal > 30 { continue }
            if events.contains(where: { $0.count == 0 }) { continue }
            if g.r > k.tier.cap + 5 { continue }
        }

        let answer: Int, sum: String
        let terms = events.map(\.term).joined(separator: " ")
        switch ask {
        case .now: answer = g.r; sum = "\(g.start) \(terms) = \(g.r)"
        case .start: answer = g.start; sum = "? \(terms) = \(g.r)   →   ? = \(g.start)"
        case .offTotal:
            answer = g.offTotal
            sum = events.filter { !$0.on }.map { "\($0.count)" }.joined(separator: " + ") + " = \(g.offTotal) got off"
        case .fare(let f): answer = g.onTotal * f; sum = "\(g.onTotal) got on × \(f) 🪙 = \(answer) 🪙"
        }

        // Distractors: near misses and the classic slips (a wrong sign, a forgotten step).
        let last = events.last?.count ?? 1
        var cands: [Int]
        switch ask {
        case .now: cands = [g.start + g.onTotal + g.offTotal, answer + last, answer - last, g.start, answer + 1, answer - 1, answer + 2, answer - 2]
        case .start: cands = [g.r + g.onTotal - g.offTotal, g.r, answer + 1, answer - 1, answer + 2, answer - 2]
        case .offTotal: cands = [g.onTotal, answer - last, answer + 1, answer - 1, answer + 2]
        case .fare(let f): cands = [answer + f, answer - f, g.onTotal + f, answer + 1, answer - 1]
        }
        let n = k.choices
        var opts = [answer]
        let picked = k.tight ? cands.filter { abs($0 - answer) <= 2 } : cands
        for c in picked.shuffled() where c >= 0 && !opts.contains(c) && opts.count < n { opts.append(c) }
        for c in [answer + 1, answer + 2, answer + 3] where opts.count < n && !opts.contains(c) { opts.append(c) }
        return OBRoute(start: g.start, stops: g.stops, ask: ask, fog: k.fog, final: g.r,
                       answer: answer, options: opts.sorted(), sum: sum)
    }
}

private let obWalkers = ["🚶", "🚶‍♀️", "🧍", "🧍‍♀️", "🚶‍♂️", "🧍‍♂️"]
private let obPeople = ["👩", "👨", "👧", "👦", "👵", "👴", "🧔", "👱‍♀️", "🧕", "👮", "🧑‍🌾", "👷", "👩‍🦰", "🧒"]

// MARK: - Model

private enum OBLoc: Equatable { case curb(Int), door, seat(Int), inside, away(Int) }

private struct OBToken: Identifiable {
    let id: Int
    var faces: [String]
    var badge: String?
    var loc: OBLoc
}

@MainActor
private final class OmnibusModel: ArcadeModel {
    enum Stage { case watching, asking, revealed }
    @Published var route = OBRoute(start: 0, stops: [], ask: .now, fog: false, final: 0, answer: 0, options: [0], sum: "")
    @Published var stage: Stage = .watching
    @Published var tokens: [OBToken] = []
    @Published var busX: CGFloat = -1.4         // in scene widths: 0 = at the stop
    @Published var caption = ""
    @Published var busBadge: String?
    @Published var chosen: Int?
    @Published var routeNo = 0

    private var task: Task<Void, Never>?
    private var nextID = 0

    init() { super.init(key: GameID.omnibus.rawValue) }

    override func perLevel(_ level: Int) -> Int { 4 }
    override func onBegin() { newRoute() }

    var canReplay: Bool { d < 3.6 && stage == .asking }

    func stop() { task?.cancel() }

    private func newRoute() {
        route = obRoute(self); routeNo += 1
        #if DEBUG
        assert(route.options.filter { $0 == route.answer }.count == 1 && Set(route.options).count == route.options.count)
        #endif
        run()
    }

    func replay() { guard canReplay else { return }; run() }

    private func run() {
        task?.cancel()
        // reset the scene synchronously so the old route never shows under the new question
        let rt = route
        stage = .watching; chosen = nil
        still {
            tokens = rt.fog ? [] : (0..<rt.start).map { token(1, badge: nil, at: .seat($0)) }
            busX = -1.4
            busBadge = rt.ask == .start ? "?" : "\(rt.start)"
            caption = "Here comes the bus!"
        }
        task = Task { [weak self] in await self?.play() }
    }

    private func wait(_ s: Double) async -> Bool {
        try? await Task.sleep(nanoseconds: UInt64(s * 1_000_000_000))
        return !Task.isCancelled && phase == .playing
    }

    private func still(_ f: () -> Void) {
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t, f)
    }

    private func token(_ n: Int, badge: String?, at loc: OBLoc) -> OBToken {
        nextID += 1
        let faces = (0..<min(n, n > 5 ? 3 : n)).map { _ in obPeople.randomElement()! }
        return OBToken(id: nextID, faces: faces, badge: n > 1 ? (badge ?? "\(n)") : nil, loc: loc)
    }

    private func freeSeat() -> Int {
        let used = Set(tokens.compactMap { if case .seat(let i) = $0.loc { return i } else { return nil } })
        return (0...).first { !used.contains($0) }!
    }

    private func move(_ id: Int, to loc: OBLoc, _ dur: Double) {
        withAnimation(.easeInOut(duration: dur)) {
            if let i = tokens.firstIndex(where: { $0.id == id }) { tokens[i].loc = loc }
        }
    }

    /// Plays the route: the bus arrives, stop by stop riders get on and off, then the question.
    private func play() async {
        let rt = route, d = ramp(1.1, 0.35, to: 9.5)    // seconds per rider's walk
        var first = true
        for (si, stop) in rt.stops.enumerated() {
            if si > 0 {
                withAnimation(.easeIn(duration: 0.9)) { busX = 1.4; caption = "Next stop! 🫏" }
                guard await wait(0.95) else { return }
                still { busX = -1.4; tokens.removeAll { if case .seat = $0.loc { return false }; return true } }
            }
            withAnimation(.easeOut(duration: si == 0 ? 1.3 : 1.0)) { busX = 0 }
            guard await wait(si == 0 ? 1.3 : 1.0 + d * 0.5) else { return }
            if si == 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    caption = rt.ask == .start ? "Who's inside? 🤫" : (rt.start == 0 ? "The bus is empty" : (rt.start == 1 ? "1 is riding" : "\(rt.start) are riding"))
                }
                guard await wait(0.6 + d * 1.2) else { return }
            }

            for ev in stop {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    caption = (ev.on ? "⬆️ " : "⬇️ ") + ev.label
                    if first { busBadge = nil; first = false }
                }
                if ev.on {
                    let waiting = ev.groups.enumerated().map { k, g in token(g, badge: ev.badge, at: .curb(k)) }
                    withAnimation(.easeOut(duration: 0.3)) { tokens += waiting }
                    guard await wait(0.4 + d * 0.5) else { return }
                    for t in waiting {
                        move(t.id, to: .door, d * 0.55)
                        guard await wait(d * 0.6) else { return }
                        move(t.id, to: rt.fog ? .inside : .seat(freeSeat()), d * 0.4)
                        guard await wait(d * 0.45) else { return }
                    }
                    still { tokens.removeAll { $0.loc == .inside } }
                } else {
                    for (k, g) in ev.groups.enumerated() {
                        let id: Int
                        if rt.fog || g > 1 {
                            let t = token(g, badge: ev.badge, at: .inside)
                            still { tokens.append(t) }
                            id = t.id
                            guard await wait(0.05) else { return }
                        } else {
                            guard let t = tokens.filter({ if case .seat = $0.loc { return true }; return false }).randomElement() else { continue }
                            id = t.id
                        }
                        move(id, to: .door, d * 0.45)
                        guard await wait(d * 0.5) else { return }
                        move(id, to: .curb(k), d * 0.5)
                        guard await wait(d * 0.55) else { return }
                    }
                }
                guard await wait(0.35 + d * 0.4) else { return }
                // riders who got off stroll away, clearing the kerb for the next event
                withAnimation(.easeIn(duration: 0.8)) {
                    for i in tokens.indices { if case .curb(let k) = tokens[i].loc { tokens[i].loc = .away(k) } }
                }
            }
        }
        if rt.ask == .start {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                caption = "Now \(rt.final) are riding"; busBadge = "\(rt.final)"
            }
            guard await wait(1.0 + d) else { return }
        } else {
            guard await wait(0.4) else { return }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { caption = rt.question; stage = .asking }
    }

    func choose(_ i: Int) {
        guard phase == .playing, stage == .asking, route.options.indices.contains(i) else { return }
        chosen = i
        let right = route.options[i] == route.answer
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { stage = .revealed }
        if right { hit() } else { miss(reason: "Out of hearts!", delay: 2.6) }
        let no = routeNo
        DispatchQueue.main.asyncAfter(deadline: .now() + (right ? 1.8 : 3.4)) { [weak self] in
            guard let self, self.routeNo == no, self.phase == .playing, !self.dying else { return }
            self.newRoute()
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .asking else { return }
        let right = route.options.firstIndex(of: route.answer) ?? 0
        let wrong = route.options.indices.filter { $0 != right }
        choose(correct || wrong.isEmpty ? right : wrong.randomElement()!)
    }
}

// MARK: - Views

struct OmnibusView: View {
    let onClose: () -> Void
    @StateObject private var model = OmnibusModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.omnibus.spec!, accent: Lu.gold, onClose: onClose,
                    backdrop: { OBStreetBackdrop() }) {
            VStack(spacing: 10) {
                HUDSpace(56)
                Text(model.caption)
                    .font(luFont(model.stage == .watching ? 26 : 22))
                    .foregroundStyle(Color(hex: 0x2b1708))
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .padding(.horizontal, 12)
                    .background(OBSign())
                    .id(model.caption)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))

                GeometryReader { geo in OBScene(model: model, size: geo.size) }
                    .frame(height: 330)
                    .padding(.horizontal, -14)

                answerArea
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
        }
        .onDisappear { model.stop() }
    }

    @ViewBuilder private var answerArea: some View {
        if model.stage == .watching {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                Text("Watch the bus!")
            }
            .font(luFont(20, .heavy)).foregroundStyle(Color(hex: 0x3a2410))
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(Capsule().fill(Color(hex: 0xf3e6c8).opacity(0.9)))
            .frame(height: 96)
        } else {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    ForEach(Array(model.route.options.enumerated()), id: \.offset) { i, v in
                        OBChoice(value: v, isAnswer: v == model.route.answer, chosen: model.chosen == i,
                                 revealed: model.stage == .revealed) { model.choose(i) }
                    }
                }
                if model.stage == .revealed {
                    Text(model.route.sum)
                        .font(luFont(19, .heavy)).foregroundStyle(Color(hex: 0x2b1708))
                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.5)
                        .padding(.vertical, 10).padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0xf6ecd4))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: model.chosen.map { model.route.options[$0] == model.route.answer } == true ? Lu.mint : Lu.coral), lineWidth: 3)))
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else if model.canReplay {
                    Button { model.replay() } label: {
                        HStack(spacing: 8) { Image(systemName: "arrow.counterclockwise"); Text("Watch again") }
                            .font(luFont(18, .heavy)).foregroundStyle(Color(hex: 0x3a2410))
                            .padding(.horizontal, 22).frame(height: 50)
                            .background(Capsule().fill(Color(hex: 0xf3e6c8)).overlay(Capsule().stroke(Color(hex: 0x8a5a2b), lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// A wooden street sign for the caption.
private struct OBSign: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(colors: [Color(hex: 0xf3dfb0), Color(hex: 0xd9b97c)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x8a5a2b), lineWidth: 3))
            .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 4)
    }
}

/// Morning over the city: a warm sky, a sun, clouds; flagstones below the street.
private struct OBStreetBackdrop: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x6fb2e0), Color(hex: 0xcfe6f0), Color(hex: 0xf7e2b8)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hex: 0xfff2c0)).frame(width: 70).position(x: w * 0.18, y: h * 0.2)
                ForEach(0..<3) { i in
                    OBCloud().frame(width: 110, height: 40)
                        .position(x: w * [0.62, 0.86, 0.36][i], y: h * [0.12, 0.24, 0.3][i])
                }
                Canvas { ctx, sz in
                    let top = sz.height * 0.55
                    ctx.fill(Path(CGRect(x: 0, y: top, width: sz.width, height: sz.height - top)), with: .color(Color(hex: 0xb8a27a)))
                    var y = top, row = 0
                    while y < sz.height {
                        var x: CGFloat = row % 2 == 0 ? 0 : -35
                        while x < sz.width {
                            ctx.fill(Path(roundedRect: CGRect(x: x + 2, y: y + 2, width: 66, height: 36), cornerRadius: 6),
                                     with: .color(Color(hex: (row + Int(x / 70)) % 3 == 0 ? 0xcdb88f : 0xc6b086)))
                            x += 70
                        }
                        y += 40; row += 1
                    }
                }
            }
        }
    }
}

private struct OBCloud: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color.white.opacity(0.9)).frame(height: 26).offset(y: 8)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 40).offset(x: -18)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 34).offset(x: 14, y: 2)
        }
    }
}

/// An answer: a bronze-edged token with the number.
private struct OBChoice: View {
    let value: Int
    let isAnswer: Bool, chosen: Bool, revealed: Bool
    let action: () -> Void
    private var fill: UInt { revealed ? (isAnswer ? 0x8fd27f : (chosen ? 0xf08a70 : 0xf6ecd4)) : 0xf6ecd4 }
    var body: some View {
        Button(action: action) {
            Text("\(value)").font(luFont(46)).monospacedDigit()
                .foregroundStyle(Color(hex: 0x2b1708))
                .lineLimit(1).minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 96)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: fill))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0x9a6634), lineWidth: 4))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x9a6634).opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [5, 4])).padding(7))
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 4))
                .scaleEffect(revealed && isAnswer ? 1.06 : 1)
                .opacity(revealed && !isAnswer && !chosen ? 0.45 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: revealed)
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }
}

/// Scene geometry: the road, the bus (moved by `busX`), the kerb.
private struct OBGeo {
    let w: CGFloat, h: CGFloat, busX: CGFloat
    var roadTop: CGFloat { h * 0.62 }
    var curbTop: CGFloat { roadTop + 30 }
    var busW: CGFloat { min(w * 0.64, 260) }
    let busH: CGFloat = 124
    var busCX: CGFloat { w * 0.40 + busX * w }
    var busBottom: CGFloat { roadTop + 6 }
    var busTop: CGFloat { busBottom - busH }
    var busLeft: CGFloat { busCX - busW / 2 }
    var busRight: CGFloat { busCX + busW / 2 }
    var door: CGPoint { CGPoint(x: busLeft + 23, y: busBottom - 40) }
    var winLeft: CGFloat { busLeft + 44 }
    func seat(_ i: Int) -> CGPoint {
        let col = i % 5, row = i / 5
        return CGPoint(x: winLeft + (busRight - 8 - winLeft) * (CGFloat(col) + 0.5) / 5, y: busTop + 36 + CGFloat(row) * 36)
    }
    func curb(_ k: Int, wide: Bool) -> CGPoint {
        CGPoint(x: wide ? 60 + CGFloat(k) * 100 : 30 + CGFloat(k) * 46, y: curbTop + (h - curbTop) / 2)
    }
    func point(_ t: OBToken) -> CGPoint {
        switch t.loc {
        case .curb(let k): return curb(k, wide: t.faces.count > 1)
        case .away(let k): let p = curb(k, wide: t.faces.count > 1); return CGPoint(x: p.x - w * 0.55, y: p.y)
        case .door, .inside: return door
        case .seat(let i): return seat(i)
        }
    }
}

private struct OBScene: View {
    @ObservedObject var model: OmnibusModel
    let size: CGSize

    var body: some View {
        let g = OBGeo(w: size.width, h: size.height, busX: model.busX)
        let fog = model.route.fog
        let seated = model.tokens.filter { if case .seat = $0.loc { return true }; return false }
            .sorted { a, b in if case .seat(let i) = a.loc, case .seat(let j) = b.loc { return i < j }; return false }
        ZStack(alignment: .topLeading) {
            // the city behind the street
            OBFacades(w: size.width, base: g.roadTop)
            // road (cobbles), kerb, pavement
            Rectangle().fill(Color(hex: 0x6e655c)).frame(height: g.curbTop - g.roadTop).offset(y: g.roadTop)
            HStack(spacing: 4) {
                ForEach(0..<Int(size.width / 22) + 1, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x857a6e)).frame(width: 18, height: 10)
                }
            }
            .frame(width: size.width, alignment: .leading).offset(y: g.roadTop + 10)
            Rectangle().fill(Color(hex: 0xb8a27a)).frame(height: size.height - g.curbTop).offset(y: g.curbTop)
            Rectangle().fill(Color(hex: 0xe2d3b0)).frame(height: 6).offset(y: g.curbTop)
            // the stop: a post with a sign
            Capsule().fill(Color(hex: 0x6b4423)).frame(width: 6, height: 60).position(x: size.width - 30, y: g.curbTop + 40)
            VStack(spacing: 0) {
                Text("STATIO").font(luSerif(10, .black)).foregroundStyle(Color(hex: 0x2b1708))
                Image(systemName: "bus.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: 0x8a2a1c))
            }
            .frame(width: 52, height: 36)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: Lu.gold)).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0x6b4423), lineWidth: 2)))
            .position(x: size.width - 30, y: g.curbTop + 8)

            OBBus(g: g, fog: fog, badge: model.busBadge)

            ForEach(model.tokens) { t in
                let num = model.stage == .revealed && !fog ? seated.firstIndex(where: { $0.id == t.id }).map { $0 + 1 } : nil
                OBTokenView(token: t, count: num)
                    .position(g.point(t))
                    .opacity(t.loc == .inside || { if case .away = t.loc { return true }; return false }() ? 0 : 1)
                    .scaleEffect(t.loc == .inside ? 0.6 : 1)
                    .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct OBTokenView: View {
    let token: OBToken
    let count: Int?
    var body: some View {
        HStack(spacing: token.faces.count > 3 ? -14 : -10) {
            ForEach(Array(token.faces.enumerated()), id: \.offset) { k, f in
                // In a window you see a face; on the street, the whole person walking.
                if case .seat = token.loc { Text(f).font(.system(size: 34)) }
                else { Text(obWalkers[(token.id + k) % obWalkers.count]).font(.system(size: 50)) }
            }
        }
        .overlay(alignment: .topTrailing) {
            if let b = token.badge {
                Text(b).font(luFont(14, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color(hex: Lu.gold)))
                    .offset(x: 10, y: -10)
            }
        }
        .overlay(alignment: .top) {
            if let c = count {
                Text("\(c)").font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                    .frame(width: 22, height: 22).background(Circle().fill(Color(hex: Lu.gold)))
                    .offset(y: -20)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

/// The donkey-bus: a terracotta carriage with a gold canopy, windows, a door, cart wheels.
private struct OBBus: View {
    let g: OBGeo
    let fog: Bool
    let badge: String?

    var body: some View {
        let wheelR: CGFloat = 19
        let spin = Angle.radians(Double(g.busX * g.w / wheelR))
        ZStack(alignment: .topLeading) {
            // shafts to the donkey
            Path { p in p.move(to: CGPoint(x: g.busRight - 4, y: g.busBottom - 34)); p.addLine(to: CGPoint(x: g.busRight + 34, y: g.busBottom - 26)) }
                .stroke(Color(hex: 0x6b4423), lineWidth: 5)
            Text("🫏").font(.system(size: 54)).scaleEffect(x: -1, y: 1)
                .position(x: g.busRight + 42, y: g.busBottom - 22)
            // body
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(hex: Lu.coral), Color(hex: 0xa9452f)], startPoint: .top, endPoint: .bottom))
                .frame(width: g.busW, height: g.busH)
                .offset(x: g.busLeft, y: g.busTop)
            // canopy
            RoundedRectangle(cornerRadius: 6).fill(Color(hex: Lu.gold))
                .frame(width: g.busW + 14, height: 14)
                .offset(x: g.busLeft - 7, y: g.busTop - 8)
            // windows (fogged from Gradus III)
            RoundedRectangle(cornerRadius: 8)
                .fill(fog ? Color(hex: 0xe8e2f0) : Color(hex: 0xbfe3f0))
                .overlay { if fog { Text("☁️ ☁️ ☁️").font(.system(size: 22)).opacity(0.7) } }
                .frame(width: g.busRight - 8 - g.winLeft, height: 76)
                .offset(x: g.winLeft, y: g.busTop + 12)
            // door
            RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0x6b4423))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: Lu.gold), lineWidth: 2))
                .frame(width: 30, height: 84)
                .offset(x: g.busLeft + 8, y: g.busTop + 16)
            // gold stripe
            Rectangle().fill(Color(hex: Lu.gold).opacity(0.8))
                .frame(width: g.busRight - 6 - g.winLeft, height: 4)
                .offset(x: g.winLeft, y: g.busBottom - 18)
            ForEach([g.busLeft + 44, g.busRight - 40], id: \.self) { x in
                OBWheel(r: wheelR).rotationEffect(spin).position(x: x, y: g.busBottom)
            }
            if let b = badge {
                Text("👥 \(b)").font(luFont(22)).foregroundStyle(Color(hex: Lu.inkDark))
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: Lu.gold)).overlay(Capsule().stroke(Color(hex: Lu.inkDark).opacity(0.4), lineWidth: 2)))
                    .position(x: g.busCX, y: g.busTop - 30)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

private struct OBWheel: View {
    let r: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x3b2a1a))
            Circle().stroke(Color(hex: 0xc89a5a), lineWidth: 4)
            ForEach(0..<4) { i in
                Capsule().fill(Color(hex: 0xc89a5a)).frame(width: 3, height: r * 2 - 4).rotationEffect(.degrees(Double(i) * 45))
            }
        }
        .frame(width: r * 2, height: r * 2)
    }
}

/// A row of Roman town houses (insulae) behind the street: ochre and terracotta walls, shuttered
/// windows, tiled roof edges, an arched shop front.
private struct OBFacades: View {
    let w: CGFloat
    let base: CGFloat
    var body: some View {
        let cols: [UInt] = [0xd99a5a, 0xe6c288, 0xc9714a, 0xe0b070]
        let widths: [CGFloat] = [0.3, 0.26, 0.24, 0.3]
        let heights: [CGFloat] = [0.78, 0.62, 0.86, 0.7]
        ZStack(alignment: .topLeading) {
            ForEach(0..<4) { i in
                let x0 = w * widths.prefix(i).reduce(0, +)
                let bw = w * widths[i], bh = base * heights[i]
                ZStack(alignment: .top) {
                    Rectangle().fill(Color(hex: cols[i]))
                    Rectangle().fill(Color(hex: 0x9a4426)).frame(height: 10)
                    VStack(spacing: 14) {
                        ForEach(0..<max(1, Int(bh / 60)), id: \.self) { _ in
                            HStack(spacing: 14) {
                                ForEach(0..<2, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x4a2c1a).opacity(0.8)).frame(width: 18, height: 24)
                                        .overlay(Rectangle().fill(Color(hex: 0x7a8a4a)).frame(width: 22, height: 4).offset(y: 14))
                                }
                            }
                        }
                    }
                    .padding(.top, 24)
                    if i == 2 {
                        ArchShape().fill(Color(hex: 0x3a2014).opacity(0.85)).frame(width: 46, height: 54)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .frame(width: bw + 1, height: bh)
                .offset(x: x0, y: base - bh)
            }
        }
        .frame(width: w, height: base, alignment: .topLeading)
    }
}

private struct ArchShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width / 2))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + r.width / 2), radius: r.width / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
