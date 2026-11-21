import SwiftUI

// MARK: - The Villa — where the arcade's coins go
//
// The child's own Roman villa, painted like a Pompeian wall fresco (flat ochres, terracotta and sage
// inside a red-and-gold fresco frame — deliberately a different register from the painted map, the
// way a fresco differs from a landscape). It starts bare: a plain house on a lawn. Denarii buy the
// garden, water, statues and pets; aurei (from laurels) buy the grand works. Everything bought
// appears in the scene at its own place, and the pets wander the lawn. Owned things can be dragged
// to new spots (VillaPlacement), saved per player.
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
    var place = "garden"       // "garden", or the id of the wing it furnishes (VillaEstate.swift)
}

/// Everything for sale: the garden's things and every wing's (VillaEstate.swift).
let villaCatalog: [VillaItem] = gardenCatalog + wingCatalog

let gardenCatalog: [VillaItem] = [
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

enum Fr {
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
//
// Three layouts, picked from the measured size (in stage points, see LudusStage):
//   • phone — the scene on top, the shop a sideways strip of cards below;
//   • upright iPad — the scene on top, the shop a grid below (two rows, every category fits);
//   • sideways iPad — the scene fills the left, the shop is a drawer of cards on the right.
// The scene itself is a fixed-aspect canvas scaled to fit; spare room becomes more sky, hills and lawn.

struct VillaView: View {
    let onClose: () -> Void

    @State private var tab: VillaCategory = .garden
    @State private var place: VillaPlace = .garden
    @State private var goal: String? = LudusEconomy.goal
    @State private var refresh = 0                 // bumps after a purchase (UserDefaults isn't observed)
    @State private var justBought: String?
    @State private var poke: String?               // an owned item tapped → it bounces in the scene
    @State private var shake: String?
    @State private var note: String?

    private var owned: Set<String> { _ = refresh; return LudusEconomy.owned }
    private var denarii: Int { _ = refresh; return LudusStore.denarii }
    private var aurei: Int { _ = refresh; return LudusEconomy.aurei }

    private enum Layout { case phone, tall, wide }

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        #if DEBUG
        // LUDUS_PLACE=garden|prizes|<wing id> opens the Villa on that place (for screenshots).
        if let p = ProcessInfo.processInfo.environment["LUDUS_PLACE"] {
            _place = State(initialValue: p == "prizes" ? .prizes : (villaWings.contains { $0.id == p } ? .wing(p) : .garden))
        }
        // LUDUS_VILLA_OWN=id+id+… marks villa items owned, once per launch (the capture probe's
        // env list is comma-separated, so LUDUS_OWN can only carry one id through it).
        if !Self.didDebugOwn, let o = ProcessInfo.processInfo.environment["LUDUS_VILLA_OWN"] {
            Self.didDebugOwn = true
            LudusStore.defaults.set(o.split(separator: "+").map(String.init), forKey: LudusEconomy.ownedKey)
        }
        #endif
    }
    #if DEBUG
    nonisolated(unsafe) private static var didDebugOwn = false
    #endif

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let layout: Layout = w < 600 ? .phone : (w > h ? .wide : .tall)
            ZStack(alignment: .top) {
                Fr.frameDeep.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    placeBar.padding(.bottom, 8)
                    switch layout {
                    case .phone:
                        scene.frame(height: min(h * 0.5, w * 1.05)).padding(.horizontal, 10)
                        stripShop
                    case .tall:
                        scene.padding(.horizontal, 14)
                        gridShop(width: w)
                    case .wide:
                        HStack(spacing: 14) {
                            scene
                            drawer.frame(width: min(370, max(320, w * 0.31)))
                        }
                        .padding(.horizontal, 14).padding(.bottom, 12)
                    }
                }
            }
        }
        .statusBarHidden(true)
    }

    private var scene: some View {
        FrescoFrame {
            switch place {
            case .garden:
                VillaScene(owned: owned, justBought: justBought, poke: poke, onTap: pokeOwned)
            case .wing:
                if let wing = place.wing, LudusEconomy.built(wing) {
                    wingRoom(wing, WingState(owned: owned, justBought: justBought, poke: poke, onTap: pokeOwned))
                } else if let wing = place.wing {
                    WingSite(wing: wing)
                }
            case .prizes:
                PrizeHall(refresh: refresh)
            }
        }
        .id(place)
        .transition(.opacity)
    }

    // MARK: Places — the garden, the eight wings, the prize hall

    private var placeBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    placeChip(.garden, icon: "leaf.fill", name: "Garden", state: .open)
                    ForEach(villaWings) { wing in
                        placeChip(.wing(wing.id), icon: wing.icon, name: wing.short,
                                  state: LudusEconomy.built(wing) ? .open : (LudusEconomy.wingUnlocked(wing) ? .buildable : .locked))
                    }
                    placeChip(.prizes, icon: "gift.fill", name: "Prizes", state: .open)
                }
                .padding(.horizontal, 14).padding(.vertical, 2)
            }
            .onAppear { proxy.scrollTo(place, anchor: .center) }
        }
    }

    private enum ChipState { case open, buildable, locked }

    private func placeChip(_ p: VillaPlace, icon: String, name: String, state: ChipState) -> some View {
        let on = place == p
        return Button {
            Sfx.play(.tick)
            withAnimation(.easeOut(duration: 0.2)) { place = p; note = nil }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: state == .locked ? "lock.fill" : icon).font(.system(size: 12, weight: .bold))
                Text(name.uppercased()).font(luCinzel(11, bold: true)).tracking(0.4).lineLimit(1)
                if state == .buildable && !on {
                    Circle().fill(Fr.gold).frame(width: 7, height: 7)      // ready to build
                }
            }
            .foregroundStyle(on ? Fr.frameDeep : Fr.parchment.opacity(state == .locked ? 0.45 : 0.9))
            .padding(.horizontal, 11).frame(height: 32)
            .background(Capsule().fill(on ? Fr.gold : Fr.frame)
                .overlay(Capsule().stroke(Fr.gold.opacity(on ? 0 : 0.45), lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .id(p)
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

    // MARK: Shop — strip (phone), grid (upright iPad), drawer (sideways iPad)

    private var stripShop: some View {
        VStack(spacing: 10) {
            switch shopMode {
            case .items:
                if place == .garden { tabs }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items) { item in card(item, width: 108) }
                    }
                    .padding(.horizontal, 2).padding(.vertical, 4)
                }
                noteLine
            case .build(let wing): buildPanel(wing)
            case .prizes: PrizeList(refresh: $refresh, note: $note)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.top, 12)
        .background(parchmentPanel(top: true))
        .padding(.top, 12)
    }

    /// Two rows always fit: four columns of compact cards and at most eight items in a category.
    private func gridShop(width: CGFloat) -> some View {
        let cols = 4, gap: CGFloat = 10
        let tw = floor((width - 24 - gap * CGFloat(cols - 1)) / CGFloat(cols))
        return VStack(spacing: 10) {
            switch shopMode {
            case .items:
                if place == .garden { tabs(roomy: true) }
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(tw), spacing: gap), count: cols), spacing: gap) {
                    ForEach(items) { item in rowCard(item, width: tw) }
                }
                .frame(height: rowCardHeight * 2 + gap, alignment: .top)
                .id(tab)
                noteLine.frame(minHeight: 36)
            case .build(let wing): buildPanel(wing).frame(minHeight: rowCardHeight * 2 + gap + 80)
            case .prizes: PrizeList(refresh: $refresh, note: $note).frame(height: rowCardHeight * 2 + gap + 90)
            }
        }
        .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 4)
        .background(parchmentPanel(top: true))
        .padding(.top, 12)
    }

    private var drawer: some View {
        GeometryReader { g in
            let cols = 3, gap: CGFloat = 10
            let tw = floor((g.size.width - 24 - gap * CGFloat(cols - 1)) / CGFloat(cols))
            VStack(spacing: 12) {
                switch shopMode {
                case .items:
                    if place == .garden { tabs }
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(tw), spacing: gap), count: cols), spacing: gap) {
                            ForEach(items) { item in card(item, width: tw) }
                        }
                        .padding(.vertical, 4)
                        .id(tab)
                    }
                case .build(let wing): buildPanel(wing)
                case .prizes: PrizeList(refresh: $refresh, note: $note)
                }
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    collection
                    noteLine.frame(minHeight: 40)
                }
                .padding(.horizontal, 14).padding(.vertical, 12).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.35))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Fr.gold.opacity(0.5), lineWidth: 1)))
            }
            .padding(12)
        }
        .background(parchmentPanel(top: false))
    }

    private var items: [VillaItem] {
        switch place {
        case .garden: return gardenCatalog.filter { $0.category == tab }
        case .wing(let id): return villaCatalog.filter { $0.place == id }
        case .prizes: return []
        }
    }

    private enum ShopMode { case items, build(VillaWing), prizes }
    private var shopMode: ShopMode {
        _ = refresh
        switch place {
        case .garden: return .items
        case .prizes: return .prizes
        case .wing:
            guard let wing = place.wing else { return .items }
            return LudusEconomy.built(wing) ? .items : .build(wing)
        }
    }

    // MARK: Building a wing

    private func buildPanel(_ wing: VillaWing) -> some View {
        let unlocked = LudusEconomy.wingUnlocked(wing)
        let cost = LudusEconomy.nextWingCost
        let afford = aurei >= cost
        return VStack(spacing: 10) {
            Text(wing.name.uppercased()).font(luCinzel(17, bold: true)).tracking(1).foregroundStyle(Fr.ink)
            Text(wing.blurb).font(luGaramond(15, semibold: true)).foregroundStyle(Fr.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            if unlocked {
                Button { build(wing) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer.fill").font(.system(size: 15, weight: .bold))
                        Text("BUILD IT").font(luCinzel(15, bold: true)).tracking(1)
                        Image("CoinGold").resizable().frame(width: 20, height: 20)
                        Text("\(cost)").font(luCinzel(16)).monospacedDigit()
                    }
                    .foregroundStyle(afford ? Fr.parchment : Fr.ink.opacity(0.45))
                    .padding(.horizontal, 22).frame(height: 46)
                    .background(Capsule().fill(afford ? Fr.frame : Color(hex: 0xd6c39b)))
                    .overlay(Capsule().stroke(Fr.gold.opacity(afford ? 0.9 : 0.4), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .offset(x: shake == wing.ownedID ? -6 : 0)
                Text(note ?? (afford ? "Gold aurei come from laurels." :
                              "You need \(cost - aurei) more gold aure\(cost - aurei == 1 ? "us" : "i"). Win laurels to earn them!"))
                    .font(luGaramond(14, semibold: true)).foregroundStyle(Fr.ink.opacity(0.7)).multilineTextAlignment(.center)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").foregroundStyle(Fr.frame)
                    Text("Win a laurel in \(LudusEconomy.worldName(wing)) to build it.")
                        .font(luGaramond(16, semibold: true)).foregroundStyle(Fr.ink)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.4)))
                Text("A laurel = reach Gradus III in any \(wing.subject) game.")
                    .font(luGaramond(14, semibold: true)).foregroundStyle(Fr.ink.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
    }

    private func build(_ wing: VillaWing) {
        if LudusEconomy.build(wing) {
            Sfx.play(.coin); Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { Sfx.play(.sparkle) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { refresh += 1 }
            note = "\(wing.name) is built! Now fill it with things."
        } else {
            Sfx.play(.wrong); Haptics.error()
            withAnimation(.linear(duration: 0.05).repeatCount(5, autoreverses: true)) { shake = wing.ownedID }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = nil }
        }
    }

    private var tabs: some View { tabs(roomy: false) }

    /// Category tabs; `roomy` (the upright iPad's full-width bar) sets icon and label side by side, larger.
    private func tabs(roomy: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(VillaCategory.allCases) { c in
                Button {
                    Sfx.play(.tick); withAnimation(.easeOut(duration: 0.18)) { tab = c }
                } label: {
                    let stack = roomy ? AnyLayout(HStackLayout(spacing: 7)) : AnyLayout(VStackLayout(spacing: 3))
                    stack {
                        Image(systemName: c.icon).font(.system(size: roomy ? 18 : 16, weight: .bold))
                        Text(c.rawValue.uppercased()).font(luCinzel(roomy ? 13 : 9.5, bold: true)).tracking(0.5)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(tab == c ? Fr.parchment : Fr.ink.opacity(0.7))
                    .frame(maxWidth: .infinity).padding(.vertical, roomy ? 11 : 7)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(tab == c ? Fr.frame : Fr.parchment.opacity(0.0)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 13).fill(Color(hex: 0xe6d3a8)))
    }

    private var noteLine: some View {
        Text(note ?? hint)
            .font(luGaramond(14, semibold: true)).foregroundStyle(Fr.ink.opacity(0.75))
            .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .animation(.easeOut(duration: 0.2), value: note)
    }

    private func parchmentPanel(top: Bool) -> some View {
        let r: CGFloat = 22
        let shape = UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: top ? 0 : r,
                                           bottomTrailingRadius: top ? 0 : r, topTrailingRadius: r)
        return shape
            .fill(LinearGradient(colors: [Fr.parchment, Color(hex: 0xe9d6ad)], startPoint: .top, endPoint: .bottom))
            .overlay(shape.stroke(Fr.gold, lineWidth: 1.5))
            .ignoresSafeArea(edges: top ? .bottom : [])
    }

    private var hint: String {
        if place != .garden { return "Tap a thing to buy it. Hold one to save up for it." }
        if tab == .grand { return "Grand works cost gold aurei. Win laurels in the games to earn them!" }
        if owned.contains(where: { villaMovable.contains($0) }) { return "Drag your things to move them around the villa." }
        return "Every right answer in a game earns a silver denarius."
    }

    /// How much of the catalog this villa holds: a count and a gold bar.
    private var collection: some View {
        let n = villaCatalog.filter { owned.contains($0.id) }.count, all = villaCatalog.count
        return VStack(spacing: 6) {
            HStack {
                Text("YOUR VILLA").font(luCinzel(11, bold: true)).tracking(1).foregroundStyle(Fr.ink.opacity(0.6))
                Spacer()
                Text("\(n) of \(all)").font(luCinzel(13, bold: true)).monospacedDigit().foregroundStyle(Fr.frame)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xd6c39b))
                    Capsule().fill(LinearGradient(colors: [Fr.gold, Fr.ochre], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(n > 0 ? 8 : 0, g.size.width * CGFloat(n) / CGFloat(all)))
                }
            }
            .frame(height: 8)
        }
    }
    private func thumbHeight(_ width: CGFloat) -> CGFloat { (width - 12) * 0.875 }

    private func card(_ item: VillaItem, width: CGFloat) -> some View {
        let has = owned.contains(item.id)
        let afford = LudusEconomy.canAfford(item)
        return Button { tap(item) } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Fr.skyLow, Fr.lawn.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                    thumb(item).padding(6)
                }
                .frame(width: width - 12, height: thumbHeight(width))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Fr.gold.opacity(0.8), lineWidth: 1))
                Text(item.name).font(luCinzel(12, bold: true)).foregroundStyle(Fr.ink)
                    .lineLimit(1).minimumScaleFactor(0.7).frame(height: 16)
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
                    .padding(.horizontal, 4)
                }
            }
            .frame(width: width)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(has ? 0.5 : 0.35))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Fr.gold.opacity(0.5), lineWidth: 1)))
            .overlay(alignment: .top) { goalRibbon(item).offset(y: -6) }
            .offset(x: shake == item.id ? -6 : 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in toggleGoal(item) })
    }

    private let rowCardHeight: CGFloat = 80

    private func thumb(_ item: VillaItem) -> AnyView { wingThumb(item) ?? AnyView(VillaThumb(id: item.id)) }

    // MARK: Saving for something — hold a card to set a goal (shown on the card and after every game)

    private func goalRibbon(_ item: VillaItem) -> some View {
        Text("SAVING").font(luCinzel(9, bold: true)).tracking(0.8).foregroundStyle(Fr.frameDeep)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(Fr.gold))
            .opacity(goal == item.id && !owned.contains(item.id) ? 1 : 0)
    }

    private func toggleGoal(_ item: VillaItem) {
        guard !owned.contains(item.id) else { return }
        Haptics.light(); Sfx.play(.tick)
        let new = goal == item.id ? nil : item.id
        LudusEconomy.goal = new
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { goal = new }
        note = new == nil ? "No goal for now." : "Saving for the \(item.name)! You'll see how close you are after every game."
    }

    /// The compact card of the upright iPad grid: picture on the left, name and price beside it.
    private func rowCard(_ item: VillaItem, width: CGFloat) -> some View {
        let has = owned.contains(item.id)
        let afford = LudusEconomy.canAfford(item)
        return Button { tap(item) } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [Fr.skyLow, Fr.lawn.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                    thumb(item).padding(4)
                }
                .frame(width: 64, height: 64)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Fr.gold.opacity(0.8), lineWidth: 1))
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name).font(luCinzel(12.5, bold: true)).foregroundStyle(Fr.ink)
                        .lineLimit(2).minimumScaleFactor(0.8).fixedSize(horizontal: false, vertical: true)
                    if has {
                        Label("Yours", systemImage: "checkmark.seal.fill")
                            .font(luCinzel(11, bold: true)).foregroundStyle(Fr.leafDark)
                            .frame(height: 24)
                    } else {
                        HStack(spacing: 4) {
                            Image(item.price.gold ? "CoinGold" : "CoinSilver").resizable().frame(width: 16, height: 16)
                            Text("\(item.price.amount)").font(luCinzel(13.5)).monospacedDigit()
                        }
                        .foregroundStyle(afford ? Fr.parchment : Fr.ink.opacity(0.45))
                        .padding(.horizontal, 10).frame(height: 24)
                        .background(Capsule().fill(afford ? Fr.frame : Color(hex: 0xd6c39b)))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(width: width, height: rowCardHeight)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(has ? 0.5 : 0.35))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Fr.gold.opacity(0.5), lineWidth: 1)))
            .overlay(alignment: .topTrailing) { goalRibbon(item).offset(x: -6, y: -6) }
            .offset(x: shake == item.id ? -6 : 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in toggleGoal(item) })
    }

    private func pokeOwned(_ id: String) {
        guard let item = villaCatalog.first(where: { $0.id == id }) else { return }
        Sfx.play(.tick)
        poke = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { if poke == item.id { poke = nil } }
        note = item.blurb
    }

    private func tap(_ item: VillaItem) {
        if owned.contains(item.id) { pokeOwned(item.id); return }
        if LudusEconomy.buy(item) {
            if goal == item.id { LudusEconomy.goal = nil; goal = nil }
            VillaPlacement.reset(item: item.id)          // a new purchase lands at its home spot
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

/// Catalog items the child can drag around the scene (the rest belong to the house).
private let villaMovable: Set<String> = Set(villaCatalog.map(\.id)).subtracting(["roses", "banners", "goldroof", "eagle"])

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
//
// The villa itself is drawn on the fixed design canvas (VillaPlacement.canvas), scaled uniformly to
// fit and set a little below center; the sky, sea, hills, lawn and path are drawn across the whole
// frame, lined up with the canvas, so a wide or tall frame shows more countryside, never a stretched
// house. Owned things can be picked up and moved (see VillaPlacement for the zones).

private struct VillaScene: View {
    let owned: Set<String>
    let justBought: String?
    let poke: String?
    var onTap: (String) -> Void = { _ in }

    @State private var places: [String: CGPoint] = VillaPlacement.loadAll(VillaScene.allIDs)
    @State private var drag: Held?
    @State private var settle: [String: Settle] = [:]       // a dropped thing glides to its spot
    @State private var petShift: [String: Double] = [:]     // re-phases a pet's stroll so it sets off from where it was dropped

    /// A thing being held: its feet (canvas fractions) and where the finger grabbed it, relative to them.
    struct Held: Equatable { let id: String; var at: CGPoint; let grab: CGSize; var moved: Bool }
    struct Settle { let from: CGPoint; let at: Double }

    private static let space = "villaCanvas"
    private static let allIDs = placed.map(\.id) + petList.map(\.id) + ["owl"]

    var body: some View {
        GeometryReader { g in
            let fw = g.size.width, fh = g.size.height
            let c = VillaPlacement.canvas
            let k = min(fw / c.width, fh / c.height)
            let w = c.width * k, h = c.height * k
            let ox = (fw - w) / 2, oy = (fh - h) * 0.65
            TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .topLeading) {
                    Countryside(fw: fw, fh: fh, ox: ox, oy: oy, w: w, h: h, t: t)
                    ZStack(alignment: .topLeading) {
                        house(w: w, h: h)
                        if let d = drag, VillaScene.statues.contains(d.id) { plinthMarks(w: w, h: h, near: d.at) }
                        things(w: w, h: h, t: t)
                        if let j = justBought, let p = sparkleSpot(j, t: t) {
                            SparkleBurst(t: t).frame(width: 120, height: 120)
                                .position(x: p.x * w, y: p.y * h).allowsHitTesting(false)
                                .zIndex(2000)
                        }
                    }
                    .frame(width: w, height: h)
                    .coordinateSpace(name: VillaScene.space)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("villa-canvas")
                    .position(x: ox + w / 2, y: oy + h / 2)
                }
                .frame(width: fw, height: fh, alignment: .topLeading)
            }
        }
        .onChange(of: owned) { _ in places = VillaPlacement.loadAll(VillaScene.allIDs) }
    }

    private func scale(for id: String) -> CGFloat {
        if justBought == id || poke == id { return 1.12 }
        return 1
    }

    /// Where each non-pet item stands by default: center x, FOOT y (canvas fractions), box size
    /// (fraction of canvas width), its zone, and how much of the box (from the bottom) is solid to a finger.
    struct Spot { let id: String; let item: String; let x: CGFloat; let y: CGFloat; let size: CGFloat; let zone: VillaZone; var hit: CGFloat = 1 }
    static let placed: [Spot] = [
        .init(id: "cypress", item: "cypress", x: 0.06, y: 0.60, size: 0.30, zone: .lawn),
        .init(id: "cypress2", item: "cypress", x: 0.94, y: 0.60, size: 0.30, zone: .lawn),
        .init(id: "olive", item: "olive", x: 0.14, y: 0.72, size: 0.30, zone: .lawn),
        .init(id: "lemon", item: "lemon", x: 0.87, y: 0.72, size: 0.26, zone: .lawn),
        .init(id: "bust", item: "bust", x: 0.33, y: 0.67, size: 0.12, zone: .plinth),
        .init(id: "minerva", item: "minerva", x: 0.67, y: 0.67, size: 0.20, zone: .plinth),
        .init(id: "fountain", item: "fountain", x: 0.50, y: 0.76, size: 0.26, zone: .lawn, hit: 0.75),
        .init(id: "birdbath", item: "birdbath", x: 0.31, y: 0.86, size: 0.12, zone: .lawn),
        .init(id: "sundial", item: "sundial", x: 0.70, y: 0.87, size: 0.13, zone: .plinth),
        .init(id: "pond", item: "pond", x: 0.19, y: 0.97, size: 0.30, zone: .lawn, hit: 0.45),
        .init(id: "chariot", item: "chariot", x: 0.13, y: 0.86, size: 0.22, zone: .lawn, hit: 0.7),
        .init(id: "elephant", item: "elephant", x: 0.86, y: 0.95, size: 0.30, zone: .lawn, hit: 0.8),
        .init(id: "arbor", item: "arbor", x: 0.50, y: 1.03, size: 0.36, zone: .lawn, hit: 0.8),
    ]
    static let statues: Set<String> = ["bust", "minerva", "sundial"]

    // MARK: Things on the lawn — props, pets and the owl, one depth-sorted layer

    private func things(w: CGFloat, h: CGFloat, t: Double) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(VillaScene.placed, id: \.id) { s in
                if owned.contains(s.item) {
                    let p = foot(s.id, home: CGPoint(x: s.x, y: s.y), t: t)
                    let box = s.size * w
                    let hitH = max(box * s.hit, 64), hitW = max(box, 64)
                    held(s.id, box: box) { prop(s.item, w: w, t: t).frame(width: box, height: box) }
                        .scaleEffect(scale(for: s.item), anchor: .bottom)
                        .frame(width: hitW, height: max(box, hitH), alignment: .bottom)
                        .contentShape(BottomRect(height: hitH))
                        .gesture(grab(s.id, zone: s.zone, size: s.size, w: w, h: h))
                        .accessibilityElement().accessibilityIdentifier("villa-item-\(s.id)")
                        .position(x: p.x * w, y: p.y * h - max(box, hitH) / 2)
                        .zIndex(drag?.id == s.id ? 1000 : p.y)
                }
            }
            ForEach(VillaScene.petList, id: \.id) { pet in
                if owned.contains(pet.id) { petView(pet, w: w, h: h, t: t) }
            }
            if owned.contains("owl") {
                let p = foot("owl", home: CGPoint(x: 0.22, y: VillaPlacement.roofY), t: t)
                let blink = (t.truncatingRemainder(dividingBy: 4)) < 0.15
                held("owl", box: w * 0.07) {
                    Text("🦉").font(.system(size: w * 0.07))
                        .scaleEffect(y: blink ? 0.9 : 1, anchor: .bottom)
                }
                .scaleEffect(scale(for: "owl"), anchor: .bottom)
                .frame(width: 60, height: 60, alignment: .bottom)
                .contentShape(Rectangle())
                .gesture(grab("owl", zone: .roof, size: 0.07, w: w, h: h))
                .accessibilityElement().accessibilityIdentifier("villa-item-owl")
                .position(x: p.x * w, y: p.y * h - 30)
                .zIndex(drag?.id == "owl" ? 1000 : 0)
            }
        }
    }

    /// The lift while a thing is held: up a little, a touch bigger, with a soft shadow left on the grass.
    private func held<V: View>(_ id: String, box: CGFloat, @ViewBuilder _ v: () -> V) -> some View {
        let up = drag?.id == id
        return v()
            .scaleEffect(up ? 1.08 : 1, anchor: .bottom)
            .offset(y: up ? -10 : 0)
            .shadow(color: .black.opacity(up ? 0.25 : 0), radius: 6, y: 6)
            .background(alignment: .bottom) {
                Ellipse().fill(.black.opacity(up ? 0.22 : 0))
                    .frame(width: max(box * 0.7, 24), height: max(box * 0.14, 6)).offset(y: 3)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: up)
    }

    /// Where a thing's feet are now: under the finger while held, gliding home after a drop, else its spot.
    private func foot(_ id: String, home: CGPoint, t: Double) -> CGPoint {
        if let d = drag, d.id == id { return d.at }
        return glide(id, to: places[id] ?? home, t: t)
    }

    private func glide(_ id: String, to target: CGPoint, t: Double) -> CGPoint {
        guard let s = settle[id] else { return target }
        let u = min(1, max(0, (t - s.at) / 0.35)), e = 1 - pow(1 - u, 3)
        return CGPoint(x: s.from.x + (target.x - s.from.x) * e, y: s.from.y + (target.y - s.from.y) * e)
    }

    /// One gesture does both: a tap pokes the thing (bounce + its blurb), a drag carries it.
    private func grab(_ id: String, zone: VillaZone, size: CGFloat, w: CGFloat, h: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(VillaScene.space))
            .onChanged { v in
                let loc = CGPoint(x: v.location.x / w, y: v.location.y / h)
                if drag?.id != id {
                    guard drag == nil else { return }               // one thing at a time
                    let now = Date().timeIntervalSinceReferenceDate
                    let cur = currentFoot(id, t: now)
                    drag = Held(id: id, at: cur, grab: CGSize(width: loc.x - cur.x, height: loc.y - cur.y), moved: false)
                }
                guard var d = drag else { return }
                if !d.moved, hypot(v.translation.width, v.translation.height) > 8 {
                    d.moved = true; Haptics.light()
                }
                if d.moved { d.at = CGPoint(x: loc.x - d.grab.width, y: loc.y - d.grab.height) }
                drag = d
            }
            .onEnded { _ in
                guard let d = drag, d.id == id else { return }
                drop(d, zone: zone, size: size)
            }
    }

    /// Where a thing's feet are at time `t`, held or not (pets are strolling).
    private func currentFoot(_ id: String, t: Double) -> CGPoint {
        if let pet = VillaScene.petList.first(where: { $0.id == id }) { return petFoot(pet, t: t).p }
        if id == "owl" { return foot(id, home: CGPoint(x: 0.22, y: VillaPlacement.roofY), t: t) }
        let s = VillaScene.placed.first { $0.id == id }
        return foot(id, home: CGPoint(x: s?.x ?? 0.5, y: s?.y ?? 0.8), t: t)
    }

    private func drop(_ d: Held, zone: VillaZone, size: CGFloat) {
        let now = Date().timeIntervalSinceReferenceDate
        drag = nil
        guard d.moved else {
            settle[d.id] = Settle(from: d.at, at: now)
            onTap(VillaScene.placed.first { $0.id == d.id }?.item ?? d.id)
            return
        }
        let pet = VillaScene.petList.first { $0.id == d.id }
        let spot = VillaPlacement.clamp(d.at, zone: zone, size: size, pet: pet != nil)
        if zone == .plinth {
            // a statue already on that plinth trades places with the one just dropped
            let was = currentFoot(d.id, t: now)
            for other in VillaScene.statues where other != d.id && owned.contains(other) {
                let op = currentFoot(other, t: now)
                if VillaPlacement.dist(op, spot) < 0.01 {
                    settle[other] = Settle(from: op, at: now)
                    places[other] = was; VillaPlacement.save(other, was)
                }
            }
        }
        if let pet {
            // re-phase the stroll so it starts exactly at the new home, walking on from there
            let base = now * pet.speed + VillaScene.phase(pet.id) + (petShift[pet.id] ?? 0)
            petShift[pet.id] = (petShift[pet.id] ?? 0) - base.truncatingRemainder(dividingBy: 2 * .pi)
        }
        settle[d.id] = Settle(from: d.at, at: now)
        places[d.id] = spot
        VillaPlacement.save(d.id, spot)
        Sfx.play(.thud); Haptics.tap(0.5)
    }

    private func plinthMarks(w: CGFloat, h: CGFloat, near: CGPoint) -> some View {
        let n = VillaPlacement.nearestPlinth(near)
        return ForEach(VillaPlacement.plinths.indices, id: \.self) { i in
            let p = VillaPlacement.plinths[i]
            Ellipse().fill(Fr.marble.opacity(i == n ? 0.9 : 0.45))
                .overlay(Ellipse().stroke(i == n ? Fr.gold : Fr.marbleShade, lineWidth: i == n ? 2.5 : 1.5))
                .frame(width: w * 0.12, height: w * 0.04)
                .position(x: p.x * w, y: p.y * h)
                .zIndex(0.01)
                .allowsHitTesting(false)
        }
    }

    private func sparkleSpot(_ id: String, t: Double) -> CGPoint? {
        if let s = VillaScene.placed.first(where: { $0.item == id }) {
            let p = foot(s.id, home: CGPoint(x: s.x, y: s.y), t: t)
            return CGPoint(x: p.x, y: p.y - s.size * VillaPlacement.canvas.width / VillaPlacement.canvas.height / 2)
        }
        if let pet = VillaScene.petList.first(where: { $0.id == id }) {
            let p = petFoot(pet, t: t).p
            return CGPoint(x: p.x, y: p.y - 0.04)
        }
        switch id {
        case "owl": let p = foot("owl", home: CGPoint(x: 0.22, y: VillaPlacement.roofY), t: t); return CGPoint(x: p.x, y: p.y - 0.03)
        case "eagle": return CGPoint(x: 0.5, y: 0.16)
        case "goldroof": return CGPoint(x: 0.5, y: 0.23)
        case "banners": return CGPoint(x: 0.5, y: 0.38)
        case "roses": return CGPoint(x: 0.5, y: 0.53)
        default: return nil
        }
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
                .overlay(TileLines().stroke(gold ? Color(hex: 0xa87a1f).opacity(0.6) : Fr.tileDeep.opacity(0.55), lineWidth: 1)
                    .clipShape(Trapezoid(inset: 0.06)))
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
                            .scaleEffect(scale(for: "banners"), anchor: .top)
                    }
                }
            }
            if owned.contains("eagle") {
                Text("🦅").font(.system(size: w * 0.08))
                    .colorMultiply(Color(hex: 0xf4c95a))
                    .position(x: w / 2, y: roofTop - h * 0.005)
                    .scaleEffect(scale(for: "eagle"))
            }
            if owned.contains("roses") {
                ForEach([0.27, 0.73], id: \.self) { fx in
                    RoseBed().frame(width: w * 0.22, height: h * 0.05).position(x: w * fx, y: base + h * 0.012)
                        .scaleEffect(scale(for: "roses"), anchor: .bottom)
                }
            }
        }
        .frame(width: w, height: h, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture { loc in
            // the house's own pieces answer a tap too
            let u = CGPoint(x: loc.x / w, y: loc.y / h)
            if owned.contains("eagle"), abs(u.x - 0.5) < 0.08, u.y < 0.22 { onTap("eagle") }
            else if owned.contains("roses"), u.y > 0.5, u.y < 0.58, abs(abs(u.x - 0.5) - 0.23) < 0.11 { onTap("roses") }
            else if owned.contains("banners"), u.y > 0.3, u.y < 0.44, u.x > 0.16, u.x < 0.84 { onTap("banners") }
            else if owned.contains("goldroof"), u.y > 0.16, u.y < 0.3, u.x > 0.13, u.x < 0.87 { onTap("goldroof") }
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

    // MARK: Pets — each strolls to and fro around its own home on the lawn; the owl perches on the roof

    struct Pet { let id: String; let emoji: String; let lane: CGFloat; let speed: Double; let size: CGFloat; let hop: Bool }
    static let petList: [Pet] = [
        .init(id: "dog", emoji: "🐕", lane: 0.92, speed: 0.22, size: 0.085, hop: false),
        .init(id: "cat", emoji: "🐈", lane: 0.80, speed: 0.15, size: 0.07, hop: false),
        .init(id: "goat", emoji: "🐐", lane: 0.70, speed: 0.10, size: 0.08, hop: false),
        .init(id: "rabbit", emoji: "🐇", lane: 0.62, speed: 0.20, size: 0.06, hop: true),
        .init(id: "rooster", emoji: "🐓", lane: 0.86, speed: 0.13, size: 0.065, hop: false),
        .init(id: "tortoise", emoji: "🐢", lane: 0.97, speed: 0.03, size: 0.06, hop: false),
        .init(id: "peacock", emoji: "🦚", lane: 0.75, speed: 0.07, size: 0.10, hop: false),
    ]

    static func phase(_ id: String) -> Double { Double(id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 100) / 16 }

    /// A pet's feet at time t and whether it faces right. It strolls ±0.40 of the width around its home,
    /// less when the home is near an edge (home 0.5 = the full stroll it always had).
    private func petFoot(_ p: Pet, t: Double) -> (p: CGPoint, right: Bool) {
        if let d = drag, d.id == p.id { return (d.at, false) }
        let home = places[p.id] ?? CGPoint(x: 0.5, y: p.lane)
        let amp = max(0, min(0.40, home.x - 0.08, 0.92 - home.x))
        let a = t * p.speed + VillaScene.phase(p.id) + (petShift[p.id] ?? 0)
        let target = CGPoint(x: home.x + amp * CGFloat(sin(a)), y: home.y)
        return (glide(p.id, to: target, t: t), cos(a) > 0)
    }

    private func petView(_ p: Pet, w: CGFloat, h: CGFloat, t: Double) -> some View {
        let (pos, right) = petFoot(p, t: t)
        let up = drag?.id == p.id
        let step = up ? 0 : abs(sin(t * (p.hop ? 6 : 9) + Double(p.lane) * 10))
        let s = p.size * w
        return held(p.id, box: s) {
            Text(p.emoji).font(.system(size: s))
                .scaleEffect(x: right ? -1 : 1, y: 1)         // emoji face left; flip when walking right
                .offset(y: -CGFloat(step) * (p.hop ? w * 0.025 : w * 0.006))
                .background(alignment: .bottom) {
                    Ellipse().fill(.black.opacity(up ? 0 : 0.18)).frame(width: s * 0.8, height: s * 0.18)
                        .offset(y: s * 0.05)
                }
        }
        .scaleEffect(scale(for: p.id), anchor: .bottom)
        .frame(width: max(s * 1.3, 64), height: max(s * 1.3, 64), alignment: .bottom)
        .contentShape(Rectangle())
        .gesture(grab(p.id, zone: .lawn, size: p.size, w: w, h: h))
        .accessibilityElement().accessibilityIdentifier("villa-item-\(p.id)")
        .position(x: pos.x * w, y: pos.y * h - max(s * 1.3, 64) / 2)
        .zIndex(up ? 1000 : pos.y)
    }
}

/// A hit shape: the bottom `height` points of the box.
private struct BottomRect: Shape {
    let height: CGFloat
    func path(in r: CGRect) -> Path { Path(CGRect(x: r.minX, y: r.maxY - min(height, r.height), width: r.width, height: min(height, r.height))) }
}

// MARK: - The countryside — sky, sun, sea, hills, lawn and path, across the whole frame

private struct Countryside: View {
    let fw: CGFloat, fh: CGFloat          // the frame
    let ox: CGFloat, oy: CGFloat          // the canvas origin in it
    let w: CGFloat, h: CGFloat            // the canvas size
    let t: Double

    private func X(_ u: CGFloat) -> CGFloat { ox + u * w }
    private func Y(_ v: CGFloat) -> CGFloat { oy + v * h }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Fr.skyTop, Fr.skyLow], startPoint: .top,
                           endPoint: .init(x: 0.5, y: max(0.05, Y(0.45) / fh)))
            Circle().fill(RadialGradient(colors: [Color(hex: 0xfff4cf), Color(hex: 0xf6d27a).opacity(0.0)],
                                         center: .center, startRadius: w * 0.04, endRadius: w * 0.14))
                .frame(width: w * 0.28, height: w * 0.28).position(x: X(0.84), y: Y(0.11))
            Circle().fill(Color(hex: 0xfff1c4)).frame(width: w * 0.08).position(x: X(0.84), y: Y(0.11))
            // soft clouds drifting across the whole sky
            // (The first layout pass can hand us a zero-size canvas: Int(∞) traps, so guard the ratio.)
            let ratio = w > 0 && fw > 0 ? fw / w : 1
            let clouds = min(12, max(2, Int((ratio * 2).rounded())))
            ForEach(0..<clouds, id: \.self) { i in
                let x = (CGFloat((t * (0.008 + Double(i % 2) * 0.004) / Double(ratio) + Double(i) / Double(clouds)).truncatingRemainder(dividingBy: 1.3)) - 0.15) * fw
                CloudPuff().fill(.white.opacity(0.75))
                    .frame(width: w * (0.22 - CGFloat(i % 2) * 0.05), height: w * 0.07)
                    .position(x: x, y: Y(0.08 + CGFloat(i % 3) * 0.05))
            }
            // sea strip and two ridges of hills
            Rectangle().fill(LinearGradient(colors: [Color(hex: 0x7fb3c4), Color(hex: 0x6aa0b5)], startPoint: .top, endPoint: .bottom))
                .frame(width: fw, height: h * 0.06).position(x: fw / 2, y: Y(0.33))
            Ridge(ox: ox, w: w, top: Y(0.26), depth: h * 0.07, bottom: Y(0.54), seed: 0.4).fill(Fr.hillBack)
            Ridge(ox: ox, w: w, top: Y(0.335), depth: h * 0.06, bottom: Y(0.54), seed: 2.1).fill(Fr.hillFront)
            // lawn, path, tufts
            Rectangle().fill(LinearGradient(colors: [Fr.lawn, Fr.lawnDeep], startPoint: .top, endPoint: .bottom))
                .frame(width: fw, height: max(0, fh - Y(0.53))).position(x: fw / 2, y: (Y(0.53) + fh) / 2)
            Walk(top: Y(0.53), bottom: Y(1.0), cx: X(0.5), topHalf: w * 0.06, bottomHalf: w * 0.22)
                .fill(LinearGradient(colors: [Fr.path, Color(hex: 0xc4a978)], startPoint: .top, endPoint: .bottom))
            tufts
        }
        .frame(width: fw, height: fh)
    }

    /// Grass tufts scattered over the lawn (the canvas's own fourteen, plus more on any extra lawn).
    private var tufts: some View {
        let w = max(self.w, 1), h = max(self.h, 1)
        let u0 = -ox / w, u1 = 1 + ox / w, v1 = (fh - oy) / h
        let spots: [CGPoint] = (0..<60).compactMap { i in
            let fx = CGFloat((i * 37) % 100) / 100, fy = CGFloat((i * 53) % 40) / 100
            let u: CGFloat = i < 14 ? fx : u0 + (u1 - u0) * fx
            let v: CGFloat = i < 14 ? 0.6 + fy : 0.6 + (v1 - 0.6) * fy / 0.4
            let inside = u >= 0 && u <= 1 && v <= 1
            if i >= 14 && inside { return nil }          // the canvas keeps its own fourteen
            let half = 0.06 + 0.16 * (v - 0.53) / 0.47   // keep off the path
            return abs(u - 0.5) > half + 0.04 ? CGPoint(x: u, y: v) : nil
        }
        return ForEach(spots.indices, id: \.self) { i in
            Text("‿").font(.system(size: w * 0.04, weight: .bold)).foregroundStyle(Fr.leafDark.opacity(0.35))
                .position(x: X(spots[i].x), y: Y(spots[i].y))
        }
    }
}

/// A rolling hill line defined in canvas units, so it runs on seamlessly past the canvas edges.
private struct Ridge: Shape {
    let ox: CGFloat, w: CGFloat, top: CGFloat, depth: CGFloat, bottom: CGFloat, seed: Double
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: bottom))
        var x = r.minX
        while x <= r.maxX + 4 {
            let u = Double((x - ox) / w)
            let k = 0.5 + 0.3 * sin(u * 9.1 + seed) + 0.2 * sin(u * 17.3 + seed * 2.7)
            p.addLine(to: CGPoint(x: x, y: top + depth * CGFloat(k)))
            x += 4
        }
        p.addLine(to: CGPoint(x: r.maxX + 4, y: bottom))
        p.closeSubpath()
        return p
    }
}

/// The garden walk: from the door it widens toward the viewer, carrying on past the canvas bottom.
private struct Walk: Shape {
    let top: CGFloat, bottom: CGFloat, cx: CGFloat, topHalf: CGFloat, bottomHalf: CGFloat
    func path(in r: CGRect) -> Path {
        let slope = (bottomHalf - topHalf) / max(1, bottom - top)
        let end = max(r.maxY, bottom), half = topHalf + slope * (end - top)
        var p = Path()
        p.move(to: CGPoint(x: cx - topHalf, y: top)); p.addLine(to: CGPoint(x: cx + topHalf, y: top))
        p.addLine(to: CGPoint(x: cx + half, y: end)); p.addLine(to: CGPoint(x: cx - half, y: end))
        p.closeSubpath()
        return p
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
