import SwiftUI

// MARK: - Porta Custos  (Brain Benders · gatekeeper)
//
// Gladiators march one at a time toward the arena gate. A picture rule on the plaque says who
// may enter: tap OPEN to raise the portcullis for a gladiator who follows it; tap SHUT (or just
// wait) to keep it down, and rule-breakers bonk off the bars. Every answer shows the rule ticked
// or crossed against that gladiator, so a miss always says why.
//
// Ladder (6 right answers a level):
//   I     one colour rule ("only 🔴 shields"), two shield colours, slow march (7 s)
//   II    one rule — a shield colour OR an animal friend, three of each
//   III   AND ("🔴 + 🦁") or NOT ("no 🐺"); weapons appear
//   IV    OR, AND with a weapon, NOT; four of everything
//   V     numbers on shields: even, odd, > 5, < 4 (alone, or with a colour / animal)
//   VI    SECRET rule: a wall of ✓ / ✗ clue gladiators; work it out, then guard (one feature)
//   VII   secret rules may be NOTs; some visible "this but not that" rules
//   VIII+ secret AND rules join; the march quickens gently (floor 4.5 s visible, 5.5 s secret)

// MARK: Gladiators and rules

private enum PCColour: Int, CaseIterable {
    case red, blue, green, yellow
    var hex: UInt { [0xe0453a, 0x3b82e0, 0x46b450, 0xf2c12e][rawValue] }
}

private enum PCPet: Int, CaseIterable {
    case lion, wolf, eagle, bear
    var emoji: String { ["🦁", "🐺", "🦅", "🐻"][rawValue] }
}

private enum PCWeapon: Int, CaseIterable {
    case sword, trident, bow, axe
    var emoji: String { ["🗡️", "🔱", "🏹", "🪓"][rawValue] }
}

private struct PCGladiator: Identifiable, Equatable {
    let id = UUID()
    var colour: PCColour
    var pet: PCPet?
    var weapon: PCWeapon
    var number: Int?
}

private enum PCAtom: Hashable {
    case colour(PCColour), pet(PCPet), weapon(PCWeapon), even, odd, over(Int), under(Int)

    /// 0 colour · 1 animal · 2 weapon · 3 number — two-part rules use two different kinds.
    var kind: Int {
        switch self {
        case .colour: return 0
        case .pet: return 1
        case .weapon: return 2
        default: return 3
        }
    }

    func holds(_ g: PCGladiator) -> Bool {
        switch self {
        case .colour(let c): return g.colour == c
        case .pet(let p): return g.pet == p
        case .weapon(let w): return g.weapon == w
        case .even: return g.number.map { $0 % 2 == 0 } ?? false
        case .odd: return g.number.map { $0 % 2 == 1 } ?? false
        case .over(let n): return g.number.map { $0 > n } ?? false
        case .under(let n): return g.number.map { $0 < n } ?? false
        }
    }
}

private struct PCTerm: Hashable {
    var atom: PCAtom
    var not = false
    func holds(_ g: PCGladiator) -> Bool { atom.holds(g) != not }
}

/// One or two terms joined by AND (default) or OR.
private struct PCRule: Hashable {
    var terms: [PCTerm]
    var isOr = false
    func admits(_ g: PCGladiator) -> Bool {
        isOr ? terms.contains { $0.holds(g) } : terms.allSatisfy { $0.holds(g) }
    }
}

/// Which feature values gladiators may have at a level (fewer = less to look at).
private struct PCPool {
    var colours: [PCColour]
    var pets: [PCPet]
    var weapons: [PCWeapon]
    var numbers: Bool

    static let all = PCPool(colours: PCColour.allCases, pets: PCPet.allCases, weapons: PCWeapon.allCases, numbers: true)

    func random() -> PCGladiator {
        PCGladiator(colour: colours.randomElement()!, pet: pets.randomElement(),
                    weapon: weapons.randomElement()!, number: numbers ? Int.random(in: 1...9) : nil)
    }

    /// Every distinct gladiator this pool can make.
    var everyone: [PCGladiator] {
        var out: [PCGladiator] = []
        let ps: [PCPet?] = pets.isEmpty ? [nil] : pets.map { $0 }
        let ns: [Int?] = numbers ? Array(1...9).map { $0 } : [nil]
        for c in colours { for p in ps { for w in weapons { for n in ns {
            out.append(PCGladiator(colour: c, pet: p, weapon: w, number: n))
        } } } }
        return out
    }
}

private let pcNumberAtoms: [PCAtom] = [.even, .odd, .over(5), .under(4)]

private func pcNontrivial(_ r: PCRule, _ pool: PCPool) -> Bool {
    let e = pool.everyone
    return e.contains { r.admits($0) } && e.contains { !r.admits($0) }
}

/// A visible rule for levels I–V (and VII+ when the rule isn't secret), with its gladiator pool.
private func pcVisible(_ level: Int, avoiding old: PCRule?) -> (PCPool, PCRule) {
    func pick<T>(_ a: [T], _ n: Int) -> [T] { Array(a.shuffled().prefix(n)) }
    func t(_ a: PCAtom, not: Bool = false) -> PCTerm { PCTerm(atom: a, not: not) }
    func two(_ atoms: [PCAtom]) -> (PCAtom, PCAtom) {
        let a = atoms.randomElement()!
        let b = atoms.filter { $0.kind != a.kind }.randomElement()!
        return (a, b)
    }
    var last: (PCPool, PCRule)?
    for _ in 0..<200 {
        var pool: PCPool
        var rule: PCRule
        switch level {
        case 1:
            pool = PCPool(colours: pick(PCColour.allCases, 2), pets: [], weapons: [.sword], numbers: false)
            rule = PCRule(terms: [t(.colour(pool.colours.randomElement()!))])
        case 2:
            pool = PCPool(colours: pick(PCColour.allCases, 3), pets: pick(PCPet.allCases, 3), weapons: [.sword], numbers: false)
            let a: PCAtom = Bool.random() ? .colour(pool.colours.randomElement()!) : .pet(pool.pets.randomElement()!)
            rule = PCRule(terms: [t(a)])
        case 3:
            pool = PCPool(colours: pick(PCColour.allCases, 3), pets: pick(PCPet.allCases, 3), weapons: pick(PCWeapon.allCases, 2), numbers: false)
            let cs = pool.colours.map { PCAtom.colour($0) }, ps = pool.pets.map { PCAtom.pet($0) }
            rule = Bool.random() ? PCRule(terms: [t(cs.randomElement()!), t(ps.randomElement()!)])
                                 : PCRule(terms: [t((cs + ps).randomElement()!, not: true)])
        case 4:
            pool = PCPool(colours: PCColour.allCases, pets: PCPet.allCases, weapons: pick(PCWeapon.allCases, 3), numbers: false)
            let cs = pool.colours.map { PCAtom.colour($0) }, ps = pool.pets.map { PCAtom.pet($0) }
            let ws = pool.weapons.map { PCAtom.weapon($0) }
            switch Int.random(in: 0..<3) {
            case 0: rule = PCRule(terms: [t(cs.randomElement()!), t(ps.randomElement()!)], isOr: true)
            case 1: rule = PCRule(terms: [t((cs + ps).randomElement()!), t(ws.randomElement()!)])
            default: rule = PCRule(terms: [t((cs + ps + ws).randomElement()!, not: true)])
            }
        case 5:
            pool = .all
            let n = pcNumberAtoms.randomElement()!
            switch Int.random(in: 0..<3) {
            case 0: rule = PCRule(terms: [t(n)])
            case 1: rule = PCRule(terms: [t(n), t(.colour(PCColour.allCases.randomElement()!))])
            default: rule = PCRule(terms: [t(n), t(.pet(PCPet.allCases.randomElement()!))], isOr: true)
            }
        default:
            pool = .all
            let feats = PCColour.allCases.map { PCAtom.colour($0) } + PCPet.allCases.map { PCAtom.pet($0) }
                + PCWeapon.allCases.map { PCAtom.weapon($0) }
            let (a, b) = two(feats)
            switch Int.random(in: 0..<3) {
            case 0: rule = PCRule(terms: [t(a), t(b, not: true)])
            case 1: rule = PCRule(terms: [t(a), t(b)], isOr: true)
            default: rule = PCRule(terms: [t(pcNumberAtoms.randomElement()!), t(a)])
            }
        }
        last = (pool, rule)
        if rule != old && pcNontrivial(rule, pool) { return (pool, rule) }
    }
    return last!
}

// MARK: Secret rules (VI+)

private let pcEveryone: [PCGladiator] = PCPool.all.everyone

private struct PCClue: Identifiable {
    var g: PCGladiator
    var admitted: Bool
    var example: Bool
    var id: UUID { g.id }
}

private let pcSingles: [PCAtom] = PCColour.allCases.map { .colour($0) } + PCPet.allCases.map { .pet($0) }
    + PCWeapon.allCases.map { .weapon($0) } + [.even, .odd]

/// Secret rules a level may pick: one feature (VI), or its NOT (VII), or colour + animal (VIII+).
private func pcSecrets(_ level: Int) -> [[PCRule]] {
    let ones = pcSingles.map { PCRule(terms: [PCTerm(atom: $0)]) }
    let nots = pcSingles.map { PCRule(terms: [PCTerm(atom: $0, not: true)]) }
    var ands: [PCRule] = []
    for c in PCColour.allCases { for p in PCPet.allCases {
        ands.append(PCRule(terms: [PCTerm(atom: .colour(c)), PCTerm(atom: .pet(p))]))
    } }
    if level >= 8 { return [ones, nots, ands, ands] }
    if level == 7 { return [ones, nots] }
    return [ones]
}

/// What a player might suspect: any one feature, any two features together, and (VII+) any
/// NOT — de-duplicated by meaning ("odd" and "not even" admit the same gladiators). Clues must
/// rule out every one of these but the secret, which is a far wider net than the secrets drawn.
private func pcHypotheses(_ level: Int) -> [PCRule] {
    var hs = pcSingles.map { PCRule(terms: [PCTerm(atom: $0)]) }
    if level >= 7 { hs += pcSingles.map { PCRule(terms: [PCTerm(atom: $0, not: true)]) } }
    for (i, a) in pcSingles.enumerated() {
        for b in pcSingles[(i + 1)...] where a.kind != b.kind {
            hs.append(PCRule(terms: [PCTerm(atom: a), PCTerm(atom: b)]))
        }
    }
    var seen = Set<[Bool]>(), uniq: [PCRule] = []
    for r in hs where seen.insert(pcEveryone.map(r.admits)).inserted { uniq.append(r) }
    return uniq
}

private let pcHypoCache: [Int: [PCRule]] = [6: pcHypotheses(6), 7: pcHypotheses(7)]
private func pcHypo(_ level: Int) -> [PCRule] { pcHypoCache[min(7, level)]! }

/// Clue gladiators (labelled ✓ / ✗ by the secret rule) chosen until exactly ONE suspect rule
/// still fits them all — so the secret is always deducible. 2–5 clues in each row.
private func pcExamples(_ truth: PCRule, _ cands: [PCRule]) -> [PCClue]? {
    var alive = cands
    var clues: [PCClue] = []
    func count(_ ok: Bool) -> Int { clues.filter { $0.admitted == ok }.count }
    while alive.count > 1 || count(true) < 2 || count(false) < 2 {
        if clues.count >= 10 { return nil }
        let needRow: Bool? = alive.count > 1 ? nil : (count(true) < 2)
        var best: (g: PCGladiator, ok: Bool, rest: [PCRule], score: Int)?
        for _ in 0..<120 {
            let g = PCPool.all.random(), ok = truth.admits(g)
            if count(ok) >= 5 || (needRow != nil && ok != needRow!) { continue }
            if clues.contains(where: { $0.g.colour == g.colour && $0.g.pet == g.pet && $0.g.weapon == g.weapon }) { continue }
            let rest = alive.filter { $0.admits(g) == ok }
            let score = rest.count * 10 + count(ok)       // fewest suspects left, then balance rows
            if best == nil || score < best!.score { best = (g, ok, rest, score) }
        }
        guard let b = best, needRow != nil || b.rest.count < alive.count else { return nil }
        clues.append(PCClue(g: b.g, admitted: b.ok, example: true))
        alive = b.rest
    }
    return clues.shuffled()
}

private func pcHidden(_ level: Int, avoiding old: PCRule?) -> (PCRule, [PCClue])? {
    let pools = pcSecrets(level)
    for _ in 0..<60 {
        let truth = pools.randomElement()!.randomElement()!
        if truth == old { continue }
        if let ex = pcExamples(truth, pcHypo(level)) { return (truth, ex) }
    }
    return nil
}

/// A gladiator for the rule: about half follow it.
private func pcWalker(_ rule: PCRule, _ pool: PCPool) -> PCGladiator {
    let want = Bool.random()
    for _ in 0..<400 { let g = pool.random(); if rule.admits(g) == want { return g } }
    return pool.random()
}

/// Seconds for a gladiator to march from the left edge to the gate.
private func pcWalkTime(_ level: Int, hidden: Bool) -> Double {
    switch level {
    case 1: return 7
    case 2, 3: return 6.5
    case 4, 5: return 6
    case 6: return 7.5
    case 7: return 7
    default:
        let k = Double(level - 8)
        return hidden ? max(5.5, 7 - 0.25 * k) : max(4.5, 6 - 0.3 * k)
    }
}

// MARK: - Model

private enum PCMood {
    case walk, happy, sneaky, dizzy, sad
    var face: String {
        switch self {
        case .walk: return "😤"
        case .happy: return "😄"
        case .sneaky: return "😏"
        case .dizzy: return "😵‍💫"
        case .sad: return "😭"
        }
    }
}

private struct PCOutcome {
    var walker: PCGladiator
    var right: Bool
    var shouldEnter: Bool
    var reveal: Bool       // a secret rule, shown because the player missed
}

@MainActor
private final class PortaModel: ArcadeModel {
    @Published var rule = PCRule(terms: [PCTerm(atom: .colour(.red))])
    @Published var pool = PCPool.all
    @Published var hidden = false
    @Published var clues: [PCClue] = []
    @Published var walker: PCGladiator?
    @Published var x: CGFloat = 0           // 0 = left edge, 1 = at the gate, > 1 = through it
    @Published var mood = PCMood.walk
    @Published var gateOpen = false
    @Published var decision: Bool?
    @Published var outcome: PCOutcome?
    @Published var leaving = false
    @Published var crowd = "🙂"
    @Published var ruleVersion = 0

    private var gen = 0
    private var walkStart = Date()
    private var walkDur = 7.0
    private var sinceRule = 0
    private var ruleStale = true

    init() {
        super.init(key: GameID.portaCustos.rawValue)
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFCHECK"] != nil { pcSelfCheck() }
        #endif
    }

    override func onBegin() {
        ruleStale = true
        nextWalker()
    }

    override func onLevelUp() { ruleStale = true }

    /// Runs `f` after `s` seconds unless a new gladiator or run has started meanwhile.
    private func later(_ s: Double, _ f: @escaping () -> Void) {
        let g = gen
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in
            guard let self, self.gen == g, self.phase == .playing else { return }
            f()
        }
    }

    private func makeRule() {
        let old = rule
        ruleStale = false
        sinceRule = 0
        let secret = level >= 6 && (level == 6 || Int.random(in: 0..<4) > 0)
        if secret, let h = pcHidden(level, avoiding: old) {
            rule = h.0; pool = .all; clues = h.1; hidden = true
        } else {
            (pool, rule) = pcVisible(level, avoiding: old)
            clues = []; hidden = false
        }
        ruleVersion += 1
    }

    private func nextWalker() {
        gen += 1
        let span = level == 1 ? 6 : (hidden ? 4 : 3)
        if ruleStale || sinceRule >= span { makeRule() }
        let w = pcWalker(rule, pool)
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) {
            walker = w; x = 0; mood = .walk; leaving = false; decision = nil
        }
        withAnimation(.easeOut(duration: 0.25)) { outcome = nil; gateOpen = false; crowd = "🙂" }
        walkDur = pcWalkTime(level, hidden: hidden)
        later(0.05) { [unowned self] in
            walkStart = Date()
            withAnimation(.linear(duration: walkDur)) { x = 1 }
            later(walkDur) { [unowned self] in if decision == nil { decide(open: false) } }
        }
    }

    /// The player's call (OPEN / SHUT button, or SHUT by waiting until he reaches the bars).
    func decide(open: Bool) {
        guard phase == .playing, decision == nil, let w = walker else { return }
        decision = open
        let p = CGFloat(min(1, max(0, Date().timeIntervalSince(walkStart) / walkDur)))
        let should = rule.admits(w), right = open == should
        if open {
            withAnimation(.easeOut(duration: 0.3)) { gateOpen = true }
            let d = 0.4 + Double(1.45 - p) * 0.6
            withAnimation(.easeIn(duration: d)) { x = 1.45 }
            mood = right ? .happy : .sneaky
            later(d * 0.7) { [unowned self] in resolve(w, entered: true, should: should) }
        } else {
            let d = 0.1 + Double(1 - p) * 0.5
            withAnimation(.easeIn(duration: d)) { x = 1 }
            later(d) { [unowned self] in
                mood = right ? .dizzy : .sad
                withAnimation(.spring(response: 0.4, dampingFraction: 0.42)) { x = 0.8 }
                resolve(w, entered: false, should: should)
            }
        }
    }

    private func resolve(_ w: PCGladiator, entered: Bool, should: Bool) {
        let right = entered == should
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            outcome = PCOutcome(walker: w, right: right, shouldEnter: should, reveal: hidden && !right)
            crowd = right ? "🙌" : "😱"
        }
        if hidden {
            addClue(w, should)
            if !right { ruleStale = true }       // the secret is out — a fresh one next
        }
        sinceRule += 1
        if right { hit(points: hidden ? 2 : 1) } else { miss(delay: 2.3) }
        let wait = right ? 1.05 : 2.5            // a miss lingers so the reason sinks in
        later(wait - 0.3) { [unowned self] in withAnimation(.easeIn(duration: 0.3)) { leaving = true } }
        later(wait) { [unowned self] in if !dying { nextWalker() } }
    }

    /// A judged gladiator joins the clue wall (rows hold 5; the oldest non-example makes room).
    private func addClue(_ w: PCGladiator, _ ok: Bool) {
        if clues.filter({ $0.admitted == ok }).count >= 5 {
            guard let i = clues.firstIndex(where: { $0.admitted == ok && !$0.example }) else { return }
            clues.remove(at: i)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            clues.append(PCClue(g: w, admitted: ok, example: false))
        }
    }

    override func botAct(correct: Bool) {
        guard decision == nil, let w = walker, Date().timeIntervalSince(walkStart) > 0.8 else { return }
        let should = rule.admits(w)
        decide(open: correct ? should : !should)
    }
}

#if DEBUG
/// LUDUS_SELFCHECK=1: every generated rule is non-trivial, gladiators split ~50/50, and every
/// secret rule is pinned down by its clues alone (exactly one candidate fits). Prints a summary.
@MainActor private func pcSelfCheck() {
    var lines: [String] = []
    for level in 1...10 {
        var trivial = 0, follow = 0, total = 0
        var exCounts: [Int] = [], ambiguous = 0, failed = 0
        let cands = level >= 6 ? pcHypo(level) : []
        for _ in 0..<300 {
            let (pool, rule) = pcVisible(level, avoiding: nil)
            if !pcNontrivial(rule, pool) { trivial += 1 }
            for _ in 0..<4 { total += 1; if rule.admits(pcWalker(rule, pool)) { follow += 1 } }
            if level >= 6 {
                guard let h = pcHidden(level, avoiding: nil) else { failed += 1; continue }
                let (truth, ex) = h
                exCounts.append(ex.count)
                let fits = cands.filter { c in ex.allSatisfy { c.admits($0.g) == $0.admitted } }
                if fits.count != 1 || pcEveryone.map(fits[0].admits) != pcEveryone.map(truth.admits) { ambiguous += 1 }
                if ex.filter(\.admitted).count > 5 || ex.filter({ !$0.admitted }).count > 5 { ambiguous += 1 }
            }
        }
        var s = "L\(level): visible trivial=\(trivial) follow=\(follow)/\(total)"
        if level >= 6 {
            let avg = Double(exCounts.reduce(0, +)) / Double(max(1, exCounts.count))
            s += " secret ambiguous=\(ambiguous) failed=\(failed) clues avg=\(String(format: "%.1f", avg)) max=\(exCounts.max() ?? 0)"
        }
        lines.append(s)
    }
    let out = "PORTA SELFCHECK\n" + lines.joined(separator: "\n")
    print(out)
    try? out.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("porta_selfcheck.txt"), atomically: true, encoding: .utf8)
}
#endif

// MARK: - Pictures

/// A shield in a colour, optionally with a number or a short label on it.
private struct PCShield: View {
    let hex: UInt
    var label: String?
    let size: CGFloat
    var body: some View {
        ZStack {
            Image(systemName: "shield.fill").resizable().scaledToFit()
                .foregroundStyle(LinearGradient(colors: [luShade(hex, 50), Color(hex: hex), luShade(hex, -45)],
                                                startPoint: .top, endPoint: .bottom))
            Image(systemName: "shield").resizable().scaledToFit()
                .foregroundStyle(Color.white.opacity(0.6))
            if let label {
                Text(label).font(luFont(size * (label.count > 2 ? 0.24 : 0.42)))
                    .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, size * 0.12).offset(y: -size * 0.04)
            }
        }
        .frame(width: size * 0.86, height: size)
    }
}

private struct PCAtomGlyph: View {
    let atom: PCAtom
    let size: CGFloat
    var body: some View {
        switch atom {
        case .colour(let c): PCShield(hex: c.hex, size: size)
        case .pet(let p): Text(p.emoji).font(.system(size: size * 0.82))
        case .weapon(let w): Text(w.emoji).font(.system(size: size * 0.82))
        case .even: PCShield(hex: 0x9a7b4f, label: "2 4 6", size: size)
        case .odd: PCShield(hex: 0x9a7b4f, label: "1 3 5", size: size)
        case .over(let n): PCShield(hex: 0x9a7b4f, label: "> \(n)", size: size)
        case .under(let n): PCShield(hex: 0x9a7b4f, label: "< \(n)", size: size)
        }
    }
}

/// The red "no" ring + slash drawn over a NOT term.
private struct PCNoSign: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: 0x2a1830), lineWidth: size * 0.1)
            Capsule().fill(Color(hex: 0x2a1830)).frame(width: size * 0.1, height: size * 0.92)
                .rotationEffect(.degrees(-45))
        }
        .frame(width: size, height: size)
    }
}

/// One rule term on an ivory tile; `mark` adds a ✓ / ✗ badge (does this gladiator meet it?).
private struct PCChip: View {
    let term: PCTerm
    let size: CGFloat
    var mark: Bool?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22).fill(Color(hex: Lu.ink))
            PCAtomGlyph(atom: term.atom, size: size * 0.68)
            if term.not { PCNoSign(size: size * 0.84).opacity(0.9) }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .topTrailing) {
            if let m = mark {
                Image(systemName: m ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(.white, Color(hex: m ? Lu.mint : Lu.coral))
                    .offset(x: size * 0.14, y: -size * 0.14)
            }
        }
    }
}

private struct PCRuleRow: View {
    let rule: PCRule
    let size: CGFloat
    var marks: PCGladiator?
    var body: some View {
        HStack(spacing: size * 0.16) {
            ForEach(Array(rule.terms.enumerated()), id: \.offset) { i, term in
                if i > 0 {
                    VStack(spacing: -2) {
                        Text(rule.isOr ? "or" : "+").font(luFont(size * (rule.isOr ? 0.4 : 0.55)))
                        Text(rule.isOr ? "OR" : "AND").font(luFont(size * 0.17, .heavy))
                    }
                    .foregroundStyle(Color(hex: Lu.gold))
                }
                PCChip(term: term, size: size, mark: marks.map { term.holds($0) })
            }
        }
    }
}

/// A gladiator: animal friend at his heels, a face that reacts, a shield and a weapon.
private struct PCFigure: View {
    let g: PCGladiator
    let face: String
    let size: CGFloat
    var body: some View {
        HStack(alignment: .bottom, spacing: -size * 0.12) {
            if let p = g.pet { Text(p.emoji).font(.system(size: size * 0.36)) }
            VStack(spacing: -size * 0.07) {
                Text(face).font(.system(size: size * 0.4))
                PCShield(hex: g.colour.hex, label: g.number.map(String.init), size: size * 0.54)
            }
            .overlay(alignment: .trailing) {
                Text(g.weapon.emoji).font(.system(size: size * 0.32)).offset(x: size * 0.24, y: -size * 0.06)
            }
        }
        .background(alignment: .bottom) {
            Ellipse().fill(Color.black.opacity(0.22)).frame(width: size * 0.8, height: size * 0.12).offset(y: size * 0.05)
        }
    }
}

/// A small clue card for the secret-rule wall.
private struct PCMini: View {
    let g: PCGladiator
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color(hex: Lu.ink).opacity(0.92))
            PCShield(hex: g.colour.hex, label: g.number.map(String.init), size: size * 0.6).offset(y: size * 0.12)
            HStack(spacing: 0) {
                Text(g.pet?.emoji ?? "").font(.system(size: size * 0.32))
                Spacer(minLength: 0)
                Text(g.weapon.emoji).font(.system(size: size * 0.3))
            }
            .padding(.horizontal, 2).offset(y: -size * 0.27)
        }
        .frame(width: size, height: size)
    }
}

/// Walks the figure along the lane from `x` (animatable, so every frame gets a stride bob).
private struct PCStride: AnimatableModifier {
    var x: CGFloat
    let from: CGFloat, to: CGFloat, footY: CGFloat, height: CGFloat
    var animatableData: CGFloat {
        get { x }
        set { x = newValue }
    }
    func body(content: Content) -> some View {
        let px = from + (to - from) * x
        let inside = max(0, x - 1.02)                 // past the bars: shrink into the dark
        content
            .scaleEffect(1 - inside * 0.9, anchor: .bottom)
            .rotationEffect(.degrees(Double(sin(x * 30)) * 3))
            .opacity(Double(1 - min(1, inside / 0.35)))
            .position(x: px, y: footY - height / 2 - abs(sin(x * 15)) * 7)
    }
}

/// An arched opening.
private struct PCArch: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rad = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + rad))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + rad), radius: rad,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// The iron grid of the portcullis.
private struct PCBars: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let cols = 5, rows = 6
        for i in 0..<cols {
            let x = r.minX + r.width * (CGFloat(i) + 0.5) / CGFloat(cols)
            p.move(to: CGPoint(x: x, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY))
        }
        for j in 1..<rows {
            let y = r.minY + r.height * CGFloat(j) / CGFloat(rows)
            p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y))
        }
        return p
    }
}

private struct PCGate: View {
    let open: Bool
    let w: CGFloat, h: CGFloat
    var body: some View {
        ZStack {
            PCArch().fill(LinearGradient(colors: [Color(hex: 0x0d0718), Color(hex: 0x2a1a10)],
                                         startPoint: .top, endPoint: .bottom))
            PCBars().stroke(Color(hex: 0x4a4656), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))
                .overlay(PCBars().stroke(Color(hex: 0x8d8899), lineWidth: w * 0.02))
                .offset(y: open ? -h * 0.86 : 0)
                .clipShape(PCArch())
            PCArch().stroke(LinearGradient(colors: [Color(hex: 0xe2c48e), Color(hex: 0x9c7442)],
                                           startPoint: .top, endPoint: .bottom), lineWidth: w * 0.13)
        }
        .frame(width: w, height: h)
    }
}

// MARK: - View

struct PortaCustosView: View {
    let onClose: () -> Void
    @StateObject private var model = PortaModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.portaCustos.spec ?? GameSpec(title: "Porta Custos", mechanic: "", premise: "", game: .portaCustos),
                    accent: Lu.grape, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)
                plaque
                PCArena(model: model).frame(minHeight: 200)
                strip.frame(height: 74)
                buttons
            }
            .padding(.horizontal, 14).padding(.bottom, 8)
        }
    }

    // MARK: Rule plaque

    private var plaque: some View {
        VStack(spacing: 6) {
            if model.hidden {
                HStack(spacing: 6) {
                    Text("🕵️").font(.system(size: 18))
                    Text("Secret rule").font(luSerif(15, .heavy)).textCase(.uppercase).tracking(2)
                }
                .foregroundStyle(Color(hex: Lu.gold))
                clueRow(true)
                clueRow(false)
            } else {
                HStack(spacing: 6) {
                    Text("🚪").font(.system(size: 18))
                    Text("Only let in").font(luSerif(15, .heavy)).textCase(.uppercase).tracking(2)
                }
                .foregroundStyle(Color(hex: Lu.gold))
                PCRuleRow(rule: model.rule, size: model.rule.terms.count == 1 ? 92 : 78)
                    .id(model.ruleVersion)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .background(luPanelShape(18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: Lu.goldLine), lineWidth: 2))
        .animation(.spring(response: 0.4, dampingFraction: 0.55), value: model.ruleVersion)
    }

    private func clueRow(_ ok: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white, Color(hex: ok ? Lu.mint : Lu.coral))
                .frame(width: 30)
            ForEach(model.clues.filter { $0.admitted == ok }) { c in
                PCMini(g: c.g, size: 56)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: ok ? Lu.mint : Lu.coral), lineWidth: 2.5))
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .frame(height: 58)
    }

    // MARK: Verdict strip — the rule ticked against the gladiator who just reached the gate

    @ViewBuilder private var strip: some View {
        if let o = model.outcome {
            HStack(spacing: 10) {
                if model.hidden && !o.reveal {
                    Text("✓").font(luFont(34)).foregroundStyle(Color(hex: Lu.mint))
                } else {
                    VStack(spacing: 2) {
                        if o.reveal {
                            Text("THE RULE").font(luFont(10, .heavy)).tracking(1.5).foregroundStyle(Color(hex: Lu.inkDim))
                        }
                        PCRuleRow(rule: model.rule, size: o.reveal ? 42 : 48, marks: o.walker)
                    }
                    Image(systemName: "arrow.right").font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Color(hex: Lu.inkDim))
                }
                Text(o.shouldEnter ? "🚪 IN" : "⛔ OUT")
                    .font(luFont(22)).foregroundStyle(Color(hex: Lu.inkDark))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: o.right ? Lu.mint : Lu.coral)))
                    .scaleEffect(o.right ? 1 : 1.08)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: o.right ? Lu.mint : Lu.coral).opacity(0.16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: o.right ? Lu.mint : Lu.coral), lineWidth: 2)))
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        } else {
            Color.clear
        }
    }

    // MARK: OPEN / SHUT

    private var buttons: some View {
        let live = model.decision == nil && model.walker != nil && model.phase == .playing
        return HStack(spacing: 12) {
            PCBigButton(icon: "🚪", title: "OPEN", hex: Lu.mint, enabled: live) { model.decide(open: true) }
            PCBigButton(icon: "✋", title: "SHUT", hex: Lu.coral, enabled: live) { model.decide(open: false) }
        }
    }
}

private struct PCBigButton: View {
    let icon: String, title: String
    let hex: UInt
    let enabled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(icon).font(.system(size: 34))
                Text(title).font(luFont(26)).foregroundStyle(Color(hex: Lu.inkDark))
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [luShade(hex, 30), Color(hex: hex)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.35), lineWidth: 2)))
            .background(RoundedRectangle(cornerRadius: 20).fill(luShade(hex, -70)).offset(y: 5))
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// The arena wall, the gate and the marching gladiator.
private struct PCArena: View {
    @ObservedObject var model: PortaModel

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let gateW = min(112, w * 0.29), gateH = h * 0.78
            let footY = h * 0.86
            let gateX = w - gateW / 2 - 8
            let fig = min(150, h * 0.56)
            let start = -fig * 0.35, stop = gateX - gateW / 2 - fig * 0.36
            ZStack {
                // Wall and sand
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color(hex: 0xc79f6a), Color(hex: 0xa57a48)], startPoint: .top, endPoint: .bottom)
                        .overlay(alignment: .top) {
                            Text(String(repeating: model.crowd, count: 12))
                                .font(.system(size: 17)).lineLimit(1).fixedSize()
                                .frame(width: w, alignment: .center).clipped()
                                .padding(.top, 6).opacity(0.85)
                        }
                        .overlay(alignment: .bottom) {
                            VStack(spacing: 18) {
                                ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color.black.opacity(0.08)).frame(height: 2) }
                            }
                            .padding(.bottom, 14)
                        }
                        .frame(height: h * 0.72)
                    LinearGradient(colors: [Color(hex: 0xe6c98f), Color(hex: 0xd2ad6e)], startPoint: .top, endPoint: .bottom)
                }
                // The gladiator
                if let g = model.walker {
                    PCFigure(g: g, face: model.mood.face, size: fig)
                        .rotationEffect(.degrees(model.mood == .dizzy || model.mood == .sad ? -12 : 0))
                        .modifier(PCStride(x: model.x, from: start, to: stop, footY: footY, height: fig))
                        .opacity(model.leaving ? 0 : 1)
                        .id(g.id)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: model.mood)
                }
                PCGate(open: model.gateOpen, w: gateW, h: gateH)
                    .position(x: gateX, y: footY - gateH / 2 + 4)
                if model.mood == .dizzy || model.mood == .sad {
                    VStack(spacing: 0) {
                        Text("💫").font(.system(size: 34))
                        Text("BONK!").font(luFont(22)).foregroundStyle(Color(hex: Lu.inkDark))
                    }
                    .position(x: stop + fig * 0.1, y: footY - fig * 1.08)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
                if model.mood == .happy {
                    Text("🎉").font(.system(size: 40))
                        .position(x: gateX, y: footY - gateH - 6)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: model.mood)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: Lu.goldLine), lineWidth: 2))
    }
}
