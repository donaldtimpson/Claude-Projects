import SwiftUI

// MARK: - Lost Zoo Ferry  (Globe Trotters · ferry)
//
// A storm scattered the zoo at the lighthouse port. A lost animal waits on the dock; drag it onto
// the ferry bound for its home (or tap that ferry). The ferry sails across the world map from
// Alexandria; at home the animal cheers. A wrong ferry turns back and the right home glows.
//
// Ladder:  I    2 continents, picture-famous animals (kangaroo, giraffe, panda, penguin …)
//          II   3 continents
//          III  4 continents, the whole animal list
//          IV   all 7 continents
//          V    countries (panda → China, kiwi → New Zealand …), 3 ferries; a slow clock (20 s)
//          VI   countries, 4 ferries
//          VII  habitats: desert, rainforest, polar ice, grassland, mountains, ocean (4 ferries)
//          VIII continent + habitat ("snow leopard → Asia · mountains"), 4 ferries
//          IX+  a mix of IV–VIII, clock tightening to 8 s.
//
// Facts are conservative: only animals whose wild home is unambiguous. Where a range spills over
// (sloths and macaws reach Central America; the fennec fox reaches Sinai) the other home is never
// offered as a wrong answer — see `also`.

private enum ZFBiome: String, CaseIterable {
    case desert = "Desert", rainforest = "Rainforest", polar = "Polar ice"
    case grassland = "Grassland", mountains = "Mountains", ocean = "Ocean"
    var icon: String {
        switch self {
        case .desert: return "🏜️"; case .rainforest: return "🌴"; case .polar: return "🧊"
        case .grassland: return "🌾"; case .mountains: return "🏔️"; case .ocean: return "🌊"
        }
    }
    /// Habitats that are plainly wrong for an animal of this habitat (never true by accident:
    /// e.g. Antarctica IS a desert, so a penguin's wrong habitats exclude desert and ocean).
    var plainlyWrong: [ZFBiome] {
        switch self {
        case .desert: return [.rainforest, .polar, .ocean]
        case .rainforest: return [.desert, .polar, .ocean]
        case .polar: return [.rainforest, .grassland]
        case .grassland: return [.rainforest, .polar, .ocean]
        case .mountains: return [.rainforest, .polar, .ocean]
        case .ocean: return [.desert, .rainforest, .mountains]
        }
    }
}

private let zfContinents = ["Africa", "Asia", "Europe", "North America", "South America", "Australia", "Antarctica"]

private func zfHex(_ continent: String) -> UInt {
    switch continent {
    case "Africa": return Lu.tangerine
    case "Asia": return Lu.coral
    case "Europe": return Lu.grape
    case "North America": return Lu.mint
    case "South America": return Lu.gold
    case "Australia": return Lu.sky
    default: return 0xe6f2f8
    }
}

/// Where a ferry docks on the map (lat, lon).
private let zfContinentAnchor: [String: (Double, Double)] = [
    "Africa": (5, 20), "Asia": (45, 90), "Europe": (50, 15), "North America": (45, -100),
    "South America": (-12, -58), "Australia": (-25, 134), "Antarctica": (-63, 20),
]

private struct ZFCountry { let name: String; let lat: Double; let lon: Double; let continent: String }
private let zfCountries: [ZFCountry] = [
    .init(name: "China", lat: 35, lon: 103, continent: "Asia"),
    .init(name: "Japan", lat: 36.5, lon: 138.5, continent: "Asia"),
    .init(name: "India", lat: 22, lon: 79, continent: "Asia"),
    .init(name: "Indonesia", lat: -2, lon: 118, continent: "Asia"),
    .init(name: "Russia", lat: 60, lon: 95, continent: "Asia"),
    .init(name: "Australia", lat: -25, lon: 134, continent: "Australia"),
    .init(name: "New Zealand", lat: -41.5, lon: 172.5, continent: "Oceania"),
    .init(name: "Madagascar", lat: -19, lon: 46.8, continent: "Africa"),
    .init(name: "Egypt", lat: 26.5, lon: 30, continent: "Africa"),
    .init(name: "Kenya", lat: 0.5, lon: 38, continent: "Africa"),
    .init(name: "United States", lat: 39, lon: -98, continent: "North America"),
    .init(name: "Canada", lat: 57, lon: -100, continent: "North America"),
    .init(name: "Mexico", lat: 23.5, lon: -102, continent: "North America"),
    .init(name: "Ecuador", lat: -1.5, lon: -78.5, continent: "South America"),
    .init(name: "Brazil", lat: -10, lon: -52, continent: "South America"),
    .init(name: "Peru", lat: -9.5, lon: -75, continent: "South America"),
    .init(name: "Argentina", lat: -35, lon: -65, continent: "South America"),
    .init(name: "France", lat: 46.5, lon: 2.5, continent: "Europe"),
    .init(name: "Italy", lat: 42.5, lon: 12.5, continent: "Europe"),
    .init(name: "United Kingdom", lat: 53, lon: -1.5, continent: "Europe"),
]

private struct ZFAnimal {
    let emoji: String, name: String
    var continent: String? = nil
    var country: String? = nil
    var biome: ZFBiome? = nil
    var also: Set<String> = []      // continents/countries that are ALSO home — never offered as wrong
    var famous = false              // level I–II pool
}

/// The deck. Sources of truth: native wild range (not zoos, not introductions).
private let zfAnimals: [ZFAnimal] = [
    .init(emoji: "🦘", name: "Kangaroo", continent: "Australia", country: "Australia", also: ["Papua New Guinea"], famous: true),
    .init(emoji: "🐨", name: "Koala", continent: "Australia", country: "Australia", famous: true),
    .init(emoji: "🦒", name: "Giraffe", continent: "Africa", biome: .grassland, famous: true),
    .init(emoji: "🦓", name: "Zebra", continent: "Africa", biome: .grassland, famous: true),
    .init(emoji: "🦛", name: "Hippo", continent: "Africa"),
    .init(emoji: "🦍", name: "Gorilla", continent: "Africa", biome: .rainforest),
    .init(emoji: "🐼", name: "Giant panda", continent: "Asia", country: "China", famous: true),
    .init(emoji: "🐅", name: "Bengal tiger", continent: "Asia", country: "India",
          also: ["Bangladesh", "Nepal", "Bhutan", "Myanmar", "China", "Russia", "Indonesia"]),
    .init(emoji: "🦧", name: "Orangutan", continent: "Asia", biome: .rainforest),
    .init(emoji: "🐫", name: "Two-hump camel", continent: "Asia", biome: .desert),
    .init(emoji: "🦎", name: "Komodo dragon", continent: "Asia", country: "Indonesia"),
    .init(emoji: "🐒", name: "Snow monkey", continent: "Asia", country: "Japan"),
    .init(emoji: "🦬", name: "American bison", continent: "North America", country: "United States", biome: .grassland,
          also: ["Canada", "Mexico", "Europe"], famous: true),
    .init(emoji: "🦝", name: "Raccoon", continent: "North America"),
    .init(emoji: "🦃", name: "Wild turkey", continent: "North America"),
    .init(emoji: "🦅", name: "Bald eagle", continent: "North America", country: "United States", also: ["Canada", "Mexico"]),
    .init(emoji: "🐊", name: "American alligator", continent: "North America", country: "United States"),
    .init(emoji: "🐐", name: "Mountain goat", continent: "North America", biome: .mountains, also: ["Canada"]),
    .init(emoji: "🦙", name: "Guanaco", continent: "South America", biome: .mountains, famous: true),
    .init(emoji: "🦥", name: "Sloth", continent: "South America", biome: .rainforest, also: ["North America"]),
    .init(emoji: "🦜", name: "Scarlet macaw", continent: "South America", biome: .rainforest, also: ["North America"]),
    .init(emoji: "🐸", name: "Poison dart frog", continent: "South America", biome: .rainforest, also: ["North America"]),
    .init(emoji: "🐢", name: "Galápagos tortoise", continent: "South America", country: "Ecuador"),
    .init(emoji: "🐧", name: "Emperor penguin", continent: "Antarctica", biome: .polar, famous: true),
    .init(emoji: "🐧", name: "Adélie penguin", continent: "Antarctica"),
    .init(emoji: "🐦", name: "Kiwi bird", country: "New Zealand"),
    .init(emoji: "🐒", name: "Ring-tailed lemur", continent: "Africa", country: "Madagascar"),
    .init(emoji: "🦊", name: "Fennec fox", continent: "Africa", biome: .desert, also: ["Asia"]),
    .init(emoji: "🐪", name: "One-hump camel", biome: .desert),
    .init(emoji: "🐻‍❄️", name: "Polar bear", biome: .polar),
    .init(emoji: "🐆", name: "Snow leopard", continent: "Asia", biome: .mountains),
    .init(emoji: "🐳", name: "Blue whale", biome: .ocean),
    .init(emoji: "🐙", name: "Octopus", biome: .ocean),
    .init(emoji: "🦈", name: "Great white shark", biome: .ocean),
]

/// What a ferry is bound for.
private enum ZFDest: Hashable {
    case continent(String)
    case country(String)
    case biome(ZFBiome)
    case both(String, ZFBiome)

    var label: String {
        switch self {
        case .continent(let c): return c
        case .country(let c): return c
        case .biome(let b): return b.rawValue
        case .both(let c, let b): return "\(c) · \(b.rawValue)"
        }
    }
    var continent: String? {
        switch self {
        case .continent(let c), .both(let c, _): return c
        case .country(let n): return zfCountries.first { $0.name == n }?.continent
        case .biome: return nil
        }
    }
    /// Map point (Mercator map units) the ferry sails to; nil for a habitat-only ferry.
    var mapPoint: CGPoint? {
        switch self {
        case .continent(let c), .both(let c, _):
            guard let a = zfContinentAnchor[c] else { return nil }
            return GeoAtlas.point(lat: a.0, lon: a.1)
        case .country(let n):
            guard let c = zfCountries.first(where: { $0.name == n }) else { return nil }
            return GeoAtlas.point(lat: c.lat, lon: c.lon)
        case .biome: return nil
        }
    }
}

private struct ZFQuestion {
    let animal: ZFAnimal
    let options: [ZFDest]
    let answer: Int
}

private enum ZFKind { case continent, country, biome, both }

private func zfKind(_ level: Int) -> (ZFKind, Int) {
    switch level {
    case 1: return (.continent, 2)
    case 2: return (.continent, 3)
    case 3: return (.continent, 4)
    case 4: return (.continent, 7)
    case 5: return (.country, 3)
    case 6: return (.country, 4)
    case 7: return (.biome, 4)
    case 8: return (.both, 4)
    default: return [(.continent, 7), (.country, 4), (.biome, 4), (.both, 4)].randomElement()!
    }
}

/// Is `d` a true home for `a`? (The answer, or a home listed in `also`.)
private func zfTrue(_ a: ZFAnimal, _ d: ZFDest) -> Bool {
    switch d {
    case .continent(let c): return c == a.continent || a.also.contains(c)
    case .country(let c): return c == a.country || a.also.contains(c)
    case .biome(let b): return b == a.biome
    case .both(let c, let b): return (c == a.continent || a.also.contains(c)) && b == a.biome
    }
}

private func zfQuestion(_ level: Int, avoiding last: String?) -> ZFQuestion {
    let (kind, n) = zfKind(level)
    let pool: [ZFAnimal] = zfAnimals.filter { a in
        switch kind {
        case .continent: return a.continent != nil && (level > 2 || a.famous)
        case .country: return a.country != nil
        case .biome: return a.biome != nil
        case .both: return a.continent != nil && a.biome != nil
        }
    }
    var animal = pool.randomElement()!
    if animal.name == last, pool.count > 1 { animal = pool.filter { $0.name != last }.randomElement()! }

    let answer: ZFDest
    var wrong: [ZFDest]
    switch kind {
    case .continent:
        answer = .continent(animal.continent!)
        wrong = zfContinents.map { ZFDest.continent($0) }
    case .country:
        answer = .country(animal.country!)
        wrong = zfCountries.map { ZFDest.country($0.name) }
    case .biome:
        answer = .biome(animal.biome!)
        wrong = animal.biome!.plainlyWrong.map { ZFDest.biome($0) }
    case .both:
        let c = animal.continent!, b = animal.biome!
        answer = .both(c, b)
        let otherPlaces = zfContinents.filter { $0 != c }.shuffled().prefix(2).map { ZFDest.both($0, b) }
        let otherHabitat = b.plainlyWrong.shuffled().prefix(1).map { ZFDest.both(c, $0) }
        wrong = otherPlaces + otherHabitat
    }
    wrong = wrong.filter { !zfTrue(animal, $0) }.shuffled()
    var opts = [answer] + wrong.prefix(n - 1)
    if kind == .continent && n == 7 {
        // All seven, in a fixed order, so the cards stay put level after level.
        opts = zfContinents.map { ZFDest.continent($0) }.filter { $0 == answer || !zfTrue(animal, $0) }
    } else {
        opts.shuffle()
    }
    return ZFQuestion(animal: animal, options: opts, answer: opts.firstIndex(of: answer)!)
}

#if DEBUG
/// Every generated question: one true option, no repeats, the asked size (all-7 may drop a
/// second home). Run once per launch in DEBUG; prints the result.
private func zfSelfCheck() {
    var n = 0
    for level in 1...12 {
        for _ in 0..<400 {
            let q = zfQuestion(level, avoiding: nil)
            let truths = q.options.filter { zfTrue(q.animal, $0) }
            precondition(truths.count == 1 && zfTrue(q.animal, q.options[q.answer]), "ZooFerry: \(q.animal.name) \(q.options)")
            precondition(Set(q.options).count == q.options.count, "ZooFerry: duplicate options")
            for case .country(let c) in q.options { precondition(GeoAtlas.named(c) != nil, "ZooFerry: no map for \(c)") }
            n += 1
        }
    }
    print("ZooFerry self-check OK: \(n) questions")
}
#endif

/// Seconds an animal waits (0 = no clock): none to IV, then 20 s easing to 8 s.
private func zfPatience(_ level: Int) -> Double { level <= 4 ? 0 : max(8, 20 - Double(level - 5) * 2) }

@MainActor
private final class ZooFerryModel: ArcadeModel {
    enum Stage { case waiting, sailing, home, lost }
    @Published var q = zfQuestion(1, avoiding: nil)
    @Published var stage: Stage = .waiting
    @Published var picked: Int?
    @Published var boat: CGPoint = GeoAtlas.point(lat: 31.2, lon: 29.92)
    @Published var boatShown = false
    @Published var showRight = false
    @Published var qid = 0
    @Published var tLeft: Double = 0
    @Published var perQ: Double = 0
    static let port = GeoAtlas.point(lat: 31.2, lon: 29.92)    // Alexandria — the Pharos

    init() {
        super.init(key: GameID.zooFerry.rawValue)
        #if DEBUG
        zfSelfCheck()
        #endif
    }

    override func onBegin() { next() }

    func next() {
        q = zfQuestion(level, avoiding: q.animal.name)
        stage = .waiting; picked = nil; showRight = false; boatShown = false
        boat = Self.port
        perQ = zfPatience(level); tLeft = perQ
        qid += 1
    }

    func tick(_ dt: Double) {
        guard phase == .playing, stage == .waiting, perQ > 0 else { return }
        tLeft -= dt
        if tLeft <= 0 { send(nil) }
    }

    /// The animal boards ferry `i` (a drop or a tap); nil = it waited too long.
    func send(_ i: Int?) {
        guard phase == .playing, stage == .waiting else { return }
        picked = i
        let right = i == q.answer
        let dest = i.flatMap { q.options[$0].mapPoint }
        let sail = dest == nil ? 0.0 : 0.9
        if let dest {
            boat = Self.port; boatShown = true
            stage = .sailing
            withAnimation(.easeInOut(duration: sail)) { boat = dest }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + sail) { [weak self] in
            guard let self, self.phase == .playing else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { self.stage = right ? .home : .lost }
            if right {
                self.hit()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
                    guard let self, self.phase == .playing else { return }
                    self.next()
                }
            } else {
                self.miss(reason: i == nil ? "The animal got tired of waiting!" : "Out of hearts!", delay: 2.0)
                // Teach: the boat turns back and the right home lights up.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self, self.phase == .playing else { return }
                    withAnimation(.easeInOut(duration: 0.4)) { self.showRight = true }
                    if let p = self.q.options[self.q.answer].mapPoint {
                        self.boatShown = true
                        withAnimation(.easeInOut(duration: 0.8)) { self.boat = p }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) { [weak self] in
                    guard let self, self.phase == .playing, !self.dying else { return }
                    self.next()
                }
            }
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .waiting else { return }
        let wrong = q.options.indices.filter { $0 != q.answer }
        send(correct || wrong.isEmpty ? q.answer : wrong.randomElement()!)
    }
}

// MARK: - Views

/// Map frame shown: the whole world, plus an ice band for Antarctica below the data's edge.
private let zfMapRect = CGRect(x: -6, y: 55, width: 1012, height: 690)

private struct ZFMap: View {
    let q: ZFQuestion
    let showRight: Bool
    let stage: ZooFerryModel.Stage

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width / zfMapRect.width, size.height / zfMapRect.height)
            ctx.translateBy(x: (size.width - zfMapRect.width * k) / 2, y: (size.height - zfMapRect.height * k) / 2)
            ctx.scaleBy(x: k, y: k)
            ctx.translateBy(x: -zfMapRect.minX, y: -zfMapRect.minY)
            ctx.fill(Path(roundedRect: zfMapRect, cornerRadius: 30), with: .color(Color(hex: 0x1d4a6e)))

            let lit = Set(q.options.compactMap(\.continent))
            let countries = Set(q.options.compactMap { d -> String? in if case .country(let c) = d { return c }; return nil })
            let answer = q.options[q.answer]
            let flash = showRight || stage == .home
            func continentOf(_ c: AtlasCountry, east: Bool) -> String? {
                switch c.continent {
                case "Oceania": return ["Australia", "Papua New Guinea"].contains(c.name) ? "Australia" : nil
                case "Europe" where c.name == "Russia": return east ? "Asia" : "Europe"
                default: return c.continent
                }
            }
            for c in GeoAtlas.countries {
                for east in (c.name == "Russia" ? [false, true] : [false]) {
                    var cx = ctx
                    if c.name == "Russia" {
                        cx.clip(to: Path(east ? CGRect(x: GeoAtlas.uralsX, y: 0, width: 1100, height: 800)
                                              : CGRect(x: -100, y: 0, width: GeoAtlas.uralsX + 100, height: 800)))
                    }
                    let cont = continentOf(c, east: east)
                    var hex: UInt = cont.map(zfHex) ?? 0x9a9a92
                    var alpha = 0.85
                    if !countries.isEmpty {                        // country levels: candidates pop
                        if let i = q.options.firstIndex(of: .country(c.name)) { hex = zfCardHexes[i % zfCardHexes.count]; alpha = 1 }
                        else { hex = 0x9a9a92; alpha = 0.35 }
                    } else if !lit.isEmpty, let cont {             // continent levels: dim the others
                        alpha = lit.contains(cont) ? 0.95 : 0.3
                    } else if lit.isEmpty { alpha = 0.55 }
                    if flash {
                        switch answer {
                        case .country(let n): if n == c.name { hex = Lu.mint; alpha = 1 }
                        case .continent(let a), .both(let a, _): if a == cont { hex = Lu.mint; alpha = 1 }
                        case .biome: break
                        }
                    }
                    cx.fill(c.path, with: .color(Color(hex: hex).opacity(alpha)))
                    cx.stroke(c.path, with: .color(.black.opacity(0.25)), lineWidth: 0.6)
                }
            }
            // Antarctica: the ice band along the bottom of a Mercator map.
            var ice = Path()
            ice.move(to: CGPoint(x: 20, y: 712))
            for i in 0...20 {
                let x = 20 + CGFloat(i) * 48
                ice.addLine(to: CGPoint(x: x, y: 706 + (i % 2 == 0 ? 0 : 6)))
            }
            ice.addLine(to: CGPoint(x: 980, y: 740)); ice.addLine(to: CGPoint(x: 20, y: 740)); ice.closeSubpath()
            let iceOn = lit.contains("Antarctica") || (lit.isEmpty && countries.isEmpty)
            let iceRight = flash && answer.continent == "Antarctica"
            ctx.fill(ice, with: .color(Color(hex: iceRight ? Lu.mint : 0xe6f2f8).opacity(iceOn || iceRight ? 0.95 : 0.3)))
        }
    }
}

/// A continent / country silhouette fitted into its box.
private struct ZFSilhouette: View {
    let dest: ZFDest
    let hex: UInt
    var body: some View {
        Canvas { ctx, size in
            let shapes: [AtlasCountry]
            switch dest {
            case .continent(let c), .both(let c, _):
                if c == "Antarctica" {
                    let r = CGRect(x: size.width * 0.12, y: size.height * 0.2, width: size.width * 0.76, height: size.height * 0.6)
                    ctx.fill(Path(ellipseIn: r), with: .color(Color(hex: hex)))
                    return
                }
                shapes = GeoAtlas.countries.filter { a in
                    if c == "Australia" { return a.name == "Australia" }
                    if a.name == "Russia" { return c == "Europe" || c == "Asia" }
                    return a.continent == c
                }
            case .country(let n): shapes = GeoAtlas.named(n).map { [$0] } ?? []
            case .biome: shapes = []
            }
            guard !shapes.isEmpty else { return }
            var box = shapes.map(\.box).reduce(shapes[0].box) { $0.union($1) }
            if case .continent(let c) = dest, c == "Europe" { box = CGRect(x: 460, y: 180, width: 220, height: 220) }
            if case .continent(let c) = dest, c == "Asia" { box = CGRect(x: 560, y: 120, width: 440, height: 400) }
            if case .both(let c, _) = dest, c == "Europe" { box = CGRect(x: 460, y: 180, width: 220, height: 220) }
            if case .both(let c, _) = dest, c == "Asia" { box = CGRect(x: 560, y: 120, width: 440, height: 400) }
            if case .country("United States") = dest { box = CGRect(x: 190, y: 330, width: 140, height: 90) }
            if case .country("Russia") = dest { box = CGRect(x: 560, y: 120, width: 440, height: 260) }
            let k = min(size.width / box.width, size.height / box.height)
            ctx.translateBy(x: (size.width - box.width * k) / 2, y: (size.height - box.height * k) / 2)
            ctx.scaleBy(x: k, y: k)
            ctx.translateBy(x: -box.minX, y: -box.minY)
            ctx.clip(to: Path(box))
            for s in shapes { ctx.fill(s.path, with: .color(Color(hex: hex))) }
        }
    }
}

private struct ZFCardFrame: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) { value.merge(nextValue()) { $1 } }
}

private let zfCardHexes: [UInt] = [Lu.tangerine, Lu.sky, Lu.mint, Lu.grape]

struct ZooFerryView: View {
    let onClose: () -> Void
    @StateObject private var m = ZooFerryModel()
    @State private var drag: CGSize = .zero
    @State private var dragging = false
    @State private var cards: [Int: CGRect] = [:]
    @State private var bob = false
    private let clock = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ArcadeShell(model: m, spec: GameID.zooFerry.spec ?? GameSpec(title: "Lost Zoo Ferry", mechanic: "", premise: "", game: .zooFerry),
                    accent: Lu.sky, onClose: onClose) {
            VStack(spacing: 8) {
                Color.clear.frame(height: 56)
                map
                dock.zIndex(2)
                ferries
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .coordinateSpace(name: "zf")
            .onPreferenceChange(ZFCardFrame.self) { cards = $0 }
        }
        .onReceive(clock) { _ in m.tick(0.1) }
        .onChange(of: m.phase) { p in
            if p == .playing { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { bob = true } }
            else { withAnimation(.linear(duration: 0.1)) { bob = false } }
        }
    }

    private func color(_ i: Int) -> UInt {
        let d = m.q.options[i]
        if case .country = d { return zfCardHexes[i % zfCardHexes.count] }
        if case .biome = d { return zfCardHexes[i % zfCardHexes.count] }
        return d.continent.map(zfHex) ?? Lu.ink
    }

    private var map: some View {
        GeometryReader { geo in
            let k = min(geo.size.width / zfMapRect.width, geo.size.height / zfMapRect.height)
            let ox = (geo.size.width - zfMapRect.width * k) / 2, oy = (geo.size.height - zfMapRect.height * k) / 2
            let toView = { (p: CGPoint) in CGPoint(x: ox + (p.x - zfMapRect.minX) * k, y: oy + (p.y - zfMapRect.minY) * k) }
            ZStack {
                ZFMap(q: m.q, showRight: m.showRight, stage: m.stage)
                Circle().fill(Color(hex: Lu.gold)).frame(width: 9, height: 9)          // the Pharos, home port
                    .overlay(Circle().stroke(Color(hex: Lu.ink), lineWidth: 2)).position(toView(ZooFerryModel.port))
                if m.boatShown {
                    ZStack {
                        Text("⛴️").font(.system(size: 26))
                        if m.stage == .home {
                            Text(m.q.animal.emoji + "🎉").font(.system(size: 22)).offset(y: -24)
                                .transition(.scale.combined(with: .opacity))
                        }
                        if m.stage == .lost && !m.showRight {
                            Text("❌").font(.system(size: 18)).offset(y: -20).transition(.scale)
                        }
                    }
                    .position(toView(m.boat))
                }
            }
        }
        .aspectRatio(zfMapRect.width / zfMapRect.height, contentMode: .fit)
        .background(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: Lu.goldLine), lineWidth: 2))
    }

    /// The lost animal on the dock — drag it to a ferry.
    private var dock: some View {
        let a = m.q.animal
        let face: String = m.stage == .home ? "🥳" : (m.stage == .lost ? "😢" : "😟")
        return HStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                Text(a.emoji).font(.system(size: 76))
                    .rotationEffect(.degrees(dragging ? 0 : (bob ? -5 : 5)))
                    .scaleEffect(dragging ? 1.15 : 1)
                Text(face).font(.system(size: 26)).offset(x: 10, y: -6)
            }
            .frame(width: 100, height: 96)
            .offset(drag)
            .opacity(m.stage == .waiting ? 1 : 0.35)
            .gesture(DragGesture(coordinateSpace: .named("zf"))
                .onChanged { g in
                    guard m.stage == .waiting else { return }
                    dragging = true; drag = g.translation
                }
                .onEnded { g in
                    dragging = false
                    let hitCard = cards.first { $0.value.insetBy(dx: -14, dy: -14).contains(g.location) }?.key
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
                    if let hitCard { m.send(hitCard) }
                })
            VStack(alignment: .leading, spacing: 3) {
                Text(m.stage == .home ? "Home at last!" : "I'm lost!").font(luFont(14, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                Text(a.name).font(luSerif(26, .black)).foregroundStyle(Color(hex: Lu.gold))
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text(prompt).font(luFont(14, .bold)).foregroundStyle(Color(hex: m.stage == .lost ? Lu.coral : Lu.ink))
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .transaction { $0.animation = nil }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(luPanelShape(18))
        .overlay(alignment: .bottom) {
            if m.perQ > 0 && m.stage == .waiting {
                GeometryReader { g in
                    Capsule().fill(Color(hex: m.tLeft / m.perQ < 0.3 ? Lu.coral : Lu.sky))
                        .frame(width: max(0, g.size.width * CGFloat(m.tLeft / m.perQ)), height: 5)
                }
                .frame(height: 5).padding(.horizontal, 14).padding(.bottom, 3)
            }
        }
    }

    private var prompt: String {
        let right = m.q.options[m.q.answer].label
        switch m.stage {
        case .lost: return "Home is \(right)!"
        case .home: return "Thank you! 💛"
        default:
            switch m.q.options[m.q.answer] {
            case .continent: return "👆 Drag me to my home land"
            case .country: return "👆 Which country is my home?"
            case .biome: return "👆 Where do I live?"
            case .both: return "👆 Which land, which place?"
            }
        }
    }

    private var ferries: some View {
        let n = m.q.options.count
        let compact = n > 4
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(Array(m.q.options.enumerated()), id: \.offset) { i, d in
                card(i, d, compact: compact)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: ZFCardFrame.self, value: [i: g.frame(in: .named("zf"))])
                    })
            }
        }
        .id(m.qid)
    }

    private func card(_ i: Int, _ d: ZFDest, compact: Bool) -> some View {
        let hex = color(i)
        let isRight = i == m.q.answer
        let fill: UInt = (m.showRight || m.stage == .home) && isRight ? Lu.mint : (m.picked == i && m.stage == .lost ? Lu.coral : Lu.panel)
        let art = Group {
            switch d {
            case .biome(let b): Text(b.icon).font(.system(size: compact ? 30 : 46))
            case .both(_, let b):
                ZStack(alignment: .bottomTrailing) {
                    ZFSilhouette(dest: d, hex: hex)
                    Text(b.icon).font(.system(size: 28))
                }
            default: ZFSilhouette(dest: d, hex: hex)
            }
        }
        return Button { m.send(i) } label: {
            Group {
                if compact {
                    HStack(spacing: 8) {
                        art.frame(width: 46, height: 40)
                        Text(d.label).font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                            .lineLimit(2).minimumScaleFactor(0.6)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 52)
                } else {
                    VStack(spacing: 4) {
                        HStack { Text("⛴️").font(.system(size: 20)); Spacer() }
                        art.frame(height: m.q.options.count <= 2 ? 120 : 64)
                        Text(d.label).font(luFont(m.q.options.count <= 2 ? 20 : 16, .heavy))
                            .foregroundStyle(Color(hex: Lu.ink))
                            .lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: fill).opacity(fill == Lu.panel ? 1 : 0.55))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: hex), lineWidth: 3)))
            .scaleEffect(m.showRight && isRight ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(m.stage == .waiting)
    }
}
