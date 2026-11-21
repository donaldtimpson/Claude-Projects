import SwiftUI

// MARK: - The estate — the villa grows a wing for every world
//
// The garden (VillaView's original scene) is where a villa starts. Beside it stand eight WINGS, one
// per world of the arcade: the Library for Language Arts, the Odeum for Music, and so on. A wing is
// BUILT with gold aurei, and only once the child has won a laurel in that world — so the rooms of
// the house are a picture of what the child has learned. A built wing is a room of its own (a fixed
// 400 × 450 design canvas like the garden's, see `WingRoom`) furnished with silver denarii, item by
// item, each with its own spot and a one-line fact.
//
// Why: the garden alone held 1,275 denarii of things and 22 aurei — about a week of play — while
// laurels can earn 240 aurei. Wings add a themed catalog per world, give gold a job (building), and
// tie every room to a subject. Each wing lives in its own file (Wing<Name>.swift): its items, its
// room drawing and its card thumbnails. The Prizes board (VillaPrizes.swift) takes what gold is left.

struct VillaWing: Identifiable, Hashable {
    let id: String          // "library" — items in it carry `place == id`
    let name: String        // "The Library"
    let latin: String       // "Bibliotheca"
    let short: String       // "Library" — the place switcher's chip
    let subject: String     // the world's subject (LudusWorld.subject)
    let icon: String        // SF Symbol for the place switcher
    let blurb: String       // what the room is, in one line
    var ownedID: String { "wing_" + id }
}

let villaWings: [VillaWing] = [
    .init(id: "library", name: "The Library", latin: "Bibliotheca", short: "Library", subject: "Language Arts", icon: "books.vertical.fill",
          blurb: "Scrolls, a writing desk and the great poets."),
    .init(id: "counting", name: "The Counting Room", latin: "Tabula", short: "Counting", subject: "Math", icon: "number",
          blurb: "Where Romans counted, weighed and measured."),
    .init(id: "odeum", name: "The Music Room", latin: "Odeum", short: "Music", subject: "Music", icon: "music.note",
          blurb: "Lyres, pipes and drums for the household band."),
    .init(id: "harbor", name: "The Harbor", latin: "Portus", short: "Harbor", subject: "Geography", icon: "sailboat.fill",
          blurb: "Your own dock on the sea — ships, maps and a lighthouse."),
    .init(id: "workshop", name: "The Workshop", latin: "Officina", short: "Workshop", subject: "Science", icon: "hammer.fill",
          blurb: "Fire, water and clever machines."),
    .init(id: "tablinum", name: "The Coin Cabinet", latin: "Tablinum", short: "Coins", subject: "History", icon: "seal.fill",
          blurb: "A cabinet of real Roman coins, emperor by emperor."),
    .init(id: "kitchen", name: "The Kitchen", latin: "Culina", short: "Kitchen", subject: "Money & Life Skills", icon: "frying.pan.fill",
          blurb: "Bread, olive oil and a busy market table."),
    .init(id: "palaestra", name: "The Exercise Yard", latin: "Palaestra", short: "Yard", subject: "Logic & Puzzles", icon: "figure.run",
          blurb: "Puzzles, board games and a racehorse."),
]

/// Where the Villa screen is looking.
enum VillaPlace: Hashable {
    case garden, wing(String), prizes
    var wing: VillaWing? { if case .wing(let id) = self { return villaWings.first { $0.id == id } }; return nil }
}

extension LudusEconomy {
    static func built(_ wing: VillaWing) -> Bool { owns(wing.ownedID) }
    static var wingsBuilt: Int { villaWings.filter(built).count }

    /// Gold to build the next wing: 3 for the first, one more for each after (3 … 10, 52 in all), so any
    /// order works and the last rooms are a real goal.
    static var nextWingCost: Int { 3 + wingsBuilt }

    /// A wing opens once the child holds a laurel (has won a game) in its world.
    static func wingUnlocked(_ wing: VillaWing) -> Bool {
        ludusWorlds.first { $0.subject == wing.subject }?.games.contains { $0.won } ?? false
    }
    static func worldName(_ wing: VillaWing) -> String {
        ludusWorlds.first { $0.subject == wing.subject }?.name ?? wing.subject
    }

    /// Builds a wing if it is unlocked and affordable.
    @discardableResult
    static func build(_ wing: VillaWing) -> Bool {
        guard !built(wing), wingUnlocked(wing), aurei >= nextWingCost else { return false }
        spendAurei(nextWingCost)
        var o = owned; o.insert(wing.ownedID)
        LudusStore.defaults.set(Array(o), forKey: ownedKey)
        return true
    }

    /// The thing the child is saving up for (held on a shop card), or nil.
    static var goal: String? {
        get { LudusStore.defaults.string(forKey: "ludus_villa_goal") }
        set { LudusStore.defaults.set(newValue, forKey: "ludus_villa_goal") }
    }
    /// "12 more denarii for the Fountain" — nil when there's no goal, it's bought, or it's affordable.
    static var goalLine: String? {
        guard let id = goal, !owns(id), let item = villaCatalog.first(where: { $0.id == id }) else { return nil }
        let have = item.price.gold ? aurei : LudusStore.denarii
        let need = item.price.amount - have
        if need <= 0 { return "You can buy the \(item.name) now!" }
        let coin = item.price.gold ? "gold aure\(need == 1 ? "us" : "i")" : "denari\(need == 1 ? "us" : "i")"
        return "\(need) more \(coin) for the \(item.name)"
    }

    static func spendAurei(_ n: Int) {
        LudusStore.defaults.set(aureiSpent + n, forKey: spentAureiKey)
    }
}

// MARK: - The room every wing is drawn in
//
// A wing draws its furniture on the fixed design canvas (400 × 450, same as the garden), scaled to fit
// and centered; spare room on a wide or tall frame becomes more wall above and more floor below, never
// a stretched room. `WingRoom` paints the shared fresco wall (a dado, red panels, a frieze) and a floor,
// then lays the wing's content over the canvas. Content places things with `WingSpot` (feet at canvas
// fractions), so a wing file only says WHAT stands WHERE.

struct WingRoom<Content: View>: View {
    var wall: Color = Fr.frame
    var panel: Color = Color(hex: 0xa8432f)
    var floor: Color = Color(hex: 0xc9a46b)
    var floorLine: CGFloat = 0.62          // where the wall meets the floor (canvas fraction)
    var outdoor = false                    // harbor/yard: sky instead of wall
    @ViewBuilder let content: (_ w: CGFloat, _ h: CGFloat, _ t: Double) -> Content

    var body: some View {
        GeometryReader { g in
            let fw = g.size.width, fh = g.size.height
            let c = VillaPlacement.canvas
            let k = max(0.01, min(fw / c.width, fh / c.height))
            let w = c.width * k, h = c.height * k
            let ox = (fw - w) / 2, oy = (fh - h) * 0.55
            let fy = oy + h * floorLine
            TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .topLeading) {
                    if outdoor {
                        LinearGradient(colors: [Color(hex: 0x9cc3cf), Color(hex: 0xf3dfb0)], startPoint: .top, endPoint: .bottom)
                            .frame(width: fw, height: max(1, fy))
                    } else {
                        FrescoWall(wall: wall, panel: panel, w: w, ox: ox, height: max(1, fy))
                    }
                    Rectangle().fill(LinearGradient(colors: [floor, floor.opacity(0.82)], startPoint: .top, endPoint: .bottom))
                        .frame(width: fw, height: max(0, fh - fy)).offset(y: fy)
                    if !outdoor {
                        Rectangle().fill(Color.black.opacity(0.18)).frame(width: fw, height: 3).offset(y: fy)
                    }
                    content(w, h, t)
                        .frame(width: w, height: h)
                        .offset(x: ox, y: oy)
                }
                .frame(width: fw, height: fh, alignment: .topLeading)
                .clipped()
            }
        }
    }
}

/// The painted wall of a room: Pompeian red panels framed in ochre over a dark dado, under a frieze.
private struct FrescoWall: View {
    let wall: Color, panel: Color
    let w: CGFloat, ox: CGFloat, height: CGFloat
    var body: some View {
        GeometryReader { g in
            let fw = g.size.width
            let pw = w * 0.22, gap = w * 0.04
            let n = Int((fw / (pw + gap)).rounded(.up)) + 2
            ZStack(alignment: .topLeading) {
                wall
                // panels, lined up with the canvas so they sit the same on every screen
                ForEach(-n / 2 ..< n, id: \.self) { i in
                    let x = ox + w * 0.07 + CGFloat(i) * (pw + gap)
                    RoundedRectangle(cornerRadius: 2).fill(panel)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Fr.ochre.opacity(0.9), lineWidth: 2))
                        .frame(width: pw, height: max(1, height * 0.56))
                        .offset(x: x, y: height * 0.16)
                }
                // frieze along the top and a dark dado along the bottom
                Rectangle().fill(Fr.ochre).frame(height: max(1, height * 0.06))
                Rectangle().fill(Color.black.opacity(0.25)).frame(height: 2).offset(y: height * 0.06)
                Rectangle().fill(Color(hex: 0x3b2418)).frame(height: max(1, height * 0.18)).offset(y: height * 0.82)
            }
            .frame(width: fw, height: height)
        }
        .frame(height: height)
    }
}

/// Places a thing by its FEET at canvas fractions (x, y) with a box `size` canvas-widths wide.
struct WingSpot<Thing: View>: View {
    let x: CGFloat, y: CGFloat, size: CGFloat
    let w: CGFloat, h: CGFloat
    var lift: CGFloat = 1        // the bounce when bought or tapped
    @ViewBuilder let thing: Thing
    var body: some View {
        thing
            .frame(width: w * size, height: w * size, alignment: .bottom)
            .scaleEffect(lift, anchor: .bottom)
            .position(x: x * w, y: y * h - w * size / 2)
    }
}

/// What a wing's room needs from the Villa screen.
struct WingState {
    let owned: Set<String>
    let justBought: String?
    let poke: String?
    let onTap: (String) -> Void
    func has(_ id: String) -> Bool { owned.contains(id) }
    func lift(_ id: String) -> CGFloat { justBought == id || poke == id ? 1.14 : 1 }
}

// MARK: - A wing not built yet

/// The empty plot with a builder's sign: shown in the scene frame until the wing is built.
struct WingSite: View {
    let wing: VillaWing
    var body: some View {
        WingRoom(floor: Color(hex: 0x9a8a62), outdoor: true) { w, h, _ in
            ZStack(alignment: .topLeading) {
                // scaffold
                ForEach(0..<4, id: \.self) { i in
                    Rectangle().fill(Color(hex: 0x8a6a42)).frame(width: w * 0.018, height: h * 0.42)
                        .position(x: w * (0.22 + CGFloat(i) * 0.19), y: h * 0.41)
                }
                ForEach(0..<3, id: \.self) { j in
                    Rectangle().fill(Color(hex: 0x9c7a4c)).frame(width: w * 0.62, height: h * 0.014)
                        .position(x: w * 0.5, y: h * (0.26 + CGFloat(j) * 0.13))
                }
                // low walls started
                Rectangle().fill(Fr.stucco).frame(width: w * 0.66, height: h * 0.08)
                    .overlay(Rectangle().stroke(Fr.stuccoShade, lineWidth: 1))
                    .position(x: w * 0.5, y: h * 0.58)
                // a pile of bricks and a builder's sign
                Text("🧱").font(.system(size: w * 0.08)).position(x: w * 0.2, y: h * 0.78)
                Text("🪵").font(.system(size: w * 0.08)).position(x: w * 0.82, y: h * 0.8)
                VStack(spacing: 2) {
                    Image(systemName: wing.icon).font(.system(size: w * 0.06, weight: .bold)).foregroundStyle(Fr.frame)
                    Text(wing.latin.uppercased()).font(luCinzel(w * 0.05, bold: true)).foregroundStyle(Fr.ink)
                }
                .padding(.horizontal, w * 0.04).padding(.vertical, w * 0.02)
                .background(RoundedRectangle(cornerRadius: 4).fill(Fr.parchment)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Fr.trunk, lineWidth: 2)))
                .position(x: w * 0.5, y: h * 0.76)
            }
        }
    }
}

// MARK: - Registry: each wing's room and thumbnails (see the Wing<Name>.swift files)

let wingCatalog: [VillaItem] = libraryItems + countingItems + odeumItems + harborItems
    + workshopItems + tablinumItems + kitchenItems + palaestraItems

@ViewBuilder
func wingRoom(_ wing: VillaWing, _ s: WingState) -> some View {
    switch wing.id {
    case "library": LibraryRoom(s: s)
    case "counting": CountingRoom(s: s)
    case "odeum": OdeumRoom(s: s)
    case "harbor": HarborRoom(s: s)
    case "workshop": WorkshopRoom(s: s)
    case "tablinum": TablinumRoom(s: s)
    case "kitchen": KitchenRoom(s: s)
    case "palaestra": PalaestraRoom(s: s)
    default: EmptyView()
    }
}

/// The card picture for a wing item (`nil` = not a wing item).
func wingThumb(_ item: VillaItem) -> AnyView? {
    switch item.place {
    case "library": return AnyView(LibraryThumb(id: item.id))
    case "counting": return AnyView(CountingThumb(id: item.id))
    case "odeum": return AnyView(OdeumThumb(id: item.id))
    case "harbor": return AnyView(HarborThumb(id: item.id))
    case "workshop": return AnyView(WorkshopThumb(id: item.id))
    case "tablinum": return AnyView(TablinumThumb(id: item.id))
    case "kitchen": return AnyView(KitchenThumb(id: item.id))
    case "palaestra": return AnyView(PalaestraThumb(id: item.id))
    default: return nil
    }
}
