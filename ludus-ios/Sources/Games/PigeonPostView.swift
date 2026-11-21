import SwiftUI

// MARK: - Pigeon Post  (Globe Trotters · tap the real map)
//
// Pippa the carrier pigeon lives on the lighthouse. Each letter has an address; tap the place on the
// real world map and she flies there. Right place: she drops the letter and the place lights up.
// Wrong place: she lands, the map says where she actually is ("That's Asia!"), then she flies on to
// the right place, which glows — every miss shows the answer.
//
// Continuous difficulty (tuned off `d`, never the level):
//   content kinds fade in by tier — continents (1) → oceans (2) → famous countries (3) → rivers,
//   mountains & deserts (4.5) → more countries (5.5) → latitude & longitude (7) → smaller
//   countries (8) — old kinds stay as review;
//   continent colours and picture badges fade out (d 2 → 4), the clue line fades out (d 5 → 7),
//   a patience bar appears from d 6 (a generous 22 s, after the new "more countries" kind has settled)
//   and tightens to 10 s by d 10; lat/long tolerance 14° → 7°.
// The clock never runs while the letter is still being delivered: it waits (bar full) until the
// card has landed and the map has panned — or, while letters are read aloud, until the voice is done.

private struct PPFeature {
    let name: String, icon: String, kind: String     // kind: "river", "mountains", "desert", "reef", "mountain"
    let line: [(Double, Double)]                      // lat, lon polyline (one point = a spot)
    let radius: Double                                // tolerance, degrees
    let hint: String
    let minD: Double
    var region: String = ""                           // continent the map zooms to (a river is too thin on the world map)
}

/// Rivers, ranges and deserts. Coordinates follow each feature's real course/extent (decimal degrees).
private let ppFeatures: [PPFeature] = [
    PPFeature(name: "Sahara Desert", icon: "🐪", kind: "desert", line: [(22, -10), (23, 0), (24, 10), (24, 20), (23, 28)],
              radius: 7, hint: "The biggest hot desert — north Africa", minD: 4.5, region: "Africa"),
    PPFeature(name: "Nile River", icon: "🐊", kind: "river",
              line: [(31.4, 31), (30, 31.2), (27, 31), (24, 32.9), (21, 30.8), (18, 31.5), (15.6, 32.5), (12, 32.6), (9, 30.5), (4.8, 31.6), (1, 32.5), (-1, 33)],
              radius: 3.5, hint: "The longest river in Africa — it flows north to Egypt", minD: 4.5, region: "Africa"),
    PPFeature(name: "Amazon River", icon: "🐸", kind: "river",
              line: [(-0.5, -50), (-2, -54.5), (-3.1, -60), (-3.4, -64.5), (-4, -69), (-4.3, -73)],
              radius: 3.5, hint: "A giant river through the rainforest of South America", minD: 4.5, region: "South America"),
    PPFeature(name: "Himalayas", icon: "🏔️", kind: "mountains",
              line: [(35, 74.5), (32, 78), (29.5, 81.5), (28, 85), (27.8, 88), (27.8, 91), (28.2, 95)],
              radius: 3.5, hint: "The highest mountains — north of India", minD: 4.5, region: "Asia"),
    PPFeature(name: "Andes Mountains", icon: "🦙", kind: "mountains",
              line: [(10, -72), (2, -77), (-6, -78), (-14, -73), (-20, -68), (-28, -69), (-35, -70), (-42, -71.5), (-50, -73)],
              radius: 3, hint: "The long mountains down the west side of South America", minD: 5, region: "South America"),
    PPFeature(name: "Rocky Mountains", icon: "🐻", kind: "mountains",
              line: [(60, -127), (54, -120), (49, -114), (45, -111), (41, -106.5), (36, -105.5)],
              radius: 4, hint: "Big mountains in the west of North America", minD: 5.5, region: "North America"),
    PPFeature(name: "Mississippi River", icon: "🚣", kind: "river",
              line: [(47.2, -95.2), (44.5, -92), (41.5, -90.8), (38.6, -90.2), (35, -90.1), (32.3, -91), (30, -90.7), (29.2, -89.3)],
              radius: 3, hint: "A great river flowing south through the USA", minD: 6, region: "North America"),
    PPFeature(name: "Alps", icon: "⛷️", kind: "mountains", line: [(44.2, 7), (45.9, 7.5), (46.5, 10), (47.1, 12.5), (47.5, 15)],
              radius: 2.5, hint: "Snowy mountains in the middle of Europe", minD: 6, region: "Europe"),
    PPFeature(name: "Great Barrier Reef", icon: "🐠", kind: "reef",
              line: [(-11, 143.8), (-15, 145.8), (-18.5, 147.5), (-21.5, 151), (-24, 152.5)],
              radius: 3, hint: "A huge coral reef off north-east Australia", minD: 6.5, region: "Oceania"),
    PPFeature(name: "Gobi Desert", icon: "🐫", kind: "desert", line: [(43, 97), (43, 103), (43.5, 108), (44, 112)],
              radius: 4.5, hint: "A cold desert in Mongolia and China", minD: 7, region: "Asia"),
    PPFeature(name: "Mount Kilimanjaro", icon: "🗻", kind: "mountain", line: [(-3.07, 37.35)],
              radius: 3.5, hint: "Africa's highest mountain, in Tanzania", minD: 7.5, region: "Africa"),
    PPFeature(name: "Ural Mountains", icon: "⛰️", kind: "mountains", line: [(67.5, 65), (63, 59.5), (59, 59.5), (55, 59), (51.5, 58.5)],
              radius: 3, hint: "Mountains between Europe and Asia, in Russia", minD: 8, region: "Europe"),
    PPFeature(name: "Yangtze River", icon: "🐼", kind: "river",
              line: [(31.4, 121.6), (30.5, 117), (30.6, 114.3), (30.3, 111), (29.6, 106.5), (28.2, 104.5), (27, 101), (32, 96)],
              radius: 3, hint: "The longest river in Asia, across China", minD: 8, region: "Asia"),
    PPFeature(name: "Mount Everest", icon: "🧗", kind: "mountain", line: [(27.99, 86.93)],
              radius: 3, hint: "The highest mountain on Earth, Nepal–China border", minD: 8.5, region: "Asia"),
]

private struct PPOceanInfo { let name: String; let icon: String; let hint: String }
private let ppOceans: [PPOceanInfo] = [
    PPOceanInfo(name: "Pacific Ocean", icon: "🐋", hint: "The BIGGEST ocean — between Asia and the Americas"),
    PPOceanInfo(name: "Atlantic Ocean", icon: "⛵️", hint: "Between the Americas and Europe & Africa"),
    PPOceanInfo(name: "Indian Ocean", icon: "🐢", hint: "South of India, between Africa and Australia"),
    PPOceanInfo(name: "Arctic Ocean", icon: "🐻‍❄️", hint: "Icy ocean at the very top of the world"),
    PPOceanInfo(name: "Southern Ocean", icon: "🐧", hint: "Cold ocean all around Antarctica"),
]

/// Famous countries first (the 36 everyone's heard of), then rank 3, then 4–5 (not tiny ones).
private let ppCountries: [[AtlasCountry]] = {
    let shapes = Dictionary(GeoShapes.all.map { ($0.name, $0.rank) }, uniquingKeysWith: { a, _ in a })
    func pool(_ ranks: ClosedRange<Int>) -> [AtlasCountry] {
        GeoAtlas.countries.filter { c in
            guard let r = shapes[c.name], ranks.contains(r), c.name.count <= 22 else { return false }
            return LH.mainBox(c).width >= 7 || ranks.lowerBound <= 2
        }
    }
    return [pool(1...2), pool(3...3), pool(4...5)]
}()

private func ppFlag(_ name: String) -> String {
    if let f = Geo.countries.first(where: { $0.name == name })?.flag { return f }
    guard let iso = ppISO[name] else { return "📍" }
    return iso.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map(String.init).joined()
}
/// ISO codes for the flags (read from the bundled atlas).
private let ppISO: [String: String] = {
    struct F: Decodable { let countries: [C]; struct C: Decodable { let name: String; let iso: String? } }
    guard let url = Bundle.main.url(forResource: "world-countries", withExtension: "json"),
          let data = try? Data(contentsOf: url), let f = try? JSONDecoder().decode(F.self, from: data) else { return [:] }
    return Dictionary(f.countries.compactMap { c in c.iso.map { (c.name, $0) } }, uniquingKeysWith: { a, _ in a })
}()

private enum PPTarget {
    case continent(String)
    case ocean(PPOceanInfo)
    case country(AtlasCountry)
    case feature(PPFeature)
    case latlon(Double, Double)
}

private struct PPTask {
    let target: PPTarget
    let title: String
    let icon: String
    let hint: String
    let camera: CGRect
    /// What the voice says: a command, with degrees read out ("30 degrees north").
    var spoken: String {
        if case .latlon(let a, let b) = target {
            func deg(_ v: Double, _ pos: String, _ neg: String) -> String {
                v == 0 ? "0 degrees" : "\(Int(abs(v))) degrees \(v > 0 ? pos : neg)"
            }
            return "Deliver to \(deg(a, "north", "south")), \(deg(b, "east", "west"))!"
        }
        return "Deliver to \(ppThe(title))!"
    }

    /// Where Pippa delivers the letter (map space).
    var home: CGPoint {
        switch target {
        case .continent(let c): return LH.anchor(c)
        case .ocean(let o): return LH.oceanPin(o.name)
        case .country(let c): return LH.pin(c)
        case .feature(let f):
            let mid = f.line[f.line.count / 2]
            return LH.point(lat: mid.0, lon: mid.1)
        case .latlon(let a, let b): return LH.point(lat: a, lon: b)
        }
    }
}

/// A place name as it sits in a sentence: "the Pacific Ocean", "the United States", "Africa".
private func ppThe(_ name: String) -> String {
    let lead = ["United ", "Netherlands", "Philippines", "Central African", "Dominican", "Czech"]
    let kinds = [" Ocean", " Sea", " River", " Desert", " Mountains", "Gulf of", "Bay of", "Himalayas", "Alps",
                 "Andes", "Great Barrier", "Ural", "Rocky", "Gambia", "Bahamas", "Democratic Republic"]
    if lead.contains(where: { name.hasPrefix($0) }) || kinds.contains(where: { name.contains($0) }) { return "the \(name)" }
    return name
}

private func ppLat(_ v: Double) -> String { v == 0 ? "0°" : "\(Int(abs(v)))°\(v > 0 ? "N" : "S")" }
private func ppLon(_ v: Double) -> String { v == 0 ? "0°" : "\(Int(abs(v)))°\(v > 0 ? "E" : "W")" }

/// Degrees between two lat/lon points on the map (longitude shrunk by latitude).
private func ppDeg(_ a: (Double, Double), _ b: (Double, Double)) -> Double {
    var dl = abs(a.1 - b.1); if dl > 180 { dl = 360 - dl }
    let k = cos((a.0 + b.0) / 2 * .pi / 180)
    return sqrt((a.0 - b.0) * (a.0 - b.0) + dl * dl * k * k)
}
/// Degrees from a point to a polyline (lat, lon).
private func ppDistance(_ p: (Double, Double), to line: [(Double, Double)]) -> Double {
    guard line.count > 1 else { return ppDeg(p, line[0]) }
    var best = Double.infinity
    for i in 0..<(line.count - 1) {
        let a = line[i], b = line[i + 1]
        for s in 0...10 {
            let t = Double(s) / 10
            best = min(best, ppDeg(p, (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t)))
        }
    }
    return best
}

@MainActor
private final class PigeonModel: ArcadeModel {
    enum Stage { case waiting, flying, delivered, wrong }
    @Published var task: PPTask
    @Published var stage: Stage = .waiting
    @Published var taskID = 0
    @Published var said: String?            // what Pippa found where she landed ("That's Asia!")
    @Published var tapped: CGPoint?         // map point of the tap
    @Published var wrongCountry: String?
    @Published var reveal = false           // the right place is glowing
    @Published var tLeft: Double = 0
    @Published var perQ: Double = 0
    @Published var clockOn = false          // false while the letter is still arriving (bar sits full)
    // Flight (map space) — the view animates Pippa along it.
    @Published var flight: (from: CGPoint?, to: CGPoint, start: Date, dur: Double)?
    private var recent: [String] = []

    init() {
        task = PPTask(target: .continent("Africa"), title: "Africa", icon: "🦁", hint: "", camera: LH.world)
        super.init(key: GameID.pigeonPost.rawValue)
        #if DEBUG
        ppSelfCheck()
        #endif
    }

    // Aids that fade as the child grows.
    var badgeAlpha: Double { ramp(1, 0, from: 2, to: 4) }
    var tintAlpha: Double { ramp(1, 0.15, from: 2, to: 4.5) }
    var hintShown: Bool {
        if case .latlon = task.target { return true }
        return d < 7
    }
    var latTol: Double { ramp(14, 7, from: 7, to: 10) }

    override func onBegin() { recent = []; next() }

    func next() {
        task = makeTask()
        stage = .waiting; said = nil; tapped = nil; wrongCountry = nil; reveal = false
        flight = nil
        perQ = d < 6 ? 0 : ramp(22, 10, from: 6, to: 10); tLeft = perQ
        clockOn = false
        taskID += 1
        let id = taskID
        let start = { [weak self] in
            guard let self, self.taskID == id, self.phase == .playing else { return }
            self.clockOn = true
        }
        // Read aloud to the younger players; the clock (if any) starts once the voice is done.
        if d < 6 { LibraryVoice.say(task.spoken, then: start) }
        // Otherwise once the card has landed and the map has panned to the region.
        else { DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: start) }
    }

    private func fresh<T>(_ pool: [T], _ name: (T) -> String) -> T {
        let ok = pool.filter { !recent.contains(name($0)) }
        let pick = (ok.isEmpty ? pool : ok).randomElement()!
        recent.append(name(pick)); if recent.count > 4 { recent.removeFirst() }
        return pick
    }

    private func makeTask() -> PPTask {
        let kind = tier([1, 2, 3, 4.5, 5.5, 7, 8])
        switch kind {
        case 0:
            // Antarctica waits until the badges have faded a little (it's the odd one, drawn as ice).
            let pool = LH.continents.filter { $0 != "Antarctica" || d >= 2 }
            let c = fresh(pool) { $0 }
            return PPTask(target: .continent(c), title: c, icon: LH.icon(c), hint: "A continent", camera: LH.world)
        case 1:
            let o = fresh(ppOceans) { $0.name }
            return PPTask(target: .ocean(o), title: o.name, icon: o.icon, hint: o.hint, camera: LH.world)
        case 3:
            let pool = ppFeatures.filter { $0.minD <= d + 0.5 }
            let f = fresh(pool.isEmpty ? Array(ppFeatures.prefix(4)) : pool) { $0.name }
            // Zoom to the feature's part of the world, so a river or a peak is a finger-sized target.
            let pts = f.line.map { LH.point(lat: $0.0, lon: $0.1) }
            let box = pts.dropFirst().reduce(CGRect(origin: pts[0], size: .zero)) { $0.union(CGRect(origin: $1, size: .zero)) }
            let cam = LH.region(f.region).union(box.insetBy(dx: -30, dy: -30))
            return PPTask(target: .feature(f), title: f.name, icon: f.icon, hint: f.hint, camera: cam)
        case 5:
            let lat = Double([-30, -15, 0, 15, 30, 45, 60].randomElement()!)
            let lon = Double(Int.random(in: -11...11) * 15)
            return PPTask(target: .latlon(lat, lon), title: "\(ppLat(lat))  \(ppLon(lon))", icon: "🧭",
                          hint: "Latitude: N/S of the equator · Longitude: E/W of 0°", camera: LH.world)
        default:
            let pool = kind == 2 ? ppCountries[0] : (kind == 4 ? ppCountries[1] : ppCountries[2])
            let c = fresh(pool) { $0.name }
            let cont = c.name == "Russia" ? "Europe" : c.continent
            let cam = c.name == "Russia" ? LH.world : LH.region(cont).union(LH.mainBox(c).insetBy(dx: -10, dy: -10))
            return PPTask(target: .country(c), title: c.name, icon: ppFlag(c.name), hint: "In \(LH.continent(of: c, at: LH.pin(c)))", camera: cam)
        }
    }

    func tick(_ dt: Double) {
        guard phase == .playing, stage == .waiting, perQ > 0, clockOn else { return }
        tLeft -= dt
        if tLeft <= 0 { timeout() }
    }

    private func timeout() {
        stage = .wrong; said = "Too slow — the letter's late!"
        miss(reason: "The letters piled up!", delay: 2.4)
        showAnswer(from: nil)
    }

    /// Judges a tap (map space): right, or what was hit instead.
    private func judge(_ p: CGPoint, tol: CGFloat) -> (Bool, String) {
        let land = p.y >= LH.iceTop ? nil : LH.country(at: p)
        let onIce = p.y >= LH.iceTop
        func placeName() -> String {
            if onIce { return "Antarctica" }
            if let land { return land.name }
            return LH.water(at: p).name
        }
        switch task.target {
        case .continent(let c):
            if onIce { return (c == "Antarctica", "Antarctica") }
            if let n = land ?? LH.countryNear(p, tol: tol) {
                let k = LH.continent(of: n, at: p)
                return (k == c, k)
            }
            return (false, LH.water(at: p).name)
        case .ocean(let o):
            if onIce { return (false, "Antarctica — that's ice, not sea!") }
            if let land { return (false, "\(land.name) — that's land!") }
            let w = LH.water(at: p)
            return (w.name == o.name, w.name)
        case .country(let c):
            if let land, land.name == c.name { return (true, c.name) }
            if land == nil, LH.countryNear(p, tol: tol)?.name == c.name { return (true, c.name) }
            return (false, placeName())
        case .feature(let f):
            // Never tighter than a fingertip (`tol` ≈ 12 pt, in map units → degrees of longitude).
            let r = max(f.radius, Double(tol) * 0.36 * 1.4)
            let ok = ppDistance((LH.lat(p.y), LH.lon(p.x)), to: f.line) <= r
            return (ok, placeName())
        case .latlon(let a, let b):
            let la = LH.lat(p.y), lo = LH.lon(p.x)
            let ok = ppDeg((la, lo), (a, b)) <= latTol
            return (ok, "\(ppLat((la / 5).rounded() * 5)) \(ppLon((lo / 5).rounded() * 5))")
        }
    }

    /// A tap on the map (map space). `tol` = how far (map units) a coast tap may be from land.
    func send(to p: CGPoint, tol: CGFloat) {
        guard phase == .playing, stage == .waiting else { return }
        let (ok, name) = judge(p, tol: tol)
        tapped = p
        stage = .flying
        Sfx.play(.whoosh); Haptics.tap(0.4)
        let dur = 0.75
        flight = (nil, p, Date(), dur)
        DispatchQueue.main.asyncAfter(deadline: .now() + dur) { [weak self] in
            guard let self, self.phase == .playing else { return }
            if ok {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { self.stage = .delivered; self.reveal = true }
                self.said = "Delivered to \(ppThe(self.task.title))!"
                Sfx.play(.thud)
                self.hit()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    guard let self, self.phase == .playing else { return }
                    self.next()
                }
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { self.stage = .wrong }
                let place = ppThe(name)
                self.said = "Coo? That's \(place)\(place.hasSuffix("!") ? "" : ".")"
                if case .country = self.task.target, let land = LH.country(at: p) { self.wrongCountry = land.name }
                self.miss(reason: "The letters got lost!", delay: 2.6)
                self.showAnswer(from: p)
            }
        }
    }

    /// Pippa flies on to the right place, which lights up; then the next letter.
    private func showAnswer(from p: CGPoint?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            guard let self, self.phase == .playing else { return }
            self.flight = (p, self.task.home, Date(), 0.8)
            withAnimation(.easeInOut(duration: 0.4)) { self.reveal = true }
            Sfx.play(.sparkle)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { [weak self] in
            guard let self, self.phase == .playing, !self.dying else { return }
            self.next()
        }
    }

    override func botAct(correct: Bool) {
        guard stage == .waiting else { return }
        if correct {
            var p = task.home
            if case .ocean(let o) = task.target { p = LH.oceanPin(o.name) }
            send(to: p, tol: 4)
        } else {
            // Somewhere plainly wrong: the far side of the world.
            let h = task.home
            send(to: CGPoint(x: (h.x + 500).truncatingRemainder(dividingBy: 1000), y: max(200, min(600, 800 - h.y))), tol: 4)
        }
    }
}

#if DEBUG
private func ppSelfCheck() {
    // Every country / feature / ocean pin must judge right at its own home.
    for c in ppCountries.flatMap({ $0 }) {
        let p = LH.pin(c)
        if !(LH.country(at: p)?.name == c.name || LH.countryNear(p, tol: 3)?.name == c.name) { print("SELFCHECK FAIL pin \(c.name)") }
    }
    for o in ppOceans {
        let p = LH.oceanPin(o.name)
        if !(LH.country(at: p) == nil && LH.water(at: p).name == o.name) { print("SELFCHECK FAIL ocean \(o.name)") }
    }
    for c in LH.continents where c != "Antarctica" {
        let p = LH.anchor(c)
        let k = LH.country(at: p).map { LH.continent(of: $0, at: p) }
        if k != c { print("SELFCHECK FAIL anchor \(c) \(k ?? "sea")") }
    }
    print("SELFCHECK pigeonPost OK: \(ppCountries.map(\.count)) countries")
}
#endif

// MARK: - Pippa

/// Pippa the pigeon, drawn (not an emoji): grey body, petrol-green neck, a letter in her beak.
private struct PPPigeon: View {
    var flap: Double          // 0…1 wing position
    var facingLeft = false
    var letter = true
    var mood: PigeonModel.Stage = .waiting
    var body: some View {
        ZStack {
            // tail
            Path { p in p.move(to: CGPoint(x: 8, y: 34)); p.addLine(to: CGPoint(x: -6, y: 28)); p.addLine(to: CGPoint(x: -4, y: 42)); p.closeSubpath() }
                .fill(Color(hex: 0x5d6670))
            // feet
            if mood != .flying {
                HStack(spacing: 6) {
                    Capsule().fill(Color(hex: 0xe07a74)).frame(width: 3, height: 9)
                    Capsule().fill(Color(hex: 0xe07a74)).frame(width: 3, height: 9)
                }.offset(x: 2, y: 25)
            }
            // body
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xb8c0c9), Color(hex: 0x8a939e)], startPoint: .top, endPoint: .bottom))
                .frame(width: 44, height: 32).offset(x: 4, y: 8)
            Ellipse().fill(Color(hex: 0xd7dde3)).frame(width: 26, height: 16).offset(x: 10, y: 14)
            // neck sheen
            Circle().fill(LinearGradient(colors: [Color(hex: 0x4caf8f), Color(hex: 0x8a5fb5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 22, height: 22).offset(x: 17, y: -4)
            // head
            Circle().fill(Color(hex: 0xa9b2bc)).frame(width: 22, height: 22).offset(x: 22, y: -14)
            Circle().fill(.white).frame(width: 8, height: 8).offset(x: 26, y: -16)
            Circle().fill(Color(hex: 0x2a1a10)).frame(width: 4.5, height: 4.5).offset(x: 27, y: -16)
            Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 9, y: 3)); p.addLine(to: CGPoint(x: 0, y: 6)); p.closeSubpath() }
                .fill(Color(hex: 0xe8a23a)).frame(width: 9, height: 6).offset(x: 36, y: -12)
            if letter {
                ZStack {
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xfbf3df)).frame(width: 20, height: 14)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: 0x9c7b33), lineWidth: 1))
                    Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 10, y: 7)); p.addLine(to: CGPoint(x: 20, y: 0)) }
                        .stroke(Color(hex: 0x9c7b33), lineWidth: 1).frame(width: 20, height: 14)
                    Circle().fill(Color(hex: 0xc0392b)).frame(width: 5, height: 5).offset(y: 1)
                }
                .rotationEffect(.degrees(-12)).offset(x: 46, y: -6)
            }
            // wing
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0x9aa3ad), Color(hex: 0x6c757f)], startPoint: .top, endPoint: .bottom))
                .overlay(VStack(spacing: 3) { Capsule().fill(Color(hex: 0x3f464d)).frame(width: 20, height: 2.5)
                                              Capsule().fill(Color(hex: 0x3f464d)).frame(width: 16, height: 2.5) }.offset(x: 4, y: 4))
                .frame(width: 34, height: 18)
                .rotationEffect(.degrees(-10 - flap * 70), anchor: .trailing)
                .offset(x: -2, y: 4 - flap * 6)
            if mood == .delivered {
                Text("♥").font(.system(size: 14, weight: .black)).foregroundStyle(Color(hex: Lu.coral)).offset(x: 30, y: -36)
            }
        }
        .frame(width: 60, height: 60)
        .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
    }
}

// MARK: - View

struct PigeonPostView: View {
    let onClose: () -> Void
    @StateObject private var m = PigeonModel()
    @State private var camFrom = LH.world
    @State private var camTo = LH.world
    @State private var camStart = Date.distantPast

    var body: some View {
        ArcadeShell(model: m, spec: GameID.pigeonPost.spec ?? GameSpec(title: "Pigeon Post", mechanic: "", premise: "", game: .pigeonPost),
                    accent: Lu.sky, onClose: onClose, backdrop: { PPSky() }) {
            VStack(spacing: 10) {
                HUDSpace(58)
                letterCard
                GeometryReader { geo in
                    // As tall as the space allows (up to a little taller than wide), and centred with
                    // Pippa's rail right under it — no dead band of sky between the letter and the map.
                    let h = max(200, min(geo.size.height - 74, geo.size.width * 1.2))
                    let spare = max(0, geo.size.height - 74 - h)
                    VStack(spacing: 0) {
                        Spacer(minLength: 0).frame(height: spare * 0.4)
                        mapArea(CGSize(width: geo.size.width, height: h)).frame(height: h)
                        Spacer(minLength: 74)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        // A task, not a Timer stored on this struct (that was rebuilt on every redraw).
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                m.tick(0.1)
            }
        }
        .onChange(of: m.taskID) { _ in
            camFrom = currentCam(Date()); camTo = m.task.camera; camStart = Date()
        }
    }

    private func currentCam(_ now: Date) -> CGRect {
        LH.lerp(camFrom, camTo, LH.smooth(now.timeIntervalSince(camStart) / 0.7))
    }

    // MARK: The letter (the call)
    private var letterCard: some View {
        let t = m.task
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xfffaf0)).frame(width: 62, height: 46)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0x9c7b33), lineWidth: 1.5))
                Text(t.icon).font(.system(size: 34))
            }
            .rotationEffect(.degrees(-4))
            VStack(alignment: .leading, spacing: 1) {
                Text("PLEASE DELIVER TO").font(luFont(11, .heavy)).tracking(1.5).foregroundStyle(Color(hex: lhInkSoft))
                Text(t.title).font(luSerif(t.title.count > 16 ? 23 : 28, .black)).foregroundStyle(Color(hex: lhInk))
                    .lineLimit(1).minimumScaleFactor(0.5)
                if m.hintShown && !t.hint.isEmpty {
                    Text(t.hint).font(luFont(13, .bold)).foregroundStyle(Color(hex: lhInkSoft))
                        .lineLimit(2).minimumScaleFactor(0.7)
                }
            }
            Spacer(minLength: 0)
            LibrarySpeakerButton(size: 44) { LibraryVoice.say(t.spoken) }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(LHParchment())
        .overlay(alignment: .bottom) {
            if m.perQ > 0 && m.stage == .waiting {
                LHPatienceBar(left: m.tLeft, total: m.perQ).padding(.horizontal, 16).padding(.bottom, 5)
            }
        }
        .id(m.taskID)
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: m.taskID)
    }

    // MARK: The map
    private func mapArea(_ size: CGSize) -> some View {
        TimelineView(.animation(paused: m.phase != .playing)) { tl in
            let now = tl.date
            let cam = LH.Camera(currentCam(now), size)
            ZStack {
                Canvas { ctx, sz in draw(&ctx, LH.Camera(cam.rect, sz), now) }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: 0x9c7b33), lineWidth: 3))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { v in
                        m.send(to: cam.map(v.location), tol: 12 / cam.scale)
                    })
                badges(cam)
                if let said = m.said, m.stage != .waiting, m.stage != .flying {
                    Text(said).font(luFont(17, .heavy)).foregroundStyle(Color(hex: lhInk))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: m.stage == .delivered ? 0xd6f0c8 : 0xfbe3d6))
                            .overlay(Capsule().stroke(Color(hex: m.stage == .delivered ? Lu.mint : Lu.coral), lineWidth: 2)))
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .padding(.horizontal, 10)
                        .position(x: size.width / 2, y: size.height - 26)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
                perch(size)
                pigeon(cam, size, now)
            }
        }
    }

    /// The continent picture badges for pre-readers (fade out as d rises).
    @ViewBuilder private func badges(_ cam: LH.Camera) -> some View {
        let a = m.badgeAlpha * (m.stage == .waiting ? 1 : 0.35)    // out of Pippa's way once she lands
        if a > 0.01, cam.rect.width > 600 {
            ForEach(LH.continents, id: \.self) { c in
                Text(LH.icon(c)).font(.system(size: 22))
                    .padding(3).background(Circle().fill(Color.white.opacity(0.75)))
                    .position(cam.view(LH.anchor(c)))
                    .opacity(a)
                    .allowsHitTesting(false)
            }
        }
    }

    /// The lighthouse gallery rail under the map, where Pippa waits.
    private func perch(_ size: CGSize) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6).fill(LinearGradient(colors: [Color(hex: 0xd8c9a8), Color(hex: 0xa8946b)], startPoint: .top, endPoint: .bottom))
                .frame(height: 16)
            HStack(spacing: 18) { ForEach(0..<14, id: \.self) { _ in Capsule().fill(Color(hex: 0x8a7350)).frame(width: 5, height: 30) } }
                .offset(y: 22).padding(.leading, 8)
            Text(m.stage == .waiting ? "👆 Tap the map where my letter goes!" : " ")
                .font(luFont(14, .heavy)).foregroundStyle(Color(hex: lhInk))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.85)))
                .offset(x: 92, y: -22)
                .opacity(m.stage == .waiting ? 1 : 0)
        }
        .frame(width: size.width)
        .position(x: size.width / 2, y: size.height + 44)
        .allowsHitTesting(false)
    }

    private func perchSpot(_ size: CGSize) -> CGPoint { CGPoint(x: 44, y: size.height + 18) }

    private func pigeon(_ cam: LH.Camera, _ size: CGSize, _ now: Date) -> some View {
        let home = perchSpot(size)
        var pos = home
        var flying = false
        var facingLeft = false
        if let f = m.flight {
            let a = f.from.map(cam.view) ?? home
            let b = cam.view(f.to)
            let t = LH.smooth(now.timeIntervalSince(f.start) / f.dur)
            let lift = min(140, hypot(b.x - a.x, b.y - a.y) * 0.35)
            pos = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t - lift * 4 * t * (1 - t))
            flying = t < 1
            facingLeft = b.x < a.x
            if t >= 1 { pos = b }
            // Keep her (and her pin) inside the map frame, even for a tap on its very edge.
            if f.from != nil || t > 0.5 {
                pos.x = min(max(pos.x, 26), size.width - 26)
                pos.y = min(max(pos.y, 44), size.height - 10)
            }
        }
        let flap = flying ? (sin(now.timeIntervalSinceReferenceDate * 22) + 1) / 2
                          : (m.stage == .waiting ? 0.1 + 0.1 * sin(now.timeIntervalSinceReferenceDate * 3) : 0.25)
        let landed = m.flight != nil && !flying
        let showLetter = !(landed && m.stage == .delivered)
        return ZStack {
            if landed {      // a pin where she landed
                Circle().fill(Color(hex: m.stage == .delivered || m.reveal ? Lu.mint : Lu.coral))
                    .frame(width: 12, height: 12).overlay(Circle().stroke(.white, lineWidth: 2))
                    .position(pos)
            }
            PPPigeon(flap: flap, facingLeft: facingLeft, letter: showLetter, mood: flying ? .flying : m.stage)
                .scaleEffect(flying ? 1.05 : 0.95)
                .position(x: pos.x, y: pos.y - (landed ? 22 : 0))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        }
        .allowsHitTesting(false)
    }

    // MARK: Drawing the map
    private func draw(_ ctx: inout GraphicsContext, _ cam: LH.Camera, _ now: Date) {
        let full = CGRect(origin: .zero, size: cam.size)
        ctx.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x6fb6d6), Color(hex: 0x3f87b3)]),
                                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: cam.size.height)))
        var c = ctx
        cam.apply(&c)
        let line = 0.7 / cam.scale
        let task = m.task
        let reveal = m.reveal
        let tint = m.tintAlpha
        let vis = cam.visible

        // Gentle wave marks on open water (old-map charm).
        let wave = Color.white.opacity(0.18)
        let step: CGFloat = 60
        var y = floor(vis.minY / step) * step
        let drift = CGFloat(now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 8) / 8) * step
        while y < vis.maxY {
            var x = floor(vis.minX / step) * step - step + drift
            while x < vis.maxX {
                var p = Path()
                p.move(to: CGPoint(x: x, y: y + 6)); p.addQuadCurve(to: CGPoint(x: x + 14, y: y + 6), control: CGPoint(x: x + 7, y: y))
                c.stroke(p, with: .color(wave), lineWidth: 1.4 / cam.scale)
                x += step
            }
            y += step / 2
        }

        // Lat/long grid: always faint, clearer on lat/long letters.
        var isLatLon = false
        if case .latlon = task.target { isLatLon = true }
        LH.drawGrid(c, step: isLatLon ? 15 : 30, alpha: isLatLon ? 0.35 : 0.12, line: line * (isLatLon ? 1.4 : 1), color: .white)

        // Land.
        let land = Color(hex: 0xe9dcb8)
        var answerCountry: String?
        if case .country(let a) = task.target { answerCountry = a.name }
        var answerContinent: String?
        if case .continent(let a) = task.target { answerContinent = a }
        var tints: [String: Color] = [:]
        // On the reveal the other lands go plain, so the green answer can't be mistaken for a tint
        // (North America's own colour is a green too).
        for k in LH.continents { tints[k] = tint > 0.2 && !reveal ? land.mix(Color(hex: LH.hex(k)), tint * 0.85) : land }
        let wrong = m.wrongCountry
        LH.drawLand(c, visible: vis, line: line) { country, cont in
            if reveal, let answerCountry, country.name == answerCountry { return Color(hex: Lu.mint) }
            if reveal, let answerContinent, cont == answerContinent { return Color(hex: Lu.mint) }
            if let wrong, country.name == wrong { return Color(hex: Lu.coral).opacity(0.85) }
            return tints[cont] ?? land
        }
        // Antarctica.
        let iceRight = reveal && answerContinent == "Antarctica"
        c.fill(LH.antarctica, with: .color(Color(hex: iceRight ? Lu.mint : 0xf4fbff)))
        c.stroke(LH.antarctica, with: .color(Color(hex: 0x9cc3d8)), lineWidth: line * 1.5)

        // The revealed feature / ocean / lat-long target.
        if reveal {
            switch task.target {
            case .feature(let f):
                let pts = f.line.map { LH.point(lat: $0.0, lon: $0.1) }
                if pts.count == 1 {
                    let r = CGFloat(f.radius) * 2.2
                    c.fill(Path(ellipseIn: CGRect(x: pts[0].x - r, y: pts[0].y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: Lu.mint).opacity(0.55)))
                } else {
                    var p = Path(); p.addLines(pts)
                    let hex: UInt = f.kind == "river" ? 0x1f6fd1 : (f.kind == "desert" ? 0xe8b04a : (f.kind == "reef" ? 0xff7f9a : 0x7a5230))
                    c.stroke(p, with: .color(Color(hex: Lu.mint).opacity(0.5)), style: StrokeStyle(lineWidth: CGFloat(f.radius) * 4, lineCap: .round, lineJoin: .round))
                    c.stroke(p, with: .color(Color(hex: hex)), style: StrokeStyle(lineWidth: f.kind == "river" ? 2.4 : 5, lineCap: .round, lineJoin: .round))
                }
            case .ocean(let o):
                let p = LH.oceanPin(o.name)
                c.fill(Path(ellipseIn: CGRect(x: p.x - 40, y: p.y - 26, width: 80, height: 52)), with: .color(Color(hex: Lu.mint).opacity(0.45)))
            case .latlon(let a, let b):
                let p = LH.point(lat: a, lon: b)
                var h = Path(); h.move(to: LH.point(lat: a, lon: -180)); h.addLine(to: LH.point(lat: a, lon: 180))
                var v = Path(); v.move(to: LH.point(lat: 84, lon: b)); v.addLine(to: CGPoint(x: p.x, y: LH.iceTop))
                c.stroke(h, with: .color(Color(hex: Lu.mint)), lineWidth: 2 / cam.scale)
                c.stroke(v, with: .color(Color(hex: Lu.mint)), lineWidth: 2 / cam.scale)
            default: break
            }
        }
        // Lat/long labels along the edges (in view space).
        if isLatLon {
            for lat in stride(from: -30.0, through: 60, by: 15) {
                let p = cam.view(LH.point(lat: lat, lon: 0))
                guard p.y > 8, p.y < cam.size.height - 8 else { continue }
                ctx.draw(ctx.resolve(Text(ppLat(lat)).font(luFont(10, .heavy)).foregroundColor(Color(hex: lhInk))),
                         at: CGPoint(x: 18, y: p.y))
            }
            // Longitudes on two staggered rows, so neighbours never run into each other.
            for (k, lon) in stride(from: -150.0, through: 150, by: 30).enumerated() {
                let p = cam.view(LH.point(lat: 0, lon: lon))
                let yy = cam.view(CGPoint(x: 0, y: LH.iceTop - 6)).y + (k % 2 == 0 ? 0 : 13)
                ctx.draw(ctx.resolve(Text(ppLon(lon)).font(luFont(10, .heavy)).foregroundColor(Color(hex: lhInk))),
                         at: CGPoint(x: p.x, y: min(cam.size.height - 8, yy)))
            }
        }
    }
}

private extension Color {
    /// Blend toward another colour by t (0…1) — sRGB components.
    func mix(_ o: Color, _ t: Double) -> Color {
        let a = UIColor(self), b = UIColor(o)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1); b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = CGFloat(t)
        return Color(red: Double(r1 + (r2 - r1) * k), green: Double(g1 + (g2 - g1) * k), blue: Double(b1 + (b2 - b1) * k))
    }
}

/// The sky above the lighthouse: soft dawn blue, drifting clouds, a few gulls.
private struct PPSky: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            GeometryReader { g in
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x8fd0ef), Color(hex: 0xc9e8f2), Color(hex: 0xf7e2c0)],
                                   startPoint: .top, endPoint: .bottom)
                    ForEach(0..<4, id: \.self) { i in
                        let w = g.size.width
                        let x = (CGFloat(t) * (8 + CGFloat(i) * 3) + CGFloat(i) * 170).truncatingRemainder(dividingBy: w + 240) - 120
                        LHCloud(color: .white.opacity(0.85))
                            .frame(width: 130 + CGFloat(i % 2) * 50, height: 56 + CGFloat(i % 2) * 18)
                            .position(x: x, y: CGFloat([120, 300, 520, 760][i]) / 874 * g.size.height)
                    }
                }
            }
        }
    }
}
