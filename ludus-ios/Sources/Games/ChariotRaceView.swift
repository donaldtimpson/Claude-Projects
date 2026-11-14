import SwiftUI

// MARK: - Circus Maximus (Forum · History · Roman life)
//
// You drive a chariot round Rome's great racetrack. Gates come galloping toward you, one in each
// lane, each flying a team's colours — Rome really had four racing teams: Reds, Whites, Greens and
// Blues. The herald calls out something Roman; steer (drag, or tap a lane) into the gate that
// matches before you reach it. Through the right gate the crowd roars; through a wrong one the
// chariot skids and the right gate lights up.
//
// What the herald asks, by `d` (tier([1, 2.5, 4, 5.5, 7])):
//   • THEN & NOW (pictures): Romans lit their homes with an oil lamp 🪔 — what do we use? 💡
//   • SPEAK LATIN (pictures): AQUA → 💧, LUPUS → 🐺 (read aloud for pre-readers)
//   • LATIN IN ENGLISH: AQUA means water → aquarium; DENS means tooth → dentist
//   • GODS, MONTHS & PLANETS: Named for Janus, god of doorways → January; OCTO means eight → October
//   • FAMOUS ROME: the volcano that buried Pompeii → Vesuvius; Rome's first emperor → Augustus
// Lanes: 2 → 3 by d≈2.8. The gates come faster as d climbs (8 s → 3.4 s, a little longer for words).

// MARK: Content

private struct CROption: Hashable { let emoji: String?; let text: String }

private struct CRQuestion {
    let kind: Int
    let cueEmoji: String?
    let cue: String          // the big line
    let ask: String          // the small line above it
    let say: String          // read aloud
    let answer: CROption
    let pool: [CROption]     // where wrong options come from
    let why: String          // shown after the gate
}

private struct CRPair { let then: String; let thenName: String; let now: String; let nowName: String; let say: String }

private let crThenNow: [CRPair] = [
    CRPair(then: "🪔", thenName: "oil lamp", now: "💡", nowName: "light bulb", say: "Romans lit their homes with oil lamps. What do we use?"),
    CRPair(then: "📜", thenName: "scroll", now: "📖", nowName: "book", say: "Romans read from scrolls. What do we read?"),
    CRPair(then: "🐎", thenName: "horse", now: "🚗", nowName: "car", say: "Romans travelled by horse. How do we travel?"),
    CRPair(then: "🔥", thenName: "torch", now: "🔦", nowName: "flashlight", say: "Romans carried a torch at night. What do we carry?"),
    CRPair(then: "🪙", thenName: "coins", now: "💳", nowName: "card", say: "Romans paid with coins. What else do we pay with?"),
    CRPair(then: "⛲️", thenName: "fountain", now: "🚰", nowName: "tap", say: "Romans fetched water from a fountain. Where do we get water?"),
    CRPair(then: "🩴", thenName: "sandals", now: "👟", nowName: "sneakers", say: "Romans wore sandals. What do we wear?"),
    CRPair(then: "🏺", thenName: "amphora jar", now: "🍾", nowName: "bottle", say: "Romans kept wine and oil in tall jars. What do we use?"),
    CRPair(then: "🐂", thenName: "ox cart", now: "🚚", nowName: "truck", say: "Romans moved heavy things by ox cart. What do we use?"),
    CRPair(then: "🏇", thenName: "rider with a letter", now: "📧", nowName: "email", say: "Romans sent letters with riders. How do we send messages?"),
    CRPair(then: "🛁", thenName: "public baths", now: "🚿", nowName: "shower", say: "Romans washed at the public baths. How do we wash?"),
]

/// Latin words with pictures (Latin spellings checked: feles / felis both attested; pila = ball).
private let crLatinPics: [(String, String, String)] = [
    ("AQUA", "💧", "water"), ("SOL", "☀️", "sun"), ("LUNA", "🌙", "moon"), ("MARE", "🌊", "sea"),
    ("CANIS", "🐶", "dog"), ("FELES", "🐱", "cat"), ("EQUUS", "🐎", "horse"), ("ROSA", "🌹", "rose"),
    ("PANIS", "🍞", "bread"), ("STELLA", "⭐️", "star"), ("ARBOR", "🌳", "tree"), ("PISCIS", "🐟", "fish"),
    ("AVIS", "🐦", "bird"), ("REX", "👑", "king"), ("LUPUS", "🐺", "wolf"), ("IGNIS", "🔥", "fire"),
    ("DOMUS", "🏠", "house"), ("LIBER", "📖", "book"), ("PILA", "⚽️", "ball"), ("MUS", "🐭", "mouse"),
]

/// (Latin, meaning, English word that grew from it).
private let crRoots: [(String, String, String)] = [
    ("AQUA", "water", "aquarium"), ("SOL", "sun", "solar"), ("LUNA", "moon", "lunar"), ("MARE", "sea", "marine"),
    ("PES", "foot", "pedal"), ("MANUS", "hand", "manual"), ("DENS", "tooth", "dentist"), ("CANIS", "dog", "canine"),
    ("FELES", "cat", "feline"), ("LIBER", "book", "library"), ("SCRIBO", "I write", "scribble"),
    ("MAGNUS", "big", "magnify"), ("CENTUM", "a hundred", "century"), ("ANNUS", "year", "annual"),
    ("PORTO", "I carry", "portable"), ("SPECTO", "I watch", "spectator"), ("VOX", "voice", "vocal"),
    ("MATER", "mother", "maternal"), ("AUDIO", "I hear", "audience"), ("TERRA", "land", "territory"),
]

/// (clue, answer, group) — answers only ever face others from the same group.
private let crNames: [(String, String, String, String)] = [
    ("🚪", "Named for Janus, god of doorways", "January", "month"),
    ("🛡️", "Named for Mars, god of war", "March", "month"),
    ("🦚", "Named for Juno, queen of the gods", "June", "month"),
    ("🏛️", "Named for Julius Caesar", "July", "month"),
    ("👑", "Named for Augustus, the first emperor", "August", "month"),
    ("7️⃣", "SEPTEM means seven (it was Rome's 7th month)", "September", "month"),
    ("8️⃣", "OCTO means eight (it was Rome's 8th month)", "October", "month"),
    ("🔟", "DECEM means ten (it was Rome's 10th month)", "December", "month"),
    ("🪽", "Named for Mercury, the speedy messenger god", "Mercury", "planet"),
    ("🌹", "Named for Venus, goddess of love", "Venus", "planet"),
    ("⚔️", "The red planet, named for the god of war", "Mars", "planet"),
    ("⚡️", "The biggest planet, named for the king of the gods", "Jupiter", "planet"),
    ("🔱", "Named for Neptune, god of the sea", "Neptune", "planet"),
    ("🌾", "Named for Saturn, god of farming", "Saturn", "planet"),
]

/// (emoji, clue, answer) — famous Rome. Decoys are the other answers.
private let crFacts: [(String, String, String)] = [
    ("🌋", "The volcano that buried Pompeii", "Vesuvius"),
    ("👑", "Rome's first emperor", "Augustus"),
    ("🗣️", "The language the Romans spoke", "Latin"),
    ("🧱", "The wall the Romans built across Britain", "Hadrian's Wall"),
    ("🏟️", "Rome's giant arena for games", "Colosseum"),
    ("🐺", "In the legend, he founded Rome", "Romulus"),
    ("🐘", "He crossed the Alps with elephants to attack Rome", "Hannibal"),
    ("🏞️", "The river Caesar crossed in 49 BC", "Rubicon"),
    ("🐍", "Queen of Egypt, friend of Julius Caesar", "Cleopatra"),
    ("🛡️", "A Roman army of about 5,000 soldiers", "Legion"),
    ("🛣️", "The 'queen of roads', running south from Rome", "Via Appia"),
    ("💧", "A stone channel that carried water to a city", "Aqueduct"),
    ("🏛️", "Rome's main square for markets and meetings", "Forum"),
    ("📜", "The council of Rome's leading men", "Senate"),
    ("🗡️", "The day Julius Caesar was killed: the Ides of…", "March"),
]

private func crMake(kind: Int) -> CRQuestion {
    switch kind {
    case 0:
        let p = crThenNow.randomElement()!
        return CRQuestion(kind: 0, cueEmoji: p.then, cue: "Romans: \(p.thenName)", ask: "WHAT DO WE USE TODAY?", say: p.say,
                          answer: CROption(emoji: p.now, text: p.nowName),
                          pool: crThenNow.map { CROption(emoji: $0.now, text: $0.nowName) },
                          why: "\(p.then) \(p.thenName) → \(p.now) \(p.nowName)")
    case 1:
        let w = crLatinPics.randomElement()!
        return CRQuestion(kind: 1, cueEmoji: nil, cue: w.0, ask: "SPEAK LATIN! WHICH ONE IS…", say: "\(w.0.lowercased())",
                          answer: CROption(emoji: w.1, text: w.2),
                          pool: crLatinPics.map { CROption(emoji: $0.1, text: $0.2) },
                          why: "\(w.0) means \(w.2) \(w.1)")
    case 2:
        let r = crRoots.randomElement()!
        return CRQuestion(kind: 2, cueEmoji: nil, cue: "\(r.0) = \(r.1)", ask: "WHICH WORD COMES FROM IT?", say: "\(r.0.lowercased()) means \(r.1)",
                          answer: CROption(emoji: nil, text: r.2), pool: crRoots.map { CROption(emoji: nil, text: $0.2) },
                          why: "\(r.0) (\(r.1)) → \(r.2)")
    case 3:
        let n = crNames.randomElement()!
        return CRQuestion(kind: 3, cueEmoji: n.0, cue: n.1, ask: n.3 == "month" ? "WHICH MONTH?" : "WHICH PLANET?", say: n.1,
                          answer: CROption(emoji: nil, text: n.2),
                          pool: crNames.filter { $0.3 == n.3 }.map { CROption(emoji: nil, text: $0.2) },
                          why: "\(n.2): \(n.1.prefix(1).lowercased() + n.1.dropFirst())")
    default:
        let f = crFacts.randomElement()!
        return CRQuestion(kind: 4, cueEmoji: f.0, cue: f.1, ask: "FAMOUS ROME", say: f.1,
                          answer: CROption(emoji: nil, text: f.2), pool: crFacts.map { CROption(emoji: nil, text: $0.2) },
                          why: "\(f.1): \(f.2)")
    }
}

/// Answers too close to share a race (a torch and a lamp both became lights).
private let crClashes: [Set<String>] = [["light bulb", "flashlight"], ["car", "truck"], ["book", "email"]]

/// The racing teams of the Circus (lane colours).
private let crTeams: [(name: String, hex: UInt)] = [("Reds", 0xd8443a), ("Blues", 0x3f7fd0), ("Greens", 0x3f9a4a), ("Whites", 0xf1ece0)]

// MARK: Model

@MainActor
private final class ChariotModel: ArcadeModel {
    enum Stage: Equatable { case racing, right, wrong }

    @Published var q = crMake(kind: 0)
    @Published var options: [CROption] = []
    @Published var correct = 0
    @Published var lanes = 2
    @Published var lane: Double = 0           // the chariot's lane (fractional while dragging)
    @Published var stage: Stage = .racing
    @Published var roundNo = 0
    @Published var gateStart = Date()
    @Published var travel: Double = 8
    @Published var teams: [Int] = [0, 1, 2]

    init() { super.init(key: GameID.chariot.rawValue) }

    override func onBegin() { lane = 0; next() }

    var target: Int { Int(lane.rounded()) }

    func next() {
        lanes = rampInt(2, 3, from: 1.8, to: 2.8)
        let kind = tier([1, 2.5, 4, 5.5, 7])
        var nq = crMake(kind: kind)
        for _ in 0..<6 where nq.answer == q.answer { nq = crMake(kind: kind) }
        q = nq
        let clash = crClashes.first { $0.contains(q.answer.text) } ?? []
        let wrong = Array(q.pool.filter { $0 != q.answer && $0.text != q.answer.text && !clash.contains($0.text) }
            .shuffled().prefix(lanes - 1))
        options = (wrong + [q.answer]).shuffled()
        correct = options.firstIndex(of: q.answer) ?? 0
        teams = Array([0, 1, 2, 3].shuffled().prefix(lanes))
        lane = min(lane.rounded(), Double(lanes - 1))
        stage = .racing
        roundNo += 1
        travel = ramp(8, 3.4, to: 9.5) + (q.kind >= 2 ? ramp(2.5, 1.6, from: 4, to: 9) : 0)
        gateStart = Date().addingTimeInterval(0.4)
        forumAfter(self, travel + 0.4, round: { $0.roundNo }) { $0.reachGate() }
        LibraryVoice.say(q.say)
    }

    func steer(to l: Double) {
        guard phase == .playing, stage == .racing else { return }
        let before = target
        lane = max(0, min(Double(lanes - 1), l))
        if target != before { Haptics.light(); Sfx.play(.whoosh, volume: 0.35) }
    }

    private func reachGate() {
        guard stage == .racing else { return }
        lane = lane.rounded()
        if target == correct {
            stage = .right
            hit()
            forumAfter(self, 1.4, round: { $0.roundNo }) { $0.next() }
        } else {
            stage = .wrong
            Sfx.play(.thud)
            let last = miss(delay: 2.6)
            LibraryVoice.say(q.why.filter { $0.isLetter || $0 == " " || $0 == "," })
            if !last { forumAfter(self, 2.8, round: { $0.roundNo }) { $0.next() } }
        }
    }

    override func botAct(correct ok: Bool) {
        guard stage == .racing else { return }
        let others = (0..<lanes).filter { $0 != correct }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            steer(to: Double(ok ? correct : (others.randomElement() ?? correct)))
        }
    }
}

// MARK: View

struct ChariotRaceView: View {
    let onClose: () -> Void
    @StateObject private var model = ChariotModel()

    var body: some View {
        ArcadeShell(model: model, spec: GameID.chariot.spec!, accent: Lu.gold,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { CRStands() }) {
            CRPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct CRPlay: View {
    @ObservedObject var model: ChariotModel

    var body: some View {
        VStack(spacing: 8) {
            Color.clear.frame(height: 56)
            CRHerald(model: model)
                .padding(.horizontal, 12)
            CRBoards(model: model)
                .padding(.horizontal, 12)
            GeometryReader { g in CRTrack(model: model, size: g.size) }
        }
    }
}

/// The herald's call: what Roman thing to match.
private struct CRHerald: View {
    @ObservedObject var model: ChariotModel

    var body: some View {
        let q = model.q
        HStack(spacing: 12) {
            if let e = q.cueEmoji {
                Text(e).font(.system(size: 46))
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(hex: 0xf3e3c0)))
                    .overlay(Circle().stroke(Color(hex: Lu.goldLine), lineWidth: 2))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(model.stage == .racing ? q.ask : (model.stage == .right ? "THE CROWD ROARS!" : "THAT GATE WAS…"))
                    .font(luFont(11, .heavy)).tracking(1.3)
                    .foregroundStyle(Color(hex: model.stage == .wrong ? 0xb3261e : 0x8a6a3a))
                Text(model.stage == .wrong ? q.why : q.cue)
                    .font(q.kind == 1 && model.stage == .racing ? luSerif(34, .black) : luFont(q.cue.count > 26 ? 17 : 21, .heavy))
                    .foregroundStyle(Color(hex: Lu.inkDark))
                    .lineLimit(2).minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            LibrarySpeakerButton(size: 42) { LibraryVoice.say(model.q.say) }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(minHeight: 82)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xfdf6e3))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: Lu.goldLine), lineWidth: 3)))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .animation(.easeOut(duration: 0.2), value: model.stage)
    }
}

/// One board per lane, in its team's colours, showing that lane's gate (readable at a glance).
private struct CRBoards: View {
    @ObservedObject var model: ChariotModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(model.options.enumerated()), id: \.offset) { i, o in
                let team = crTeams[model.teams[min(i, model.teams.count - 1)]]
                let isAnswer = i == model.correct && model.stage != .racing
                let here = model.target == i
                VStack(spacing: 2) {
                    if let e = o.emoji { Text(e).font(.system(size: model.q.kind <= 1 ? 40 : 30)) }
                    if model.q.kind >= 1 || model.d >= 2 || o.emoji == nil {
                        Text(o.text).font(luFont(o.emoji == nil ? 17 : 13, .heavy))
                            .foregroundStyle(Color(hex: team.hex == 0xf1ece0 ? Lu.inkDark : 0xffffff))
                            .lineLimit(2).minimumScaleFactor(0.55).multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: o.emoji == nil ? 58 : 76)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: team.hex)))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: isAnswer ? Lu.gold : (here ? 0xffffff : 0x00000)).opacity(isAnswer || here ? 1 : 0.3),
                            lineWidth: isAnswer ? 5 : (here ? 3 : 1.5)))
                .shadow(color: isAnswer ? Color(hex: Lu.gold) : .black.opacity(0.25), radius: isAnswer ? 10 : 3, y: 2)
                .scaleEffect(isAnswer ? 1.06 : (here ? 1.02 : 1))
                .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { model.steer(to: Double(i)) } }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: model.stage)
        .animation(.easeOut(duration: 0.15), value: model.target)
        .id(model.roundNo)
        .transition(.opacity)
    }
}

/// The sand track in perspective: lane lines rushing by, a gate per lane galloping closer, and
/// the chariot at the bottom (drag anywhere to steer, or tap a lane).
private struct CRTrack: View {
    @ObservedObject var model: ChariotModel
    let size: CGSize
    @State private var skid: CGFloat = 0

    private let farScale: CGFloat = 0.32

    var body: some View {
        let w = size.width, h = size.height
        let near = h - 92                         // the gates' line when they reach the horses
        TimelineView(.animation(paused: model.phase != .playing)) { tl in
            let now = tl.date
            let t = now.timeIntervalSinceReferenceDate
            let raw = model.stage == .racing ? now.timeIntervalSince(model.gateStart) / model.travel : 1
            let D = 1 - max(0, min(1, raw))       // 1 far … 0 at the chariot
            let speed = 1.0 / max(2.5, model.travel)
            ZStack {
                Canvas { ctx, sz in
                    drawTrack(ctx, w: w, h: h, near: near, t: t * speed * 3)
                    if model.stage == .racing || D <= 0.001 {
                        drawGates(ctx, w: w, near: near, D: model.stage == .racing ? D : 0)
                    }
                }
                chariot(t)
                    .position(x: laneX(model.lane, depth: 0, w: w), y: h - 64)
                    .modifier(ForumShake(amount: 10, shakes: skid))
            }
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in
                // The chariot follows the finger (a tap jumps it to that lane).
                withAnimation(.interactiveSpring()) { model.steer(to: laneIndex(atX: v.location.x, w: w, snap: false)) }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { model.steer(to: model.lane.rounded()) }
            })
        .onChange(of: model.stage) { s in
            if s == .wrong { withAnimation(.linear(duration: 0.5)) { skid += 1 } }
        }
    }

    private func laneWidth(_ w: CGFloat) -> CGFloat { w * 0.86 / CGFloat(model.lanes) }
    private func laneX(_ l: Double, depth: Double, w: CGFloat) -> CGFloat {
        let s = farScale + (1 - farScale) * CGFloat(1 - depth)
        let off = (CGFloat(l) - CGFloat(model.lanes - 1) / 2) * laneWidth(w)
        return w / 2 + off * s
    }
    private func laneIndex(atX x: CGFloat, w: CGFloat, snap: Bool = true) -> Double {
        let off = (x - w / 2) / laneWidth(w) + CGFloat(model.lanes - 1) / 2
        return Double(max(0, min(CGFloat(model.lanes - 1), snap ? off.rounded() : off)))
    }
    /// Screen y for a depth (1 far … 0 near): perspective-ish so gates speed up as they come.
    private func y(_ depth: Double, near: CGFloat) -> CGFloat {
        let p = pow(1 - depth, 1.6)
        return 8 + (near - 8) * CGFloat(p)
    }

    private func drawTrack(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, near: CGFloat, t: Double) {
        // Sand, widening toward us.
        var sand = Path()
        let farHalf = w * 0.46 * farScale, nearHalf = w * 0.52
        sand.move(to: CGPoint(x: w / 2 - farHalf, y: 0))
        sand.addLine(to: CGPoint(x: w / 2 + farHalf, y: 0))
        sand.addLine(to: CGPoint(x: w / 2 + nearHalf, y: h))
        sand.addLine(to: CGPoint(x: w / 2 - nearHalf, y: h))
        sand.closeSubpath()
        ctx.fill(sand, with: .linearGradient(Gradient(colors: [Color(hex: 0xd9b77a), Color(hex: 0xe9c98a), Color(hex: 0xcfa766)]),
                                             startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h)))
        // Rails.
        for side in [-1.0, 1.0] {
            var rail = Path()
            rail.move(to: CGPoint(x: w / 2 + CGFloat(side) * farHalf, y: 0))
            rail.addLine(to: CGPoint(x: w / 2 + CGFloat(side) * nearHalf, y: h))
            ctx.stroke(rail, with: .color(Color(hex: 0xf4ecda)), lineWidth: 6)
        }
        // Lane lines: dashes rushing toward us.
        for k in 1..<model.lanes {
            let l = Double(k) - 0.5
            for j in 0..<10 {
                let f = (Double(j) / 10 + t).truncatingRemainder(dividingBy: 1)
                let d0 = 1 - f, d1 = max(0, d0 - 0.045)
                var dash = Path()
                dash.move(to: CGPoint(x: laneX(l, depth: d0, w: w), y: y(d0, near: h)))
                dash.addLine(to: CGPoint(x: laneX(l, depth: d1, w: w), y: y(d1, near: h)))
                ctx.stroke(dash, with: .color(.white.opacity(0.75)), style: StrokeStyle(lineWidth: 2 + 4 * CGFloat(1 - d0), lineCap: .round))
            }
        }
        // Ruts and pebbles streaming by.
        for j in 0..<14 {
            let f = (Double(j) / 14 + t * 1.0 + Double(j % 3) * 0.13).truncatingRemainder(dividingBy: 1)
            let d = 1 - f
            let lx = (Double((j * 37) % 100) / 100) * Double(model.lanes) - 0.5
            let p = CGPoint(x: laneX(lx, depth: d, w: w), y: y(d, near: h))
            let r = 1.5 + 3 * CGFloat(1 - d)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r * 1.5, y: p.y - r / 2, width: r * 3, height: r)), with: .color(Color(hex: 0xa98552).opacity(0.6)))
        }
    }

    private func drawGates(_ ctx: GraphicsContext, w: CGFloat, near: CGFloat, D: Double) {
        let s = farScale + (1 - farScale) * CGFloat(1 - D)
        let gy = y(D, near: near)
        let lw = laneWidth(w) * s
        for i in 0..<model.lanes {
            let cx = laneX(Double(i), depth: D, w: w)
            let team = crTeams[model.teams[min(i, model.teams.count - 1)]]
            let gw = lw * 0.86, gh = 120 * s
            let postW = 9 * s
            let reveal = model.stage == .wrong && i == model.correct
            let col = Color(hex: team.hex)
            // Posts and lintel.
            for side in [-1.0, 1.0] {
                let r = CGRect(x: cx + CGFloat(side) * gw / 2 - postW / 2, y: gy - gh, width: postW, height: gh)
                ctx.fill(Path(roundedRect: r, cornerRadius: 2 * s), with: .color(Color(hex: 0xf1e7cf)))
                ctx.stroke(Path(roundedRect: r, cornerRadius: 2 * s), with: .color(.black.opacity(0.25)), lineWidth: 1)
            }
            let lintel = CGRect(x: cx - gw / 2 - postW, y: gy - gh - 22 * s, width: gw + postW * 2, height: 26 * s)
            ctx.fill(Path(roundedRect: lintel, cornerRadius: 5 * s), with: .color(col))
            ctx.stroke(Path(roundedRect: lintel, cornerRadius: 5 * s), with: .color(reveal ? Color(hex: Lu.gold) : .black.opacity(0.3)),
                       lineWidth: reveal ? 4 : 1.5)
            // A pennant hanging in the gate with the option's picture (or its first word).
            let o = model.options.indices.contains(i) ? model.options[i] : CROption(emoji: nil, text: "")
            let banner = CGRect(x: cx - gw * 0.32, y: gy - gh + 6 * s, width: gw * 0.64, height: 56 * s)
            var pen = Path()
            pen.move(to: CGPoint(x: banner.minX, y: banner.minY))
            pen.addLine(to: CGPoint(x: banner.maxX, y: banner.minY))
            pen.addLine(to: CGPoint(x: banner.maxX, y: banner.maxY))
            pen.addLine(to: CGPoint(x: banner.midX, y: banner.maxY - 12 * s))
            pen.addLine(to: CGPoint(x: banner.minX, y: banner.maxY))
            pen.closeSubpath()
            ctx.fill(pen, with: .color(col.opacity(0.92)))
            if let e = o.emoji {
                ctx.draw(Text(e).font(.system(size: 30 * s)), at: CGPoint(x: banner.midX, y: banner.midY - 4 * s))
            } else {
                ctx.draw(Text(o.text).font(luFont(13 * s, .heavy)).foregroundColor(team.hex == 0xf1ece0 ? Color(hex: Lu.inkDark) : .white),
                         at: CGPoint(x: banner.midX, y: banner.midY - 4 * s))
            }
            if reveal {
                ctx.stroke(pen, with: .color(Color(hex: Lu.gold)), lineWidth: 4)
            }
        }
    }

    /// Two horses (from behind) and the chariot with its driver, galloping.
    private func chariot(_ t: Double) -> some View {
        let gallop = sin(t * 14)
        let happy = model.stage == .right
        return ZStack {
            // Reins.
            Path { p in
                p.move(to: CGPoint(x: 70, y: 106)); p.addLine(to: CGPoint(x: 44, y: 50))
                p.move(to: CGPoint(x: 80, y: 106)); p.addLine(to: CGPoint(x: 106, y: 50))
            }
            .stroke(Color(hex: 0x5a3a1a), lineWidth: 2)
            CRHorse(phase: gallop).offset(x: -30, y: -38 + CGFloat(gallop) * 2)
            CRHorse(phase: -gallop).offset(x: 30, y: -38 - CGFloat(gallop) * 2)
            // Wheels (edge-on from behind).
            ForEach([-1.0, 1.0], id: \.self) { side in
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x4a2f1e))
                    .frame(width: 10, height: 44).offset(x: CGFloat(side) * 40, y: 46)
            }
            // The car.
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color(hex: 0xc0392b), Color(hex: 0x8a2018)], startPoint: .top, endPoint: .bottom))
                .frame(width: 72, height: 36).offset(y: 50)
            Capsule().fill(Color(hex: Lu.gold)).frame(width: 76, height: 6).offset(y: 33)
            // The driver from behind: red cloak, helmet with crest; arms up when he wins.
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Capsule().fill(Color(hex: 0xe2b48a)).frame(width: 7, height: 24)
                        .rotationEffect(.degrees(happy ? side * 150 : side * 30), anchor: .top)
                        .offset(x: CGFloat(side) * 14, y: 6)
                }
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xa82820)).frame(width: 34, height: 34).offset(y: 10)
                Circle().fill(Color(hex: 0x5a3a22)).frame(width: 22).offset(y: -12)
                ForumDome().fill(Color(hex: 0xb9bec6)).frame(width: 26, height: 12).offset(y: -18)
                Ellipse().fill(Color(hex: 0xd8443a)).frame(width: 8, height: 18).offset(y: -26)
            }
            .offset(y: happy ? 4 : 10)
        }
        .frame(width: 150, height: 150)
        .rotationEffect(.degrees(model.stage == .wrong ? 8 : (model.lane - model.lane.rounded()) * 14))
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: model.stage)
    }
}

/// A horse seen from behind: rump, tail, legs pumping, head and ears beyond.
private struct CRHorse: View {
    let phase: Double
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x6a4224)).frame(width: 20, height: 26).offset(y: -30)   // head
            ForEach([-1.0, 1.0], id: \.self) { s in
                ForumTriangle().fill(Color(hex: 0x5a361c)).frame(width: 7, height: 9).offset(x: CGFloat(s) * 6, y: -45)
            }
            Capsule().fill(Color(hex: 0x3a2412)).frame(width: 10, height: 26).offset(y: -18)     // mane
            ForEach([-1.0, 1.0], id: \.self) { s in
                Capsule().fill(Color(hex: 0x5a361c)).frame(width: 9, height: 26)
                    .offset(x: CGFloat(s) * 9, y: 22 + CGFloat(phase * s) * 5)
            }
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0x8a5a34), Color(hex: 0x5e3a1e)], startPoint: .top, endPoint: .bottom))
                .frame(width: 38, height: 40)
            Capsule().fill(Color(hex: 0x2e1c0e)).frame(width: 8, height: 26)
                .rotationEffect(.degrees(phase * 18), anchor: .top).offset(y: 14)            // tail
        }
    }
}

/// The Circus Maximus: sky over the Palatine, packed stands with waving crowds, team bunting.
private struct CRStands: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(hex: 0x5aa0d8), Color(hex: 0xa8d4ee), Color(hex: 0xf3dcae)], startPoint: .top, endPoint: .bottom)
                // Palatine hill with palace columns.
                Ellipse().fill(Color(hex: 0x7a9a5a)).frame(width: w * 1.3, height: h * 0.2).position(x: w * 0.3, y: h * 0.33)
                ForEach(0..<7, id: \.self) { i in
                    Rectangle().fill(Color(hex: 0xefe4cc)).frame(width: 5, height: h * 0.04)
                        .position(x: w * (0.12 + 0.05 * Double(i)), y: h * 0.255)
                }
                // Stands: rows of spectators on both sides of the track.
                Canvas { ctx, sz in
                    let top = sz.height * 0.3
                    let rows = 16
                    for r in 0..<rows {
                        let y = top + CGFloat(r) * sz.height * 0.045
                        let band = CGRect(x: 0, y: y, width: sz.width, height: sz.height * 0.045)
                        ctx.fill(Path(band), with: .color(Color(hex: r.isMultiple(of: 2) ? 0xcdb38a : 0xbfa478)))
                        let n = 26
                        for k in 0..<n {
                            let x = (CGFloat(k) + (r.isMultiple(of: 2) ? 0.5 : 0)) * sz.width / CGFloat(n)
                            let hue = [0xd8443a, 0x3f7fd0, 0x3f9a4a, 0xf1ece0, 0x9a6a3a, 0x6b5a8a][(k * 7 + r * 3) % 6]
                            ctx.fill(Path(ellipseIn: CGRect(x: x - 4, y: y + 2, width: 8, height: 8)), with: .color(Color(hex: 0xe2b48a)))
                            ctx.fill(Path(roundedRect: CGRect(x: x - 5, y: y + 9, width: 10, height: 9), cornerRadius: 3),
                                     with: .color(Color(hex: UInt(hue))))
                        }
                    }
                }
                // Bunting in the four team colours.
                HStack(spacing: 0) {
                    ForEach(0..<16, id: \.self) { i in
                        ForumTriangle().fill(Color(hex: crTeams[i % 4].hex)).frame(height: 18).rotationEffect(.degrees(180))
                    }
                }
                .frame(width: w).position(x: w / 2, y: h * 0.29)
            }
        }
    }
}
