import SwiftUI

// MARK: - Agrippa's Map  (Globe Trotters · jigsaw on the real map)
//
// Marcus Agrippa's great map of the world hung in a colonnade in Rome. Here it lies unfinished on
// the mapmaker's desk: pieces of the world wait in the tray — drag each into its place. A piece
// dropped near its home snaps in with a thud; a wrong drop slides it to where it really belongs
// (the hole flashes) — every miss shows the answer. A finished board gets a wax seal.
//
// Continuous difficulty (tuned off `d`):
//   boards fade in by tier — the continents on the world map (1) → famous countries of a continent
//   (2.5) → more countries (4.5) → smaller ones (6.5); old boards stay as review;
//   pieces per board 2 → 5; the holes' dashed outlines fade out (d 3 → 7) so the place must be
//   known, not just matched; snap tolerance 64 pt → 22 pt.

private struct APPart { let path: Path; let clip: CGRect? }

private struct APPiece: Identifiable {
    let id: String
    let name: String
    let badge: String
    let parts: [APPart]
    let box: CGRect                       // map space
    var home: CGPoint { CGPoint(x: box.midX, y: box.midY) }
}

private struct APBoard {
    let title: String
    let region: CGRect                    // map rect shown
    let pieces: [APPiece]
    let backdrop: [APPart]                // land already drawn (not pieces)
    let continentBoard: Bool
}

/// Sub-outlines of a country (islands etc.) as separate paths.
private func apSubpaths(_ c: AtlasCountry) -> [Path] {
    var out: [Path] = [], cur = Path(), open = false
    c.path.forEach { e in
        switch e {
        case .move(let p): if open { out.append(cur) }; cur = Path(); cur.move(to: p); open = true
        case .line(let p): cur.addLine(to: p)
        case .closeSubpath: cur.closeSubpath()
        default: break
        }
    }
    if open { out.append(cur) }
    return out
}

/// Where each continent's land is gathered from (drops far-flung islands and the dateline wrap).
private func apWindow(_ cont: String) -> CGRect {
    switch cont {
    case "Europe": return LH.box(lat: 34...82, lon: -32...60)
    case "Asia": return LH.box(lat: -12...82, lon: 25...180)
    case "Africa": return LH.box(lat: -36...38, lon: -26...64)
    case "North America": return LH.box(lat: 5...84, lon: -180...(-10))
    case "South America": return LH.box(lat: -57...14, lon: -92...(-30))
    default: return LH.box(lat: -50...0, lon: 110...180)
    }
}

private func apParts(_ c: AtlasCountry, window: CGRect, clip: CGRect? = nil) -> [APPart] {
    apSubpaths(c).filter { $0.boundingRect.intersects(window) && (clip == nil || $0.boundingRect.intersects(clip!)) }
        .map { APPart(path: $0, clip: clip) }
}
private func apBox(_ parts: [APPart]) -> CGRect {
    parts.reduce(CGRect.null) { acc, p in
        let b = p.clip.map { p.path.boundingRect.intersection($0) } ?? p.path.boundingRect
        return acc.union(b)
    }
}

private let apRussiaWest = CGRect(x: 400, y: 0, width: GeoAtlas.uralsX - 400, height: 900)
private let apRussiaEast = CGRect(x: GeoAtlas.uralsX, y: 0, width: 1000 - GeoAtlas.uralsX, height: 900)

/// A continent as one piece.
private func apContinent(_ cont: String) -> APPiece {
    let win = apWindow(cont)
    var parts: [APPart] = []
    for c in GeoAtlas.countries {
        if c.name == "Russia" {
            if cont == "Europe" { parts += apParts(c, window: win, clip: apRussiaWest) }
            if cont == "Asia" { parts += apParts(c, window: win, clip: apRussiaEast) }
        } else if c.continent == cont {
            parts += apParts(c, window: win)
        }
    }
    return APPiece(id: cont, name: cont, badge: LH.icon(cont), parts: parts, box: apBox(parts))
}

private let apRanks: [String: Int] = Dictionary(GeoShapes.all.map { ($0.name, $0.rank) }, uniquingKeysWith: { a, _ in a })

/// A country of a continent board as a piece (mainland + nearby islands only).
private func apCountry(_ c: AtlasCountry, _ cont: String) -> APPiece {
    let win = LH.region(cont).insetBy(dx: -20, dy: -20)
    let parts = apParts(c, window: win)
    return APPiece(id: c.name, name: c.name, badge: apFlag(c.name), parts: parts, box: apBox(parts))
}

private let apISO: [String: String] = {
    struct F: Decodable { let countries: [C]; struct C: Decodable { let name: String; let iso: String? } }
    guard let url = Bundle.main.url(forResource: "world-countries", withExtension: "json"),
          let data = try? Data(contentsOf: url), let f = try? JSONDecoder().decode(F.self, from: data) else { return [:] }
    return Dictionary(f.countries.compactMap { c in c.iso.map { (c.name, $0) } }, uniquingKeysWith: { a, _ in a })
}()
private func apFlag(_ name: String) -> String {
    guard let iso = apISO[name], iso.count == 2 else { return "📍" }
    return iso.uppercased().unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map(String.init).joined()
}

/// Boards of countries are drawn from these continents (Oceania is too small for a board).
private let apBoardContinents = ["Africa", "Asia", "Europe", "North America", "South America"]

@MainActor
private final class AgrippaModel: ArcadeModel {
    @Published var board: APBoard
    @Published var placed: Set<String> = []
    @Published var boardID = 0
    @Published var flash: (id: String, wrong: Bool, at: Date)?
    @Published var flyer: (piece: String, from: CGPoint, start: Date)?     // a wrong piece sliding home (map space)
    @Published var note: String?
    @Published var sealed = false
    private var lastTitle = ""

    init() {
        board = APBoard(title: "", region: LH.world, pieces: [], backdrop: [], continentBoard: true)
        super.init(key: GameID.agrippaMap.rawValue)
    }

    var holeAlpha: Double { ramp(1, 0, from: 3, to: 7) }
    var tolPt: CGFloat { CGFloat(ramp(64, 22, to: 9)) }
    var remaining: [APPiece] { board.pieces.filter { !placed.contains($0.id) && flyer?.piece != $0.id } }

    override func onBegin() { newBoard() }

    func newBoard() {
        var b = makeBoard()
        if b.title == lastTitle { b = makeBoard() }
        lastTitle = b.title
        board = b; placed = []; flash = nil; flyer = nil; note = nil; sealed = false
        boardID += 1
    }

    private func makeBoard() -> APBoard {
        let n = rampInt(2, 5, to: 7)
        let kind = tier([1, 2.5, 4.5, 6.5])
        if kind == 0 {
            let all = ["Africa", "Asia", "Europe", "North America", "South America", "Oceania"].map(apContinent)
            // Early on the big, easy shapes go missing first.
            let easy = ["Africa", "South America", "Oceania", "North America"]
            let order = d < 2 ? all.filter { easy.contains($0.id) }.shuffled() : all.shuffled()
            let pieces = Array(order.prefix(min(n + 1, 6)))
            let ids = Set(pieces.map(\.id))
            let back = all.filter { !ids.contains($0.id) }.flatMap(\.parts)
            return APBoard(title: "the World", region: LH.world.insetBy(dx: 0, dy: 40), pieces: pieces, backdrop: back, continentBoard: true)
        }
        let maxRank = [2, 3, 5][kind - 1]
        let minRank = [1, 3, 4][kind - 1]
        let options = apBoardContinents.filter { cont in
            GeoAtlas.countries.filter { $0.continent == cont && (apRanks[$0.name] ?? 9) >= minRank && (apRanks[$0.name] ?? 9) <= maxRank }.count >= 2
        }
        let cont = options.randomElement() ?? "Europe"
        let region = LH.region(cont)
        let usable = GeoAtlas.countries.filter { c in
            c.continent == cont && c.name != "Russia" && (apRanks[c.name] ?? 9) <= maxRank &&
            LH.mainBox(c).width >= 5 && LH.mainBox(c).height >= 4 && region.intersects(LH.mainBox(c))
        }
        // At least one piece of the newest kind, the rest from everything up to it.
        let fresh = usable.filter { (apRanks[$0.name] ?? 9) >= minRank }.shuffled()
        var chosen = Array(fresh.prefix(max(1, n / 2)))
        for c in usable.shuffled() where chosen.count < n && !chosen.contains(where: { $0.name == c.name }) { chosen.append(c) }
        let pieces = chosen.map { apCountry($0, cont) }
        let ids = Set(pieces.map(\.id))
        let win = region.insetBy(dx: -60, dy: -60)
        let back = GeoAtlas.countries.filter { !ids.contains($0.name) && $0.box.intersects(win) }
            .flatMap { apParts($0, window: win) }
        return APBoard(title: cont, region: region, pieces: pieces, backdrop: back, continentBoard: false)
    }

    /// A piece dropped with its centre at map point `p`; `tol` = snap distance in map units.
    func drop(_ id: String, at p: CGPoint, tol: CGFloat) {
        guard phase == .playing, let piece = board.pieces.first(where: { $0.id == id }), !placed.contains(id), flyer == nil else { return }
        let dist = hypot(p.x - piece.home.x, p.y - piece.home.y)
        if dist <= tol {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = placed.insert(id) }
            flash = (id, false, Date())
            note = "\(piece.badge) \(piece.name)!"
            Sfx.play(.thud)
            hit()
            checkDone()
        } else {
            // Where did it land? Name it, then slide the piece home.
            let near = board.pieces.first { !placed.contains($0.id) && $0.id != id && hypot(p.x - $0.home.x, p.y - $0.home.y) <= tol }
            note = near.map { "That's where \($0.name) goes!" } ?? "\(piece.name) goes here!"
            flyer = (id, p, Date())
            flash = (id, true, Date())
            Sfx.play(.whoosh)
            miss(reason: "The map got muddled!", delay: 1.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
                guard let self, self.phase == .playing else { return }
                self.flyer = nil
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = self.placed.insert(id) }
                Sfx.play(.thud)
                self.checkDone()
            }
        }
    }

    private func checkDone() {
        guard placed.count == board.pieces.count else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.phase == .playing else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { self.sealed = true }
            Sfx.play(.sparkle); Haptics.success()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { [weak self] in
            guard let self, self.phase == .playing, !self.dying else { return }
            self.newBoard()
        }
    }

    override func botAct(correct: Bool) {
        guard let p = remaining.first, flyer == nil else { return }
        if correct { drop(p.id, at: p.home, tol: 4) }
        else {
            let r = board.region
            let far = CGPoint(x: p.home.x > r.midX ? r.minX + r.width * 0.15 : r.maxX - r.width * 0.15,
                              y: p.home.y > r.midY ? r.minY + r.height * 0.15 : r.maxY - r.height * 0.15)
            drop(p.id, at: far, tol: 4)
        }
    }
}

// MARK: - Drawing

private func apFill(_ ctx: GraphicsContext, _ parts: [APPart], _ shading: GraphicsContext.Shading) {
    for p in parts {
        var c = ctx
        if let clip = p.clip { c.clip(to: Path(clip)) }
        c.fill(p.path, with: shading)
    }
}
private func apStroke(_ ctx: GraphicsContext, _ parts: [APPart], _ color: Color, _ style: StrokeStyle) {
    for p in parts {
        var c = ctx
        if let clip = p.clip { c.clip(to: Path(clip)) }
        c.stroke(p.path, with: .color(color), style: style)
    }
}

private func apPieceHex(_ piece: APPiece, _ board: APBoard) -> UInt {
    if board.continentBoard { return LH.hex(piece.id) }
    let palette: [UInt] = [0xe8973a, 0x63b96b, 0x4fa6cf, 0xa96fd6, 0xe0684f, 0xf5c542]
    let i = board.pieces.firstIndex { $0.id == piece.id } ?? 0
    return palette[i % palette.count]
}

/// One piece drawn to fit a box (tray slots, the dragged piece).
private struct APPieceShape: View {
    let piece: APPiece
    let hex: UInt
    var scale: CGFloat? = nil      // map → view scale; nil = fit the frame
    var body: some View {
        Canvas { ctx, size in
            let b = piece.box
            let k = scale ?? min(size.width / max(b.width, 1), size.height / max(b.height, 1)) * 0.92
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.scaleBy(x: k, y: k)
            ctx.translateBy(x: -b.midX, y: -b.midY)
            var shadow = ctx
            shadow.translateBy(x: 1.5 / k, y: 2.5 / k)
            apFill(shadow, piece.parts, .color(.black.opacity(0.35)))
            apFill(ctx, piece.parts, .color(Color(hex: hex)))
            apStroke(ctx, piece.parts, Color(hex: 0x4a2f12), StrokeStyle(lineWidth: 1.2 / k, lineJoin: .round))
        }
    }
}

// MARK: - View

struct AgrippaMapView: View {
    let onClose: () -> Void
    @StateObject private var m = AgrippaModel()
    @State private var dragging: String?
    @State private var dragAt: CGPoint = .zero          // finger, in the "ap" space
    @State private var boardFrame: CGRect = .zero

    var body: some View {
        ArcadeShell(model: m, spec: GameID.agrippaMap.spec ?? GameSpec(title: "Agrippa's Map", mechanic: "", premise: "", game: .agrippaMap),
                    accent: Lu.gold, onClose: onClose, backdrop: { APDesk() }) {
            GeometryReader { root in
                VStack(spacing: 8) {
                    Color.clear.frame(height: 58)
                    ribbon
                    GeometryReader { outer in
                        // The sheet takes the board's own shape (no acres of empty sea).
                        let r = m.board.region
                        let h = min(outer.size.height, max(220, outer.size.width * r.height / max(r.width, 1) * 1.04))
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            GeometryReader { g in
                                boardView(g.size)
                                    .onAppear { boardFrame = g.frame(in: .named("ap")) }
                                    .onChange(of: g.frame(in: .named("ap"))) { f in boardFrame = f }
                            }
                            .frame(height: h)
                            Spacer(minLength: 0)
                        }
                    }
                    tray.frame(height: 118)
                }
                .padding(.horizontal, 12).padding(.bottom, 6)
                .overlay { draggedPiece(root.size) }
            }
            .coordinateSpace(name: "ap")
        }
    }

    private var cam: LH.Camera { LH.Camera(m.board.region, boardFrame.size) }

    private var ribbon: some View {
        HStack(spacing: 10) {
            Text("🏛️").font(.system(size: 30))
            VStack(alignment: .leading, spacing: 0) {
                Text("AGRIPPA'S MAP OF").font(luFont(11, .heavy)).tracking(1.5).foregroundStyle(Color(hex: lhInkSoft))
                Text(m.board.title.isEmpty ? " " : (m.board.continentBoard ? "The World" : m.board.title))
                    .font(luSerif(26, .black)).foregroundStyle(Color(hex: lhInk)).lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            Text(m.note ?? "Drag each piece home")
                .font(luFont(13, .heavy)).foregroundStyle(Color(hex: lhInk))
                .multilineTextAlignment(.trailing).lineLimit(2).minimumScaleFactor(0.6)
                .frame(maxWidth: 150, alignment: .trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(LHParchment(radius: 14))
    }

    private func boardView(_ size: CGSize) -> some View {
        TimelineView(.animation(paused: m.phase != .playing)) { tl in
            let now = tl.date
            ZStack {
                Canvas { ctx, sz in drawBoard(&ctx, LH.Camera(m.board.region, sz), now) }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x6b4a1f), lineWidth: 4))
                    .shadow(color: .black.opacity(0.45), radius: 10, y: 6)
                if m.sealed {
                    ZStack {
                        Circle().fill(RadialGradient(colors: [Color(hex: 0xd8473a), Color(hex: 0x8e1f17)], center: .center, startRadius: 2, endRadius: 46))
                            .frame(width: 92, height: 92)
                        Circle().stroke(Color(hex: 0x6e140e), lineWidth: 3).frame(width: 70, height: 70)
                        Text("SPQR").font(luSerif(18, .black)).foregroundStyle(Color(hex: 0xffd9c9))
                    }
                    .rotationEffect(.degrees(-12))
                    .position(x: size.width - 64, y: size.height - 64)
                    .transition(.scale(scale: 2.4).combined(with: .opacity))
                }
            }
        }
    }

    private func drawBoard(_ ctx: inout GraphicsContext, _ cam: LH.Camera, _ now: Date) {
        let full = CGRect(origin: .zero, size: cam.size)
        // Sea: a sepia-blue wash on parchment.
        ctx.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0xb9d3cf), Color(hex: 0x9fc1c0)]),
                                                   startPoint: .zero, endPoint: CGPoint(x: cam.size.width, y: cam.size.height)))
        var c = ctx
        cam.apply(&c)
        let line = 0.8 / cam.scale
        let b = m.board
        LH.drawGrid(c, step: 30, alpha: 0.18, line: line, color: Color(hex: 0x3b5a66))
        // Land already on the map.
        apFill(c, b.backdrop, .color(Color(hex: 0xe8d7ae)))
        apStroke(c, b.backdrop, Color(hex: 0x7a5a36).opacity(0.6), StrokeStyle(lineWidth: line, lineJoin: .round))
        if b.continentBoard {
            c.fill(LH.antarctica, with: .color(Color(hex: 0xeef4f2)))
        }
        // Holes and placed pieces.
        let holeA = m.holeAlpha
        let pulse = 0.5 + 0.5 * sin(now.timeIntervalSinceReferenceDate * 6)
        for p in b.pieces {
            let isPlaced = m.placed.contains(p.id)
            if isPlaced {
                apFill(c, p.parts, .color(Color(hex: apPieceHex(p, b))))
                apStroke(c, p.parts, Color(hex: 0x4a2f12), StrokeStyle(lineWidth: line * 1.3, lineJoin: .round))
            } else {
                // Unplaced: plain parchment; at low d a dark cut-out with a dashed edge.
                apFill(c, p.parts, .color(Color(hex: 0xe8d7ae)))
                apFill(c, p.parts, .color(Color(hex: 0x5b4127).opacity(0.55 * holeA)))
                apStroke(c, p.parts, Color(hex: 0x3b2410).opacity(holeA), StrokeStyle(lineWidth: line * 1.8, dash: [4 / cam.scale, 3 / cam.scale]))
            }
            if let f = m.flash, f.id == p.id {
                let age = now.timeIntervalSince(f.at)
                if age < (f.wrong ? 1.6 : 0.6) {
                    let a = f.wrong ? (0.4 + 0.5 * pulse) : (1 - age / 0.6)
                    apFill(c, p.parts, .color(Color(hex: f.wrong ? Lu.mint : 0xffffff).opacity(a * 0.75)))
                    apStroke(c, p.parts, Color(hex: f.wrong ? 0x2e7d32 : 0xfff3c4).opacity(a), StrokeStyle(lineWidth: line * 3))
                }
            }
        }
        // A wrong piece sliding to its home.
        if let fl = m.flyer, let p = b.pieces.first(where: { $0.id == fl.piece }) {
            let t = LH.smooth(now.timeIntervalSince(fl.start) / 0.8)
            let dx = (fl.from.x - p.home.x) * (1 - t), dy = (fl.from.y - p.home.y) * (1 - t)
            var mc = c
            mc.translateBy(x: dx, y: dy)
            apFill(mc, p.parts, .color(Color(hex: apPieceHex(p, b))))
            apStroke(mc, p.parts, Color(hex: Lu.coral), StrokeStyle(lineWidth: line * 2.5))
        }
        // Compass rose in the corner (decoration).
        let rc = CGPoint(x: 34, y: cam.size.height - 34)
        for k in 0..<4 {
            let a = Double(k) * .pi / 2
            var p = Path()
            p.move(to: CGPoint(x: rc.x + CGFloat(sin(a)) * 24, y: rc.y - CGFloat(cos(a)) * 24))
            p.addLine(to: CGPoint(x: rc.x + CGFloat(sin(a + .pi / 2)) * 5, y: rc.y - CGFloat(cos(a + .pi / 2)) * 5))
            p.addLine(to: CGPoint(x: rc.x + CGFloat(sin(a - .pi / 2)) * 5, y: rc.y - CGFloat(cos(a - .pi / 2)) * 5))
            p.closeSubpath()
            ctx.fill(p, with: .color(Color(hex: k == 0 ? 0xa8321f : 0x5b4127).opacity(0.75)))
        }
        ctx.draw(ctx.resolve(Text("N").font(luFont(11, .black)).foregroundColor(Color(hex: 0xa8321f))), at: CGPoint(x: rc.x, y: rc.y - 32))
    }

    // MARK: Tray
    private var tray: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(hex: 0x5a3a1c), Color(hex: 0x3f2712)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x2a190b), lineWidth: 2))
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            HStack(spacing: 6) {
                ForEach(m.board.pieces) { p in slot(p) }
            }
            .padding(.horizontal, 8)
            .id(m.boardID)
        }
    }

    private func slot(_ p: APPiece) -> some View {
        let gone = m.placed.contains(p.id) || dragging == p.id || m.flyer?.piece == p.id
        return VStack(spacing: 2) {
            APPieceShape(piece: p, hex: apPieceHex(p, m.board))
                .frame(height: 66)
            Text("\(p.badge) \(p.name)").font(luFont(11, .heavy)).foregroundStyle(Color(hex: 0xf6ecd4))
                .lineLimit(2).minimumScaleFactor(0.55).multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .frame(maxWidth: 76)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.18)))
        .opacity(gone ? 0.15 : 1)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .named("ap"))
            .onChanged { g in
                guard !gone || dragging == p.id, m.phase == .playing else { return }
                if dragging == nil { dragging = p.id; Sfx.play(.tick); Haptics.light() }
                dragAt = g.location
            }
            .onEnded { g in
                guard dragging == p.id else { return }
                dragging = nil
                let center = CGPoint(x: g.location.x - boardFrame.minX, y: g.location.y - 46 - boardFrame.minY)
                let camNow = cam
                m.drop(p.id, at: camNow.map(center), tol: m.tolPt / camNow.scale)
            })
        .allowsHitTesting(!m.placed.contains(p.id) && m.flyer == nil)
    }

    /// The piece under the finger: true map scale (so it matches its hole), lifted above the finger.
    @ViewBuilder private func draggedPiece(_ size: CGSize) -> some View {
        if let id = dragging, let p = m.board.pieces.first(where: { $0.id == id }) {
            let k = cam.scale
            let w = max(p.box.width * k, 10), h = max(p.box.height * k, 10)
            ZStack {
                if max(w, h) < 40 { Circle().stroke(Color(hex: Lu.gold), lineWidth: 3).frame(width: 46, height: 46) }
                APPieceShape(piece: p, hex: apPieceHex(p, m.board), scale: k)
                    .frame(width: w + 8, height: h + 8)
            }
            .position(x: dragAt.x, y: dragAt.y - 46)
            .allowsHitTesting(false)
        }
    }
}

/// The mapmaker's desk: dark walnut with grain, an inkwell and a quill.
private struct APDesk: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                LinearGradient(colors: [Color(hex: 0x6b4423), Color(hex: 0x4a2c15)], startPoint: .top, endPoint: .bottom)
                Canvas { ctx, size in
                    for i in 0..<34 {
                        let y = CGFloat(i) / 34 * size.height
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: y))
                        var x: CGFloat = 0
                        while x < size.width {
                            x += 40
                            p.addLine(to: CGPoint(x: x, y: y + CGFloat(sin(Double(x) / 60 + Double(i))) * 3))
                        }
                        ctx.stroke(p, with: .color(.black.opacity(i % 3 == 0 ? 0.16 : 0.08)), lineWidth: i % 3 == 0 ? 2 : 1)
                    }
                }
                // Inkwell + quill peeking from the top corner.
                ZStack {
                    Ellipse().fill(Color(hex: 0x1d1d2b)).frame(width: 40, height: 16).offset(y: 14)
                    RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x23233a)).frame(width: 36, height: 28)
                    Capsule().fill(Color(hex: 0xf3ead8)).frame(width: 6, height: 70).rotationEffect(.degrees(28)).offset(x: 14, y: -30)
                    Ellipse().fill(Color(hex: 0xf8f1e2)).frame(width: 14, height: 40).rotationEffect(.degrees(28)).offset(x: 24, y: -50)
                }
                .position(x: g.size.width - 40, y: g.size.height - 30)
                .opacity(0.9)
            }
        }
    }
}
