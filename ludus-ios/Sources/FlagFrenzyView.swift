import SwiftUI

// MARK: - Flag Frenzy  (Lighthouse · pop-the-bubble, geography)
//
// Flag bubbles float up; the banner says which one to pop. Built on GameKit. A wrong pop shows
// that flag's name and makes the right bubble(s) glow — a miss always teaches. Escaped bubbles
// cost nothing, and the right flag is always kept on screen.
//
// Level ladder:
//   I    MATCH: the banner shows the flag itself; only 3 very different flags float, slowly
//   II   MATCH: 22 famous flags, 4 kinds at once
//   III  NAME: the banner shows the country's name + its continent (picture & colour)
//   IV   CONTINENT: "pop a flag from 🦘 Oceania" — bubbles ringed in their continent's colour
//   V    CONTINENT without the colour rings, more flags
//   VI   NAME among look-alikes (Ireland / Italy / Ivory Coast, Indonesia / Poland / Austria…)
//   VII+ look-alikes and continents mixed; a little faster each level (capped)
//
// Continents follow the usual 7-continent school model with Oceania for Australia & the Pacific;
// countries that span two continents (Russia, Turkey, Egypt, Indonesia…) never appear in a
// continent round.

private struct Cont { let name: String; let icon: String; let tint: UInt }
private let ffConts: [String: Cont] = [
    "af": Cont(name: "Africa", icon: "🦁", tint: Lu.tangerine),
    "as": Cont(name: "Asia", icon: "🐼", tint: Lu.coral),
    "eu": Cont(name: "Europe", icon: "🏰", tint: Lu.sky),
    "na": Cont(name: "North America", icon: "🦅", tint: Lu.mint),
    "sa": Cont(name: "South America", icon: "🦜", tint: Lu.gold),
    "oc": Cont(name: "Oceania", icon: "🦘", tint: Lu.grape),
]

private struct FFCountry: Hashable {
    let name: String
    let flag: String
    let cont: String?        // nil = spans two continents → never used in a continent round
}

private func c(_ n: String, _ f: String, _ k: String?) -> FFCountry { FFCountry(name: n, flag: f, cont: k) }

/// Level I: eight flags that look nothing alike.
private let ffTierA: [FFCountry] = [
    c("Japan", "🇯🇵", "as"), c("Canada", "🇨🇦", "na"), c("Brazil", "🇧🇷", "sa"), c("United States", "🇺🇸", "na"),
    c("United Kingdom", "🇬🇧", "eu"), c("Kenya", "🇰🇪", "af"), c("Australia", "🇦🇺", "oc"), c("China", "🇨🇳", "as"),
]
/// Level II+: more famous flags.
private let ffTierB: [FFCountry] = [
    c("France", "🇫🇷", "eu"), c("Italy", "🇮🇹", "eu"), c("Germany", "🇩🇪", "eu"), c("Mexico", "🇲🇽", "na"),
    c("India", "🇮🇳", "as"), c("South Africa", "🇿🇦", "af"), c("Argentina", "🇦🇷", "sa"), c("South Korea", "🇰🇷", "as"),
    c("Greece", "🇬🇷", "eu"), c("Jamaica", "🇯🇲", "na"), c("New Zealand", "🇳🇿", "oc"), c("Nigeria", "🇳🇬", "af"),
    c("Switzerland", "🇨🇭", "eu"), c("Spain", "🇪🇸", "eu"),
]
/// Level V+: the rest (many are look-alikes of each other or of the famous ones).
private let ffTierC: [FFCountry] = [
    c("Ireland", "🇮🇪", "eu"), c("Ivory Coast", "🇨🇮", "af"), c("Indonesia", "🇮🇩", nil), c("Monaco", "🇲🇨", "eu"),
    c("Poland", "🇵🇱", "eu"), c("Romania", "🇷🇴", "eu"), c("Chad", "🇹🇩", "af"), c("Netherlands", "🇳🇱", "eu"),
    c("Luxembourg", "🇱🇺", "eu"), c("Colombia", "🇨🇴", "sa"), c("Ecuador", "🇪🇨", "sa"), c("Venezuela", "🇻🇪", "sa"),
    c("Norway", "🇳🇴", "eu"), c("Iceland", "🇮🇸", "eu"), c("Denmark", "🇩🇰", "eu"), c("Sweden", "🇸🇪", "eu"),
    c("Finland", "🇫🇮", "eu"), c("Mali", "🇲🇱", "af"), c("Senegal", "🇸🇳", "af"), c("Guinea", "🇬🇳", "af"),
    c("Austria", "🇦🇹", "eu"), c("Peru", "🇵🇪", "sa"), c("Chile", "🇨🇱", "sa"), c("Belgium", "🇧🇪", "eu"),
    c("Hungary", "🇭🇺", "eu"), c("Bulgaria", "🇧🇬", "eu"), c("Ghana", "🇬🇭", "af"), c("Cameroon", "🇨🇲", "af"),
    c("Fiji", "🇫🇯", "oc"), c("Papua New Guinea", "🇵🇬", "oc"), c("Samoa", "🇼🇸", "oc"), c("Thailand", "🇹🇭", "as"),
    c("Vietnam", "🇻🇳", "as"), c("Bangladesh", "🇧🇩", "as"), c("Pakistan", "🇵🇰", "as"), c("Philippines", "🇵🇭", "as"),
    c("Cuba", "🇨🇺", "na"), c("Honduras", "🇭🇳", "na"), c("Guatemala", "🇬🇹", "na"), c("Uruguay", "🇺🇾", "sa"),
    c("Bolivia", "🇧🇴", "sa"), c("Morocco", "🇲🇦", "af"), c("Ethiopia", "🇪🇹", "af"),
]
private let ffAll = ffTierA + ffTierB + ffTierC
private func ffFind(_ n: String) -> FFCountry { ffAll.first { $0.name == n }! }

/// Flags that are easy to mix up.
private let ffLookalikes: [[String]] = [
    ["Ireland", "Italy", "Ivory Coast", "Mexico"], ["Indonesia", "Poland", "Austria"],
    ["Romania", "Belgium", "Mali"], ["Netherlands", "Luxembourg", "France"],
    ["Australia", "New Zealand", "United Kingdom", "Fiji"], ["Colombia", "Ecuador", "Venezuela"],
    ["Norway", "Iceland", "Denmark", "Sweden", "Finland"], ["Mali", "Senegal", "Guinea", "Cameroon", "Ghana"],
    ["Austria", "Peru", "Canada"], ["Germany", "Belgium", "Hungary", "Bulgaria"],
    ["Japan", "Bangladesh", "South Korea"], ["Chile", "Cuba", "United States"],
    ["Honduras", "Guatemala", "Argentina", "Uruguay"],
]

/// Flags that are practically identical (same colours, same layout): never on screen together,
/// in any kind of round, so a tap can always be judged by the picture.
private let ffTwins: [Set<String>] = [["Monaco", "Indonesia"], ["Chad", "Romania"]]
private func ffClashes(_ a: FFCountry, _ b: FFCountry) -> Bool {
    ffTwins.contains { $0.contains(a.name) && $0.contains(b.name) && a.name != b.name }
}
/// Drop any flag whose twin is already kept (earlier entries win, so a target listed first stays).
private func ffNoTwins(_ list: [FFCountry]) -> [FFCountry] {
    var kept: [FFCountry] = []
    for x in list where !kept.contains(where: { ffClashes($0, x) }) { kept.append(x) }
    return kept
}

private enum FFMode: Equatable { case match, name, continent }

/// What to pop right now, and which flags may float meanwhile.
private struct FFTarget: Hashable {
    let mode: FFMode
    let country: FFCountry?       // match / name
    let cont: String?             // continent
    let rings: Bool               // bubbles ringed in continent colours
    let kinds: [FFCountry]        // what may float (always includes right answers)
    func isRight(_ x: FFCountry) -> Bool {
        mode == .continent ? x.cont == cont : x.name == country?.name
    }
}

private func ffTarget(_ level: Int, avoid: String?) -> FFTarget {
    func pick(_ pool: [FFCountry]) -> FFCountry {
        var t = pool.randomElement()!
        for _ in 0..<8 where t.name == avoid { t = pool.randomElement()! }
        return t
    }
    func others(_ pool: [FFCountry], not t: FFCountry, _ n: Int) -> [FFCountry] {
        Array(ffNoTwins([t] + pool.filter { $0.name != t.name }.shuffled()).dropFirst().prefix(n))
    }
    func continent(_ pool: [FFCountry], rings: Bool) -> FFTarget {
        let usable = pool.filter { $0.cont != nil }
        let k = Array(Set(usable.compactMap(\.cont))).randomElement()!
        let right = Array(ffNoTwins(usable.filter { $0.cont == k }.shuffled()).prefix(2))
        let wrong = Array(ffNoTwins(right + usable.filter { $0.cont != k }.shuffled()).dropFirst(right.count).prefix(3))
        return FFTarget(mode: .continent, country: nil, cont: k, rings: rings, kinds: right + wrong)
    }
    func lookalike() -> FFTarget {
        let g = ffLookalikes.randomElement()!.map(ffFind)
        let t = pick(g)
        return FFTarget(mode: .name, country: t, cont: nil, rings: false, kinds: [t] + others(g, not: t, 3))
    }
    switch level {
    case 1:
        let t = pick(ffTierA)
        return FFTarget(mode: .match, country: t, cont: nil, rings: true, kinds: [t] + others(ffTierA, not: t, 2))
    case 2:
        let pool = ffTierA + ffTierB, t = pick(pool)
        return FFTarget(mode: .match, country: t, cont: nil, rings: true, kinds: [t] + others(pool, not: t, 3))
    case 3:
        let pool = ffTierA + ffTierB, t = pick(pool)
        return FFTarget(mode: .name, country: t, cont: nil, rings: true, kinds: [t] + others(pool, not: t, 3))
    case 4: return continent(ffTierA + ffTierB, rings: true)
    case 5: return continent(ffAll, rings: false)
    case 6: return lookalike()
    default: return Bool.random() ? lookalike() : continent(ffAll, rings: false)
    }
}

// MARK: - Engine

private struct FFBubble {
    let id = UUID()
    var x: CGFloat, y: CGFloat, r: CGFloat, vx: CGFloat, phase: CGFloat
    let country: FFCountry
    var pop: CGFloat = 0          // > 0 while popping (good)
    var burst: CGFloat = 0        // > 0 while bursting (wrong)
}
private struct FFFloater { var x, y: CGFloat; var text: String; var life: CGFloat; var hex: UInt }
private struct FFSpark { var x, y, vx, vy, life: CGFloat; var glyph: String }

@MainActor
private final class FlagFrenzyModel: ArcadeModel {
    @Published var target = ffTarget(1, avoid: nil)
    @Published var note: String?

    private(set) var bubbles: [FFBubble] = []
    private var floaters: [FFFloater] = []
    private var sparks: [FFSpark] = []
    private var size: CGSize = .zero
    private var lastTick: Date?
    private var spawnAcc = 0.0
    private var glowUntil = Date.distantPast
    private var noteToken = UUID()

    init() { super.init(key: GameID.flagFrenzy.rawValue) }

    // Level → pace. Rise speed in pt/s, seconds between spawns, most bubbles at once, radius.
    private var speed: CGFloat { level <= 8 ? [55, 62, 68, 74, 80, 86, 94, 100][level - 1] : min(130, 100 + CGFloat(level - 8) * 5) }
    private var spawnEvery: Double { max(0.8, 1.9 - Double(level - 1) * 0.15) }
    private var maxBubbles: Int { min(9, 3 + level) }
    private var radius: CGFloat { level == 1 ? 58 : (level <= 3 ? 52 : (level <= 5 ? 48 : 44)) }

    override func onBegin() {
        bubbles = []; floaters = []; sparks = []; note = nil
        lastTick = nil; spawnAcc = 0; glowUntil = .distantPast
        target = ffTarget(level, avoid: nil)
    }

    // MARK: Simulation (runs inside the Canvas; touches no @Published state)

    func advance(to date: Date, size: CGSize) {
        self.size = size
        guard let prev = lastTick else { lastTick = date; seed(); return }
        lastTick = date
        let dt = min(max(date.timeIntervalSince(prev), 0), 0.05)
        guard phase == .playing else { return }

        spawnAcc += dt
        if spawnAcc >= spawnEvery {
            spawnAcc = 0
            if bubbles.filter({ $0.pop == 0 && $0.burst == 0 }).count < maxBubbles { spawnOne() }
        }
        // Keep a right answer findable: if none is low enough to tap, launch one now.
        let live = bubbles.filter { $0.pop == 0 && $0.burst == 0 }
        if !live.contains(where: { target.isRight($0.country) && $0.y > size.height * 0.35 }) {
            spawn(target.kinds.filter(target.isRight).randomElement()!)
        }

        for i in bubbles.indices.reversed() {
            if bubbles[i].pop > 0 { bubbles[i].pop += CGFloat(dt) * 5; if bubbles[i].pop >= 1 { bubbles.remove(at: i) }; continue }
            if bubbles[i].burst > 0 { bubbles[i].burst += CGFloat(dt) * 1.4; if bubbles[i].burst >= 1 { bubbles.remove(at: i) }; continue }
            bubbles[i].phase += CGFloat(dt) * 2
            bubbles[i].y -= speed * CGFloat(dt)
            bubbles[i].x += bubbles[i].vx * CGFloat(dt) + sin(bubbles[i].phase) * 0.35
            let r = bubbles[i].r
            if bubbles[i].x < r { bubbles[i].x = r; bubbles[i].vx = abs(bubbles[i].vx) }
            if bubbles[i].x > size.width - r { bubbles[i].x = size.width - r; bubbles[i].vx = -abs(bubbles[i].vx) }
            if bubbles[i].y < -r { bubbles.remove(at: i) }      // escaped: no penalty
        }
        for i in sparks.indices.reversed() {
            sparks[i].life -= CGFloat(dt) * 1.6
            if sparks[i].life <= 0 { sparks.remove(at: i); continue }
            sparks[i].x += sparks[i].vx * CGFloat(dt); sparks[i].y += sparks[i].vy * CGFloat(dt)
            sparks[i].vy += CGFloat(300 * dt)
        }
        for i in floaters.indices.reversed() {
            floaters[i].life -= CGFloat(dt) * 0.8
            floaters[i].y -= CGFloat(30 * dt)
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
    }

    private func seed() {
        guard size.width > 0 else { return }
        let rights = target.kinds.filter(target.isRight)
        spawn(rights.randomElement()!, atY: size.height * 0.62)
        for k in 0..<2 { spawnOne(atY: size.height * (0.78 + CGFloat(k) * 0.14)) }
    }

    private func spawnOne(atY y: CGFloat? = nil) {
        // About a third of spawns are a right answer.
        let rights = target.kinds.filter(target.isRight), wrongs = target.kinds.filter { !target.isRight($0) }
        let pick = (Double.random(in: 0..<1) < 0.33 || wrongs.isEmpty) ? rights.randomElement()! : wrongs.randomElement()!
        spawn(pick, atY: y)
    }

    private func spawn(_ country: FFCountry, atY y: CGFloat? = nil) {
        guard size.width > 0 else { return }
        let r = radius
        // Spread out: try a few x positions and keep the one farthest from nearby bubbles.
        var best = CGFloat.random(in: r...(size.width - r)), bestGap: CGFloat = -1
        for _ in 0..<6 {
            let x = CGFloat.random(in: r...(size.width - r))
            let gap = bubbles.filter { $0.y > size.height * 0.6 }.map { abs($0.x - x) }.min() ?? .infinity
            if gap > bestGap { best = x; bestGap = gap }
        }
        bubbles.append(FFBubble(x: best, y: y ?? size.height + r, r: r, vx: .random(in: -12...12),
                                phase: .random(in: 0...6.28), country: country))
    }

    // MARK: Input

    func tap(_ p: CGPoint) {
        guard phase == .playing, !dying else { return }
        guard let i = bubbles.indices.reversed().first(where: { i in
            let b = bubbles[i]
            return b.pop == 0 && b.burst == 0 && hypot(p.x - b.x, p.y - b.y) <= b.r + 10
        }) else { return }
        let b = bubbles[i]
        if target.isRight(b.country) {
            bubbles[i].pop = 0.001
            for k in 0..<7 {
                let a = Double(k) / 7 * 2 * .pi
                sparks.append(FFSpark(x: b.x, y: b.y, vx: CGFloat(cos(a) * 170), vy: CGFloat(sin(a) * 170 - 60),
                                      life: 1, glyph: ["✨", "⭐️"][k % 2]))
            }
            floaters.append(FFFloater(x: b.x, y: b.y - b.r - 8, text: b.country.name, life: 1, hex: Lu.mint))
            hit()
            target = ffTarget(level, avoid: b.country.name)
        } else {
            bubbles[i].burst = 0.001
            floaters.append(FFFloater(x: b.x, y: b.y - b.r - 10, text: "\(b.country.flag) \(b.country.name)", life: 1.6, hex: Lu.coral))
            glowUntil = Date().addingTimeInterval(1.8)
            let why: String
            switch target.mode {
            case .continent:
                let k = b.country.cont.flatMap { ffConts[$0] }
                why = k.map { "\(b.country.name) is in \($0.icon) \($0.name)" } ?? "\(b.country.name) isn't in \(ffConts[target.cont!]!.name)"
            default: why = "That's \(b.country.name) — find the glowing one!"
            }
            say(why)
            miss(delay: 1.6)
        }
    }

    private func say(_ s: String) {
        let t = UUID(); noteToken = t; note = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in if self?.noteToken == t { self?.note = nil } }
    }

    override func botAct(correct: Bool) {
        let tappable = bubbles.filter { $0.pop == 0 && $0.burst == 0 && $0.y > 260 && $0.y < size.height - 30 }
        let choice = tappable.filter { target.isRight($0.country) == correct }.randomElement()
        if let b = choice { tap(CGPoint(x: b.x, y: b.y)) }
    }

    // MARK: Drawing

    func render(_ ctx: inout GraphicsContext) {
        let glow = Date() < glowUntil
        let t = Date().timeIntervalSinceReferenceDate
        for b in bubbles {
            var r = b.r
            var alpha = 1.0
            var dx: CGFloat = 0
            if b.pop > 0 { r *= 1 + b.pop * 0.5; alpha = Double(1 - b.pop) }
            if b.burst > 0 { dx = sin(b.burst * 40) * 8 * (1 - b.burst); alpha = Double(1 - b.burst * b.burst) }
            alpha *= Double(min(1, max(0, (b.y - 170) / 140)))      // fade out under the banner
            let rect = CGRect(x: b.x - r + dx, y: b.y - r, width: r * 2, height: r * 2)
            ctx.opacity = alpha * 0.95
            ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: b.burst > 0 ? 0xf6d0c6 : 0xfef6e9)))
            let ringHex = target.rings ? (b.country.cont.flatMap { ffConts[$0]?.tint } ?? Lu.line) : Lu.line
            ctx.opacity = alpha
            ctx.stroke(Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)), with: .color(Color(hex: ringHex)), lineWidth: target.rings ? 6 : 3)
            if glow && b.pop == 0 && b.burst == 0 && target.isRight(b.country) {
                let pulse = 0.5 + 0.5 * sin(t * 10)
                ctx.opacity = 0.6 + 0.4 * pulse
                ctx.stroke(Path(ellipseIn: rect.insetBy(dx: -6, dy: -6)), with: .color(Color(hex: Lu.gold)), lineWidth: 6)
                ctx.opacity = alpha
            }
            ctx.draw(ctx.resolve(Text(b.country.flag).font(.system(size: r * 1.35))), at: CGPoint(x: b.x + dx, y: b.y))
        }
        for s in sparks {
            ctx.opacity = Double(max(0, s.life))
            ctx.draw(ctx.resolve(Text(s.glyph).font(.system(size: 20))), at: CGPoint(x: s.x, y: s.y))
        }
        for f in floaters {
            ctx.opacity = Double(min(1, max(0, f.life)))
            let t = ctx.resolve(Text(f.text).font(luFont(20)).foregroundColor(Color(hex: f.hex)))
            let half = t.measure(in: CGSize(width: 400, height: 40)).width / 2 + 8
            ctx.draw(t, at: CGPoint(x: min(max(f.x, half), size.width - half), y: f.y))
        }
        ctx.opacity = 1
    }
}

#if DEBUG
/// Every target has at least one right flag among its kinds, and (except continent rounds) exactly
/// one; continent rounds never use a two-continent country; no flag or name is listed twice.
private func ffSelfCheck() {
    precondition(Set(ffAll.map(\.name)).count == ffAll.count && Set(ffAll.map(\.flag)).count == ffAll.count, "Flag Frenzy: duplicate")
    for g in ffLookalikes { for n in g { _ = ffFind(n) } }
    for lv in 1...12 {
        for _ in 0..<300 {
            let t = ffTarget(lv, avoid: nil)
            let right = t.kinds.filter(t.isRight).count
            precondition(right >= 1, "Flag Frenzy: no right flag at \(lv)")
            for a in t.kinds { for b in t.kinds { precondition(!ffClashes(a, b), "Flag Frenzy: twin flags together at \(lv)") } }
            if t.mode != .continent { precondition(right == 1, "Flag Frenzy: two right flags at \(lv)") }
            else { precondition(t.kinds.allSatisfy { $0.cont != nil } && right < t.kinds.count, "Flag Frenzy: bad continent round") }
        }
    }
    print("SELFCHECK flagFrenzy OK")
}
#endif

// MARK: - View

struct FlagFrenzyView: View {
    let onClose: () -> Void
    @StateObject private var model = FlagFrenzyModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.flagFrenzy.spec ?? GameSpec(title: "Flag Frenzy", mechanic: "", premise: "", game: .flagFrenzy),
                    accent: Lu.sky, onClose: onClose) {
            ZStack(alignment: .top) {
                TimelineView(.animation(paused: model.phase != .playing)) { tl in
                    Canvas { ctx, sz in
                        model.advance(to: tl.date, size: sz)
                        model.render(&ctx)
                    }
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { model.tap($0.location) })
                .ignoresSafeArea(edges: .bottom)

                FFBanner(target: model.target, note: model.note, combo: model.combo)
                    .padding(.top, 62).padding(.horizontal, 16)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            #if DEBUG
            ffSelfCheck()
            #endif
        }
    }
}

private struct FFBanner: View {
    let target: FFTarget
    let note: String?
    let combo: Int

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                switch target.mode {
                case .match:
                    Text("POP THIS FLAG").font(luFont(12, .heavy)).tracking(2).foregroundStyle(Color(hex: Lu.inkDim))
                    HStack(spacing: 12) {
                        Text(target.country!.flag).font(.system(size: 54))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.country!.name).font(luFont(22)).foregroundStyle(Color(hex: Lu.ink))
                                .lineLimit(1).minimumScaleFactor(0.6)
                            chip(target.country!.cont)
                        }
                    }
                case .name:
                    Text("FIND THE FLAG OF").font(luFont(12, .heavy)).tracking(2).foregroundStyle(Color(hex: Lu.inkDim))
                    Text(target.country!.name).font(luFont(30)).foregroundStyle(Color(hex: Lu.ink))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    if target.rings { chip(target.country!.cont) }
                case .continent:
                    Text("POP A FLAG FROM").font(luFont(12, .heavy)).tracking(2).foregroundStyle(Color(hex: Lu.inkDim))
                    let k = ffConts[target.cont!]!
                    HStack(spacing: 10) {
                        Text(k.icon).font(.system(size: 40))
                        Text(k.name).font(luFont(28)).foregroundStyle(Color(hex: k.tint))
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(luPanelShape(18))
            .id(target)
            .transition(.scale(scale: 0.85).combined(with: .opacity))

            ZStack {
                if let note {
                    Text(note).font(luFont(17, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                        .multilineTextAlignment(.center).minimumScaleFactor(0.6)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: Lu.gold)))
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                } else if combo >= 2 {
                    Text("COMBO ×\(combo)!").font(luFont(18)).foregroundStyle(Color(hex: Lu.mint))
                        .id(combo).transition(.scale(scale: 1.3).combined(with: .opacity))
                }
            }
            .frame(height: 40)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: target)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: note)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: combo)
    }

    @ViewBuilder private func chip(_ cont: String?) -> some View {
        if let k = cont.flatMap({ ffConts[$0] }) {
            HStack(spacing: 4) {
                Text(k.icon).font(.system(size: 16))
                Text(k.name).font(luFont(13, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(Color(hex: k.tint)))
        }
    }
}
