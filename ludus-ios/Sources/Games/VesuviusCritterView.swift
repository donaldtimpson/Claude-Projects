import SwiftUI

// MARK: - Critter Sort (Vesuvius · Science — animal classes)
//
// A cart rolls into the Emperor's menagerie with one animal at a time. Around the sandy courtyard
// stand the animal houses — MAMMAL, BIRD, FISH, REPTILE, AMPHIBIAN. SWIPE (fling) the animal toward
// its house and it sails across in an arc; or tap a house. Right: it hops in and the house cheers.
// Wrong: it bounces off the door ("Not my house!"), then trots into the RIGHT house with the reason
// ("A bat is a MAMMAL — it has fur and feeds its babies milk"), so a miss always teaches.
//
// Continuous difficulty (all off `d`):
//   • houses open one at a time: mammal + bird at the start, fish from d≈2, reptile d≈3, amphibian
//     d≈4 (a house never closes again within a run), and the newest house gets extra visitors;
//   • the tricky ones (bat, whale, penguin, shark, sea turtle, axolotl…) fade in from d≈4.5;
//   • names under the pictures fade in from d≈1.6; from d≈6.5 some animals come as a NAME only;
//   • a patience bar appears at d≈5 (15 s — after the last house and the first tricky ones, so
//     no two new things land together) and shortens to 6 s by d≈9.5. It sits FULL until the
//     question has been said (and any "New house!" news with it), then starts to drain.
//
// Each animal comes with a question, shown and read aloud for pre-readers ("Is the goat a mammal
// or a bird?"; with all five houses, "Which house does the goat go in?"); 🔊 repeats it.

private struct CHouse: Identifiable, Equatable {
    let id: String, title: String, icon: String, tint: UInt, why: String
}

private let chHouses: [CHouse] = [
    CHouse(id: "mammal", title: "MAMMAL", icon: "🐾", tint: 0xc8553d, why: "has fur or hair and feeds its babies milk"),
    CHouse(id: "bird", title: "BIRD", icon: "🪶", tint: 0x3f86c6, why: "has feathers and lays eggs"),
    CHouse(id: "fish", title: "FISH", icon: "🫧", tint: 0x2a9d8f, why: "breathes with gills and swims with fins"),
    CHouse(id: "reptile", title: "REPTILE", icon: "🦎", tint: 0x6a8f2e, why: "has dry, scaly skin"),
    CHouse(id: "amphibian", title: "AMPHIBIAN", icon: "🐸", tint: 0xc99a1e, why: "has smooth, damp skin and starts life in water"),
]
/// When each house opens (d).
private let chOpens: [Double] = [0, 0, 2, 3, 4]

private struct CCritter: Equatable {
    let emoji: String
    let name: String
    let cls: String
    var hue = 0.0
    var tricky: String? = nil      // the special reason for a tricky one
}

private func c(_ e: String, _ n: String, _ k: String, hue: Double = 0, _ t: String? = nil) -> CCritter {
    CCritter(emoji: e, name: n, cls: k, hue: hue, tricky: t)
}

private let chCritters: [CCritter] = [
    // Mammals
    c("🐕", "dog", "mammal"), c("🐈", "cat", "mammal"), c("🐄", "cow", "mammal"), c("🐖", "pig", "mammal"),
    c("🐎", "horse", "mammal"), c("🐇", "rabbit", "mammal"), c("🐘", "elephant", "mammal"), c("🐁", "mouse", "mammal"),
    c("🐒", "monkey", "mammal"), c("🦒", "giraffe", "mammal"), c("🐅", "tiger", "mammal"), c("🦓", "zebra", "mammal"),
    c("🐑", "sheep", "mammal"), c("🐐", "goat", "mammal"), c("🦔", "hedgehog", "mammal"), c("🐿️", "squirrel", "mammal"),
    c("🦇", "bat", "mammal", "it flies, but it has fur and feeds its babies milk"),
    c("🐋", "whale", "mammal", "it lives in the sea, but breathes air and feeds its babies milk"),
    c("🐬", "dolphin", "mammal", "it swims, but breathes air and feeds its babies milk"),
    c("🦭", "seal", "mammal", "it swims, but has fur and feeds its babies milk"),
    c("🦦", "otter", "mammal", "it swims, but has thick fur and feeds its babies milk"),
    c("", "platypus", "mammal", "it lays eggs, but it has fur and feeds its babies milk"),
    // Birds
    c("🐓", "rooster", "bird"), c("🦆", "duck", "bird"), c("🦉", "owl", "bird"), c("🦜", "parrot", "bird"),
    c("🦅", "eagle", "bird"), c("🦢", "swan", "bird"), c("🦩", "flamingo", "bird"), c("🦚", "peacock", "bird"),
    c("🕊️", "dove", "bird"), c("🦃", "turkey", "bird"),
    c("🐧", "penguin", "bird", "it can't fly, but it has feathers and lays eggs"),
    c("🦤", "dodo", "bird", "it couldn't fly, but it had feathers and laid eggs"),
    // Fish
    c("🐠", "clownfish", "fish"), c("🐡", "pufferfish", "fish"), c("🐟", "trout", "fish"),
    c("🦈", "shark", "fish", "it's huge, but it breathes with gills — a shark is a fish"),
    c("", "seahorse", "fish", "it looks like a little horse, but it breathes with gills and has fins"),
    // Reptiles
    c("🐍", "snake", "reptile"), c("🦎", "lizard", "reptile"), c("🐢", "tortoise", "reptile"), c("🐊", "crocodile", "reptile"),
    c("🐢", "sea turtle", "reptile", hue: 40, "it lives in the sea, but has scales and breathes air"),
    c("🦎", "chameleon", "reptile", hue: 90, "it changes colour, but it has dry, scaly skin"),
    // Amphibians
    c("🐸", "frog", "amphibian"), c("🐸", "toad", "amphibian", hue: -60, "its skin is dry and bumpy, but it starts life as a tadpole in water"),
    c("", "newt", "amphibian"),
    c("", "axolotl", "amphibian", "it never leaves the water, but it's an amphibian, like a frog"),
    c("", "salamander", "amphibian", "it looks like a lizard, but has damp skin with no scales"),
]

// MARK: Model

@MainActor
private final class CritterModel: ArcadeModel {
    enum Stage: Equatable { case waiting, flying(String), home, bounced(String), walking }
    @Published var houses: [CHouse] = []
    @Published var critter = chCritters[0]
    @Published var stage: Stage = .waiting
    @Published var showPicture = true
    @Published var roundID = 0
    @Published var lesson: String?
    @Published var news: String?
    @Published var deadline: Date?
    @Published var patience: Double = 0
    @Published var prompt = ""
    @Published var cheers = 0
    private let clock = VesRunClock()
    private var recent: [String] = []
    private var timeout: DispatchWorkItem?

    init() { super.init(key: GameID.critterSort.rawValue) }

    var namesAlpha: Double { ramp(0, 1, from: 1.4, to: 2.2) }

    override func onBegin() {
        clock.reset()
        houses = []
        recent = []
        openHouses(announce: false)
        serve()
    }

    /// Opens every house whose time has come (never closes one).
    @discardableResult
    private func openHouses(announce: Bool) -> Bool {
        let n = max(houses.count, chOpens.filter { $0 <= d }.count)
        guard n > houses.count else { return false }
        let added = chHouses[houses.count]
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { houses = Array(chHouses.prefix(n)) }
        if announce {
            news = "New house: \(added.icon) \(added.title)!"
            Sfx.play(.sparkle)
            clock.after(2.4) { self.news = nil }
        }
        return announce
    }

    private func serve() {
        let announced = openHouses(announce: roundID > 0)
        roundID += 1
        let open = houses.map(\.id)
        let pool = chCritters.filter { open.contains($0.cls) && !recent.contains($0.name) }
        let tricky = pool.filter { $0.tricky != nil }
        let plain = pool.filter { $0.tricky == nil }
        var pick: CCritter
        if !tricky.isEmpty, chance(0.6, from: 4.5, to: 8) {
            pick = tricky.randomElement()!
        } else if let newest = open.last, open.count > 2, Double.random(in: 0..<1) < 0.35,
                  let p = plain.filter({ $0.cls == newest }).randomElement() {
            pick = p
        } else {
            // Even over the open classes (not by how many animals each has).
            let cls = open.randomElement()!
            pick = plain.filter { $0.cls == cls }.randomElement() ?? pool.randomElement()!
        }
        critter = pick
        recent = Array((recent + [pick.name]).suffix(6))
        showPicture = !pick.emoji.isEmpty && !chance(0.35, from: 6.5, to: 9.5)
        stage = .waiting
        lesson = nil
        prompt = question(pick)
        // Patience (none for the youngest). The clock starts once the question has been said;
        // until then the bar shows full.
        timeout?.cancel()
        deadline = nil
        patience = d >= 5 ? ramp(15, 6, from: 5, to: 9.5) : 0
        let id = roundID
        let news = announced ? "New house: \(houses.last!.title.lowercased())! " : ""
        LibraryVoice.say(news + prompt) { [weak self] in
            guard let self, self.roundID == id, self.patience > 0 else { return }
            self.startClock(round: id)
        }
    }

    /// "Is the goat a mammal or a bird?" — or, with all five houses open, "Which house does
    /// the goat go in?"
    private func question(_ c: CCritter) -> String {
        let names = houses.map { ($0.id == "amphibian" ? "an " : "a ") + $0.id }
        guard names.count <= 4 else { return "Which house does the \(c.name) go in?" }
        let list = names.count == 2 ? names.joined(separator: " or ")
                                    : names.dropLast().joined(separator: ", ") + " or " + names.last!
        return "Is the \(c.name) \(list)?"
    }

    private func startClock(round id: Int) {
        guard phase == .playing, stage == .waiting else { return }
        deadline = Date().addingTimeInterval(patience)
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.roundID == id, self.stage == .waiting, self.phase == .playing else { return }
            self.wrong(nil)
        }
        timeout = item
        DispatchQueue.main.asyncAfter(deadline: .now() + patience, execute: item)
    }

    /// 🔊: ask again (a clock still waiting keeps waiting).
    func sayAgain() { LibraryVoice.say(prompt) }

    /// Send the animal to house `id` (a swipe, a tap on a house, and the bot all land here).
    func send(to id: String) {
        guard phase == .playing, stage == .waiting, houses.contains(where: { $0.id == id }) else { return }
        timeout?.cancel(); deadline = nil
        Sfx.play(.whoosh)
        withAnimation(.easeOut(duration: 0.45)) { stage = .flying(id) }
        if id == critter.cls {
            clock.after(0.45) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { self.stage = .home }
                self.cheers += 1
                Sfx.play(.pop)
                self.hit()
                self.clock.after(0.9) { self.next() }
            }
        } else {
            clock.after(0.45) { self.wrong(id) }
        }
    }

    private func wrong(_ id: String?) {
        Sfx.play(.thud)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { stage = .bounced(id ?? "") }
        let last = miss(reason: id == nil ? "Too slow!" : "Out of hearts!", delay: 3.0)
        let h = chHouses.first { $0.id == critter.cls }!
        let art = "aeiou".contains(critter.name.first!) ? "An" : "A"
        let a2 = h.id == "amphibian" ? "an" : "a"
        lesson = "\(art) \(critter.name) is \(a2) \(h.title): " + (critter.tricky ?? "it " + h.why)
        clock.after(0.9) {
            Sfx.play(.whoosh)
            withAnimation(.easeInOut(duration: 0.9)) { self.stage = .walking }
        }
        if !last { clock.after(3.4) { self.next() } }
    }

    private func next() {
        guard phase == .playing else { return }
        withAnimation(.easeInOut(duration: 0.3)) { serve() }
    }

    override func botAct(correct: Bool) {
        guard stage == .waiting else { return }
        if correct { send(to: critter.cls) }
        else if let w = houses.first(where: { $0.id != critter.cls }) { send(to: w.id) }
    }
}

// MARK: Views

struct CritterSwipeView: View {
    let onClose: () -> Void
    @StateObject private var model = CritterModel()

    var body: some View {
        ArcadeShell(model: model,
                    spec: GameID.critterSort.spec ?? GameSpec(title: "Critter Sort", mechanic: "", premise: "", game: .critterSort),
                    accent: Lu.mint, onClose: onClose,
                    backdrop: { Courtyard() }) {
            CritterPlay(model: model)
        }
    }
}

private struct CritterPlay: View {
    @ObservedObject var model: CritterModel
    @State private var drag: CGSize = .zero

    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            let center = CGPoint(x: W / 2, y: H * 0.68)
            let spots = houseSpots(W: W, H: H, center: center)
            ZStack {
                // houses
                ForEach(Array(model.houses.enumerated()), id: \.element.id) { i, h in
                    let target = isTarget(h.id)
                    HouseView(house: h, state: target, compact: model.houses.count >= 4,
                              guest: houseGuest(h.id))
                        .frame(width: model.houses.count >= 4 ? 96 : 120, height: model.houses.count >= 4 ? 112 : 130)
                        .position(spots[i])
                        .onTapGesture { model.send(to: h.id) }
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
                // the cart + the animal
                CartView().frame(width: 150, height: 70).position(x: center.x, y: center.y + 58)
                critterView
                    .position(critterPos(spots: spots, center: center))
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { v in if model.stage == .waiting { drag = v.translation } }
                            .onEnded { v in
                                guard model.stage == .waiting else { return }
                                let dx = v.predictedEndTranslation.width, dy = v.predictedEndTranslation.height
                                if hypot(dx, dy) > 40, let id = aim(dx: dx, dy: dy, spots: spots, center: center) {
                                    drag = .zero
                                    model.send(to: id)
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { drag = .zero }
                                }
                            }
                    )
                    .onChange(of: model.roundID) { _ in drag = .zero }
                VesBurst(trigger: model.cheers, emojis: ["✨", "⭐️", "💛", "🎉"], radius: 90, size: 26)
                    .position(model.houses.firstIndex { $0.id == model.critter.cls }.map { spots[$0] } ?? center)
                // the question
                HStack(spacing: 8) {
                    LibrarySpeakerButton(size: 36) { model.sayAgain() }
                    Text(model.prompt).font(luSerif(18, .black)).foregroundStyle(Color(hex: 0x2a1a08))
                        .multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.7)
                }
                .padding(.leading, 6).padding(.trailing, 14).padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: 0xfff6e0).opacity(0.95))
                    .overlay(Capsule().stroke(Color(hex: 0x9c7b33), lineWidth: 2)))
                .frame(maxWidth: W - 24)
                .position(x: W / 2, y: 84)
                .opacity(model.stage == .waiting ? 1 : 0.8)
                // patience (full while the question is being asked)
                if model.patience > 0, model.deadline != nil || model.stage == .waiting {
                    TimelineView(.animation(minimumInterval: 0.1)) { tl in
                        let left = model.deadline.map { min(1, max(0, $0.timeIntervalSince(tl.date)) / max(0.1, model.patience)) } ?? 1
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.25))
                            Capsule().fill(Color(hex: left < 0.3 ? Lu.coral : Lu.mint)).frame(width: 150 * left)
                        }
                        .frame(width: 150, height: 10)
                    }
                    .position(x: center.x, y: center.y + 112)
                }
                // lesson / news
                if let text = model.lesson ?? model.news {
                    Text(text).font(luFont(17, .heavy)).foregroundStyle(Color(hex: 0x2a1a08))
                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.7)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: model.lesson != nil ? 0xfff3d0 : 0xd6f5c8))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0x9c7b33), lineWidth: 2)))
                        .frame(maxWidth: W - 32)
                        .position(x: W / 2, y: H - 46)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.lesson)
        }
    }

    private func houseSpots(W: CGFloat, H: CGFloat, center: CGPoint) -> [CGPoint] {
        let n = model.houses.count
        let rx = W / 2 - (n >= 4 ? 48 : 60) - 12, ry = H * 0.44   // half a house + a margin from the edge
        return (0..<n).map { i in
            let a = n <= 1 ? Double.pi / 2 : Double.pi - Double(i) * Double.pi / Double(n - 1)
            let lift: CGFloat = n == 2 ? H * 0.16 : 0    // two houses sit a little higher than the cart
            return CGPoint(x: center.x + rx * CGFloat(cos(a)), y: center.y - ry * CGFloat(sin(a)) - lift)
        }
    }

    /// The house a fling points at: the smallest angle between the swipe and the house direction.
    private func aim(dx: CGFloat, dy: CGFloat, spots: [CGPoint], center: CGPoint) -> String? {
        let a = atan2(dy, dx)
        var best: (String, CGFloat)?
        for (i, h) in model.houses.enumerated() {
            let s = spots[i]
            let b = atan2(s.y - center.y, s.x - center.x)
            var diff = abs(a - b); if diff > .pi { diff = 2 * .pi - diff }
            if best == nil || diff < best!.1 { best = (h.id, diff) }
        }
        return best?.0
    }

    private func isTarget(_ id: String) -> HouseView.Mark {
        switch model.stage {
        case .home: return id == model.critter.cls ? .right : .plain
        case .bounced(let w): return id == w ? .wrong : .plain
        case .walking: return id == model.critter.cls ? .right : .plain
        default: return .plain
        }
    }

    private func houseGuest(_ id: String) -> String? {
        guard id == model.critter.cls else { return nil }
        switch model.stage {
        default: return nil
        }
    }

    private func critterPos(spots: [CGPoint], center: CGPoint) -> CGPoint {
        func spot(_ id: String) -> CGPoint {
            model.houses.firstIndex { $0.id == id }.map { spots[$0] } ?? center
        }
        switch model.stage {
        case .waiting: return CGPoint(x: center.x + drag.width * 0.6, y: center.y + drag.height * 0.6)
        case .flying(let id): return spot(id)
        case .home: return spot(model.critter.cls)
        case .bounced(let id):
            guard !id.isEmpty else { return center }
            let s = spot(id)
            return CGPoint(x: (s.x * 2 + center.x) / 3, y: (s.y * 2 + center.y) / 3 + 20)
        case .walking: return spot(model.critter.cls)
        }
    }

    private var critterView: some View {
        let cr = model.critter
        let inHouse = model.stage == .home || model.stage == .walking
        return VStack(spacing: 2) {
            if model.showPicture {
                Text(cr.emoji).font(.system(size: 92))
                    .hueRotation(.degrees(cr.hue))
                    .scaleEffect(x: -1)        // face into the courtyard
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
            }
            Text(cr.name.capitalized)
                .font(luSerif(model.showPicture ? 20 : 30, .black)).foregroundStyle(Color(hex: 0x2a1a08))
                .padding(.horizontal, 12).padding(.vertical, model.showPicture ? 2 : 14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xfff6e0))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x9c7b33), lineWidth: 2)))
                .opacity(model.showPicture ? model.namesAlpha : 1)
        }
        .scaleEffect(inHouse ? 0.45 : (model.stage == .waiting ? 1 : 0.8))
        .rotationEffect(.degrees(model.stage == .waiting ? Double(drag.width) / 12 : 0))
        .modifier(VesShake(amount: 10, shakes: 3, beats: model.stage.isBounce ? 1 : 0))
        .contentShape(Rectangle().inset(by: -20))
    }
}

private extension CritterModel.Stage {
    var isBounce: Bool { if case .bounced = self { return true }; return false }
}

/// A little Roman animal house: a pediment roof, columns, an arched door, a sign.
private struct HouseView: View {
    enum Mark { case plain, right, wrong }
    let house: CHouse
    let state: Mark
    let compact: Bool
    let guest: String?
    var body: some View {
        let tint = Color(hex: house.tint)
        VStack(spacing: 0) {
            Roof().fill(luShade(house.tint, -30)).frame(height: compact ? 22 : 26)
                .overlay(Text(house.icon).font(.system(size: compact ? 14 : 16)).offset(y: 4))
            ZStack {
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xf6ead2), Color(hex: 0xe2d2b2)], startPoint: .top, endPoint: .bottom))
                HStack { Rectangle().fill(Color(hex: 0xd2c19f)).frame(width: 6); Spacer(); Rectangle().fill(Color(hex: 0xd2c19f)).frame(width: 6) }
                    .padding(.horizontal, 6)
                DoorArch().fill(Color(hex: 0x3a2414)).frame(width: compact ? 34 : 40, height: compact ? 40 : 46)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                if let g = guest { Text(g).font(.system(size: 26)).frame(maxHeight: .infinity, alignment: .bottom) }
            }
            Text(house.title).font(luFont(compact ? 12 : 14, .black)).foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.6)
                .padding(.horizontal, 4).padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(tint)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: state == .right ? Lu.mint : state == .wrong ? Lu.coral : 0x7a5a2a),
                                                          lineWidth: state == .plain ? 2 : 5))
        .shadow(color: state == .right ? Color(hex: Lu.mint).opacity(0.9) : .black.opacity(0.25), radius: state == .right ? 14 : 3, y: 3)
        .scaleEffect(state == .right ? 1.08 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: state)
    }
}

private struct Roof: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX - 4, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX + 4, y: r.maxY)); p.closeSubpath()
        }
    }
}

private struct DoorArch: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width / 2))
            p.addArc(center: CGPoint(x: r.midX, y: r.minY + r.width / 2), radius: r.width / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.closeSubpath()
        }
    }
}

/// The wooden cart the animals arrive on.
private struct CartView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(LinearGradient(colors: [Color(hex: 0xb07a45), Color(hex: 0x7a4a22)], startPoint: .top, endPoint: .bottom))
                .frame(height: 30).offset(y: -8)
                .overlay(HStack(spacing: 22) { ForEach(0..<5, id: \.self) { _ in Rectangle().fill(Color(hex: 0x5a3416)).frame(width: 2, height: 26) } }.offset(y: -8))
            HStack(spacing: 70) {
                ForEach(0..<2, id: \.self) { _ in
                    Circle().stroke(Color(hex: 0x4a2a10), lineWidth: 6).frame(width: 34, height: 34)
                        .overlay(Circle().fill(Color(hex: 0x4a2a10)).frame(width: 8))
                }
            }
            .offset(y: 16)
        }
    }
}

/// The menagerie courtyard: sand, a mosaic path, potted palms, a wall with Vesuvius peeking over.
private struct Courtyard: View {
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x9fd3ee), Color(hex: 0xd9eef5)], startPoint: .top, endPoint: .center)
                VesMountain(smoke: true, tint: 0x8a7c88).frame(width: W * 0.7, height: H * 0.14).position(x: W * 0.62, y: H * 0.13)
                // courtyard wall
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xd99b6c), Color(hex: 0xb9784a)], startPoint: .top, endPoint: .bottom))
                    .frame(height: H * 0.1).position(x: W / 2, y: H * 0.23)
                Rectangle().fill(Color(hex: 0x8a4a2a)).frame(height: 6).position(x: W / 2, y: H * 0.18)
                // arched niches along the wall
                HStack(spacing: W / 9) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x9a5a34).opacity(0.55)).frame(width: 26, height: H * 0.06)
                    }
                }
                .position(x: W / 2, y: H * 0.235)
                // sand
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0xf0d9a8), Color(hex: 0xe2c48a)], startPoint: .top, endPoint: .bottom))
                    .frame(height: H * 0.73).position(x: W / 2, y: H * 0.645)
                // circular mosaic in the middle
                Circle().stroke(Color(hex: 0x2f5d8a).opacity(0.5), style: StrokeStyle(lineWidth: 10, dash: [8, 5]))
                    .frame(width: W * 0.62, height: W * 0.62).scaleEffect(x: 1, y: 0.55).position(x: W / 2, y: H * 0.74)
                Circle().stroke(Color(hex: 0xb5523b).opacity(0.45), style: StrokeStyle(lineWidth: 6, dash: [6, 4]))
                    .frame(width: W * 0.48, height: W * 0.48).scaleEffect(x: 1, y: 0.55).position(x: W / 2, y: H * 0.74)
                // footprints
                ForEach(0..<6, id: \.self) { i in
                    Text("🐾").font(.system(size: 14)).opacity(0.18)
                        .position(x: W * (0.12 + CGFloat(i) * 0.15), y: H * (0.93 - CGFloat(i % 2) * 0.02))
                }
            }
        }
    }
}
