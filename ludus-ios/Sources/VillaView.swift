import SwiftUI

// MARK: - The Villa — where the arcade's coins go
//
// The child's own Roman villa, painted like a Pompeian wall fresco (flat ochres, terracotta and sage
// inside a red-and-gold fresco frame — deliberately a different register from the painted map, the
// way a fresco differs from a landscape). It starts bare: a plain house on a lawn. Denarii buy the
// garden, water, statues and pets; aurei (from laurels) buy the grand works. Everything bought
// appears in the scene at its own place, and the pets wander the lawn.
//
// Opened from the home bar's coin corners.

enum VillaPrice: Hashable {
    case denarii(Int), aurei(Int)
    var amount: Int { switch self { case .denarii(let n), .aurei(let n): return n } }
    var gold: Bool { if case .aurei = self { return true }; return false }
}

enum VillaCategory: String, CaseIterable, Identifiable {
    case garden = "Garden", water = "Water", statues = "Statues", pets = "Pets", grand = "Grand"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .garden: return "leaf.fill"
        case .water: return "drop.fill"
        case .statues: return "building.columns.fill"
        case .pets: return "pawprint.fill"
        case .grand: return "crown.fill"
        }
    }
}

struct VillaItem: Identifiable, Hashable {
    let id: String
    let name: String
    let category: VillaCategory
    let price: VillaPrice
    let blurb: String
}

let villaCatalog: [VillaItem] = [
    .init(id: "roses", name: "Rose Beds", category: .garden, price: .denarii(25), blurb: "Romans loved roses."),
    .init(id: "cypress", name: "Cypress Trees", category: .garden, price: .denarii(30), blurb: "Tall and pointy, like green flames."),
    .init(id: "banners", name: "Red Banners", category: .garden, price: .denarii(40), blurb: "Hang them between the columns."),
    .init(id: "olive", name: "Olive Tree", category: .garden, price: .denarii(45), blurb: "Olives for oil, lamps and dinner."),
    .init(id: "lemon", name: "Lemon Tree", category: .garden, price: .denarii(50), blurb: "Sunny fruit for your garden."),
    .init(id: "arbor", name: "Grape Arbor", category: .garden, price: .denarii(70), blurb: "A shady walk under the vines."),
    .init(id: "birdbath", name: "Bird Bath", category: .water, price: .denarii(35), blurb: "Sparrows come to splash."),
    .init(id: "pond", name: "Fish Pond", category: .water, price: .denarii(90), blurb: "Goldfish swim in circles."),
    .init(id: "fountain", name: "Fountain", category: .water, price: .denarii(120), blurb: "Water from the aqueduct!"),
    .init(id: "bust", name: "Marble Bust", category: .statues, price: .denarii(60), blurb: "A stone head of a famous Roman."),
    .init(id: "sundial", name: "Sundial", category: .statues, price: .denarii(80), blurb: "Romans told time with shadows."),
    .init(id: "minerva", name: "Minerva", category: .statues, price: .denarii(150), blurb: "Goddess of wisdom — and of you!"),
    .init(id: "tortoise", name: "Tortoise", category: .pets, price: .denarii(40), blurb: "Slow, steady, and very old."),
    .init(id: "rooster", name: "Rooster", category: .pets, price: .denarii(40), blurb: "Your morning alarm clock."),
    .init(id: "rabbit", name: "Rabbit", category: .pets, price: .denarii(45), blurb: "Loves the rose beds. Uh oh."),
    .init(id: "goat", name: "Goat", category: .pets, price: .denarii(55), blurb: "Eats everything. Even sandals."),
    .init(id: "cat", name: "Cat", category: .pets, price: .denarii(60), blurb: "Keeps the mice away."),
    .init(id: "dog", name: "Dog", category: .pets, price: .denarii(60), blurb: "Cave canem — beware of the dog!"),
    .init(id: "owl", name: "Owl", category: .pets, price: .denarii(70), blurb: "Minerva's wise bird. Sits on the roof."),
    .init(id: "peacock", name: "Peacock", category: .pets, price: .denarii(110), blurb: "Rich Romans kept peacocks."),
    .init(id: "eagle", name: "Golden Eagle", category: .grand, price: .aurei(3), blurb: "The eagle of the legions, on your roof."),
    .init(id: "chariot", name: "Chariot", category: .grand, price: .aurei(5), blurb: "Race it at the Circus Maximus!"),
    .init(id: "goldroof", name: "Golden Roof", category: .grand, price: .aurei(6), blurb: "Gild every tile. Very fancy."),
    .init(id: "elephant", name: "Elephant", category: .grand, price: .aurei(8), blurb: "Hannibal brought elephants over the Alps."),
]

// MARK: - Fresco palette

private enum Fr {
    static let frame = Color(hex: 0x8f2a1e)       // Pompeian red
    static let frameDeep = Color(hex: 0x6b1d14)
    static let gold = Color(hex: 0xd9a944)
    static let skyTop = Color(hex: 0x9cc3cf)
    static let skyLow = Color(hex: 0xf3dfb0)
    static let hillBack = Color(hex: 0x9fae7c)
    static let hillFront = Color(hex: 0x7f9560)
    static let lawn = Color(hex: 0x86a35a)
    static let lawnDeep = Color(hex: 0x5f7d3d)
    static let stucco = Color(hex: 0xf1e2c0)
    static let stuccoShade = Color(hex: 0xd9c49a)
    static let ochre = Color(hex: 0xc98a3c)
    static let tile = Color(hex: 0xb5552f)
    static let tileDeep = Color(hex: 0x8a3b1f)
    static let marble = Color(hex: 0xf7f2e6)
    static let marbleShade = Color(hex: 0xc9c1ae)
    static let path = Color(hex: 0xd8c39a)
    static let water = Color(hex: 0x5fa6c4)
    static let leaf = Color(hex: 0x4f7a3a)
    static let leafDark = Color(hex: 0x355a29)
    static let trunk = Color(hex: 0x6e4a2c)
    static let parchment = Color(hex: 0xf4e7c9)
    static let ink = Color(hex: 0x3a2412)
}

// MARK: - The screen

struct VillaView: View {
    let onClose: () -> Void

    @State private var tab: VillaCategory = .garden
    @State private var refresh = 0                 // bumps after a purchase (UserDefaults isn't observed)
    @State private var justBought: String?
    @State private var poke: String?               // an owned item tapped → it bounces in the scene
    @State private var shake: String?
    @State private var note: String?

    private var owned: Set<String> { _ = refresh; return LudusEconomy.owned }
    private var denarii: Int { _ = refresh; return LudusStore.denarii }
    private var aurei: Int { _ = refresh; return LudusEconomy.aurei }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let sceneH = min(geo.size.height * 0.56, w * 1.12)
            ZStack(alignment: .top) {
                Fr.frameDeep.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    FrescoFrame {
                        VillaScene(owned: owned, justBought: justBought, poke: poke)
                    }
                    .frame(height: sceneH)
                    .padding(.horizontal, 10)
                    shop
                }
            }
        }
        .statusBarHidden(true)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Fr.gold)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Fr.frame).overlay(Circle().stroke(Fr.gold, lineWidth: 1.5)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to the map")
            VStack(alignment: .leading, spacing: 0) {
                Text("VILLA").font(luCinzel(24)).foregroundStyle(Fr.parchment).tracking(2)
                Text(ludusRank() + "'s house").font(luGaramond(13, semibold: true)).foregroundStyle(Fr.gold)
            }
            Spacer()
            purse(img: "CoinSilver", value: denarii)
            purse(img: "CoinGold", value: aurei)
        }
        .padding(.horizontal, 14).padding(.top, 8).padding(.bottom, 8)
    }

    private func purse(img: String, value: Int) -> some View {
        HStack(spacing: 5) {
            Image(img).resizable().frame(width: 24, height: 24)
            Text("\(value)").font(luCinzel(17)).monospacedDigit().foregroundStyle(Fr.parchment)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(Fr.frame).overlay(Capsule().stroke(Fr.gold.opacity(0.7), lineWidth: 1)))
    }

    // MARK: Shop drawer

    private var shop: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(VillaCategory.allCases) { c in
                    Button {
                        Sfx.play(.tick); withAnimation(.easeOut(duration: 0.18)) { tab = c }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: c.icon).font(.system(size: 16, weight: .bold))
                            Text(c.rawValue.uppercased()).font(luCinzel(9.5, bold: true)).tracking(0.5)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(tab == c ? Fr.parchment : Fr.ink.opacity(0.7))
                        .frame(maxWidth: .infinity).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(tab == c ? Fr.frame : Fr.parchment.opacity(0.0)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 13).fill(Color(hex: 0xe6d3a8)))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(villaCatalog.filter { $0.category == tab }) { item in
                        card(item)
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 4)
            }

            Text(note ?? hint)
                .font(luGaramond(14, semibold: true)).foregroundStyle(Fr.ink.opacity(0.75))
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                .animation(.easeOut(duration: 0.2), value: note)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.top, 12)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                .fill(LinearGradient(colors: [Fr.parchment, Color(hex: 0xe9d6ad)], startPoint: .top, endPoint: .bottom))
                .overlay(UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                    .stroke(Fr.gold, lineWidth: 1.5))
                .ignoresSafeArea(edges: .bottom)
        )
        .padding(.top, 12)
    }

    private var hint: String {
        tab == .grand ? "Grand works cost gold aurei. Win laurels in the games to earn them!"
                      : "Every right answer in a game earns a silver denarius."
    }

    private func card(_ item: VillaItem) -> some View {
        let has = owned.contains(item.id)
        let afford = LudusEconomy.canAfford(item)
        return Button { tap(item) } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Fr.skyLow, Fr.lawn.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                    VillaThumb(id: item.id).padding(6)
                }
                .frame(width: 96, height: 84)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Fr.gold.opacity(0.8), lineWidth: 1))
                Text(item.name).font(luCinzel(12, bold: true)).foregroundStyle(Fr.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                if has {
                    Label("Yours", systemImage: "checkmark.seal.fill")
                        .font(luCinzel(11, bold: true)).foregroundStyle(Fr.leafDark)
                        .frame(height: 26)
                } else {
                    HStack(spacing: 4) {
                        Image(item.price.gold ? "CoinGold" : "CoinSilver").resizable().frame(width: 18, height: 18)
                        Text("\(item.price.amount)").font(luCinzel(14)).monospacedDigit()
                    }
                    .foregroundStyle(afford ? Fr.parchment : Fr.ink.opacity(0.45))
                    .frame(maxWidth: .infinity).frame(height: 26)
                    .background(Capsule().fill(afford ? Fr.frame : Color(hex: 0xd6c39b)))
                }
            }
            .frame(width: 108)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Fr.gold.opacity(0.5), lineWidth: 1)))
            .offset(x: shake == item.id ? -6 : 0)
        }
        .buttonStyle(.plain)
    }

    private func tap(_ item: VillaItem) {
        if owned.contains(item.id) {
            Sfx.play(.tick)
            poke = item.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { if poke == item.id { poke = nil } }
            note = item.blurb
            return
        }
        if LudusEconomy.buy(item) {
            Sfx.play(.coin); Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { Sfx.play(.sparkle) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                refresh += 1; justBought = item.id
            }
            note = "\(item.name)! " + item.blurb
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { if justBought == item.id { justBought = nil } }
        } else {
            Sfx.play(.wrong); Haptics.error()
            let need = item.price.amount - (item.price.gold ? aurei : denarii)
            note = item.price.gold
                ? "You need \(need) more gold aure\(need == 1 ? "us" : "i"). Win laurels to earn them!"
                : "You need \(need) more silver denari\(need == 1 ? "us" : "i"). Go play a game!"
            withAnimation(.linear(duration: 0.05).repeatCount(5, autoreverses: true)) { shake = item.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = nil }
        }
    }
}

// MARK: - The fresco frame

private struct FrescoFrame<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(7)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(Fr.frame)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Fr.gold, lineWidth: 1.5).padding(3))
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            )
    }
}

// MARK: - The scene

private struct VillaScene: View {
    let owned: Set<String>
    let justBought: String?
    let poke: String?

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .topLeading) {
                    backdrop(w: w, h: h, t: t)
                    house(w: w, h: h)
                    lawn(w: w, h: h)
                    ForEach(placed, id: \.id) { p in
                        if owned.contains(p.id) {
                            prop(p.id, w: w, t: t)
                                .frame(width: p.size * w, height: p.size * w)
                                .scaleEffect(scale(for: p.id), anchor: .bottom)
                                .position(x: p.x * w, y: p.y * h - p.size * w / 2)
                                .zIndex(p.y)
                        }
                    }
                    pets(w: w, h: h, t: t)
                    if let j = justBought, let p = placed.first(where: { $0.id == j }) ?? petSpot(j, w: w, h: h, t: t) {
                        SparkleBurst(t: t).frame(width: 120, height: 120)
                            .position(x: p.x * w, y: p.y * h - p.size * w / 2).allowsHitTesting(false)
                            .zIndex(100)
                    }
                }
            }
        }
    }

    private func scale(for id: String) -> CGFloat {
        if justBought == id || poke == id { return 1.12 }
        return 1
    }

    /// Where each non-pet item stands: center x, FOOT y (fractions of the scene), and its box size (fraction of width).
    struct Spot { let id: String; let x: CGFloat; let y: CGFloat; let size: CGFloat }
    private var placed: [Spot] { [
        .init(id: "cypress", x: 0.06, y: 0.60, size: 0.30),
        .init(id: "cypress2", x: 0.94, y: 0.60, size: 0.30),
        .init(id: "olive", x: 0.14, y: 0.72, size: 0.30),
        .init(id: "lemon", x: 0.87, y: 0.72, size: 0.26),
        .init(id: "bust", x: 0.33, y: 0.67, size: 0.12),
        .init(id: "minerva", x: 0.67, y: 0.67, size: 0.20),
        .init(id: "fountain", x: 0.50, y: 0.76, size: 0.26),
        .init(id: "birdbath", x: 0.31, y: 0.86, size: 0.12),
        .init(id: "sundial", x: 0.70, y: 0.87, size: 0.13),
        .init(id: "pond", x: 0.19, y: 0.97, size: 0.30),
        .init(id: "chariot", x: 0.13, y: 0.86, size: 0.22),
        .init(id: "elephant", x: 0.86, y: 0.95, size: 0.30),
        .init(id: "arbor", x: 0.50, y: 1.03, size: 0.36),
    ].map { $0.id == "cypress2" ? Spot(id: "cypress", x: $0.x, y: $0.y, size: $0.size) : $0 } }

    // MARK: Backdrop: sky, sun, hills, sea

    private func backdrop(w: CGFloat, h: CGFloat, t: Double) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Fr.skyTop, Fr.skyLow], startPoint: .top, endPoint: .init(x: 0.5, y: 0.45))
            Circle().fill(RadialGradient(colors: [Color(hex: 0xfff4cf), Color(hex: 0xf6d27a).opacity(0.0)],
                                         center: .center, startRadius: w * 0.04, endRadius: w * 0.14))
                .frame(width: w * 0.28, height: w * 0.28).position(x: w * 0.84, y: h * 0.11)
            Circle().fill(Color(hex: 0xfff1c4)).frame(width: w * 0.08).position(x: w * 0.84, y: h * 0.11)
            // two soft clouds drifting
            ForEach(0..<2, id: \.self) { i in
                let x = (CGFloat((t * (0.008 + Double(i) * 0.004) + Double(i) * 0.5).truncatingRemainder(dividingBy: 1.3)) - 0.15) * w
                CloudPuff().fill(.white.opacity(0.75))
                    .frame(width: w * (0.22 - CGFloat(i) * 0.05), height: w * 0.07)
                    .position(x: x, y: h * (0.08 + CGFloat(i) * 0.07))
            }
            // sea strip and hills
            Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7fb3c4), Color(hex: 0x6aa0b5)], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: h * 0.06).position(x: w / 2, y: h * 0.33)
            Hill(peaks: [0.0, 0.32, 0.18, 0.40, 0.25, 0.36, 0.1]).fill(Fr.hillBack)
                .frame(width: w, height: h * 0.16).position(x: w / 2, y: h * 0.34)
            Hill(peaks: [0.3, 0.1, 0.35, 0.2, 0.4, 0.05]).fill(Fr.hillFront)
                .frame(width: w, height: h * 0.14).position(x: w / 2, y: h * 0.40)
        }
        .frame(width: w, height: h)
    }

    // MARK: The house

    private func house(w: CGFloat, h: CGFloat) -> some View {
        let gold = owned.contains("goldroof")
        let left = w * 0.16, right = w * 0.84, roofTop = h * 0.17, eave = h * 0.29, base = h * 0.53
        let cols = 6
        return ZStack(alignment: .topLeading) {
            // wall
            Rectangle().fill(LinearGradient(colors: [Fr.stucco, Fr.stuccoShade], startPoint: .top, endPoint: .bottom))
                .frame(width: right - left, height: base - eave).position(x: w / 2, y: (eave + base) / 2)
            // ochre dado band
            Rectangle().fill(Fr.ochre.opacity(0.8))
                .frame(width: right - left, height: h * 0.025).position(x: w / 2, y: base - h * 0.0125)
            // doorway
            UnevenRoundedRectangle(topLeadingRadius: w * 0.05, topTrailingRadius: w * 0.05)
                .fill(LinearGradient(colors: [Color(hex: 0x4a2a18), Color(hex: 0x2b170c)], startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.12, height: h * 0.15).position(x: w / 2, y: base - h * 0.075)
            // windows
            ForEach([0.3, 0.7], id: \.self) { fx in
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x4a2a18).opacity(0.85))
                    .frame(width: w * 0.06, height: h * 0.06).position(x: w * fx, y: eave + h * 0.07)
            }
            // roof: tiled slope with a pediment in the middle
            Trapezoid(inset: 0.06).fill(gold ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xf7d36b), Color(hex: 0xc4922c)], startPoint: .top, endPoint: .bottom))
                                             : AnyShapeStyle(LinearGradient(colors: [Fr.tile, Fr.tileDeep], startPoint: .top, endPoint: .bottom)))
                .overlay(TileLines().stroke(gold ? Color(hex: 0xa87a1f).opacity(0.6) : Fr.tileDeep.opacity(0.55), lineWidth: 1))
                .frame(width: right - left + w * 0.06, height: eave - roofTop + h * 0.01)
                .position(x: w / 2, y: (roofTop + eave) / 2)
            Triangle().fill(Fr.marble).overlay(Triangle().stroke(Fr.marbleShade, lineWidth: 1.5))
                .frame(width: w * 0.36, height: h * 0.09).position(x: w / 2, y: eave - h * 0.035)
            // columns + architrave
            Rectangle().fill(Fr.marble).frame(width: right - left, height: h * 0.022).position(x: w / 2, y: eave + h * 0.011)
            ForEach(0..<cols, id: \.self) { i in
                let x = left + (right - left) * (CGFloat(i) + 0.5) / CGFloat(cols)
                if abs(x - w / 2) > w * 0.06 {
                    Column().fill(LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing))
                        .frame(width: w * 0.035, height: base - eave - h * 0.02)
                        .position(x: x, y: (eave + base) / 2 + h * 0.011)
                }
            }
            if owned.contains("banners") {
                ForEach(0..<(cols - 1), id: \.self) { i in
                    let x = left + (right - left) * CGFloat(i + 1) / CGFloat(cols)
                    if abs(x - w / 2) > w * 0.06 {
                        Banner().fill(LinearGradient(colors: [Color(hex: 0xb8322a), Color(hex: 0x8a1f19)], startPoint: .top, endPoint: .bottom))
                            .overlay(Banner().stroke(Fr.gold, lineWidth: 1))
                            .frame(width: w * 0.05, height: h * 0.12).position(x: x, y: eave + h * 0.085)
                    }
                }
            }
            if owned.contains("eagle") {
                Text("🦅").font(.system(size: w * 0.08))
                    .colorMultiply(Color(hex: 0xf4c95a))
                    .position(x: w / 2, y: roofTop - h * 0.005)
                    .scaleEffect(justBought == "eagle" || poke == "eagle" ? 1.2 : 1)
            }
            if owned.contains("roses") {
                ForEach([0.27, 0.73], id: \.self) { fx in
                    RoseBed().frame(width: w * 0.22, height: h * 0.05).position(x: w * fx, y: base + h * 0.012)
                }
            }
        }
    }

    // MARK: Lawn + path

    private func lawn(w: CGFloat, h: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(LinearGradient(colors: [Fr.lawn, Fr.lawnDeep], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: h * 0.48).position(x: w / 2, y: h * 0.53 + h * 0.24)
            PathShape().fill(LinearGradient(colors: [Fr.path, Color(hex: 0xc4a978)], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: h * 0.47).position(x: w / 2, y: h * 0.53 + h * 0.235)
            // tufts of grass
            ForEach(0..<14, id: \.self) { i in
                let fx = CGFloat((i * 37) % 100) / 100, fy = 0.6 + CGFloat((i * 53) % 40) / 100
                if abs(fx - 0.5) > 0.12 {
                    Text("‿").font(.system(size: w * 0.04, weight: .bold)).foregroundStyle(Fr.leafDark.opacity(0.35))
                        .position(x: fx * w, y: fy * h)
                }
            }
        }
    }

    // MARK: Props

    @ViewBuilder
    private func prop(_ id: String, w: CGFloat, t: Double) -> some View {
        switch id {
        case "cypress": Cypress()
        case "olive": FruitTree(fruit: Color(hex: 0x3b3f22), canopy: Color(hex: 0x7f9a63))
        case "lemon": FruitTree(fruit: Color(hex: 0xf3d43c), canopy: Fr.leaf)
        case "bust": Pedestal { Text("🗿").font(.system(size: w * 0.06)).grayscale(1).brightness(0.25) }
        case "minerva": MinervaStatue()
        case "fountain": Fountain(t: t)
        case "birdbath": BirdBath(t: t)
        case "sundial": Sundial()
        case "pond": Pond(t: t)
        case "chariot": Chariot()
        case "elephant": Text("🐘").font(.system(size: w * 0.2)).scaleEffect(x: -1)
        case "arbor": Arbor()
        default: EmptyView()
        }
    }

    // MARK: Pets — wander the lawn in their own lanes; the owl perches on the roof

    private struct Pet { let id: String; let emoji: String; let lane: CGFloat; let speed: Double; let size: CGFloat; let hop: Bool }
    private let petList: [Pet] = [
        .init(id: "dog", emoji: "🐕", lane: 0.92, speed: 0.22, size: 0.085, hop: false),
        .init(id: "cat", emoji: "🐈", lane: 0.80, speed: 0.15, size: 0.07, hop: false),
        .init(id: "goat", emoji: "🐐", lane: 0.70, speed: 0.10, size: 0.08, hop: false),
        .init(id: "rabbit", emoji: "🐇", lane: 0.62, speed: 0.20, size: 0.06, hop: true),
        .init(id: "rooster", emoji: "🐓", lane: 0.86, speed: 0.13, size: 0.065, hop: false),
        .init(id: "tortoise", emoji: "🐢", lane: 0.97, speed: 0.03, size: 0.06, hop: false),
        .init(id: "peacock", emoji: "🦚", lane: 0.75, speed: 0.07, size: 0.10, hop: false),
    ]

    private func petX(_ p: Pet, _ t: Double) -> (x: CGFloat, right: Bool) {
        let phase = Double(p.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 100) / 16
        let s = sin(t * p.speed + phase)
        return (0.5 + 0.40 * CGFloat(s), cos(t * p.speed + phase) > 0)
    }

    private func petSpot(_ id: String, w: CGFloat, h: CGFloat, t: Double) -> Spot? {
        if id == "owl" { return Spot(id: id, x: 0.22, y: 0.20, size: 0.07) }
        guard let p = petList.first(where: { $0.id == id }) else { return nil }
        return Spot(id: id, x: petX(p, t).x, y: p.lane, size: p.size)
    }

    private func pets(w: CGFloat, h: CGFloat, t: Double) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(petList, id: \.id) { p in
                if owned.contains(p.id) {
                    let (x, right) = petX(p, t)
                    let step = abs(sin(t * (p.hop ? 6 : 9) + Double(p.lane) * 10))
                    Text(p.emoji).font(.system(size: p.size * w))
                        .scaleEffect(x: right ? -1 : 1, y: 1)         // emoji face left; flip when walking right
                        .scaleEffect(scale(for: p.id), anchor: .bottom)
                        .offset(y: -CGFloat(step) * (p.hop ? w * 0.025 : w * 0.006))
                        .background(alignment: .bottom) {
                            Ellipse().fill(.black.opacity(0.18)).frame(width: p.size * w * 0.8, height: p.size * w * 0.18)
                                .offset(y: p.size * w * 0.05)
                        }
                        .position(x: x * w, y: p.lane * h - p.size * w / 2)
                        .zIndex(p.lane)
                }
            }
            if owned.contains("owl") {
                let blink = (t.truncatingRemainder(dividingBy: 4)) < 0.15
                Text("🦉").font(.system(size: w * 0.07))
                    .scaleEffect(y: blink ? 0.9 : 1, anchor: .bottom)
                    .scaleEffect(scale(for: "owl"), anchor: .bottom)
                    .position(x: w * 0.22, y: h * 0.20 - w * 0.035)
            }
        }
    }
}

// MARK: - Thumbnails in the shop cards (the same drawings, framed)

private struct VillaThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            Group {
                switch id {
                case "roses": RoseBed().frame(height: w * 0.35)
                case "cypress": HStack(spacing: 2) { Cypress(); Cypress() }
                case "banners": HStack(spacing: 6) { ForEach(0..<3, id: \.self) { _ in Banner().fill(Color(hex: 0xb8322a)).overlay(Banner().stroke(Fr.gold, lineWidth: 1)) } }.padding(.horizontal, 8).padding(.vertical, 6)
                case "olive": FruitTree(fruit: Color(hex: 0x3b3f22), canopy: Color(hex: 0x7f9a63))
                case "lemon": FruitTree(fruit: Color(hex: 0xf3d43c), canopy: Fr.leaf)
                case "arbor": Arbor()
                case "birdbath": BirdBath(t: 0).padding(.horizontal, w * 0.2)
                case "pond": Pond(t: 0)
                case "fountain": Fountain(t: 0)
                case "bust": Pedestal { Text("🗿").font(.system(size: w * 0.3)).grayscale(1).brightness(0.25) }.padding(.horizontal, w * 0.2)
                case "sundial": Sundial().padding(.horizontal, w * 0.15)
                case "minerva": MinervaStatue().padding(.horizontal, w * 0.15)
                case "goldroof": Trapezoid(inset: 0.15).fill(LinearGradient(colors: [Color(hex: 0xf7d36b), Color(hex: 0xc4922c)], startPoint: .top, endPoint: .bottom)).overlay(TileLines().stroke(Color(hex: 0xa87a1f), lineWidth: 1)).frame(height: w * 0.5)
                case "chariot": Chariot().frame(height: w * 0.55)
                default:
                    let emoji = ["tortoise": "🐢", "rooster": "🐓", "rabbit": "🐇", "goat": "🐐", "cat": "🐈", "dog": "🐕",
                                 "owl": "🦉", "peacock": "🦚", "eagle": "🦅", "elephant": "🐘"][id] ?? "❔"
                    Text(emoji).font(.system(size: w * 0.55))
                        .colorMultiply(id == "eagle" ? Color(hex: 0xf4c95a) : .white)
                }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
    }
}

// MARK: - Drawn pieces

private struct Hill: Shape {
    let peaks: [CGFloat]   // heights (0 = top of rect) at evenly spaced points
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        let n = peaks.count
        var pts: [CGPoint] = []
        for (i, k) in peaks.enumerated() { pts.append(CGPoint(x: r.minX + r.width * CGFloat(i) / CGFloat(n - 1), y: r.minY + r.height * k)) }
        p.addLine(to: pts[0])
        for i in 1..<pts.count {
            let mid = CGPoint(x: (pts[i - 1].x + pts[i].x) / 2, y: (pts[i - 1].y + pts[i].y) / 2)
            p.addQuadCurve(to: mid, control: pts[i - 1])
        }
        p.addLine(to: pts.last!)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct CloudPuff: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX, y: r.midY - r.height * 0.1, width: r.width * 0.5, height: r.height * 0.6))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.25, y: r.minY, width: r.width * 0.45, height: r.height * 0.9))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.5, y: r.midY - r.height * 0.15, width: r.width * 0.5, height: r.height * 0.65))
        return p
    }
}

private struct Trapezoid: Shape {
    var inset: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct TileLines: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        for i in 1..<4 { let y = r.minY + r.height * CGFloat(i) / 4; p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y)) }
        let n = 22
        for i in 1..<n {
            let x = r.minX + r.width * CGFloat(i) / CGFloat(n)
            p.move(to: CGPoint(x: x + (x - r.midX) * -0.1, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY))
        }
        return p
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        return p
    }
}

private struct Column: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let cap = r.height * 0.06
        p.addRect(CGRect(x: r.minX - r.width * 0.25, y: r.minY, width: r.width * 1.5, height: cap))
        p.addRect(CGRect(x: r.minX, y: r.minY + cap, width: r.width, height: r.height - 2 * cap))
        p.addRect(CGRect(x: r.minX - r.width * 0.25, y: r.maxY - cap, width: r.width * 1.5, height: cap))
        return p
    }
}

private struct Banner: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.18))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        return p
    }
}

private struct PathShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX - r.width * 0.06, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.06, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.22, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX - r.width * 0.22, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct RoseBed: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                Capsule().fill(Fr.leafDark).frame(height: g.size.height * 0.7).offset(y: g.size.height * 0.15)
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { i in
                        Circle().fill(i % 2 == 0 ? Color(hex: 0xd2405a) : Color(hex: 0xf28aa0))
                            .frame(width: g.size.height * 0.45).frame(maxWidth: .infinity)
                            .offset(y: i % 2 == 0 ? -2 : 1)
                    }
                }
            }
        }
    }
}

private struct Cypress: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                Rectangle().fill(Fr.trunk).frame(width: w * 0.06, height: h * 0.1)
                Ellipse().fill(LinearGradient(colors: [Fr.leaf, Fr.leafDark], startPoint: .leading, endPoint: .trailing))
                    .frame(width: w * 0.3, height: h * 0.92).offset(y: -h * 0.06)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct FruitTree: View {
    let fruit: Color, canopy: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                Rectangle().fill(Fr.trunk).frame(width: w * 0.09, height: h * 0.45)
                ZStack {
                    Circle().fill(canopy).frame(width: w * 0.55).offset(x: -w * 0.15, y: h * 0.06)
                    Circle().fill(canopy).frame(width: w * 0.6).offset(x: w * 0.13, y: h * 0.04)
                    Circle().fill(canopy.opacity(0.9)).frame(width: w * 0.55).offset(y: -h * 0.12)
                    ForEach(0..<7, id: \.self) { i in
                        Circle().fill(fruit).frame(width: w * 0.07)
                            .offset(x: w * CGFloat([-0.2, 0.05, 0.22, -0.08, 0.15, -0.28, 0.3][i]),
                                    y: h * CGFloat([-0.05, -0.18, 0.02, 0.12, 0.15, 0.08, -0.06][i]))
                    }
                }
                .offset(y: -h * 0.38)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct Pedestal<Top: View>: View {
    @ViewBuilder let top: Top
    var body: some View {
        GeometryReader { g in
            VStack(spacing: 0) {
                top
                Rectangle().fill(LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing))
                    .frame(width: g.size.width * 0.45, height: g.size.height * 0.4)
                Rectangle().fill(Fr.marbleShade).frame(width: g.size.width * 0.6, height: g.size.height * 0.06)
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
    }
}

private struct MinervaStatue: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let stone = LinearGradient(colors: [Fr.marble, Fr.marbleShade], startPoint: .leading, endPoint: .trailing)
            ZStack(alignment: .bottom) {
                Rectangle().fill(Fr.marbleShade).frame(width: w * 0.5, height: h * 0.08)
                Rectangle().fill(stone).frame(width: w * 0.36, height: h * 0.16).offset(y: -h * 0.08)
                // robe
                Trapezoid(inset: 0.3).fill(stone).frame(width: w * 0.34, height: h * 0.42).offset(y: -h * 0.24)
                // head + helmet crest
                Circle().fill(stone).frame(width: w * 0.12).offset(y: -h * 0.70)
                Capsule().fill(Fr.marbleShade).frame(width: w * 0.04, height: h * 0.1).rotationEffect(.degrees(-20)).offset(x: -w * 0.02, y: -h * 0.78)
                // spear + shield
                Rectangle().fill(Fr.marbleShade).frame(width: w * 0.025, height: h * 0.7).offset(x: w * 0.17, y: -h * 0.2)
                Circle().fill(stone).overlay(Circle().stroke(Fr.marbleShade, lineWidth: 1.5)).frame(width: w * 0.2).offset(x: -w * 0.17, y: -h * 0.32)
                Text("🦉").font(.system(size: w * 0.09)).grayscale(1).brightness(0.3).offset(x: -w * 0.17, y: -h * 0.345)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct Fountain: View {
    let t: Double
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                Ellipse().fill(Fr.marbleShade).frame(width: w, height: h * 0.32)
                Ellipse().fill(LinearGradient(colors: [Fr.water, Color(hex: 0x3f87a8)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.86, height: h * 0.2).offset(y: -h * 0.07)
                Rectangle().fill(Fr.marble).frame(width: w * 0.08, height: h * 0.38).offset(y: -h * 0.16)
                Ellipse().fill(Fr.marble).frame(width: w * 0.36, height: h * 0.08).offset(y: -h * 0.52)
                // water arcs
                ForEach(0..<6, id: \.self) { i in
                    let a = Double(i) / 6 * .pi * 2 + t * 0.4
                    let dx = CGFloat(cos(a)) * w * 0.3
                    Circle().fill(Color.white.opacity(0.75)).frame(width: w * 0.035)
                        .offset(x: dx, y: -h * (0.22 + 0.2 * CGFloat(abs(sin(t * 3 + Double(i))))))
                }
                Capsule().fill(Color.white.opacity(0.8)).frame(width: w * 0.03, height: h * 0.16).offset(y: -h * 0.6)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct BirdBath: View {
    let t: Double
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                Rectangle().fill(Fr.marbleShade).frame(width: w * 0.5, height: h * 0.08)
                Rectangle().fill(Fr.marble).frame(width: w * 0.16, height: h * 0.45).offset(y: -h * 0.08)
                Ellipse().fill(Fr.marble).frame(width: w * 0.9, height: h * 0.22).offset(y: -h * 0.48)
                Ellipse().fill(Fr.water).frame(width: w * 0.7, height: h * 0.1).offset(y: -h * 0.55)
                Text("🐦").font(.system(size: w * 0.35))
                    .offset(x: w * 0.2, y: -h * (0.62 + (sin(t * 2) > 0.7 ? 0.05 : 0)))
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct Sundial: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                Rectangle().fill(Fr.marble).frame(width: w * 0.3, height: h * 0.5)
                Ellipse().fill(Color(hex: 0xc9a14a)).frame(width: w * 0.9, height: h * 0.25).offset(y: -h * 0.45)
                Triangle().fill(Color(hex: 0x8a6a22)).frame(width: w * 0.06, height: h * 0.25).offset(y: -h * 0.6)
                Ellipse().fill(.black.opacity(0.25)).frame(width: w * 0.4, height: h * 0.05).offset(x: w * 0.2, y: -h * 0.53)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct Pond: View {
    let t: Double
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Ellipse().fill(Fr.marbleShade).frame(width: w, height: h * 0.42)
                Ellipse().fill(LinearGradient(colors: [Fr.water, Color(hex: 0x3f7f9a)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.88, height: h * 0.34)
                ForEach(0..<3, id: \.self) { i in
                    let a = t * (0.6 + Double(i) * 0.15) + Double(i) * 2
                    Capsule().fill(Color(hex: 0xf08a2c)).frame(width: w * 0.08, height: w * 0.035)
                        .rotationEffect(.radians(a + .pi / 2))
                        .offset(x: CGFloat(cos(a)) * w * 0.28, y: CGFloat(sin(a)) * h * 0.1)
                }
                Text("🪷").font(.system(size: w * 0.12)).offset(x: -w * 0.2, y: -h * 0.02)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct Chariot: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottomLeading) {
                // car
                UnevenRoundedRectangle(topLeadingRadius: w * 0.2, bottomLeadingRadius: 4)
                    .fill(LinearGradient(colors: [Color(hex: 0xb8322a), Color(hex: 0x7d1c16)], startPoint: .top, endPoint: .bottom))
                    .overlay(UnevenRoundedRectangle(topLeadingRadius: w * 0.2, bottomLeadingRadius: 4).stroke(Fr.gold, lineWidth: 2))
                    .frame(width: w * 0.5, height: h * 0.45).offset(x: w * 0.1, y: -h * 0.25)
                // pole
                Rectangle().fill(Fr.trunk).frame(width: w * 0.42, height: 3).offset(x: w * 0.55, y: -h * 0.32)
                // wheel
                Circle().stroke(Fr.gold, lineWidth: 3).frame(width: h * 0.5)
                    .overlay(Rectangle().fill(Fr.gold).frame(width: 2)).overlay(Rectangle().fill(Fr.gold).frame(height: 2))
                    .offset(x: w * 0.22, y: -h * 0.02)
            }
            .frame(width: w, height: h, alignment: .bottomLeading)
        }
    }
}

private struct Arbor: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                ForEach([-0.42, 0.42], id: \.self) { fx in
                    Rectangle().fill(Fr.trunk).frame(width: w * 0.035, height: h * 0.62).offset(x: w * fx)
                }
                Rectangle().fill(Fr.trunk).frame(width: w * 0.95, height: h * 0.05).offset(y: -h * 0.6)
                // vine canopy along the top with grapes
                HStack(spacing: -w * 0.03) {
                    ForEach(0..<8, id: \.self) { i in
                        Circle().fill(i % 2 == 0 ? Fr.leaf : Fr.leafDark).frame(width: w * 0.15)
                    }
                }
                .offset(y: -h * 0.62)
                ForEach(0..<4, id: \.self) { i in
                    Text("🍇").font(.system(size: w * 0.07))
                        .offset(x: w * CGFloat(-0.3 + Double(i) * 0.2), y: -h * 0.5)
                }
                ForEach([-0.42, 0.42], id: \.self) { fx in
                    Capsule().fill(Fr.leaf.opacity(0.9)).frame(width: w * 0.06, height: h * 0.4).offset(x: w * fx, y: -h * 0.2)
                }
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

private struct SparkleBurst: View {
    let t: Double
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) / 8 * .pi * 2 + t
                Image(systemName: "sparkle").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0xffe08a))
                    .offset(x: CGFloat(cos(a)) * 40, y: CGFloat(sin(a)) * 40)
                    .opacity(0.5 + 0.5 * sin(t * 6 + Double(i)))
            }
        }
    }
}
