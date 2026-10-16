import SwiftUI

// MARK: - Omnibus Driver (Temple · Math) — riders hop on and off the donkey-bus; how many now?
//
// Watch the bus pull up at each stop: riders walk from the kerb to the door one at a time (or a
// whole family / crowd at once later on) and others step off. Then the inspector asks a question
// and the child taps one of 2–3 big numbers. A miss lights the right number and spells out the
// sum (and, on the see-through bus, numbers every rider).
//
// Level ladder (one route = one answer; 4 routes a level):
//   I    see-through bus, 0–2 riding, 1–2 get on, one stop; totals ≤ 4; 2 choices; slow; replay
//   II   see-through, 1–3 riding, some get on and some get off; totals ≤ 6; 3 choices; replay
//   III  the windows fog up (track it in your head): 2 stops, on and off, ≤ 12; replay
//   IV   families ("a family of 4 gets on"), 2–3 stops, ≤ 20
//   V    crowds (+9), 3–4 stops, ≤ 40; or "how many got OFF in all?"
//   VI   groups as multiplication ("3 families of 4"), working backwards ("how many at the START?")
//   VII  "half / a third / a quarter get off", fares ("each new rider paid 3 🪙"), ≤ 80
//   VIII+ percentages ("25% get off"), all the above, ≤ 100; the pace quickens a little each level

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

private func obTier(_ level: Int) -> OBTier {
    switch level {
    case 3: return OBTier(stops: 2...2, each: 1...3, cap: 12)
    case 4: return OBTier(stops: 2...3, each: 1...4, cap: 20, family: true)
    case 5: return OBTier(stops: 3...4, each: 2...9, cap: 40, crowd: true, family: true)
    case 6: return OBTier(stops: 3...3, each: 2...9, cap: 60, crowd: true, family: true, multi: true)
    case 7: return OBTier(stops: 3...3, each: 2...12, cap: 80, crowd: true, family: true, multi: true, fraction: true)
    default: return OBTier(stops: 3...4, each: 3...15, cap: 100, crowd: true, family: true, multi: true, fraction: true)
    }
}

private func obAsk(_ level: Int) -> OBAsk {
    let x = Double.random(in: 0..<1)
    switch level {
    case ...4: return .now
    case 5: return x < 0.7 ? .now : .offTotal
    case 6: return x < 0.5 ? .now : .start
    case 7: return x < 0.35 ? .now : (x < 0.65 ? .start : .fare(.random(in: 2...5)))
    default: return x < 0.4 ? .now : (x < 0.6 ? .start : (x < 0.8 ? .fare(.random(in: 2...9)) : .offTotal))
    }
}

private func obRoute(_ level: Int) -> OBRoute {
    while true {
        let ask = obAsk(level)
        var g: OBGen
        switch level {
        case 1:
            g = OBGen(.random(in: 0...2)); g.on(.random(in: 1...2)); g.endStop()
        case 2:
            g = OBGen(.random(in: 1...3))
            let n = Int.random(in: 1...3)
            if Double.random(in: 0..<1) < 0.75 {
                let m = Int.random(in: 1...2)
                if Bool.random() && m <= g.r { g.off(m); g.on(n) } else { g.on(n); g.off(min(m, g.r)) }
            } else { g.on(n) }
            g.endStop()
        default:
            let t = obTier(level)
            let fractions = ask != .start
            let start: Int
            switch level {
            case 3: start = .random(in: 1...4)
            case 4: start = .random(in: 2...6)
            case 5: start = .random(in: 5...15)
            case 6: start = .random(in: 4...12)
            case 7: start = .random(in: 6...20)
            default: start = ask == .start ? .random(in: 10...40) : [20, 40, 60, 80].randomElement()!
            }
            g = OBGen(start)
            for s in 0..<Int.random(in: t.stops) {
                if s == 0 && level >= 8 && ask != .start {
                    let p = [10, 20, 25, 50, 75].filter { g.r * $0 % 100 == 0 }.randomElement()!
                    let k = g.r * p / 100
                    g.off(k, label: "\(p)% get off", groups: [k], badge: "\(p)%", term: "− \(k) (\(p)% of \(g.r))")
                }
                for _ in 0..<Int.random(in: t.perStop) { g.random(t, fractions: fractions) }
                g.endStop()
            }
        }
        // Constraints that make each question worth asking.
        let events = g.stops.flatMap { $0 }
        if level >= 3 && (g.onTotal == 0 || g.offEvents == 0) { continue }
        if case .offTotal = ask, g.offEvents < 2 { continue }
        if case .fare = ask, g.onTotal < 2 || g.onTotal > 30 { continue }
        if events.contains(where: { $0.count == 0 }) { continue }

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
        let n = level == 1 ? 2 : 3
        var opts = [answer]
        let picked = level == 1 ? cands.filter { abs($0 - answer) <= 2 } : cands
        for c in picked.shuffled() where c >= 0 && !opts.contains(c) && opts.count < n { opts.append(c) }
        for c in [answer + 1, answer + 2, answer + 3] where opts.count < n && !opts.contains(c) { opts.append(c) }
        return OBRoute(start: g.start, stops: g.stops, ask: ask, fog: level >= 3, final: g.r,
                       answer: answer, options: opts.sorted(), sum: sum)
    }
}

/// Seconds per rider's walk.
private func obPace(_ level: Int) -> Double {
    switch level {
    case 1: return 1.1
    case 2: return 0.95
    case 3: return 0.8
    case 4: return 0.7
    case 5: return 0.6
    case 6: return 0.55
    case 7: return 0.5
    default: return max(0.35, 0.5 - Double(level - 8) * 0.03)
    }
}

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
    @Published var route = obRoute(1)
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

    var canReplay: Bool { level <= 3 && stage == .asking }

    func stop() { task?.cancel() }

    private func newRoute() {
        route = obRoute(level); routeNo += 1
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
        let rt = route, d = obPace(level)
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
        ArcadeShell(model: model, spec: GameID.omnibus.spec!, accent: Lu.gold, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)
                Text(model.caption)
                    .font(luFont(model.stage == .watching ? 26 : 21))
                    .foregroundStyle(Color(hex: model.stage == .watching ? Lu.gold : Lu.ink))
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .padding(.horizontal, 12)
                    .background(luPanelShape(18))
                    .id(model.caption)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))

                GeometryReader { geo in OBScene(model: model, size: geo.size) }
                    .frame(height: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: Lu.line), lineWidth: 2))

                answerArea
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
        }
        .onDisappear { model.stop() }
    }

    @ViewBuilder private var answerArea: some View {
        if model.stage == .watching {
            Text("👀 Watch the bus!").font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.inkDim))
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
                        .font(luFont(19, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.5)
                        .padding(.vertical, 10).padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: Lu.ground))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: model.chosen.map { model.route.options[$0] == model.route.answer } == true ? Lu.mint : Lu.coral), lineWidth: 2)))
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else if model.canReplay {
                    Button { model.replay() } label: {
                        Text("👀 Watch again").font(luFont(18, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                            .padding(.horizontal, 22).frame(height: 50)
                            .background(Capsule().fill(Color(hex: Lu.panel2)).overlay(Capsule().stroke(Color(hex: Lu.line), lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct OBChoice: View {
    let value: Int
    let isAnswer: Bool, chosen: Bool, revealed: Bool
    let action: () -> Void
    private var fill: UInt { revealed ? (isAnswer ? Lu.mint : (chosen ? Lu.coral : Lu.panel)) : Lu.panel }
    var body: some View {
        Button(action: action) {
            Text("\(value)").font(luFont(46)).monospacedDigit()
                .foregroundStyle(Color(hex: revealed && (isAnswer || chosen) ? Lu.inkDark : Lu.ink))
                .lineLimit(1).minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 96)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: fill))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: Lu.line), lineWidth: 2)))
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
            // sky, road, kerb, the stop
            LinearGradient(colors: [Color(hex: 0x3a2a6a), Color(hex: 0x6a4a8a)], startPoint: .top, endPoint: .bottom)
            Text("🏛️").font(.system(size: 54)).opacity(0.35).position(x: size.width - 60, y: 52)
            Rectangle().fill(Color(hex: 0x5b5048)).frame(height: g.curbTop - g.roadTop).offset(y: g.roadTop)
            Rectangle().fill(Color(hex: 0x8f7a5c)).frame(height: size.height - g.curbTop).offset(y: g.curbTop)
            Rectangle().fill(Color(hex: 0xb79f78)).frame(height: 4).offset(y: g.curbTop)
            // the stop: a post with a gold disc
            Capsule().fill(Color(hex: 0x6b4423)).frame(width: 6, height: 54).position(x: size.width - 26, y: g.curbTop + 42)
            Circle().fill(Color(hex: Lu.gold)).overlay(Circle().stroke(Color(hex: Lu.inkDark).opacity(0.5), lineWidth: 2))
                .overlay(Text("🚌").font(.system(size: 18)))
                .frame(width: 36, height: 36).position(x: size.width - 26, y: g.curbTop + 14)

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
            ForEach(Array(token.faces.enumerated()), id: \.offset) { _, f in Text(f).font(.system(size: 34)) }
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
