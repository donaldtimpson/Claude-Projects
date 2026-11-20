import SwiftUI

// MARK: - Lost Zoo Ferry  (Globe Trotters · ferry)
//
// A storm scattered the zoo at the lighthouse port. A lost animal waits on the dock; drag it onto
// the ferry bound for its home (or tap that ferry). The ferry sails across the world map from
// Alexandria; at home the animal cheers. A wrong ferry turns back and the right home glows.
//
// Continuous difficulty (tuned off `d`, never the level):
//   kinds fade in by tier — continents (1) → countries (4: panda → China, kiwi → New Zealand) →
//   habitats (5.5: desert, rainforest, polar ice, grassland, mountains, ocean) → continent +
//   habitat (7: "snow leopard → Asia · mountains") — old kinds stay as review;
//   continent rounds: Africa-vs-Australia starters only below d 2, picture-famous animals below
//   d 3, then the whole deck; ferries 2 → 4 (by d 3.5); a patience clock from d 4 (20 s → 8 s).
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
    var famous = false              // the early pool (the very first: `zfStarters`)
}

/// The deck. Sources of truth: native wild range (not zoos, not introductions).
private let zfAnimals: [ZFAnimal] = [
    .init(emoji: "🦘", name: "Kangaroo", continent: "Australia", country: "Australia", also: ["Papua New Guinea"], famous: true),
    .init(emoji: "🐨", name: "Koala", continent: "Australia", country: "Australia", famous: true),
    .init(emoji: "🦒", name: "Giraffe", continent: "Africa", biome: .grassland, famous: true),
    .init(emoji: "🦓", name: "Zebra", continent: "Africa", biome: .grassland, famous: true),
    .init(emoji: "🦛", name: "Hippo", continent: "Africa", famous: true),
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
    .init(emoji: "🦙", name: "Llama", continent: "South America", biome: .mountains),
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

/// Gradus I: only these, and only their two homes (Africa, Australia) as ferries.
private let zfStarters: Set<String> = ["🦒", "🦓", "🦛", "🦘", "🐨"]
private let zfStarterHomes = ["Africa", "Australia"]

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

/// Is `d` a true home for `a`? (The answer, or a home listed in `also`.)
private func zfTrue(_ a: ZFAnimal, _ d: ZFDest) -> Bool {
    switch d {
    case .continent(let c): return c == a.continent || a.also.contains(c)
    case .country(let c): return c == a.country || a.also.contains(c)
    case .biome(let b): return b == a.biome
    case .both(let c, let b): return (c == a.continent || a.also.contains(c)) && b == a.biome
    }
}

/// `starter` = Africa/Australia only; `famousOnly` = the picture-famous animals; `n` ferries.
private func zfQuestion(_ kind: ZFKind, n: Int, starter: Bool = false, famousOnly: Bool = false,
                        avoiding last: String?) -> ZFQuestion {
    let pool: [ZFAnimal] = zfAnimals.filter { a in
        switch kind {
        case .continent: return a.continent != nil && (!famousOnly || a.famous) && (!starter || zfStarters.contains(a.emoji))
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
        wrong = (starter ? zfStarterHomes : zfContinents).map { ZFDest.continent($0) }
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
    opts.shuffle()
    return ZFQuestion(animal: animal, options: opts, answer: opts.firstIndex(of: answer)!)
}

#if DEBUG
/// Every generated question: one true option, no repeats, the asked size (all-7 may drop a
/// second home). Run once per launch in DEBUG; prints the result.
private func zfSelfCheck() {
    var n_ = 0
    let kinds: [ZFKind] = [.continent, .country, .biome, .both]
    for kind in kinds {
        for (starter, famous) in [(true, true), (false, true), (false, false)] where kind == .continent || !starter {
            for n in 2...4 {
                for _ in 0..<60 {
                    let q = zfQuestion(kind, n: n, starter: starter, famousOnly: famous, avoiding: nil)
                    let truths = q.options.filter { zfTrue(q.animal, $0) }
                    precondition(truths.count == 1 && zfTrue(q.animal, q.options[q.answer]), "ZooFerry: \(q.animal.name) \(q.options)")
                    precondition(Set(q.options).count == q.options.count, "ZooFerry: duplicate options")
                    for case .country(let c) in q.options { precondition(GeoAtlas.named(c) != nil, "ZooFerry: no map for \(c)") }
                    if starter {
                        precondition(zfStarters.contains(q.animal.emoji), "ZooFerry: starter animal \(q.animal.name)")
                        for case .continent(let c) in q.options { precondition(zfStarterHomes.contains(c), "ZooFerry: starter ferry \(c)") }
                    }
                    n_ += 1
                }
            }
        }
    }
    print("ZooFerry self-check OK: \(n_) questions")
}
#endif


@MainActor
private final class ZooFerryModel: ArcadeModel {
    enum Stage { case waiting, sailing, home, lost }
    @Published var q = zfQuestion(.continent, n: 2, starter: true, famousOnly: true, avoiding: nil)
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
        let kind = [ZFKind.continent, .country, .biome, .both][tier([1, 4, 5.5, 7])]
        let n = kind == .continent ? rampInt(2, 4, to: 3.5) : (kind == .country ? rampInt(3, 4, from: 4, to: 6) : 4)
        q = zfQuestion(kind, n: n, starter: d < 2, famousOnly: d < 3, avoiding: q.animal.name)
        stage = .waiting; picked = nil; showRight = false; boatShown = false
        boat = Self.port
        perQ = d < 4 ? 0 : ramp(20, 8, from: 4, to: 10); tLeft = perQ
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

/// A little ferry: coloured hull, white cabin with portholes, a funnel that puffs.
private struct ZFBoat: View {
    let hex: UInt
    var puff: Bool
    var body: some View {
        ZStack(alignment: .bottom) {
            // smoke
            HStack(spacing: -4) {
                Circle().fill(.white.opacity(0.7)).frame(width: 12, height: 12)
                Circle().fill(.white.opacity(0.5)).frame(width: 16, height: 16).offset(y: -8)
            }
            .offset(x: 48, y: puff ? -30 : -26).opacity(puff ? 0.85 : 0.35)
            // funnel
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x2c2c3a)).frame(width: 12, height: 18)
                .overlay(Rectangle().fill(Color(hex: Lu.coral)).frame(height: 4).offset(y: -4))
                .offset(x: 22, y: -34)
            // cabin
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xfdf8ee)).frame(width: 70, height: 20)
                .overlay(HStack(spacing: 7) { ForEach(0..<4, id: \.self) { _ in Circle().fill(Color(hex: 0x2f6f95)).frame(width: 7, height: 7) } })
                .offset(x: -4, y: -20)
            // hull
            ZFHull().fill(LinearGradient(colors: [Color(hex: hex), Color(hex: hex).opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .overlay(ZFHull().stroke(Color.black.opacity(0.35), lineWidth: 1.5))
                .frame(width: 120, height: 24)
        }
        .frame(width: 124, height: 62)
    }
}

private struct ZFHull: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.14, y: r.maxY), control: CGPoint(x: r.maxX - 2, y: r.maxY - 2))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.06, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// The harbour by day: sky, sea with sparkle, a stone quay along the bottom.
private struct ZFHarbour: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let sea = h * 0.30
                ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: sea)),
                         with: .linearGradient(Gradient(colors: [Color(hex: 0x7cc6ea), Color(hex: 0xcdeaf3)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: sea)))
                ctx.fill(Path(CGRect(x: 0, y: sea, width: w, height: h - sea)),
                         with: .linearGradient(Gradient(colors: [Color(hex: 0x2f8fb8), Color(hex: 0x1d5f86)]), startPoint: CGPoint(x: 0, y: sea), endPoint: CGPoint(x: 0, y: h)))
                for k in 0..<12 {
                    let y0 = sea + 14 + CGFloat(k) * (h - sea) / 13
                    var p = Path()
                    var x: CGFloat = -10 + CGFloat(k % 2) * 20
                    while x < w {
                        let xx = x + CGFloat(sin(t * 0.7 + Double(k))) * 10
                        p.move(to: CGPoint(x: xx, y: y0)); p.addQuadCurve(to: CGPoint(x: xx + 18, y: y0), control: CGPoint(x: xx + 9, y: y0 - 5))
                        x += 60
                    }
                    ctx.stroke(p, with: .color(.white.opacity(0.22)), lineWidth: 1.6)
                }
                // Quay.
                let qy = h - 150
                ctx.fill(Path(CGRect(x: 0, y: qy, width: w, height: h - qy)),
                         with: .linearGradient(Gradient(colors: [Color(hex: 0xc9b48e), Color(hex: 0x9c8762)]), startPoint: CGPoint(x: 0, y: qy), endPoint: CGPoint(x: 0, y: h)))
                ctx.fill(Path(CGRect(x: 0, y: qy, width: w, height: 8)), with: .color(Color(hex: 0x7d6a48)))
                var row = 0
                var y = qy + 8
                while y < h {
                    var x: CGFloat = row % 2 == 0 ? 0 : -24
                    while x < w {
                        ctx.stroke(Path(roundedRect: CGRect(x: x + 1, y: y + 1, width: 46, height: 22), cornerRadius: 3),
                                   with: .color(Color(hex: 0x7d6a48).opacity(0.45)), lineWidth: 1.2)
                        x += 48
                    }
                    y += 24; row += 1
                }
            }
        }
    }
}

struct ZooFerryView: View {
    let onClose: () -> Void
    @StateObject private var m = ZooFerryModel()
    @State private var drag: CGSize = .zero
    @State private var dragging = false
    @State private var cards: [Int: CGRect] = [:]
    @State private var bob = false

    var body: some View {
        ArcadeShell(model: m, spec: GameID.zooFerry.spec ?? GameSpec(title: "Lost Zoo Ferry", mechanic: "", premise: "", game: .zooFerry),
                    accent: Lu.sky, onClose: onClose, backdrop: { ZFHarbour() }) {
            GeometryReader { root in
                VStack(spacing: 6) {
                    HUDSpace(56)
                    // Sideways on a tablet the harbour is wide: the chart grows to suit.
                    map(maxHeight: root.size.width > 900 ? 300 : 210)
                    Spacer(minLength: 0)
                    ferries
                    Spacer(minLength: 0)
                    dock.frame(height: 132)
                }
                .padding(.horizontal, 12).padding(.bottom, 6)
                .frame(width: root.size.width, height: root.size.height)
            }
            .coordinateSpace(name: "zf")
            .onPreferenceChange(ZFCardFrame.self) { cards = $0 }
        }
        // A task, not a Timer stored on this struct (that was rebuilt on every redraw).
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                m.tick(0.1)
            }
        }
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

    /// The sea chart pinned up in the harbour master's window.
    private func map(maxHeight: CGFloat) -> some View {
        GeometryReader { geo in
            let k = min(geo.size.width / zfMapRect.width, geo.size.height / zfMapRect.height)
            let ox = (geo.size.width - zfMapRect.width * k) / 2, oy = (geo.size.height - zfMapRect.height * k) / 2
            let toView = { (p: CGPoint) in CGPoint(x: ox + (p.x - zfMapRect.minX) * k, y: oy + (p.y - zfMapRect.minY) * k) }
            ZStack {
                ZFMap(q: m.q, showRight: m.showRight, stage: m.stage)
                Circle().fill(Color(hex: Lu.gold)).frame(width: 9, height: 9)          // the Pharos, home port
                    .overlay(Circle().stroke(Color(hex: lhInk), lineWidth: 2)).position(toView(ZooFerryModel.port))
                if m.boatShown {
                    ZStack {
                        Text("⛴️").font(.system(size: 24))
                        if m.stage == .home {
                            Text(m.q.animal.emoji + "🎉").font(.system(size: 20)).offset(y: -22)
                                .transition(.scale.combined(with: .opacity))
                        }
                        if m.stage == .lost && !m.showRight {
                            Text("❌").font(.system(size: 16)).offset(y: -18).transition(.scale)
                        }
                    }
                    .position(toView(m.boat))
                }
            }
        }
        .aspectRatio(zfMapRect.width / zfMapRect.height, contentMode: .fit)
        .frame(maxHeight: maxHeight)
        .padding(6)
        .background(LHParchment(radius: 12))
    }

    /// The quay: the lost animal with its suitcase — drag it onto a ferry.
    private var dock: some View {
        let a = m.q.animal
        let face: String = m.stage == .home ? "🥳" : (m.stage == .lost ? "😢" : "😟")
        return HStack(alignment: .bottom, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Ellipse().fill(Color.black.opacity(0.25)).frame(width: 90, height: 16).offset(x: -6, y: 6)
                Text(a.emoji).font(.system(size: 82))
                    .rotationEffect(.degrees(dragging ? 0 : (bob ? -4 : 4)), anchor: .bottom)
                    .scaleEffect(dragging ? 1.12 : 1)
                    .frame(width: 104, height: 96)
                // suitcase with a luggage tag
                ZStack {
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x8a4b24)).frame(width: 30, height: 22)
                    Rectangle().fill(Color(hex: 0x5e3216)).frame(width: 30, height: 3)
                    Capsule().stroke(Color(hex: 0x5e3216), lineWidth: 2.5).frame(width: 14, height: 8).offset(y: -13)
                    Text("?").font(luFont(12, .black)).foregroundStyle(Color(hex: lhInk))
                        .frame(width: 14, height: 14).background(RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xfbf0d6)))
                        .rotationEffect(.degrees(14)).offset(x: 16, y: -8)
                }
                .offset(x: 8, y: 0)
                Text(face).font(.system(size: 24)).offset(x: 6, y: -70)
            }
            .offset(drag)
            .opacity(m.stage == .waiting ? 1 : 0.4)
            .gesture(DragGesture(coordinateSpace: .named("zf"))
                .onChanged { g in
                    guard m.stage == .waiting, m.phase == .playing else { return }
                    if !dragging { Sfx.play(.tick) }
                    dragging = true; drag = g.translation
                }
                .onEnded { g in
                    dragging = false
                    let hitCard = cards.first { $0.value.insetBy(dx: -10, dy: -10).contains(g.location) }?.key
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
                    if let hitCard { m.send(hitCard) }
                })
            .zIndex(3)
            // Speech bubble.
            VStack(alignment: .leading, spacing: 2) {
                Text(m.stage == .home ? "Home at last!" : "I'm lost!").font(luFont(13, .bold)).foregroundStyle(Color(hex: lhInkSoft))
                Text(a.name).font(luSerif(24, .black)).foregroundStyle(Color(hex: lhInk))
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text(prompt).font(luFont(14, .heavy)).foregroundStyle(Color(hex: m.stage == .lost ? 0xb23a26 : lhInk))
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .transaction { $0.animation = nil }
                if m.perQ > 0 && m.stage == .waiting {
                    LHPatienceBar(left: m.tLeft, total: m.perQ).padding(.top, 2)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LHParchment(radius: 14))
            .padding(.bottom, 26)
        }
        .padding(.horizontal, 4)
    }

    private var prompt: String {
        let right = m.q.options[m.q.answer].label
        switch m.stage {
        case .lost: return "Home is \(right)!"
        case .home: return "Thank you! 💛"
        default:
            switch m.q.options[m.q.answer] {
            case .continent: return "👆 Drag me onto my ferry home"
            case .country: return "👆 Which country is my home?"
            case .biome: return "👆 Where do I live?"
            case .both: return "👆 Which land, which place?"
            }
        }
    }

    private var ferries: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(Array(m.q.options.enumerated()), id: \.offset) { i, d in
                ferry(i, d)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: ZFCardFrame.self, value: [i: g.frame(in: .named("zf"))])
                    })
            }
        }
        .id(m.qid)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: m.qid)
    }

    /// One ferry at its berth: a destination signboard above a bobbing boat.
    private func ferry(_ i: Int, _ d: ZFDest) -> some View {
        let hex = color(i)
        let isRight = i == m.q.answer
        let glow = (m.showRight || m.stage == .home) && isRight
        let wrongPick = m.picked == i && m.stage == .lost
        let big = m.q.options.count <= 2
        let sailing = m.picked == i && m.stage != .waiting
        let art = Group {
            switch d {
            case .biome(let b): Text(b.icon).font(.system(size: big ? 54 : 40))
            case .both(_, let b):
                ZStack(alignment: .bottomTrailing) {
                    ZFSilhouette(dest: d, hex: hex)
                    Text(b.icon).font(.system(size: 26))
                }
            default: ZFSilhouette(dest: d, hex: hex)
            }
        }
        return Button { m.send(i) } label: {
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    art.frame(height: big ? 92 : 52)
                    Text(d.label).font(luFont(big ? 19 : 15, .heavy)).foregroundStyle(Color(hex: lhInk))
                        .lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: glow ? 0xd6f0c8 : (wrongPick ? 0xfbd6cb : 0xfbf0d6)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: glow ? Lu.mint : hex), lineWidth: glow ? 4 : 3)))
                // posts holding the sign
                HStack { Rectangle().fill(Color(hex: 0x6b4a2a)).frame(width: 4, height: 8); Spacer(); Rectangle().fill(Color(hex: 0x6b4a2a)).frame(width: 4, height: 8) }
                    .padding(.horizontal, 30)
                ZFBoat(hex: hex, puff: bob)
                    .offset(x: sailing ? 260 : 0, y: bob ? -2 : 2)
                    .opacity(sailing && m.stage != .waiting ? 0 : 1)
                    .animation(.easeIn(duration: 0.8), value: sailing)
            }
            .scaleEffect(glow ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(m.stage == .waiting)
    }
}
