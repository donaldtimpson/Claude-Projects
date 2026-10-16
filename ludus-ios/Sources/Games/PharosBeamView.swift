import SwiftUI

// MARK: - Pharos Beam  (Globe Trotters · spinner)
//
// You keep the Pharos of Alexandria. A ship calls from a direction; drag (or tap) to swing the
// beam onto it — letting go locks the beam on the nearest bearing. A lit ship toots its thanks;
// a miss swings the beam to where the ship really was. The sea disc is the real map around
// Alexandria (Mercator, so on-map directions are true compass directions).
//
// Ladder:  I    the ship is VISIBLE; "a ship from the TOP ⬆️ (North)"; 4 directions
//          II   ships hide in fog — read NORTH / SOUTH / EAST / WEST off the rose; 4 directions
//          III  8 directions (NORTH-EAST …)
//          IV   the rose (and map) is turned 90/180/270° — find N first; 4 directions
//          V    turned by any 45° step; 8 directions; a slow clock appears (20 s)
//          VI   "a ship from Rome" — Mediterranean places relative to Alexandria; 8 directions
//          VII  bearings in degrees (045°, 270°…) on 45° steps
//          VIII bearings on 30° steps (12 spots)
//          IX+  a mix of V–VIII on a turned rose, clock tightening to 7 s.

private enum PBLabels { case four, eight, degrees }

private struct PBPlace {
    let name: String, flag: String
    let sector: Int         // 0 = N, 1 = NE … 7 = NW (true bearing from Alexandria)
    let lat: Double, lon: Double
    var caravan = false     // inland: a camel caravan, not a ship
}

/// Every place sits well inside its 45° sector by BOTH the great-circle and the rhumb (map)
/// bearing from Alexandria (31.20 N, 29.92 E) — ≥ 8° from any sector edge; bearings in degrees:
/// Rome 312 · Athens 325 · Crete (Knossos) 317 · Byzantium 356 · Cyprus 33 · Antioch 44 ·
/// Petra 99 · Giza 139 · Mt Sinai 126 · Abu Simbel 170 · Kharga 174 · Leptis Magna 280 · Benghazi 279.
private let pbPlaces: [PBPlace] = [
    PBPlace(name: "Rome", flag: "🇮🇹", sector: 7, lat: 41.9, lon: 12.5),
    PBPlace(name: "Athens", flag: "🇬🇷", sector: 7, lat: 37.98, lon: 23.73),
    PBPlace(name: "Crete", flag: "🇬🇷", sector: 7, lat: 35.3, lon: 25.16),
    PBPlace(name: "Byzantium", flag: "🇹🇷", sector: 0, lat: 41.01, lon: 28.98),
    PBPlace(name: "Cyprus", flag: "🇨🇾", sector: 1, lat: 35.0, lon: 33.0),
    PBPlace(name: "Antioch", flag: "🇹🇷", sector: 1, lat: 36.2, lon: 36.16),
    PBPlace(name: "Petra", flag: "🇯🇴", sector: 2, lat: 30.33, lon: 35.44, caravan: true),
    PBPlace(name: "the Pyramids", flag: "🇪🇬", sector: 3, lat: 29.98, lon: 31.13, caravan: true),
    PBPlace(name: "Mount Sinai", flag: "🇪🇬", sector: 3, lat: 28.54, lon: 33.97, caravan: true),
    PBPlace(name: "Abu Simbel", flag: "🇪🇬", sector: 4, lat: 22.34, lon: 31.63),
    PBPlace(name: "Kharga Oasis", flag: "🇪🇬", sector: 4, lat: 25.45, lon: 30.55, caravan: true),
    PBPlace(name: "Leptis Magna", flag: "🇱🇾", sector: 6, lat: 32.64, lon: 14.29),
    PBPlace(name: "Benghazi", flag: "🇱🇾", sector: 6, lat: 32.12, lon: 20.07),
]

#if DEBUG
/// Recomputes every place's bearing from Alexandria — great-circle AND rhumb (the map's) — and
/// checks both sit ≥ 8° inside the stated 45° sector.
private func pbSelfCheck() {
    let (la1, lo1) = (31.20 * Double.pi / 180, 29.92 * Double.pi / 180)
    func merc(_ la: Double) -> Double { log(tan(.pi / 4 + la / 2)) }
    for p in pbPlaces {
        let la2 = p.lat * .pi / 180, lo2 = p.lon * .pi / 180
        let gc = atan2(sin(lo2 - lo1) * cos(la2), cos(la1) * sin(la2) - sin(la1) * cos(la2) * cos(lo2 - lo1)) * 180 / .pi
        let rh = atan2(lo2 - lo1, merc(la2) - merc(la1)) * 180 / .pi
        for b in [gc, rh] {
            let off = abs(pbDelta(Double(p.sector) * 45, b))
            precondition(off <= 22.5 - 8, "Pharos: \(p.name) bearing \(b) not inside sector \(p.sector)")
        }
    }
    print("Pharos self-check OK: \(pbPlaces.count) places")
}
#endif

private let pbNames8 = ["NORTH", "NORTH-EAST", "EAST", "SOUTH-EAST", "SOUTH", "SOUTH-WEST", "WEST", "NORTH-WEST"]
private let pbShort8 = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

private struct PBRound {
    var bearings: [Double]          // true bearings of the candidate spots
    var answer: Int
    var rose: Double = 0            // screen rotation of North (clockwise degrees)
    var fog = true
    var labels: PBLabels = .four
    var lead = "A ship from the"
    var title = ""
    var sub = ""
    var traveller = "⛵️"
    var mapStrong = false
    var ticks30 = false
    func screen(_ i: Int) -> Double { rose + bearings[i] }
    var answerName: String {
        let b = bearings[answer]
        if labels == .degrees { return String(format: "%03.0f°", b) }
        return pbNames8[Int((b / 45).rounded()) % 8]
    }
}

private func pbDeg(_ b: Double) -> String { String(format: "%03.0f°", b) }

private func makeRound(_ level: Int) -> PBRound {
    var lv = level
    var rose: Double = 0
    if lv >= 9 {                        // endless: a turned rose over the hardest kinds
        lv = [5, 6, 7, 8].randomElement()!
        rose = Double(Int.random(in: 1...3) * 90)
    }
    let four: [Double] = [0, 90, 180, 270]
    let eight: [Double] = (0..<8).map { Double($0) * 45 }
    switch lv {
    case 1:
        let i = Int.random(in: 0..<4)
        let words = [("TOP", "⬆️"), ("RIGHT", "➡️"), ("BOTTOM", "⬇️"), ("LEFT", "⬅️")][i]
        return PBRound(bearings: four, answer: i, fog: false, title: "\(words.0) \(words.1)",
                       sub: "That's \(pbNames8[i * 2])!")
    case 2:
        let i = Int.random(in: 0..<4)
        return PBRound(bearings: four, answer: i, title: pbNames8[i * 2], sub: "Find \(pbShort8[i * 2]) on the compass")
    case 3:
        let i = Int.random(in: 0..<8)
        return PBRound(bearings: eight, answer: i, labels: .eight, title: pbNames8[i],
                       sub: i % 2 == 1 ? "Between \(pbShort8[i - 1]) and \(pbShort8[(i + 1) % 8])" : "")
    case 4:
        let i = Int.random(in: 0..<4)
        return PBRound(bearings: four, answer: i, rose: Double(Int.random(in: 1...3) * 90),
                       title: pbNames8[i * 2], sub: "The compass is turned — find N!")
    case 5:
        let i = Int.random(in: 0..<8)
        return PBRound(bearings: eight, answer: i, rose: rose != 0 ? rose : Double(Int.random(in: 1...7) * 45),
                       labels: .eight, title: pbNames8[i], sub: "Find N first!")
    case 6:
        let p = pbPlaces.randomElement()!
        return PBRound(bearings: eight, answer: p.sector, rose: rose, labels: .eight,
                       lead: p.caravan ? "A caravan from" : "A ship from",
                       title: "\(p.name.prefix(1).uppercased() + p.name.dropFirst()) \(p.flag)",
                       sub: "Which way is it from Alexandria?", traveller: p.caravan ? "🐪" : "⛵️", mapStrong: true)
    case 7:
        let i = Int.random(in: 0..<8)
        return PBRound(bearings: eight, answer: i, rose: rose, labels: .degrees, lead: "A ship at bearing",
                       title: pbDeg(eight[i]), sub: "0° is North · count clockwise")
    default:
        let b = (0..<12).map { Double($0) * 30 }
        let i = Int.random(in: 0..<12)
        return PBRound(bearings: b, answer: i, rose: rose, labels: .degrees, lead: "A ship at bearing",
                       title: pbDeg(b[i]), sub: "0° is North · count clockwise", ticks30: true)
    }
}

/// Seconds a ship waits (0 = no clock): none to IV, then 20 s easing to 7 s.
private func pbPatience(_ level: Int) -> Double { level <= 4 ? 0 : max(7, 20 - Double(level - 5) * 2) }

/// Signed shortest turn from a to b, degrees.
private func pbDelta(_ a: Double, _ b: Double) -> Double {
    var d = (b - a).truncatingRemainder(dividingBy: 360)
    if d > 180 { d -= 360 }; if d < -180 { d += 360 }
    return d
}

@MainActor
private final class PharosModel: ArcadeModel {
    enum Outcome { case none, lit, missed }
    @Published var round = makeRound(1)
    @Published var beam: Double = 0          // screen angle, unwrapped (so springs take the short way)
    @Published var chosen: Int?
    @Published var outcome: Outcome = .none
    @Published var showAnswer = false
    @Published var roundID = 0
    @Published var tLeft: Double = 0
    @Published var perQ: Double = 0
    private var locked = false

    init() {
        super.init(key: GameID.pharosBeam.rawValue)
        #if DEBUG
        pbSelfCheck()
        #endif
    }

    override func onBegin() { next() }

    func next() {
        var r = makeRound(level)
        // Don't repeat the same spot twice running.
        if r.answer == round.answer && r.bearings.count == round.bearings.count && roundID > 0 { r = makeRound(level) }
        round = r
        chosen = nil; outcome = .none; showAnswer = false; locked = false
        perQ = pbPatience(level); tLeft = perQ
        roundID += 1
    }

    /// Point the beam at a screen angle (finger drag).
    func aim(_ screen: Double) {
        guard phase == .playing, !locked else { return }
        beam += pbDelta(beam, screen)
    }

    /// Let go: snap to the nearest spot and light it.
    func release() {
        guard phase == .playing, !locked else { return }
        let i = round.bearings.indices.min { abs(pbDelta(beam, round.screen($0))) < abs(pbDelta(beam, round.screen($1))) } ?? 0
        lock(i)
    }

    func tick(_ dt: Double) {
        guard phase == .playing, !locked, perQ > 0 else { return }
        tLeft -= dt
        if tLeft <= 0 { lock(nil) }
    }

    private func lock(_ i: Int?) {
        locked = true
        chosen = i
        if let i { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { beam += pbDelta(beam, round.screen(i)) } }
        let right = i == round.answer
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { outcome = right ? .lit : .missed }
        if right {
            hit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) { [weak self] in
                guard let self, self.phase == .playing else { return }
                self.next()
            }
        } else {
            miss(reason: i == nil ? "The ship sailed away!" : "Out of hearts!", delay: 1.9)
            // Teach: swing the beam to where the ship really was.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                guard let self, self.phase == .playing else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.beam += pbDelta(self.beam, self.round.screen(self.round.answer))
                    self.showAnswer = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self, self.phase == .playing, !self.dying else { return }
                self.next()
            }
        }
    }

    override func botAct(correct: Bool) {
        guard !locked else { return }
        let wrong = round.bearings.indices.filter { $0 != round.answer }
        let i = correct ? round.answer : wrong.randomElement()!
        aim(round.screen(i) + Double.random(in: -8...8))   // a finger is never exact
        release()
    }
}

// MARK: - Views

private func pbUnit(_ deg: Double) -> CGPoint {
    let r = deg * .pi / 180
    return CGPoint(x: sin(r), y: -cos(r))
}

/// The sea disc: the real coast around Alexandria, turned with the rose.
private struct PBSea: View {
    let rose: Double
    let strong: Bool
    static let center = GeoAtlas.point(lat: 31.2, lon: 29.92)
    static let span: CGFloat = 62               // map units from Alexandria to the disc's edge
    static let near: [AtlasCountry] = {
        let win = CGRect(x: center.x - span * 1.5, y: center.y - span * 1.5, width: span * 3, height: span * 3)
        return GeoAtlas.countries.filter { $0.box.intersects(win) }
    }()

    var body: some View {
        Canvas { ctx, size in
            let R = min(size.width, size.height) / 2
            ctx.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)),
                     with: .radialGradient(Gradient(colors: [Color(hex: 0x2f6f95), Color(hex: 0x173a5a)]),
                                           center: CGPoint(x: R, y: R), startRadius: 0, endRadius: R))
            ctx.clip(to: Path(ellipseIn: CGRect(origin: .zero, size: size)))
            let k = R / Self.span
            ctx.translateBy(x: R, y: R)
            ctx.rotate(by: .degrees(rose))
            ctx.scaleBy(x: k, y: k)
            ctx.translateBy(x: -Self.center.x, y: -Self.center.y)
            for c in Self.near {
                ctx.fill(c.path, with: .color(Color(hex: 0xd9c49a).opacity(strong ? 0.85 : 0.5)))
                ctx.stroke(c.path, with: .color(Color(hex: 0x6b5530).opacity(strong ? 0.9 : 0.5)), lineWidth: 0.9 / k)
            }
        }
    }
}

/// The compass rose star (drawn turned), letters kept upright.
private struct PBRose: View {
    let round: PBRound
    let R: CGFloat
    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                for k in 0..<8 {
                    let a = round.rose + Double(k) * 45
                    let len = R * (k % 2 == 0 ? 0.44 : 0.28)
                    let tip = CGPoint(x: c.x + pbUnit(a).x * len, y: c.y + pbUnit(a).y * len)
                    for side in [-1.0, 1.0] {
                        let s = pbUnit(a + side * 45)
                        let w = R * 0.07
                        var p = Path()
                        p.move(to: c); p.addLine(to: tip)
                        p.addLine(to: CGPoint(x: c.x + s.x * w, y: c.y + s.y * w)); p.closeSubpath()
                        let hex: UInt = k == 0 ? (side < 0 ? 0xc0392b : 0xe0684f)
                                               : (side < 0 ? Lu.gold : 0xb8902a)
                        ctx.fill(p, with: .color(Color(hex: hex).opacity(k % 2 == 0 ? 0.95 : 0.6)))
                    }
                }
                let tickN = round.ticks30 ? 12 : (round.labels == .degrees ? 8 : 0)
                for t in 0..<tickN {
                    let u = pbUnit(round.rose + Double(t) * 360 / Double(tickN))
                    var p = Path()
                    p.move(to: CGPoint(x: c.x + u.x * R * 0.93, y: c.y + u.y * R * 0.93))
                    p.addLine(to: CGPoint(x: c.x + u.x * R * 0.995, y: c.y + u.y * R * 0.995))
                    ctx.stroke(p, with: .color(Color(hex: Lu.ink).opacity(0.7)), lineWidth: 2)
                }
            }
            ForEach(labels, id: \.0) { l in
                let u = pbUnit(round.rose + l.1)
                Text(l.0)
                    .font(luFont(l.2 ? 22 : 14, .black))
                    .foregroundStyle(Color(hex: l.3))
                    .shadow(color: .black.opacity(0.7), radius: 2)
                    .position(x: R + u.x * R * labelR, y: R + u.y * R * labelR)
            }
        }
        .frame(width: R * 2, height: R * 2)
    }

    private var labelR: CGFloat { round.labels == .degrees ? 0.5 : 0.6 }

    private var labels: [(String, Double, Bool, UInt)] {
        switch round.labels {
        case .four: return [("N", 0, true, 0xff7a66), ("E", 90, true, Lu.ink), ("S", 180, true, Lu.ink), ("W", 270, true, Lu.ink)]
        case .eight:
            return (0..<8).map { k in (pbShort8[k], Double(k) * 45, k % 2 == 0, k == 0 ? 0xff7a66 : (k % 2 == 0 ? Lu.ink : Lu.inkDim)) }
        case .degrees:
            return [("N 0°", 0, true, 0xff7a66), ("90°", 90, true, Lu.ink), ("180°", 180, true, Lu.ink), ("270°", 270, true, Lu.ink)]
        }
    }
}

/// The light cone, drawn pointing up; rotated by the beam angle.
private struct PBBeamShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let R = rect.width / 2
        var p = Path()
        p.move(to: c)
        p.addArc(center: c, radius: R * 0.98, startAngle: .degrees(-90 - 14), endAngle: .degrees(-90 + 14), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// The Pharos: three stacked tiers and a fire on top.
private struct PBTower: View {
    let glow: Bool
    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(RadialGradient(colors: [.white, Color(hex: Lu.gold), Color(hex: Lu.tangerine).opacity(0)],
                                         center: .center, startRadius: 1, endRadius: 14))
                .frame(width: 26, height: 26).scaleEffect(glow ? 1.5 : 1)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xe9dcc0)).frame(width: 10, height: 10)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xd9c8a4)).frame(width: 16, height: 14)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xc8b48c)).frame(width: 24, height: 20)
            Capsule().fill(Color(hex: 0x8a7350)).frame(width: 38, height: 7)
        }
        .offset(y: -18)
        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
    }
}

struct PharosBeamView: View {
    let onClose: () -> Void
    @StateObject private var m = PharosModel()
    @State private var bob = false
    private let clock = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ArcadeShell(model: m, spec: GameID.pharosBeam.spec ?? GameSpec(title: "Pharos Beam", mechanic: "", premise: "", game: .pharosBeam),
                    accent: Lu.sky, onClose: onClose) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 56)
                banner
                GeometryReader { geo in
                    let R = min(geo.size.width, geo.size.height) / 2 - 6
                    disc(R).position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                footer.frame(height: 56)
            }
            .padding(.horizontal, 12)
        }
        .onReceive(clock) { _ in m.tick(0.1) }
        .onChange(of: m.phase) { p in
            if p == .playing { withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { bob = true } }
            else { withAnimation(.linear(duration: 0.1)) { bob = false } }
        }
    }

    private var banner: some View {
        let r = m.round
        return HStack(spacing: 12) {
            Text(r.traveller).font(.system(size: 44))
                .rotationEffect(.degrees(bob ? -6 : 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(r.lead).font(luFont(15, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                Text(r.title).font(luSerif(30, .black)).foregroundStyle(Color(hex: Lu.gold))
                    .lineLimit(1).minimumScaleFactor(0.5)
                if !r.sub.isEmpty {
                    Text(r.sub).font(luFont(14, .bold)).foregroundStyle(Color(hex: Lu.ink))
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            Spacer(minLength: 0)
            Text("📯").font(.system(size: 30)).scaleEffect(bob ? 1.12 : 0.92)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(luPanelShape(18))
        .overlay(alignment: .bottom) {
            if m.perQ > 0 {
                GeometryReader { g in
                    Capsule().fill(Color(hex: m.tLeft / m.perQ < 0.3 ? Lu.coral : Lu.sky))
                        .frame(width: max(0, g.size.width * CGFloat(m.tLeft / m.perQ)), height: 5)
                }
                .frame(height: 5).padding(.horizontal, 14).padding(.bottom, 3)
            }
        }
        .id(m.roundID)
        .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: m.roundID)
    }

    private var footer: some View {
        let r = m.round
        let text: String, hex: UInt
        switch m.outcome {
        case .none: (text, hex) = ("👆 Drag the beam — let go to shine!", Lu.inkDim)
        case .lit: (text, hex) = ("TOOT TOOT! Thank you, keeper! 📯", Lu.mint)
        case .missed: (text, hex) = (r.labels == .degrees ? "It was at \(r.answerName)" : "It was in the \(r.answerName)!", Lu.coral)
        }
        return Text(text).font(luFont(18, .heavy)).foregroundStyle(Color(hex: hex))
            .multilineTextAlignment(.center).minimumScaleFactor(0.6)
            .transaction { $0.animation = nil }
    }

    private func disc(_ R: CGFloat) -> some View {
        let r = m.round
        let beamHex: UInt = m.outcome == .lit ? Lu.mint : (m.showAnswer ? Lu.mint : (m.outcome == .missed ? Lu.coral : Lu.gold))
        return ZStack {
            PBSea(rose: r.rose, strong: r.mapStrong).frame(width: R * 2, height: R * 2)
            Circle().stroke(Color(hex: Lu.goldLine), lineWidth: 4).frame(width: R * 2, height: R * 2)
            PBRose(round: r, R: R)
            PBBeamShape()
                .fill(RadialGradient(colors: [Color(hex: beamHex).opacity(0.85), Color(hex: beamHex).opacity(0.12)],
                                     center: .center, startRadius: 4, endRadius: R))
                .frame(width: R * 2, height: R * 2)
                .rotationEffect(.degrees(m.beam))
                .allowsHitTesting(false)
            ForEach(r.bearings.indices, id: \.self) { i in spot(i, R) }
            PBTower(glow: m.outcome == .lit)
        }
        .frame(width: R * 2, height: R * 2)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { g in
                let dx = g.location.x - R, dy = g.location.y - R
                guard dx * dx + dy * dy > 64 else { return }
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) { m.aim(atan2(dx, -dy) * 180 / .pi) }
            }
            .onEnded { _ in m.release() })
        .id(m.roundID)
        .transition(.opacity)
    }

    /// One candidate spot: fog (or open sea), the ship when it's there and showing.
    @ViewBuilder private func spot(_ i: Int, _ R: CGFloat) -> some View {
        let r = m.round
        let isShip = i == r.answer
        let lit = m.chosen == i && m.outcome != .none
        let shipShown = isShip && (!r.fog || (lit && m.outcome == .lit) || m.showAnswer)
        let fogShown = r.fog && !(lit || (isShip && m.showAnswer))
        let u = pbUnit(r.screen(i))
        let rad = R * (r.bearings.count > 8 ? 0.84 : 0.8)
        ZStack {
            if fogShown {
                Text("☁️").font(.system(size: r.bearings.count > 8 ? 34 : 42))
                    .opacity(0.92).scaleEffect(bob ? 1.06 : 0.96)
                    .transition(.scale(scale: 1.8).combined(with: .opacity))
            }
            if lit && !isShip {
                Text("🌊").font(.system(size: 34)).transition(.scale)
            }
            if shipShown {
                ZStack {
                    if m.showAnswer { Circle().stroke(Color(hex: Lu.mint), lineWidth: 4).frame(width: 66, height: 66) }
                    Text(r.traveller).font(.system(size: r.fog ? 44 : 56))
                        .rotationEffect(.degrees(bob ? -7 : 7))
                    if m.outcome == .lit {
                        Text("TOOT!").font(luFont(13, .black)).foregroundStyle(Color(hex: Lu.inkDark))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: Lu.ink)))
                            .offset(x: 26, y: -30)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .position(x: R + u.x * rad, y: R + u.y * rad + (r.fog ? 0 : (bob ? -3 : 3)))
        .allowsHitTesting(false)
    }
}
