import SwiftUI

// MARK: - Flag Festival  (Lighthouse · pop the balloons; GameID .flagFrenzy)
//
// It's the festival of nations on the lighthouse quay: balloons printed with flags float up into
// the dusk sky and the herald's banner calls which one to pop. A wrong pop shows that flag's name
// and makes the right balloon(s) glow — a miss always teaches. Escaped balloons cost nothing, and
// the right flag is always kept on screen.
//
// Continuous difficulty (tuned off `d`, never the level) — kinds of call fade in by tier, old
// kinds stay as review:
//   1    MATCH: the banner shows the flag itself; very different flags
//   2    MATCH among 22 famous flags
//   3    NAME: the banner shows the country's name (+ its continent chip)
//   4.5  CONTINENT: "pop a flag from 🦘 Oceania" — balloons coloured by continent
//   5.5  CONTINENT without the colours, more flags
//   6.5  NAME among look-alikes (Ireland / Italy / Ivory Coast, Indonesia / Poland / Austria…)
//   7.5  CAPITAL: "pop the flag of the country whose capital is Nairobi"
// Rise speed 55 → 115 pt/s, spawn gap 1.9 → 0.85 s, balloons on screen 3 → 9, size 58 → 44 —
// all smooth ramps of `d`.
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

private enum FFMode: Equatable { case match, name, continent, capital }

/// Capitals asked in CAPITAL rounds (only countries with one clear, official capital city).
private let ffCapitals: [String: String] = [
    "Japan": "Tokyo", "Canada": "Ottawa", "Brazil": "Brasília", "United States": "Washington, D.C.",
    "United Kingdom": "London", "Kenya": "Nairobi", "Australia": "Canberra", "China": "Beijing",
    "France": "Paris", "Italy": "Rome", "Germany": "Berlin", "Mexico": "Mexico City", "India": "New Delhi",
    "Argentina": "Buenos Aires", "South Korea": "Seoul", "Greece": "Athens", "Jamaica": "Kingston",
    "New Zealand": "Wellington", "Nigeria": "Abuja", "Spain": "Madrid", "Ireland": "Dublin", "Norway": "Oslo",
    "Sweden": "Stockholm", "Poland": "Warsaw", "Peru": "Lima", "Chile": "Santiago", "Thailand": "Bangkok",
    "Vietnam": "Hanoi", "Cuba": "Havana", "Austria": "Vienna", "Hungary": "Budapest", "Denmark": "Copenhagen",
    "Finland": "Helsinki", "Iceland": "Reykjavík", "Colombia": "Bogotá", "Ghana": "Accra", "Morocco": "Rabat",
    "Ethiopia": "Addis Ababa", "Philippines": "Manila", "Pakistan": "Islamabad", "Bangladesh": "Dhaka",
    "Belgium": "Brussels", "Romania": "Bucharest", "Bulgaria": "Sofia", "Uruguay": "Montevideo",
    "Venezuela": "Caracas", "Ecuador": "Quito", "Fiji": "Suva", "Egypt": "Cairo",
]

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
    var capital: String { country.flatMap { ffCapitals[$0.name] } ?? "" }
}

/// `kind` 0…6 (see the header); `n` = how many different flags float.
private func ffTarget(_ kind: Int, n: Int = 4, avoid: String?) -> FFTarget {
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
    switch kind {
    case 0:
        let t = pick(ffTierA)
        return FFTarget(mode: .match, country: t, cont: nil, rings: true, kinds: [t] + others(ffTierA, not: t, max(2, n - 1)))
    case 1:
        let pool = ffTierA + ffTierB, t = pick(pool)
        return FFTarget(mode: .match, country: t, cont: nil, rings: true, kinds: [t] + others(pool, not: t, n - 1))
    case 2:
        let pool = ffTierA + ffTierB, t = pick(pool)
        return FFTarget(mode: .name, country: t, cont: nil, rings: true, kinds: [t] + others(pool, not: t, n - 1))
    case 3: return continent(ffTierA + ffTierB, rings: true)
    case 4: return continent(ffAll, rings: false)
    case 5: return lookalike()
    default:
        let pool = ffAll.filter { ffCapitals[$0.name] != nil }, t = pick(pool)
        return FFTarget(mode: .capital, country: t, cont: nil, rings: false, kinds: [t] + others(ffAll, not: t, n - 1))
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
    @Published var target = ffTarget(0, avoid: nil)
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

    // Pace, all smooth in `d`: rise speed (pt/s), seconds between spawns, most balloons at once, radius.
    private var speed: CGFloat { CGFloat(ramp(55, 115, to: 9.5)) }
    private var spawnEvery: Double { ramp(1.9, 0.85, to: 9) }
    private var maxBubbles: Int { rampInt(3, 9, to: 8) }
    private var radius: CGFloat { CGFloat(ramp(58, 44, to: 6)) }

    private func nextTarget(avoid: String?) -> FFTarget {
        ffTarget(tier([1, 2, 3, 4.5, 5.5, 6.5, 7.5]), n: rampInt(3, 5, to: 6), avoid: avoid)
    }

    override func onBegin() {
        bubbles = []; floaters = []; sparks = []; note = nil
        lastTick = nil; spawnAcc = 0; glowUntil = .distantPast
        target = nextTarget(avoid: nil)
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
        // Balloons that drift into each other ease apart, so every flag stays readable and tappable.
        let liveIdx = bubbles.indices.filter { bubbles[$0].pop == 0 && bubbles[$0].burst == 0 }
        for (n, i) in liveIdx.enumerated() {
            for j in liveIdx[(n + 1)...] {
                let dx = bubbles[j].x - bubbles[i].x, dy = bubbles[j].y - bubbles[i].y
                let gap = bubbles[i].r + bubbles[j].r + 6
                let dist = max(0.5, hypot(dx * 1.1, dy * 0.9))
                guard dist < gap else { continue }
                let k = (gap - dist) * CGFloat(min(1, dt * 4)) / dist
                let ux = dx == 0 ? 1 : dx
                bubbles[i].x -= ux * k * 0.5; bubbles[j].x += ux * k * 0.5
                bubbles[i].y -= dy * k * 0.3; bubbles[j].y += dy * k * 0.3
            }
        }
        for i in bubbles.indices { let r = bubbles[i].r; bubbles[i].x = min(max(bubbles[i].x, r), size.width - r) }
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
        // Overlapping balloons: the one whose middle is nearest the finger wins.
        func dist(_ b: FFBubble) -> CGFloat { hypot(p.x - b.x, (p.y - b.y) * 0.85) }
        guard let i = bubbles.indices.filter({ i in
            let b = bubbles[i]
            return b.pop == 0 && b.burst == 0 && dist(b) <= b.r + 10
        }).min(by: { dist(bubbles[$0]) < dist(bubbles[$1]) }) else { return }
        let b = bubbles[i]
        if target.isRight(b.country) {
            bubbles[i].pop = 0.001
            for k in 0..<14 {
                let a = Double(k) / 14 * 2 * .pi + Double.random(in: 0...0.3)
                let v = Double.random(in: 120...220)
                sparks.append(FFSpark(x: b.x, y: b.y, vx: CGFloat(cos(a) * v), vy: CGFloat(sin(a) * v - 80),
                                      life: 1, glyph: ""))
            }
            let label = target.mode == .capital ? "\(target.capital) → \(b.country.name)" : b.country.name
            floaters.append(FFFloater(x: b.x, y: b.y - b.r - 8, text: label, life: 1.2, hex: 0xffffff))
            hit()
            Sfx.play(.pop)
            target = nextTarget(avoid: b.country.name)
            retireAmbiguous()
        } else {
            bubbles[i].burst = 0.001
            floaters.append(FFFloater(x: b.x, y: b.y - b.r - 10, text: "\(b.country.flag) \(b.country.name)", life: 1.6, hex: Lu.coral))
            glowUntil = Date().addingTimeInterval(1.8)
            let why: String
            switch target.mode {
            case .continent:
                let k = b.country.cont.flatMap { ffConts[$0] }
                why = k.map { "\(b.country.name) is in \($0.icon) \($0.name)" } ?? "\(b.country.name) isn't in \(ffConts[target.cont!]!.name)"
            case .capital:
                why = "That's \(b.country.name). \(target.capital) is in \(target.country!.name)!"
            default: why = "That's \(b.country.name) — find the glowing one!"
            }
            say(why)
            miss(delay: 1.6)
        }
    }

    /// Balloons from the last call keep floating, but not ones the NEW call can't judge fairly: the
    /// twin of a right flag (Chad while the call is Romania), or a two-continent country in a
    /// continent round (Indonesia while the call is Asia; Chad or Romania unless the call dealt it). They drift off with a soft poof.
    private func retireAmbiguous() {
        let rights = target.kinds.filter(target.isRight)
        for i in bubbles.indices where bubbles[i].pop == 0 && bubbles[i].burst == 0 {
            let c = bubbles[i].country
            let twinNotInCall = ffTwins.contains { $0.contains(c.name) } && !target.kinds.contains(c)
            if (target.mode == .continent && (c.cont == nil || twinNotInCall)) || rights.contains(where: { ffClashes($0, c) }) {
                bubbles[i].pop = 0.001
            }
        }
    }

    private func say(_ s: String) {
        let t = UUID(); noteToken = t; note = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in if self?.noteToken == t { self?.note = nil } }
    }

    override func botAct(correct: Bool) {
        let tappable = bubbles.filter { $0.pop == 0 && $0.burst == 0 && $0.y > size.height * 0.3 && $0.y < size.height - 30 }
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
            var squash: CGFloat = 1
            if b.pop > 0 { r *= 1 + b.pop * 0.6; alpha = Double(1 - b.pop) }
            if b.burst > 0 { dx = sin(b.burst * 40) * 8 * (1 - b.burst); alpha = Double(1 - b.burst * b.burst); squash = 1 - b.burst * 0.35 }
            alpha *= Double(min(1, max(0, (b.y - 190) / 130)))      // fade out under the banner
            let cx = b.x + dx, cy = b.y
            let w = r * 1.84 * squash, h = r * 2.16 * squash
            let body = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
            let hex: UInt = target.rings ? (b.country.cont.flatMap { ffConts[$0]?.tint } ?? Lu.line)
                                         : ffBalloonHexes[abs(b.country.name.hashValue) % ffBalloonHexes.count]
            ctx.opacity = alpha
            // string
            var s = Path()
            s.move(to: CGPoint(x: cx, y: body.maxY + 4))
            for k in 1...6 {
                let yy = body.maxY + 4 + CGFloat(k) * r * 0.22
                s.addLine(to: CGPoint(x: cx + sin(CGFloat(t) * 3 + b.phase + CGFloat(k)) * 4, y: yy))
            }
            ctx.stroke(s, with: .color(.white.opacity(0.75)), lineWidth: 1.3)
            if glow && b.pop == 0 && b.burst == 0 && target.isRight(b.country) {
                let pulse = 0.5 + 0.5 * sin(t * 10)
                ctx.opacity = alpha * (0.5 + 0.5 * pulse)
                ctx.fill(Path(ellipseIn: body.insetBy(dx: -12, dy: -12)), with: .color(Color(hex: Lu.gold).opacity(0.7)))
                ctx.opacity = alpha
            }
            // knot
            var knot = Path()
            knot.move(to: CGPoint(x: cx - 6, y: body.maxY + 6)); knot.addLine(to: CGPoint(x: cx + 6, y: body.maxY + 6))
            knot.addLine(to: CGPoint(x: cx, y: body.maxY - 2)); knot.closeSubpath()
            ctx.fill(knot, with: .color(Color(hex: hex).opacity(0.9)))
            // balloon body
            ctx.fill(Path(ellipseIn: body), with: .radialGradient(
                Gradient(colors: [Color(hex: hex).opacity(0.8), Color(hex: hex), Color(hex: hex).opacity(0.85)]),
                center: CGPoint(x: cx - w * 0.2, y: cy - h * 0.25), startRadius: 2, endRadius: h * 0.8))
            ctx.stroke(Path(ellipseIn: body), with: .color(.black.opacity(0.18)), lineWidth: 1.5)
            // flag patch
            let pr = r * 0.66
            ctx.fill(Path(ellipseIn: CGRect(x: cx - pr, y: cy - pr - h * 0.04, width: pr * 2, height: pr * 2)), with: .color(Color(hex: 0xfffaf0)))
            ctx.draw(ctx.resolve(Text(b.country.flag).font(.system(size: r * 1.05))), at: CGPoint(x: cx, y: cy - h * 0.04))
            // shine
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w * 0.36, y: cy - h * 0.38, width: w * 0.16, height: h * 0.22)), with: .color(.white.opacity(0.55)))
        }
        for s in sparks {
            ctx.opacity = Double(max(0, s.life))
            if s.glyph.isEmpty {
                let hex = ffBalloonHexes[Int(abs(s.vx)) % ffBalloonHexes.count]
                var c = ctx
                c.translateBy(x: s.x, y: s.y)
                c.rotate(by: .radians(Double(s.life) * 9 + Double(s.vx)))
                c.fill(Path(CGRect(x: -4, y: -2.5, width: 8, height: 5)), with: .color(Color(hex: hex)))
            } else {
                ctx.draw(ctx.resolve(Text(s.glyph).font(.system(size: 20))), at: CGPoint(x: s.x, y: s.y))
            }
        }
        for f in floaters {
            ctx.opacity = Double(min(1, max(0, f.life)))
            let t = ctx.resolve(Text(f.text).font(luFont(20)).foregroundColor(Color(hex: f.hex)))
            let m = t.measure(in: CGSize(width: 400, height: 40))
            let half = m.width / 2 + 10
            let p = CGPoint(x: min(max(f.x, half), size.width - half), y: f.y)
            ctx.fill(Path(roundedRect: CGRect(x: p.x - half, y: p.y - m.height / 2 - 4, width: half * 2, height: m.height + 8), cornerRadius: 10),
                     with: .color(.black.opacity(0.45)))
            ctx.draw(t, at: p)
        }
        ctx.opacity = 1
    }
}

private let ffBalloonHexes: [UInt] = [0xe0684f, 0xf5c542, 0x63b96b, 0x4fa6cf, 0xa96fd6, 0xe8973a, 0xff8fb1]

#if DEBUG
/// Every target has at least one right flag among its kinds, and (except continent rounds) exactly
/// one; continent rounds never use a two-continent country; no flag or name is listed twice.
private func ffSelfCheck() {
    precondition(Set(ffAll.map(\.name)).count == ffAll.count && Set(ffAll.map(\.flag)).count == ffAll.count, "Flag Frenzy: duplicate")
    for g in ffLookalikes { for n in g { _ = ffFind(n) } }
    for lv in 0...6 {
        for _ in 0..<300 {
            let t = ffTarget(lv, n: Int.random(in: 3...5), avoid: nil)
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
        ArcadeShell(model: model, spec: GameID.flagFrenzy.spec ?? GameSpec(title: "Flag Festival", mechanic: "", premise: "", game: .flagFrenzy),
                    accent: Lu.sky, onClose: onClose, backdrop: { FFFestival() }) {
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

                VStack(spacing: 0) {
                    HUDSpace(58)
                    FFBanner(target: model.target, note: model.note, combo: model.combo)
                }
                .padding(.horizontal, 14)
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

/// The herald's banner: a cloth pennant hung from a rope of bunting.
private struct FFBanner: View {
    let target: FFTarget
    let note: String?
    let combo: Int

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 3) {
                switch target.mode {
                case .match:
                    caption("POP THIS FLAG")
                    HStack(spacing: 12) {
                        Text(target.country!.flag).font(.system(size: 54))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.country!.name).font(luSerif(22, .black)).foregroundStyle(Color(hex: lhInk))
                                .lineLimit(1).minimumScaleFactor(0.6)
                            chip(target.country!.cont)
                        }
                    }
                case .name:
                    caption("FIND THE FLAG OF")
                    Text(target.country!.name).font(luSerif(30, .black)).foregroundStyle(Color(hex: lhInk))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    if target.rings { chip(target.country!.cont) }
                case .continent:
                    caption("POP A FLAG FROM")
                    let k = ffConts[target.cont!]!
                    HStack(spacing: 10) {
                        Text(k.icon).font(.system(size: 38))
                        Text(k.name).font(luSerif(28, .black)).foregroundStyle(Color(hex: lhInk))
                            .lineLimit(1).minimumScaleFactor(0.6)
                        if target.rings { Circle().fill(Color(hex: k.tint)).frame(width: 18, height: 18) }
                    }
                case .capital:
                    caption("WHOSE CAPITAL CITY IS")
                    HStack(spacing: 8) {
                        Text("🏛️").font(.system(size: 30))
                        Text(target.capital).font(luSerif(28, .black)).foregroundStyle(Color(hex: lhInk))
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
            }
            .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(FFPennant().fill(LinearGradient(colors: [Color(hex: 0xfbf0d6), Color(hex: 0xefdcb2)], startPoint: .top, endPoint: .bottom))
                .overlay(FFPennant().stroke(Color(hex: 0x9c7b33), lineWidth: 2))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 3))
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
                    Text("COMBO ×\(combo)!").font(luFont(18)).foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .id(combo).transition(.scale(scale: 1.3).combined(with: .opacity))
                }
            }
            .frame(height: 40)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: target)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: note)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: combo)
    }

    private func caption(_ s: String) -> some View {
        Text(s).font(luFont(11, .heavy)).tracking(2).foregroundStyle(Color(hex: lhInkSoft))
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

/// A banner with a swallow-tail notch along the bottom edge.
private struct FFPennant: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 8, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - 8, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 8), control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX + 22, y: r.maxY - 8))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX - 22, y: r.maxY - 8))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + 8))
        p.addQuadCurve(to: CGPoint(x: r.minX + 8, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Festival dusk over the harbour town: a warm sky, a low sun, bunting, rooftops and the Pharos.
private struct FFFestival: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(colors: [Color(hex: 0x2b3a7a), Color(hex: 0x7a4f9a), Color(hex: 0xe9806a), Color(hex: 0xffc983)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
                // Sun.
                let sc = CGPoint(x: w * 0.3, y: h * 0.82)
                ctx.fill(Path(ellipseIn: CGRect(x: sc.x - 90, y: sc.y - 90, width: 180, height: 180)), with: .color(Color(hex: 0xffe3a3).opacity(0.25)))
                ctx.fill(Path(ellipseIn: CGRect(x: sc.x - 46, y: sc.y - 46, width: 92, height: 92)), with: .color(Color(hex: 0xffd27a)))
                // Drifting clouds.
                for i in 0..<3 {
                    let x = (CGFloat(t) * (6 + CGFloat(i) * 4) + CGFloat(i) * 160).truncatingRemainder(dividingBy: w + 200) - 100
                    let y = h * [0.32, 0.5, 0.62][i]
                    for (dx, dy, rr) in [(0.0, 0.0, 22.0), (24, -8, 28), (52, 0, 20), (26, 8, 26)] {
                        let r = CGFloat(rr)
                        ctx.fill(Path(ellipseIn: CGRect(x: x + CGFloat(dx) - r, y: y + CGFloat(dy) - r * 0.6, width: r * 2, height: r * 1.2)),
                                 with: .color(Color(hex: 0xffe9d6).opacity(0.35)))
                    }
                }
                // Rooftops + the Pharos silhouette.
                let base = h - 70
                var town = Path()
                town.move(to: CGPoint(x: 0, y: h))
                var x: CGFloat = 0
                var i = 0
                while x < w {
                    let bw: CGFloat = [46, 34, 58, 40, 52][i % 5]
                    let bh: CGFloat = [40, 62, 34, 70, 48][i % 5]
                    town.addLine(to: CGPoint(x: x, y: base - bh))
                    if i % 3 == 1 { town.addLine(to: CGPoint(x: x + bw / 2, y: base - bh - 16)) }   // a gable
                    town.addLine(to: CGPoint(x: x + bw, y: base - bh))
                    x += bw; i += 1
                }
                town.addLine(to: CGPoint(x: w, y: h)); town.closeSubpath()
                ctx.fill(town, with: .color(Color(hex: 0x3a2350)))
                let lx = w * 0.82
                var tower = Path()
                tower.move(to: CGPoint(x: lx - 22, y: base - 30)); tower.addLine(to: CGPoint(x: lx - 12, y: base - 170))
                tower.addLine(to: CGPoint(x: lx + 12, y: base - 170)); tower.addLine(to: CGPoint(x: lx + 22, y: base - 30)); tower.closeSubpath()
                ctx.fill(tower, with: .color(Color(hex: 0x2c1a40)))
                let flick = 1 + 0.12 * sin(t * 11)
                ctx.fill(Path(ellipseIn: CGRect(x: lx - 22 * flick, y: base - 196 - 22 * flick, width: 44 * flick, height: 44 * flick)),
                         with: .color(Color(hex: 0xffd27a).opacity(0.45)))
                ctx.fill(Path(ellipseIn: CGRect(x: lx - 7, y: base - 196, width: 14, height: 20)), with: .color(Color(hex: 0xfff1b8)))
                // Lit windows.
                for k in 0..<9 {
                    let wx = CGFloat((k * 97) % 100) / 100 * w * 0.7 + 10
                    ctx.fill(Path(CGRect(x: wx, y: base - 22, width: 7, height: 10)), with: .color(Color(hex: 0xffd27a).opacity(0.8)))
                }
                // Bunting across the top (behind the herald's banner).
                for row in 0..<2 {
                    let y0 = h * (0.2 + CGFloat(row) * 0.06)
                    var rope = Path()
                    rope.move(to: CGPoint(x: -10, y: y0))
                    rope.addQuadCurve(to: CGPoint(x: w + 10, y: y0), control: CGPoint(x: w / 2, y: y0 + 40))
                    ctx.stroke(rope, with: .color(.white.opacity(0.5)), lineWidth: 1.2)
                    for k in 0..<12 {
                        let u = CGFloat(k) / 11
                        let px = -10 + (w + 20) * u
                        let py = y0 + 2 * (1 - u) * u * 40
                        var flag = Path()
                        flag.move(to: CGPoint(x: px - 8, y: py)); flag.addLine(to: CGPoint(x: px + 8, y: py)); flag.addLine(to: CGPoint(x: px, y: py + 16)); flag.closeSubpath()
                        ctx.fill(flag, with: .color(Color(hex: ffBalloonHexes[(k + row * 3) % ffBalloonHexes.count]).opacity(0.85)))
                    }
                }
            }
        }
    }
}
