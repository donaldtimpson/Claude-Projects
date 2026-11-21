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
                        // The scene takes whatever the shop strip leaves (up to a little taller than wide).
                        scene.frame(maxHeight: w * 1.2).padding(.horizontal, 10)
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
                    WingPreview(wing: wing)
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
                // locked wings keep their subject's icon (so the chip still says which world), with a small lock
                Image(systemName: icon).font(.system(size: 12, weight: .bold))
                    .overlay(alignment: .bottomTrailing) {
                        if state == .locked {
                            Image(systemName: "lock.fill").font(.system(size: 8, weight: .black))
                                .foregroundStyle(Fr.gold).offset(x: 5, y: 4)
                        }
                    }
                Text(name.uppercased()).font(luCinzel(11, bold: true)).tracking(0.4).lineLimit(1)
                if state == .buildable && !on && denarii >= LudusEconomy.nextWingCost {
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
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(ludusRank() + "'s house").font(luGaramond(13, semibold: true)).foregroundStyle(Fr.gold)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .layoutPriority(-1)
            Spacer()
            purse(img: "CoinSilver", value: denarii)
            purse(img: "CoinGold", value: aurei)
            prizesButton
        }
        .padding(.horizontal, 14).padding(.top, 8).padding(.bottom, 8)
    }

    /// The prize board, always one tap away (a badge counts prizes waiting for a grown-up).
    private var prizesButton: some View {
        let waiting = PrizeBook.shared.pending.count
        return Button {
            Sfx.play(.tick)
            withAnimation(.easeOut(duration: 0.2)) { place = place == .prizes ? .garden : .prizes; note = nil }
        } label: {
            Image(systemName: "gift.fill").font(.system(size: 17, weight: .bold))
                .foregroundStyle(place == .prizes ? Fr.frameDeep : Fr.gold)
                .frame(width: 38, height: 38)
                .background(Circle().fill(place == .prizes ? Fr.gold : Fr.frame)
                    .overlay(Circle().stroke(Fr.gold.opacity(0.7), lineWidth: 1)))
                .overlay(alignment: .topTrailing) {
                    if waiting > 0 {
                        Text("\(waiting)").font(.system(size: 11, weight: .heavy)).foregroundStyle(.white)
                            .frame(minWidth: 17, minHeight: 17).background(Circle().fill(Color(hex: 0xc0392b)))
                            .offset(x: 4, y: -4)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Prizes")
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
            case .build(let wing): buildPanel(wing).frame(height: 214)
            case .prizes: PrizeList(refresh: $refresh, note: $note).frame(height: 214)
            }
        }
        .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 6)
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
        let afford = denarii >= cost
        return VStack(spacing: 10) {
            Text(wing.name.uppercased()).font(luCinzel(17, bold: true)).tracking(1).foregroundStyle(Fr.ink)
            Text(wing.blurb).font(luGaramond(15, semibold: true)).foregroundStyle(Fr.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            if unlocked {
                Button { build(wing) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer.fill").font(.system(size: 15, weight: .bold))
                        Text("BUILD IT").font(luCinzel(15, bold: true)).tracking(1)
                        Image("CoinSilver").resizable().frame(width: 20, height: 20)
                        Text("\(cost)").font(luCinzel(16)).monospacedDigit().fixedSize()
                    }
                    .foregroundStyle(afford ? Fr.parchment : Fr.ink.opacity(0.45))
                    .padding(.horizontal, 22).frame(height: 46)
                    .background(Capsule().fill(afford ? Fr.frame : Color(hex: 0xd6c39b)))
                    .overlay(Capsule().stroke(Fr.gold.opacity(afford ? 0.9 : 0.4), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .offset(x: shake == wing.ownedID ? -6 : 0)
                Text(note ?? (afford ? "Every wing you build makes the next one cost a little more." :
                              "You need \(cost - denarii) more silver denarii. Every right answer earns one!"))
                    .font(luGaramond(14, semibold: true)).foregroundStyle(Fr.ink.opacity(0.7)).multilineTextAlignment(.center)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").foregroundStyle(Fr.frame)
                    Text("Win a laurel at \(wing.landmark) to build it.")
                        .font(luGaramond(16, semibold: true)).foregroundStyle(Fr.ink)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.4)))
                Text("Reach Gradus III in any of its games to win a laurel.")
                    .font(luGaramond(14, semibold: true)).foregroundStyle(Fr.ink.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
    }

    private func build(_ wing: VillaWing) {
        if LudusEconomy.build(wing) {
            if goal == wing.ownedID { LudusEconomy.goal = nil; goal = nil }
            Sfx.play(.coin); Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { Sfx.play(.sparkle) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { refresh += 1 }
            note = "\(wing.name) is built! Now fill it with things."
        } else {
            Sfx.play(.wrong); Haptics.error()
            if LudusEconomy.wingUnlocked(wing) { setGoal(wing.ownedID, name: wing.name) }
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
        if place != .garden { return "Tap a thing to buy it — or to start saving for it." }
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
                        Text("\(item.price.amount)").font(luCinzel(14)).monospacedDigit().fixedSize()
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
    }

    private let rowCardHeight: CGFloat = 80

    private func thumb(_ item: VillaItem) -> AnyView { wingThumb(item) ?? AnyView(VillaThumb(id: item.id)) }

    // MARK: Saving for something — tapping a thing the child can't afford yet makes it the goal (shown on
    // its card, in the note, and after every game). A long-press was invisible and collided with the tap.

    private func goalRibbon(_ item: VillaItem) -> some View {
        Text("SAVING").font(luCinzel(9, bold: true)).tracking(0.8).foregroundStyle(Fr.frameDeep)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(Fr.gold))
            .opacity(goal == item.id && !owned.contains(item.id) ? 1 : 0)
    }

    private func setGoal(_ id: String, name: String) {
        LudusEconomy.goal = id
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { goal = id }
        if let line = LudusEconomy.goalLine { note = "Saving for \(name)! " + line + "." }
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
                            Text("\(item.price.amount)").font(luCinzel(13.5)).monospacedDigit().fixedSize()
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
            setGoal(item.id, name: item.name)
            if item.price.gold { note = (note ?? "") + " Gold comes from new laurels in the games." }
            withAnimation(.linear(duration: 0.05).repeatCount(5, autoreverses: true)) { shake = item.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = nil }
        }
    }
}

/// Catalog items the child can drag around the scene (the rest belong to the house).
private let villaMovable: Set<String> = Set(gardenCatalog.map(\.id)).subtracting(["roses", "banners", "goldroof", "eagle"])

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
                        house(w: w, h: h, t: t)
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
        .init(id: "bust", item: "bust", x: 0.33, y: 0.67, size: 0.15, zone: .plinth),
        .init(id: "minerva", item: "minerva", x: 0.67, y: 0.67, size: 0.20, zone: .plinth),
        .init(id: "fountain", item: "fountain", x: 0.50, y: 0.76, size: 0.26, zone: .lawn, hit: 0.75),
        .init(id: "birdbath", item: "birdbath", x: 0.255, y: 0.81, size: 0.12, zone: .lawn),
        .init(id: "sundial", item: "sundial", x: 0.70, y: 0.87, size: 0.13, zone: .plinth),
        .init(id: "pond", item: "pond", x: 0.19, y: 0.97, size: 0.30, zone: .lawn, hit: 0.45),
        .init(id: "chariot", item: "chariot", x: 0.13, y: 0.76, size: 0.23, zone: .lawn, hit: 0.7),
        .init(id: "elephant", item: "elephant", x: 0.875, y: 1.0, size: 0.26, zone: .lawn, hit: 0.8),
        .init(id: "arbor", item: "arbor", x: 0.50, y: 1.03, size: 0.32, zone: .lawn, hit: 0.8),
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
                held("owl", box: w * 0.085) {
                    LittleOwl(blink: blink, t: t).frame(width: w * 0.085, height: w * 0.085)
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
        // pets keep out from behind big things: when one moves, they glide to their new strolls
        var petsWere: [String: CGPoint] = [:]
        if pet == nil {
            for p in VillaScene.petList where owned.contains(p.id) { petsWere[p.id] = petFoot(p, t: now).p }
        }
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
        for (id, was) in petsWere { settle[id] = Settle(from: was, at: now) }
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

    private func house(w: CGFloat, h: CGFloat, t: Double) -> some View {
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
            TiledRoof(gold: gold, t: t)
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
                Aquila(t: t).frame(width: w * 0.15, height: w * 0.15)
                    .scaleEffect(scale(for: "eagle"), anchor: .bottom)
                    .position(x: w / 2, y: roofTop + h * 0.012 - w * 0.075)
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
            if owned.contains("eagle"), abs(u.x - 0.5) < 0.09, u.y < 0.19 { onTap("eagle") }
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
        case "bust": RomanBust()
        case "minerva": MinervaStatue()
        case "fountain": Fountain(t: t)
        case "birdbath": BirdBath(t: t)
        case "sundial": Sundial()
        case "pond": Pond(t: t)
        case "chariot": Chariot()
        case "elephant": Elephant(t: t)
        case "arbor": Arbor()
        default: EmptyView()
        }
    }

    // MARK: Pets — each strolls to and fro around its own home on the lawn; the owl perches on the roof

    struct Pet { let id: String; let home: CGPoint; let speed: Double; let size: CGFloat; let hop: Bool }
    static let petList: [Pet] = [
        .init(id: "dog", home: CGPoint(x: 0.56, y: 0.975), speed: 0.22, size: 0.095, hop: false),
        .init(id: "cat", home: CGPoint(x: 0.74, y: 0.70), speed: 0.15, size: 0.075, hop: false),
        .init(id: "goat", home: CGPoint(x: 0.22, y: 0.83), speed: 0.10, size: 0.095, hop: false),
        .init(id: "rabbit", home: CGPoint(x: 0.48, y: 0.63), speed: 0.20, size: 0.065, hop: true),
        .init(id: "rooster", home: CGPoint(x: 0.13, y: 0.845), speed: 0.13, size: 0.075, hop: false),
        .init(id: "tortoise", home: CGPoint(x: 0.3, y: 0.985), speed: 0.03, size: 0.07, hop: false),
        .init(id: "peacock", home: CGPoint(x: 0.76, y: 0.785), speed: 0.07, size: 0.12, hop: false),
    ]

    static func phase(_ id: String) -> Double { Double(id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 100) / 16 }

    /// The solid, ground-hugging part of each big thing, as fractions of its box: its width, and the band of
    /// height above its feet (lo…hi) where a pet's feet would look buried in it or lost behind it.
    static let solid: [String: (w: CGFloat, lo: CGFloat, hi: CGFloat)] = [
        "elephant": (0.92, 0, 0.8), "chariot": (0.85, 0, 0.62), "fountain": (0.95, 0, 0.42),
        "minerva": (0.75, 0, 0.9), "bust": (0.5, 0, 0.9), "sundial": (0.45, 0, 0.7), "birdbath": (0.5, 0, 0.6),
        "pond": (0.95, -0.12, 0.42), "arbor": (0.95, 0.25, 0.8), "olive": (0.2, 0, 0.45), "lemon": (0.2, 0, 0.45),
    ]

    /// Where a pet may stroll along its line: the stretch around its home that no big thing hides — and the
    /// home itself, moved aside (or out in front) when it has ended up somewhere hidden.
    private func petRange(_ p: Pet, home h0: CGPoint) -> (home: CGPoint, lo: CGFloat, hi: CGFloat) {
        let ratio = VillaPlacement.canvas.width / VillaPlacement.canvas.height
        var home = h0
        for _ in 0..<4 {
            var lo: CGFloat = 0.08, hi: CGFloat = 0.92
            var hit: (l: CGFloat, r: CGFloat, foot: CGFloat)?
            for s in VillaScene.placed where owned.contains(s.item) {
                guard let k = VillaScene.solid[s.item] else { continue }
                let f = places[s.id] ?? CGPoint(x: s.x, y: s.y)
                let bh = s.size * ratio
                guard home.y < f.y - k.lo * bh + 0.005, home.y > f.y - k.hi * bh else { continue }
                let half = s.size * k.w / 2 + p.size * 0.45
                let l = f.x - half, r = f.x + half
                if home.x > l && home.x < r { hit = (l, r, f.y) }
                else if r <= home.x { lo = max(lo, r) } else { hi = min(hi, l) }
            }
            guard let b = hit else { return (home, max(lo, home.x - 0.4), min(hi, home.x + 0.4)) }
            // hidden: step aside to the nearer open side, or (no room) walk just in front of it
            let left = b.l - 0.005, right = b.r + 0.005
            if left >= 0.08 && (home.x - left <= right - home.x || right > 0.92) { home.x = left }
            else if right <= 0.92 { home.x = right }
            else { home.y = min(VillaPlacement.petBottom, b.foot + 0.012) }
        }
        return (home, home.x, home.x)
    }

    /// A pet's feet at time t, whether it faces right, and how briskly it is walking (0…1).
    private func petFoot(_ p: Pet, t: Double) -> (p: CGPoint, right: Bool, pace: Double) {
        if let d = drag, d.id == p.id { return (d.at, false, 0) }
        let r = petRange(p, home: places[p.id] ?? p.home)
        let c = (r.lo + r.hi) / 2, amp = max(0, (r.hi - r.lo) / 2)
        // phased so the stroll passes through home just as a drop re-phases the clock
        let off = amp > 0.001 ? asin(Double(min(1, max(-1, (r.home.x - c) / amp)))) : 0
        let a = t * p.speed + VillaScene.phase(p.id) + (petShift[p.id] ?? 0) + off
        let target = CGPoint(x: c + amp * CGFloat(sin(a)), y: r.home.y)
        let pace = amp > 0.01 ? min(1, abs(cos(a)) * 3) : 0
        return (glide(p.id, to: target, t: t), cos(a) > 0 && amp > 0.01, pace)
    }

    private func petView(_ p: Pet, w: CGFloat, h: CGFloat, t: Double) -> some View {
        let (pos, right, pace) = petFoot(p, t: t)
        let up = drag?.id == p.id
        let ph = t * (p.hop ? 6 : 9) + VillaScene.phase(p.id) * 3
        let bob = up ? 0 : abs(sin(ph)) * pace
        let s = p.size * w
        return held(p.id, box: s) {
            PetArt(id: p.id, step: up ? 0 : sin(ph) * pace, t: t)
                .frame(width: s, height: s)
                .scaleEffect(x: right ? -1 : 1, y: 1)         // drawn facing left; flip when walking right
                .offset(y: -CGFloat(bob) * (p.hop ? w * 0.025 : w * 0.004))
                .background(alignment: .bottom) {
                    Ellipse().fill(.black.opacity(up ? 0 : 0.16)).frame(width: s * 0.7, height: s * 0.12)
                        .offset(y: s * 0.03)
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
                case "cypress": HStack(spacing: -w * 0.3) { Cypress(); Cypress() }
                case "banners": HStack(spacing: 6) { ForEach(0..<3, id: \.self) { _ in Banner().fill(Color(hex: 0xb8322a)).overlay(Banner().stroke(Fr.gold, lineWidth: 1)) } }.padding(.horizontal, 8).padding(.vertical, 6)
                case "olive": FruitTree(fruit: Color(hex: 0x3b3f22), canopy: Color(hex: 0x7f9a63))
                case "lemon": FruitTree(fruit: Color(hex: 0xf3d43c), canopy: Fr.leaf)
                case "arbor": Arbor()
                case "birdbath": BirdBath(t: 0).padding(.horizontal, w * 0.2)
                case "pond": Pond(t: 0)
                case "fountain": Fountain(t: 0)
                case "sundial": Sundial().padding(.horizontal, w * 0.15)
                case "goldroof":
                    TiledRoof(gold: true, t: 1.2)
                        .overlay(alignment: .bottom) {
                            Triangle().fill(Fr.marble).overlay(Triangle().stroke(Fr.marbleShade, lineWidth: 1.2))
                                .frame(width: w * 0.42, height: w * 0.16)
                        }
                        .frame(width: w * 0.92, height: w * 0.42).padding(.bottom, w * 0.06)
                default:
                    // the drawn pieces share one square framing, feet near the card's bottom
                    let side = min(w, g.size.height) * 0.96
                    thumbArt.frame(width: side, height: side).padding(.bottom, g.size.height * 0.02)
                }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
        }
        .clipped()
    }

    @ViewBuilder private var thumbArt: some View {
        switch id {
        case "bust": RomanBust()
        case "minerva": MinervaStatue()
        case "eagle": Aquila(t: 0)
        case "elephant": Elephant(t: 0)
        case "chariot": Chariot()
        case "owl": LittleOwl(blink: false, t: 0)
        default: PetArt(id: id, step: 0, t: 0)
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

/// A slim Italian cypress: a dark green flame, lit on its left, with scalloped sprays.
private struct Cypress: View {
    var body: some View {
        let flame: (inout Path) -> Void = { p in
            p.move(to: coPt(0.5, 0.02))
            p.addCurve(to: coPt(0.36, 0.62), control1: coPt(0.44, 0.15), control2: coPt(0.34, 0.4))
            p.addQuadCurve(to: coPt(0.5, 0.93), control: coPt(0.38, 0.88))
            p.addQuadCurve(to: coPt(0.64, 0.62), control: coPt(0.62, 0.88))
            p.addCurve(to: coPt(0.5, 0.02), control1: coPt(0.66, 0.4), control2: coPt(0.56, 0.15))
            p.closeSubpath()
        }
        return ZStack {
            GPath { $0.coBox(0.48, 0.88, 0.04, 0.12) }.fill(Fr.trunk)
            GPath(flame).fill(LinearGradient(colors: [Color(hex: 0x5d8a44), Fr.leaf, Fr.leafDark], startPoint: .leading, endPoint: .trailing))
            GPath { p in
                for i in 0..<9 {
                    let y = 0.14 + CGFloat(i) * 0.085
                    let half = 0.03 + 0.1 * sin(.pi * min(1, (y - 0.02) / 0.75))
                    p.coQuad(coPt(0.5 - half * 0.7, y), coPt(0.5 - half * 0.2, y + 0.03), coPt(0.5 + half * 0.1, y - 0.005), 0.009)
                    p.coQuad(coPt(0.5 + half * 0.15, y + 0.04), coPt(0.5 + half * 0.5, y + 0.07), coPt(0.5 + half * 0.8, y + 0.035), 0.009)
                }
            }.fill(Fr.leafDark.opacity(0.7))
        }
    }
}

/// A fruit tree (olive or lemon): a forked trunk under a rounded canopy of leaf clusters, fruit among them.
private struct FruitTree: View {
    let fruit: Color, canopy: Color
    private var olive: Bool { fruit != Color(hex: 0xf3d43c) }
    private static let blobs: [(CGFloat, CGFloat, CGFloat)] = [
        (0.3, 0.36, 0.16), (0.5, 0.26, 0.19), (0.7, 0.36, 0.16), (0.38, 0.47, 0.15), (0.62, 0.48, 0.15),
        (0.5, 0.42, 0.17), (0.2, 0.47, 0.11), (0.8, 0.47, 0.11),
    ]
    private static let fruits: [(CGFloat, CGFloat)] = [
        (0.28, 0.4), (0.42, 0.3), (0.58, 0.25), (0.7, 0.38), (0.36, 0.52), (0.52, 0.47), (0.66, 0.53), (0.22, 0.5), (0.8, 0.49), (0.47, 0.36),
    ]
    var body: some View {
        let dark = olive ? Color(hex: 0x5f7a48) : Fr.leafDark
        let hi = olive ? Color(hex: 0xb4c497) : Color(hex: 0x7fa65a)
        ZStack {
            GPath { $0.coOval(0.28, 0.965, 0.44, 0.035) }.fill(COC.shadow)
            GPath { p in      // trunk forking into two limbs
                p.move(to: coPt(0.45, 1.0)); p.addQuadCurve(to: coPt(0.47, 0.6), control: coPt(0.48, 0.8))
                p.addLine(to: coPt(0.36, 0.44)); p.addLine(to: coPt(0.4, 0.42)); p.addLine(to: coPt(0.5, 0.56))
                p.addLine(to: coPt(0.62, 0.42)); p.addLine(to: coPt(0.66, 0.44)); p.addLine(to: coPt(0.53, 0.62))
                p.addQuadCurve(to: coPt(0.56, 1.0), control: coPt(0.52, 0.8)); p.closeSubpath()
            }.fill(LinearGradient(colors: [Color(hex: 0x8a6440), Fr.trunk], startPoint: .leading, endPoint: .trailing))
            GPath { p in for b in Self.blobs { p.coDot(b.0, b.1 + 0.02, b.2, b.2 * 0.9) } }.fill(dark)
            GPath { p in for b in Self.blobs { p.coDot(b.0 - 0.01, b.1 - 0.005, b.2 * 0.85, b.2 * 0.75) } }.fill(canopy)
            GPath { p in for b in Self.blobs { p.coDot(b.0 - 0.03, b.1 - 0.035, b.2 * 0.4, b.2 * 0.3) } }.fill(hi)
            GPath { p in for f in Self.fruits { p.gLeaf(f.0, f.1, olive ? 0.022 : 0.032, olive ? 0.016 : 0.024, -20) } }.fill(fruit)
            GPath { p in for f in Self.fruits { p.coDot(f.0 - 0.008, f.1 - 0.007, 0.006) } }.fill(Color.white.opacity(olive ? 0.35 : 0.6))
        }
    }
}

private struct MinervaStatue: View {
    var body: some View {
        let deep = GA.marbleDeep, carve = GA.carve
        ZStack {
            GPath { $0.coOval(0.2, 0.955, 0.6, 0.045) }.fill(COC.shadow)
            // plinth
            GPath { p in p.coBox(0.26, 0.93, 0.48, 0.065, r: 0.01); p.coBox(0.29, 0.83, 0.42, 0.03, r: 0.006) }.fill(Fr.marbleShade)
            GPath { p in p.coBox(0.31, 0.855, 0.38, 0.08) }.fill(COC.marbleFill)
            // the spear, held upright
            GPath { p in p.coLine([coPt(0.665, 0.1), coPt(0.665, 0.84)], 0.018); p.coPoly([coPt(0.645, 0.11), coPt(0.665, 0.03), coPt(0.685, 0.11)]) }.fill(deep)
            // peplos: a long gown flaring to the hem, an overfold belted at the waist
            GPath { p in
                p.move(to: coPt(0.43, 0.31)); p.addLine(to: coPt(0.57, 0.31))
                p.addQuadCurve(to: coPt(0.63, 0.835), control: coPt(0.6, 0.6))
                p.addLine(to: coPt(0.37, 0.835))
                p.addQuadCurve(to: coPt(0.43, 0.31), control: coPt(0.4, 0.6))
                p.closeSubpath()
            }.fill(COC.marbleFill)
            GPath { p in
                for (x0, x1) in [(0.45, 0.42), (0.5, 0.5), (0.55, 0.58), (0.475, 0.46), (0.525, 0.54)] as [(CGFloat, CGFloat)] {
                    p.coLine([coPt(x0, 0.56), coPt(x1, 0.83)], 0.008)
                }
                p.coQuad(coPt(0.41, 0.5), coPt(0.5, 0.53), coPt(0.59, 0.5), 0.012)     // the overfold's edge
                p.coLine([coPt(0.43, 0.44), coPt(0.57, 0.44)], 0.014)                  // belt
            }.fill(carve)
            // the aegis, a short cape over the shoulders
            GPath { p in
                p.move(to: coPt(0.4, 0.33)); p.addQuadCurve(to: coPt(0.6, 0.33), control: coPt(0.5, 0.29))
                p.addQuadCurve(to: coPt(0.5, 0.42), control: coPt(0.6, 0.4)); p.addQuadCurve(to: coPt(0.4, 0.33), control: coPt(0.4, 0.4))
                p.closeSubpath()
            }.fill(Fr.marbleShade)
            GPath { $0.coDot(0.5, 0.37, 0.018) }.fill(deep)
            // arms: the right raised to the spear, the left down to the shield's rim
            GPath { p in
                p.coLine([coPt(0.58, 0.34), coPt(0.64, 0.27), coPt(0.665, 0.25)], 0.04)
                p.coLine([coPt(0.42, 0.34), coPt(0.39, 0.46), coPt(0.37, 0.55)], 0.038)
            }.fill(COC.marbleFill)
            // head, neck and the Corinthian helmet pushed up, its crest sweeping back
            GPath { $0.coBox(0.475, 0.255, 0.05, 0.06) }.fill(Fr.marbleShade)
            GPath { $0.coOval(0.445, 0.155, 0.11, 0.12) }.fill(COC.marbleFill)
            GPath { p in
                p.move(to: coPt(0.44, 0.2)); p.addQuadCurve(to: coPt(0.56, 0.2), control: coPt(0.5, 0.11))
                p.addLine(to: coPt(0.565, 0.22)); p.addQuadCurve(to: coPt(0.435, 0.22), control: coPt(0.5, 0.17)); p.closeSubpath()
            }.fill(Fr.marbleShade)
            GPath { p in
                p.move(to: coPt(0.45, 0.17)); p.addQuadCurve(to: coPt(0.62, 0.2), control: coPt(0.52, 0.04))
                p.addQuadCurve(to: coPt(0.55, 0.19), control: coPt(0.6, 0.13)); p.addQuadCurve(to: coPt(0.45, 0.17), control: coPt(0.5, 0.12))
                p.closeSubpath()
            }.fill(deep)
            GPath { p in
                p.coLine([coPt(0.475, 0.228), coPt(0.495, 0.228)], 0.007); p.coLine([coPt(0.51, 0.228), coPt(0.53, 0.228)], 0.007)
                p.coLine([coPt(0.5, 0.235), coPt(0.497, 0.252)], 0.006); p.coLine([coPt(0.49, 0.262), coPt(0.51, 0.262)], 0.006)
            }.fill(carve)
            // the shield, standing on its rim beside her
            GPath { $0.coDot(0.33, 0.68, 0.14, 0.15) }.fill(COC.marbleFill)
            GPath { p in
                p.coRing(0.33, 0.68, 0.125, 0.135, 0.016)
                p.coRing(0.33, 0.68, 0.06, 0.065, 0.01)
                p.gStar(0.33, 0.68, 0.035)
            }.fill(deep)
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
                Sparrow().frame(width: w * 0.32, height: w * 0.32)
                    .offset(x: w * 0.22, y: -h * (0.56 + (sin(t * 2) > 0.7 ? 0.04 : 0)))
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
                WaterLily().frame(width: w * 0.16, height: w * 0.16).offset(x: -w * 0.2, y: -h * 0.03)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}

/// A pergola of grapevines: two posts on stone footings, a beam with rafter ends, a leafy canopy with
/// bunches of grapes, and vines twining up the posts.
private struct Arbor: View {
    var body: some View {
        let wood = vgrad(COC.woodLt, COC.wood)
        let leaves: [(CGFloat, CGFloat, CGFloat)] = [
            (0.06, 0.36, 0.08), (0.15, 0.3, 0.09), (0.25, 0.35, 0.08), (0.34, 0.29, 0.09), (0.44, 0.34, 0.085),
            (0.53, 0.28, 0.09), (0.62, 0.34, 0.085), (0.71, 0.29, 0.09), (0.8, 0.35, 0.08), (0.89, 0.3, 0.085), (0.95, 0.37, 0.07),
        ]
        ZStack {
            // posts on footings, the beam and its rafter ends
            GPath { p in p.coBox(0.06, 0.36, 0.05, 0.62, r: 0.01); p.coBox(0.89, 0.36, 0.05, 0.62, r: 0.01) }.fill(wood)
            GPath { p in p.coBox(0.045, 0.955, 0.08, 0.045, r: 0.008); p.coBox(0.875, 0.955, 0.08, 0.045, r: 0.008) }.fill(Fr.marbleShade)
            GPath { p in p.coBox(0.0, 0.36, 1.0, 0.045, r: 0.01) }.fill(wood)
            GPath { p in for i in 0..<7 { p.coBox(0.04 + CGFloat(i) * 0.15, 0.335, 0.035, 0.03, r: 0.006) } }.fill(COC.woodDk)
            // vines twining up the posts, with a few leaves
            GPath { p in
                for x in [0.085, 0.915] as [CGFloat] {
                    p.coCurve(coPt(x, 0.97), coPt(x - 0.05, 0.8), coPt(x + 0.05, 0.62), coPt(x, 0.42), 0.014)
                }
            }.fill(Color(hex: 0x5e4a2a))
            GPath { p in
                for x in [0.085, 0.915] as [CGFloat] {
                    for (dy, dx, deg) in [(0.86, -0.035, -30.0), (0.74, 0.035, 30.0), (0.62, -0.03, -25.0), (0.52, 0.03, 25.0)] as [(CGFloat, CGFloat, Double)] {
                        p.gLeaf(x + dx, dy, 0.03, 0.02, CGFloat(deg))
                    }
                }
            }.fill(Fr.leaf)
            // the canopy: overlapping vine leaves in three greens
            GPath { p in for l in leaves { p.coDot(l.0, l.1 - 0.02, l.2, l.2 * 0.8) } }.fill(Fr.leafDark)
            GPath { p in for l in leaves { p.coDot(l.0 + 0.012, l.1 - 0.035, l.2 * 0.75, l.2 * 0.6) } }.fill(Fr.leaf)
            GPath { p in for l in leaves { p.coDot(l.0 + 0.02, l.1 - 0.05, l.2 * 0.35, l.2 * 0.28) } }.fill(Color(hex: 0x7fa65a))
            // bunches of grapes hanging under the leaves
            GPath { p in
                for cx in [0.2, 0.4, 0.6, 0.8] as [CGFloat] {
                    for (dx, dy) in [(-0.03, 0.0), (0.0, 0.0), (0.03, 0.0), (-0.015, 0.03), (0.015, 0.03), (0.0, 0.06), (-0.03, 0.03) , (0.03, 0.03)] as [(CGFloat, CGFloat)] {
                        p.coDot(cx + dx, 0.41 + dy + (dx == 0 && dy == 0.06 ? 0.005 : 0), 0.019)
                    }
                }
            }.fill(vgrad(Color(hex: 0x86509b), Color(hex: 0x4e2a63)))
            GPath { p in for cx in [0.2, 0.4, 0.6, 0.8] as [CGFloat] { p.coDot(cx - 0.035, 0.405, 0.006); p.coDot(cx - 0.005, 0.405, 0.006) } }.fill(Color.white.opacity(0.5))
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

// MARK: - The garden's statues, grand works and animals
//
// Drawn in a unit square (feet at y = 1) with the unit-space kit (COPath and the `co…` path helpers in
// Villa/WingCountingArt.swift), so a piece is the same drawing on the lawn and on its shop card.
// Animals face LEFT (the scene flips them when they walk right); `step` (-1…1) swings their legs.

/// A path drawn in unit space (feet at y = 1), scaled into the bottom-centred square of its frame —
/// COPath's rule. A zero-size extra subpath keeps SwiftUI from treating a lone oval or box as a
/// primitive, which (scaled and gradient-filled) it can draw in the wrong place.
private struct GPath: Shape {
    let make: (inout Path) -> Void
    init(_ make: @escaping (inout Path) -> Void) { self.make = make }
    func path(in r: CGRect) -> Path {
        var p = Path()
        make(&p)
        p.addRect(.zero)
        let s = min(r.width, r.height)
        return p.applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: r.midX - s / 2, ty: r.maxY - s))
    }
}

private extension Path {
    /// An oval centred at (cx, cy) with radii (rx, ry), turned `deg` degrees.
    mutating func gLeaf(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ deg: CGFloat) {
        let q = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
        addPath(q, transform: CGAffineTransform(translationX: cx, y: cy).rotated(by: deg * .pi / 180))
    }
    /// A leg hanging from a hip at (hx, hy), `len` long and `w` wide, swung `deg` degrees (+ = foot forward,
    /// i.e. to the left); `from` leaves out its top part (for hooves and paws).
    mutating func gLimb(_ hx: CGFloat, _ hy: CGFloat, _ len: CGFloat, _ w: CGFloat, _ deg: CGFloat, from: CGFloat = 0) {
        let q = Path(roundedRect: CGRect(x: -w / 2, y: from, width: w, height: len - from), cornerRadius: w * 0.45)
        addPath(q, transform: CGAffineTransform(translationX: hx, y: hy).rotated(by: deg * .pi / 180))
    }
    /// A leg (see gLimb) ending in a paw pointing forward.
    mutating func gLeg(_ hx: CGFloat, _ hy: CGFloat, _ len: CGFloat, _ w: CGFloat, _ deg: CGFloat, paw: CGFloat) {
        gLimb(hx, hy, len, w, deg)
        let a = deg * .pi / 180
        let fx = hx - (len - paw * 0.4) * sin(a), fy = hy + (len - paw * 0.4) * cos(a)
        addEllipse(in: CGRect(x: fx - paw * 1.3, y: fy - paw * 0.5, width: paw * 2, height: paw))
    }
    /// The outline of `q`, `lw` wide.
    mutating func gEdge(_ q: Path, _ lw: CGFloat) {
        addPath(q.strokedPath(StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)))
    }
    /// A four-point twinkle at (cx, cy).
    mutating func gStar(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        let b = r * 0.16
        move(to: CGPoint(x: cx, y: cy - r))
        addQuadCurve(to: CGPoint(x: cx + r, y: cy), control: CGPoint(x: cx + b, y: cy - b))
        addQuadCurve(to: CGPoint(x: cx, y: cy + r), control: CGPoint(x: cx + b, y: cy + b))
        addQuadCurve(to: CGPoint(x: cx - r, y: cy), control: CGPoint(x: cx - b, y: cy + b))
        addQuadCurve(to: CGPoint(x: cx, y: cy - r), control: CGPoint(x: cx - b, y: cy - b))
        closeSubpath()
    }
}

private let flipX = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 1, ty: 0)
private func vgrad(_ c: Color...) -> LinearGradient { LinearGradient(colors: c, startPoint: .top, endPoint: .bottom) }

private enum GA {
    static let goldHi = Color(hex: 0xfde7a0), goldMid = Color(hex: 0xe5b24a), goldDeep = Color(hex: 0xa8741f)
    static let goldLine = Color(hex: 0x76500f)
    static var gold: LinearGradient { vgrad(goldHi, goldMid, goldDeep) }
    static let carve = Color(hex: 0x9d937e)          // incised lines in marble
    static let marbleDeep = Color(hex: 0xa59c88)
}

// MARK: Roof

/// The villa's tiled roof: pan tiles under rows of round cover tiles (imbrices) running down the slope,
/// a ridge along the top and antefixes along the eave. Gilded, it glints as the light sweeps across.
private struct TiledRoof: View {
    let gold: Bool
    let t: Double
    var body: some View {
        let base = gold ? vgrad(Color(hex: 0xf3cf68), Color(hex: 0xc99a35), Color(hex: 0xa9781f))
                        : vgrad(Color(hex: 0xc0603a), Fr.tile, Fr.tileDeep)
        let rib = gold ? vgrad(Color(hex: 0xfff0b8), Color(hex: 0xf0c75a)) : vgrad(Color(hex: 0xd77a4c), Color(hex: 0xb85a32))
        let seam = gold ? Color(hex: 0x8e6418) : Color(hex: 0x6e2c14)
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                Trapezoid(inset: 0.06).fill(base)
                RoofRibs(inset: 0.06, n: 26, body: true).fill(rib)
                RoofRibs(inset: 0.06, n: 26, body: false).stroke(seam.opacity(0.75), lineWidth: max(0.6, W * 0.0025))
                if gold {
                    // a slow band of light crossing the gilding
                    let u = CGFloat((t / 6).truncatingRemainder(dividingBy: 1)) * 1.8 - 0.4
                    Rectangle().fill(LinearGradient(colors: [.white.opacity(0), .white.opacity(0.55), .white.opacity(0)],
                                                    startPoint: .leading, endPoint: .trailing))
                        .frame(width: W * 0.12, height: H * 2.2)
                        .rotationEffect(.degrees(24))
                        .position(x: W * u, y: H / 2)
                        .clipShape(Trapezoid(inset: 0.06))
                }
                // ridge tiles along the top
                Capsule().fill(gold ? vgrad(Color(hex: 0xfff2c4), Color(hex: 0xd9a944)) : vgrad(Color(hex: 0xd27448), Fr.tileDeep))
                    .frame(width: W * 0.9, height: max(2, H * 0.09))
                    .position(x: W / 2, y: H * 0.02)
                // antefixes: a little palmette at the foot of every cover-tile row
                RoofAntefixes(n: 26).fill(gold ? vgrad(Color(hex: 0xfff2c4), Color(hex: 0xe0ac40)) : vgrad(Fr.parchment, Color(hex: 0xe0c08a)))
                    .frame(width: W, height: H * 0.16)
                    .position(x: W / 2, y: H - H * 0.08)
            }
        }
    }
}

/// The cover-tile rows: as filled strips (`body`), or as the shadow line down the right of each.
private struct RoofRibs: Shape {
    let inset: CGFloat, n: Int, body: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        for i in 0...n {
            let f = CGFloat(i) / CGFloat(n)
            let xt = r.minX + r.width * (inset + (1 - 2 * inset) * f)
            let xb = r.minX + r.width * f
            let wt = r.width * (1 - 2 * inset) / CGFloat(n) * 0.36, wb = r.width / CGFloat(n) * 0.36
            if body {
                p.move(to: CGPoint(x: xt - wt / 2, y: r.minY)); p.addLine(to: CGPoint(x: xt + wt / 2, y: r.minY))
                p.addLine(to: CGPoint(x: xb + wb / 2, y: r.maxY)); p.addLine(to: CGPoint(x: xb - wb / 2, y: r.maxY))
                p.closeSubpath()
            } else {
                p.move(to: CGPoint(x: xt + wt / 2, y: r.minY)); p.addLine(to: CGPoint(x: xb + wb / 2, y: r.maxY))
            }
        }
        // the courses where one row of tiles overlaps the next
        for k in 1..<4 {
            let y = r.minY + r.height * CGFloat(k) / 4
            let ins = r.width * inset * (1 - CGFloat(k) / 4)
            if !body { p.move(to: CGPoint(x: r.minX + ins, y: y)); p.addLine(to: CGPoint(x: r.maxX - ins, y: y)) }
        }
        return p
    }
}

private struct RoofAntefixes: Shape {
    let n: Int
    func path(in r: CGRect) -> Path {
        var p = Path()
        let step = r.width / CGFloat(n), aw = step * 0.62
        for i in 0...n {
            let cx = r.minX + CGFloat(i) * step
            // a rounded fan on a short neck
            p.move(to: CGPoint(x: cx - aw * 0.16, y: r.maxY))
            p.addLine(to: CGPoint(x: cx - aw * 0.16, y: r.maxY - r.height * 0.3))
            p.addQuadCurve(to: CGPoint(x: cx, y: r.minY), control: CGPoint(x: cx - aw * 0.6, y: r.minY + r.height * 0.1))
            p.addQuadCurve(to: CGPoint(x: cx + aw * 0.16, y: r.maxY - r.height * 0.3), control: CGPoint(x: cx + aw * 0.6, y: r.minY + r.height * 0.1))
            p.addLine(to: CGPoint(x: cx + aw * 0.16, y: r.maxY))
            p.closeSubpath()
        }
        return p
    }
}

// MARK: Statues

/// A marble portrait bust of a Roman (clean-shaven, with combed locks and a laurel wreath, like the
/// portraits of Augustus) on a pedestal with a carved name panel.
private struct RomanBust: View {
    var body: some View {
        let hair = Color(hex: 0xe0d6bf)
        ZStack {
            GPath { $0.coOval(0.22, 0.955, 0.56, 0.045) }.fill(COC.shadow)
            // pedestal: plinth, shaft with a name panel, moulded cap
            GPath { p in
                p.coBox(0.26, 0.925, 0.48, 0.065, r: 0.01)
                p.coBox(0.29, 0.89, 0.42, 0.04, r: 0.006)
                p.coBox(0.29, 0.585, 0.42, 0.04, r: 0.008)
            }.fill(Fr.marbleShade)
            GPath { p in p.coBox(0.33, 0.62, 0.34, 0.275) }.fill(COC.marbleFill)
            GPath { p in p.coBox(0.375, 0.675, 0.25, 0.15, r: 0.01) }.fill(GA.marbleDeep.opacity(0.32))
            GPath { p in
                p.coLine([coPt(0.41, 0.725), coPt(0.59, 0.725)], 0.014)
                p.coLine([coPt(0.43, 0.775), coPt(0.57, 0.775)], 0.014)
            }.fill(GA.carve)
            // the round foot under the bust
            GPath { $0.coPoly([coPt(0.44, 0.52), coPt(0.56, 0.52), coPt(0.6, 0.59), coPt(0.4, 0.59)]) }.fill(COC.marbleFill)
            // chest and shoulders in a toga, cut off in a curve
            GPath { p in
                p.move(to: coPt(0.2, 0.5))
                p.addQuadCurve(to: coPt(0.42, 0.335), control: coPt(0.2, 0.35))
                p.addLine(to: coPt(0.58, 0.335))
                p.addQuadCurve(to: coPt(0.8, 0.5), control: coPt(0.8, 0.35))
                p.addQuadCurve(to: coPt(0.2, 0.5), control: coPt(0.5, 0.6))
                p.closeSubpath()
            }.fill(COC.marbleFill)
            // folds of the toga, drawn over the left shoulder and across the chest
            GPath { p in
                p.coQuad(coPt(0.66, 0.35), coPt(0.52, 0.41), coPt(0.36, 0.52), 0.016)
                p.coQuad(coPt(0.74, 0.39), coPt(0.62, 0.45), coPt(0.5, 0.545), 0.014)
                p.coQuad(coPt(0.29, 0.39), coPt(0.32, 0.45), coPt(0.3, 0.5), 0.012)
            }.fill(GA.marbleDeep)
            // neck, shaded under the jaw
            GPath { p in p.coBox(0.445, 0.27, 0.11, 0.09) }.fill(Fr.marbleShade)
            // ears, then the head
            GPath { p in p.coOval(0.35, 0.165, 0.055, 0.08); p.coOval(0.595, 0.165, 0.055, 0.08) }.fill(Fr.marbleShade)
            GPath { $0.coOval(0.37, 0.055, 0.26, 0.26) }.fill(COC.marbleFill)
            GPath { p in      // the shaded side of the face
                p.move(to: coPt(0.57, 0.09)); p.addQuadCurve(to: coPt(0.56, 0.3), control: coPt(0.66, 0.2))
                p.addQuadCurve(to: coPt(0.57, 0.09), control: coPt(0.6, 0.2))
            }.fill(GA.marbleDeep.opacity(0.35))
            // hair: a close cap of combed locks, a fringe across the brow
            GPath { p in
                p.move(to: coPt(0.368, 0.19))
                p.addQuadCurve(to: coPt(0.5, 0.04), control: coPt(0.365, 0.045))
                p.addQuadCurve(to: coPt(0.632, 0.19), control: coPt(0.635, 0.045))
                let fringe: [CGPoint] = [coPt(0.612, 0.14), coPt(0.59, 0.158), coPt(0.568, 0.128), coPt(0.545, 0.152),
                                         coPt(0.522, 0.124), coPt(0.5, 0.15), coPt(0.478, 0.124), coPt(0.455, 0.152),
                                         coPt(0.432, 0.128), coPt(0.41, 0.158), coPt(0.388, 0.14), coPt(0.368, 0.19)]
                for q in fringe { p.addLine(to: q) }
                p.closeSubpath()
            }.fill(hair)
            GPath { p in      // comb lines in the locks
                for i in 0..<6 {
                    let x = 0.41 + CGFloat(i) * 0.036
                    p.coQuad(coPt(x + 0.01, 0.075), coPt(x - 0.012, 0.1), coPt(x - 0.004, 0.13), 0.006)
                }
            }.fill(GA.marbleDeep.opacity(0.7))
            // the laurel wreath: leaves pointing back from the brow on both sides
            GPath { p in
                for i in 0..<12 {
                    let u = (CGFloat(i) + 0.5) / 12
                    let x = (1 - u) * (1 - u) * 0.37 + 2 * u * (1 - u) * 0.5 + u * u * 0.63
                    let y = (1 - u) * (1 - u) * 0.175 + 2 * u * (1 - u) * 0.07 + u * u * 0.175
                    let dx = 2 * (1 - u) * 0.13 + 2 * u * 0.13, dy = 2 * (1 - u) * -0.105 + 2 * u * 0.105
                    var deg = atan2(dy, dx) * 180 / .pi
                    if u < 0.5 { deg += 180 }
                    p.gLeaf(x, y + (i % 2 == 0 ? -0.008 : 0.008), 0.03, 0.011, deg + (i % 2 == 0 ? -22 : 22))
                }
            }.fill(Color(hex: 0xb5aa90))
            // brows, eyes, nose, mouth
            GPath { p in
                p.coQuad(coPt(0.425, 0.188), coPt(0.45, 0.176), coPt(0.478, 0.186), 0.01)
                p.coQuad(coPt(0.522, 0.186), coPt(0.55, 0.176), coPt(0.575, 0.188), 0.01)
                p.coQuad(coPt(0.432, 0.207), coPt(0.452, 0.2), coPt(0.472, 0.207), 0.008)
                p.coQuad(coPt(0.528, 0.207), coPt(0.548, 0.2), coPt(0.568, 0.207), 0.008)
                p.coDot(0.452, 0.207, 0.006); p.coDot(0.548, 0.207, 0.006)
                p.coLine([coPt(0.5, 0.2), coPt(0.49, 0.246), coPt(0.507, 0.252)], 0.009)
                p.coQuad(coPt(0.474, 0.274), coPt(0.5, 0.268), coPt(0.526, 0.274), 0.009)
                p.coQuad(coPt(0.485, 0.295), coPt(0.5, 0.3), coPt(0.515, 0.295), 0.006)
            }.fill(GA.carve)
        }
    }
}

// MARK: Grand works

/// The aquila: the gilded eagle the legions carried, wings raised, a thunderbolt of Jupiter in its claws,
/// on a little stepped base that stands on the roof ridge.
private struct Aquila: View {
    var t: Double = 0

    private static let notches: [CGPoint] = [coPt(0.13, 0.03), coPt(0.072, 0.12), coPt(0.07, 0.22), coPt(0.1, 0.31),
                                             coPt(0.16, 0.39), coPt(0.24, 0.455), coPt(0.33, 0.505), coPt(0.44, 0.53)]
    private static func wing() -> Path {
        var p = Path()
        p.move(to: coPt(0.47, 0.4))
        p.addQuadCurve(to: coPt(0.3, 0.2), control: coPt(0.37, 0.27))
        p.addQuadCurve(to: notches[0], control: coPt(0.21, 0.1))
        let sh = coPt(0.44, 0.36)
        for i in 1..<notches.count {
            let a = notches[i - 1], b = notches[i]
            let m = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            p.addQuadCurve(to: b, control: CGPoint(x: m.x + (m.x - sh.x) * 0.16, y: m.y + (m.y - sh.y) * 0.16))
        }
        p.closeSubpath()
        return p
    }
    private static func wingLines() -> Path {
        var p = Path()
        p.gEdge(wing(), 0.012)
        let sh = coPt(0.44, 0.37)
        for n in notches.dropFirst().dropLast() {
            p.coLine([CGPoint(x: sh.x + (n.x - sh.x) * 0.5, y: sh.y + (n.y - sh.y) * 0.5),
                      CGPoint(x: sh.x + (n.x - sh.x) * 0.96, y: sh.y + (n.y - sh.y) * 0.96)], 0.008)
        }
        p.coQuad(coPt(0.44, 0.45), coPt(0.26, 0.37), coPt(0.19, 0.12), 0.009)     // the coverts
        return p
    }
    private static func bodyPath() -> Path {
        var p = Path()
        p.move(to: coPt(0.5, 0.3))
        p.addQuadCurve(to: coPt(0.615, 0.58), control: coPt(0.63, 0.36))
        p.addQuadCurve(to: coPt(0.5, 0.79), control: coPt(0.6, 0.76))
        p.addQuadCurve(to: coPt(0.385, 0.58), control: coPt(0.4, 0.76))
        p.addQuadCurve(to: coPt(0.5, 0.3), control: coPt(0.37, 0.36))
        p.closeSubpath()
        return p
    }
    private static func bolt() -> Path {
        var p = Path()
        p.coLine([coPt(0.43, 0.845), coPt(0.36, 0.815), coPt(0.315, 0.862), coPt(0.235, 0.83)], 0.024)
        p.coLine([coPt(0.43, 0.84), coPt(0.37, 0.872), coPt(0.31, 0.835), coPt(0.255, 0.876)], 0.016)
        return p
    }

    var body: some View {
        let line = GA.goldLine
        ZStack {
            // wings: the left drawn, the right its mirror
            GPath { p in let q = Self.wing(); p.addPath(q); p.addPath(q, transform: flipX) }.fill(GA.gold)
            GPath { p in let q = Self.wingLines(); p.addPath(q); p.addPath(q, transform: flipX) }.fill(line)
            // tail fan
            GPath { $0.coPoly([coPt(0.45, 0.72), coPt(0.55, 0.72), coPt(0.6, 0.86), coPt(0.4, 0.86)]) }.fill(GA.gold)
            GPath { p in
                p.gEdge(Path { q in q.addLines([coPt(0.45, 0.72), coPt(0.55, 0.72), coPt(0.6, 0.86), coPt(0.4, 0.86)]); q.closeSubpath() }, 0.01)
                p.coLine([coPt(0.5, 0.75), coPt(0.5, 0.86)], 0.007); p.coLine([coPt(0.47, 0.75), coPt(0.45, 0.86)], 0.007)
                p.coLine([coPt(0.53, 0.75), coPt(0.55, 0.86)], 0.007)
            }.fill(line)
            // body, breast feathers
            GPath { $0.addPath(Self.bodyPath()) }.fill(GA.gold)
            GPath { p in
                p.gEdge(Self.bodyPath(), 0.012)
                for r in 0..<4 {
                    let y = 0.45 + CGFloat(r) * 0.065
                    let n = r == 3 ? 2 : 3
                    for k in 0..<n {
                        let x = 0.5 + (CGFloat(k) - CGFloat(n - 1) / 2) * 0.05
                        p.coQuad(coPt(x - 0.022, y), coPt(x, y + 0.028), coPt(x + 0.022, y), 0.007)
                    }
                }
            }.fill(line)
            // head in profile, looking left, with a hooked beak
            GPath { p in
                p.coOval(0.4, 0.175, 0.14, 0.135)
                p.coPoly([coPt(0.52, 0.22), coPt(0.575, 0.29), coPt(0.5, 0.31)])
            }.fill(GA.gold)
            GPath { p in
                p.move(to: coPt(0.415, 0.222)); p.addLine(to: coPt(0.345, 0.236))
                p.addQuadCurve(to: coPt(0.338, 0.29), control: coPt(0.316, 0.256))
                p.addLine(to: coPt(0.368, 0.268)); p.addLine(to: coPt(0.418, 0.268)); p.closeSubpath()
            }.fill(Color(hex: 0xd09a2e))
            GPath { p in
                p.coRing(0.47, 0.2425, 0.07, 0.0675, 0.011)
                p.coDot(0.452, 0.232, 0.013)
                p.coLine([coPt(0.425, 0.214), coPt(0.476, 0.21)], 0.011)
                p.coLine([coPt(0.352, 0.255), coPt(0.405, 0.248)], 0.006)
            }.fill(line)
            // legs gripping the thunderbolt
            GPath { p in
                p.coLine([coPt(0.465, 0.76), coPt(0.455, 0.835)], 0.032)
                p.coLine([coPt(0.535, 0.76), coPt(0.545, 0.835)], 0.032)
            }.fill(Color(hex: 0xc48e2c))
            GPath { p in
                p.coOval(0.41, 0.815, 0.18, 0.052)
                let b = Self.bolt(); p.addPath(b); p.addPath(b, transform: flipX)
            }.fill(vgrad(Color(hex: 0xfff2c4), GA.goldMid))
            // stepped base
            GPath { p in p.coBox(0.4, 0.875, 0.2, 0.04, r: 0.01); p.coBox(0.35, 0.91, 0.3, 0.09, r: 0.014) }.fill(GA.gold)
            GPath { p in
                p.gEdge(Path(roundedRect: CGRect(x: 0.35, y: 0.91, width: 0.3, height: 0.09), cornerRadius: 0.014), 0.01)
                p.coLine([coPt(0.38, 0.945), coPt(0.62, 0.945)], 0.008)
            }.fill(line)
            // a glint that now and then runs over the gold
            let g = pow(max(0, sin(t * 0.9)), 12)
            GPath { $0.gStar(0.2, 0.12, 0.06) }.fill(Color.white.opacity(0.95 * g))
            GPath { $0.gStar(0.58, 0.5, 0.04) }.fill(Color.white.opacity(0.9 * pow(max(0, sin(t * 0.9 + 2.2)), 12)))
        }
    }
}

/// A war elephant like Hannibal's, in a red saddle cloth with a gold fringe; it flaps an ear and swishes
/// its tail.
private struct Elephant: View {
    var t: Double = 0
    private static let hide = Color(hex: 0x9c968e), hideHi = Color(hex: 0xbab4ab), hideDeep = Color(hex: 0x6e6862)
    private static let far = Color(hex: 0x837d76)

    private static func bodyPath() -> Path {
        var p = Path()
        p.move(to: coPt(0.3, 0.42))
        p.addCurve(to: coPt(0.86, 0.44), control1: coPt(0.42, 0.24), control2: coPt(0.74, 0.25))
        p.addQuadCurve(to: coPt(0.89, 0.68), control: coPt(0.95, 0.52))
        p.addQuadCurve(to: coPt(0.3, 0.7), control: coPt(0.6, 0.8))
        p.addQuadCurve(to: coPt(0.3, 0.42), control: coPt(0.24, 0.56))
        p.closeSubpath()
        return p
    }
    private static func trunk() -> Path {
        var p = Path()
        p.move(to: coPt(0.11, 0.4))
        p.addCurve(to: coPt(0.06, 0.86), control1: coPt(0.06, 0.55), control2: coPt(0.04, 0.75))
        p.addQuadCurve(to: coPt(0.135, 0.93), control: coPt(0.07, 0.95))
        p.addQuadCurve(to: coPt(0.125, 0.875), control: coPt(0.15, 0.9))
        p.addCurve(to: coPt(0.23, 0.53), control1: coPt(0.12, 0.72), control2: coPt(0.15, 0.6))
        p.closeSubpath()
        return p
    }
    private static func ear() -> Path {
        var p = Path()
        p.move(to: coPt(0.29, 0.25))
        p.addQuadCurve(to: coPt(0.5, 0.33), control: coPt(0.46, 0.21))
        p.addQuadCurve(to: coPt(0.44, 0.66), control: coPt(0.54, 0.56))
        p.addQuadCurve(to: coPt(0.3, 0.58), control: coPt(0.36, 0.66))
        p.closeSubpath()
        return p
    }

    var body: some View {
        let flap = CGFloat(0.06 * (1 + sin(t * 1.7)) * (sin(t * 0.45) > 0.2 ? 1 : 0.2))
        let swish = CGFloat(0.03 * sin(t * 2.3))
        ZStack {
            GPath { $0.coOval(0.12, 0.955, 0.82, 0.05) }.fill(COC.shadow)
            // far legs, then tail, body, near legs
            GPath { p in
                p.coBox(0.36, 0.6, 0.11, 0.38, r: 0.03); p.coBox(0.79, 0.6, 0.1, 0.37, r: 0.03)
            }.fill(Self.far)
            GPath { p in
                p.coQuad(coPt(0.885, 0.47), coPt(0.94, 0.55), coPt(0.925 + swish, 0.7), 0.016)
                p.gLeaf(0.925 + swish, 0.725, 0.014, 0.03, 0)
            }.fill(Self.hideDeep)
            GPath { $0.addPath(Self.bodyPath()) }.fill(vgrad(Self.hideHi, Self.hide, Self.hideDeep))
            GPath { p in
                p.coBox(0.24, 0.6, 0.13, 0.385, r: 0.035); p.coBox(0.68, 0.6, 0.13, 0.385, r: 0.035)
            }.fill(vgrad(Self.hide, Color(hex: 0x8a847c)))
            GPath { p in    // toenails and the knee creases
                for x in [0.255, 0.695] as [CGFloat] {
                    for k in 0..<3 { p.coDot(x + 0.02 + CGFloat(k) * 0.035, 0.975, 0.014, 0.01) }
                }
            }.fill(Color(hex: 0xe8e0cc))
            GPath { p in
                for x in [0.26, 0.7] as [CGFloat] {
                    p.coQuad(coPt(x, 0.8), coPt(x + 0.045, 0.81), coPt(x + 0.09, 0.8), 0.007)
                    p.coQuad(coPt(x + 0.01, 0.83), coPt(x + 0.045, 0.84), coPt(x + 0.08, 0.83), 0.006)
                }
            }.fill(Self.hideDeep.opacity(0.6))
            // the saddle cloth, gold-bordered, with a medallion and a fringe
            GPath { p in
                p.move(to: coPt(0.44, 0.3)); p.addQuadCurve(to: coPt(0.76, 0.3), control: coPt(0.6, 0.235))
                p.addLine(to: coPt(0.78, 0.6)); p.addQuadCurve(to: coPt(0.42, 0.6), control: coPt(0.6, 0.64)); p.closeSubpath()
            }.fill(vgrad(Color(hex: 0xc23a2e), Color(hex: 0x8a1f19)))
            GPath { p in
                var q = Path()
                q.move(to: coPt(0.455, 0.32)); q.addQuadCurve(to: coPt(0.745, 0.32), control: coPt(0.6, 0.26))
                q.addLine(to: coPt(0.762, 0.575)); q.addQuadCurve(to: coPt(0.438, 0.575), control: coPt(0.6, 0.612)); q.closeSubpath()
                p.gEdge(q, 0.014)
                p.coRing(0.6, 0.45, 0.06, 0.06, 0.012)
                p.gStar(0.6, 0.45, 0.04)
                for i in 0..<10 {
                    let u = CGFloat(i) / 9, x = 0.43 + 0.34 * u
                    let y = 0.6 + 0.04 * (1 - pow(2 * u - 1, 2)) * 0.9
                    p.coLine([coPt(x, y), coPt(x, y + 0.035)], 0.012)
                }
            }.fill(Fr.gold)
            // the great ear, flapping now and then
            ZStack {
                GPath { $0.addPath(Self.ear()) }.fill(vgrad(Self.hide, Self.hideDeep))
                GPath { p in
                    p.gEdge(Self.ear(), 0.01)
                    p.coQuad(coPt(0.34, 0.34), coPt(0.44, 0.4), coPt(0.42, 0.56), 0.007)
                }.fill(Self.hideDeep)
            }
            .scaleEffect(x: 1 - flap, anchor: UnitPoint(x: 0.3, y: 0.45))
            // head, trunk, tusk, eye
            GPath { $0.coOval(0.1, 0.2, 0.28, 0.33) }.fill(vgrad(Self.hideHi, Self.hide))
            GPath { $0.addPath(Self.trunk()) }.fill(LinearGradient(colors: [Self.hideHi, Self.hide], startPoint: .leading, endPoint: .trailing))
            GPath { p in
                for i in 0..<6 {
                    let y = 0.58 + CGFloat(i) * 0.05
                    let x = 0.075 - CGFloat(i) * 0.003 + (i > 3 ? -0.006 : 0)
                    p.coQuad(coPt(x + 0.004, y), coPt(x + 0.035, y + 0.012), coPt(x + 0.065 - CGFloat(i) * 0.004, y - 0.004), 0.006)
                }
                p.coQuad(coPt(0.165, 0.575), coPt(0.2, 0.6), coPt(0.235, 0.575), 0.01)      // mouth
            }.fill(Self.hideDeep.opacity(0.75))
            GPath { p in
                p.move(to: coPt(0.2, 0.545)); p.addQuadCurve(to: coPt(0.03, 0.63), control: coPt(0.14, 0.7))
                p.addQuadCurve(to: coPt(0.17, 0.585), control: coPt(0.11, 0.66)); p.closeSubpath()
            }.fill(vgrad(Color(hex: 0xfaf3df), Color(hex: 0xd9ccb0)))
            GPath { p in
                p.gLeaf(0.205, 0.365, 0.018, 0.013, -10)
            }.fill(Color(hex: 0x2a221c))
            GPath { p in
                p.coQuad(coPt(0.18, 0.345), coPt(0.205, 0.335), coPt(0.235, 0.35), 0.007)
                p.coQuad(coPt(0.15, 0.28), coPt(0.22, 0.24), coPt(0.3, 0.27), 0.006)
            }.fill(Self.hideDeep.opacity(0.7))
        }
    }
}

/// A Roman racing chariot: a light car with a high curved front, painted red and gold, on spoked wheels.
private struct Chariot: View {
    var body: some View {
        let wood = COC.wood, woodDk = COC.woodDk
        ZStack {
            GPath { $0.coOval(0.06, 0.955, 0.8, 0.045) }.fill(COC.shadow)
            // the far wheel, peeking out behind
            GPath { p in p.coRing(0.6, 0.755, 0.215, 0.215, 0.03) }.fill(woodDk.opacity(0.7))
            // the pole, running forward to the yoke
            GPath { p in
                p.coQuad(coPt(0.3, 0.64), coPt(0.14, 0.64), coPt(0.02, 0.52), 0.026)
                p.coLine([coPt(0.03, 0.46), coPt(0.0, 0.58)], 0.024)
            }.fill(vgrad(COC.woodLt, wood))
            // the car: floor, then the curved red breastwork
            GPath { p in p.coBox(0.22, 0.6, 0.6, 0.05, r: 0.01) }.fill(woodDk)
            GPath { p in
                p.move(to: coPt(0.22, 0.62)); p.addLine(to: coPt(0.22, 0.36))
                p.addQuadCurve(to: coPt(0.33, 0.29), control: coPt(0.22, 0.28))
                p.addQuadCurve(to: coPt(0.82, 0.54), control: coPt(0.62, 0.31))
                p.addLine(to: coPt(0.82, 0.62)); p.closeSubpath()
            }.fill(vgrad(Color(hex: 0xc8392e), Color(hex: 0x8a1f19)))
            GPath { p in
                var q = Path()
                q.move(to: coPt(0.22, 0.62)); q.addLine(to: coPt(0.22, 0.36))
                q.addQuadCurve(to: coPt(0.33, 0.29), control: coPt(0.22, 0.28))
                q.addQuadCurve(to: coPt(0.82, 0.54), control: coPt(0.62, 0.31))
                q.addLine(to: coPt(0.82, 0.62)); q.closeSubpath()
                p.gEdge(q, 0.018)
                p.coQuad(coPt(0.24, 0.335), coPt(0.6, 0.27), coPt(0.81, 0.51), 0.028)        // the gilt rail
                p.coRing(0.38, 0.47, 0.075, 0.075, 0.014)                               // a gold wreath
                for i in 0..<8 {
                    let a = CGFloat(i) / 8 * 2 * .pi
                    p.gLeaf(0.38 + 0.075 * cos(a), 0.47 + 0.075 * sin(a), 0.022, 0.009, a * 180 / .pi + 90)
                }
                p.gStar(0.38, 0.47, 0.035)
                p.coLine([coPt(0.5, 0.58), coPt(0.78, 0.58)], 0.01)
            }.fill(vgrad(Color(hex: 0xfbe08a), Fr.gold))
            // the near wheel: iron tyre, wooden felloe, eight spokes and a bronze hub
            GPath { p in
                for i in 0..<8 {
                    let a = CGFloat(i) / 8 * .pi
                    p.coLine([coPt(0.53 - 0.2 * cos(a), 0.765 - 0.2 * sin(a)), coPt(0.53 + 0.2 * cos(a), 0.765 + 0.2 * sin(a))], 0.022)
                }
                p.coRing(0.53, 0.765, 0.205, 0.205, 0.038)
            }.fill(wood)
            GPath { p in p.coRing(0.53, 0.765, 0.222, 0.222, 0.014) }.fill(COC.iron)
            GPath { p in p.coRing(0.53, 0.765, 0.188, 0.188, 0.007) }.fill(woodDk.opacity(0.6))
            GPath { p in p.coDot(0.53, 0.765, 0.05) }.fill(COC.bronzeFill())
            GPath { p in p.coDot(0.53, 0.765, 0.018) }.fill(COC.bronzeDk)
        }
    }
}

// MARK: Animals

/// The pets (and the owl) by id.
private struct PetArt: View {
    let id: String
    var step: Double = 0
    var t: Double = 0
    var body: some View {
        switch id {
        case "dog": DogArt(step: step)
        case "cat": CatArt(step: step)
        case "goat": GoatArt(step: step)
        case "rabbit": RabbitArt()
        case "rooster": RoosterArt(step: step)
        case "tortoise": TortoiseArt(step: step)
        case "peacock": PeacockArt(step: step)
        case "owl": LittleOwl(blink: false, t: t)
        default: EmptyView()
        }
    }
}

/// Minerva's little owl (Athene noctua, the owl on Athens' coins): round, spotted, with stern white brows
/// over big yellow eyes. It blinks.
private struct LittleOwl: View {
    var blink = false
    var t: Double = 0
    var body: some View {
        let brown = Color(hex: 0x8b6a47), brownDk = Color(hex: 0x5f452c), buff = Color(hex: 0xeee2c4)
        ZStack {
            GPath { p in      // toes on the perch
                for x in [0.4, 0.45, 0.55, 0.6] as [CGFloat] { p.coLine([coPt(x, 0.9), coPt(x + (x < 0.5 ? -0.01 : 0.01), 0.985)], 0.035) }
            }.fill(Color(hex: 0xb8a988))
            GPath { $0.coOval(0.22, 0.3, 0.56, 0.66) }.fill(brown)
            GPath { p in      // wings down the sides
                p.move(to: coPt(0.25, 0.48)); p.addQuadCurve(to: coPt(0.36, 0.95), control: coPt(0.2, 0.86)); p.addQuadCurve(to: coPt(0.25, 0.48), control: coPt(0.36, 0.62)); p.closeSubpath()
                p.move(to: coPt(0.75, 0.48)); p.addQuadCurve(to: coPt(0.64, 0.95), control: coPt(0.8, 0.86)); p.addQuadCurve(to: coPt(0.75, 0.48), control: coPt(0.64, 0.62)); p.closeSubpath()
            }.fill(brownDk)
            GPath { $0.coOval(0.35, 0.5, 0.3, 0.42) }.fill(buff)
            GPath { p in      // streaks on the breast
                for (x, y) in [(0.42, 0.58), (0.5, 0.62), (0.58, 0.58), (0.44, 0.7), (0.56, 0.7), (0.5, 0.77), (0.44, 0.83), (0.56, 0.83)] as [(CGFloat, CGFloat)] {
                    p.gLeaf(x, y, 0.016, 0.03, 0)
                }
            }.fill(brown)
            GPath { $0.coOval(0.17, 0.05, 0.66, 0.54) }.fill(brown)
            GPath { p in      // spots on the crown and wings
                for (x, y) in [(0.36, 0.12), (0.45, 0.09), (0.55, 0.09), (0.64, 0.12), (0.3, 0.2), (0.7, 0.2), (0.4, 0.17), (0.5, 0.15), (0.6, 0.17),
                               (0.28, 0.62), (0.3, 0.74), (0.72, 0.62), (0.7, 0.74)] as [(CGFloat, CGFloat)] {
                    p.coDot(x, y, 0.018)
                }
            }.fill(buff)
            // facial discs, white brows, eyes
            GPath { p in p.coDot(0.385, 0.33, 0.13); p.coDot(0.615, 0.33, 0.13) }.fill(Color(hex: 0xcdb48a))
            GPath { p in
                p.move(to: coPt(0.25, 0.25)); p.addQuadCurve(to: coPt(0.5, 0.3), control: coPt(0.38, 0.16))
                p.addQuadCurve(to: coPt(0.75, 0.25), control: coPt(0.62, 0.16))
                p.addQuadCurve(to: coPt(0.5, 0.36), control: coPt(0.6, 0.22))
                p.addQuadCurve(to: coPt(0.25, 0.25), control: coPt(0.4, 0.22)); p.closeSubpath()
            }.fill(Color.white.opacity(0.92))
            GPath { p in p.coDot(0.39, 0.345, 0.085); p.coDot(0.61, 0.345, 0.085) }.fill(Color(hex: 0xf4c430))
            if blink {
                GPath { p in p.coDot(0.39, 0.345, 0.09); p.coDot(0.61, 0.345, 0.09) }.fill(brown)
                GPath { p in
                    p.coQuad(coPt(0.31, 0.35), coPt(0.39, 0.38), coPt(0.47, 0.35), 0.014)
                    p.coQuad(coPt(0.53, 0.35), coPt(0.61, 0.38), coPt(0.69, 0.35), 0.014)
                }.fill(brownDk)
            } else {
                GPath { p in p.coDot(0.395, 0.35, 0.045); p.coDot(0.605, 0.35, 0.045) }.fill(Color(hex: 0x1d1610))
                GPath { p in p.coDot(0.41, 0.33, 0.014); p.coDot(0.62, 0.33, 0.014) }.fill(Color.white)
            }
            GPath { $0.coPoly([coPt(0.47, 0.4), coPt(0.53, 0.4), coPt(0.5, 0.47)]) }.fill(Color(hex: 0xc9bf92))
        }
    }
}

/// A peacock strutting with its tail fanned: eyes of gold, bronze and blue on a green fan.
private struct PeacockArt: View {
    var step: Double = 0
    var body: some View {
        let c = coPt(0.62, 0.66), R: CGFloat = 0.38
        let blue = vgrad(Color(hex: 0x3a86e0), Color(hex: 0x1d4fa0))
        let a0: CGFloat = 196, a1: CGFloat = -16
        func at(_ r: CGFloat, _ deg: CGFloat) -> CGPoint { coPt(c.x + r * cos(deg * .pi / 180), c.y - r * sin(deg * .pi / 180)) }
        func eyes(_ k: CGFloat, _ e: CGFloat) -> Path {
            var p = Path()
            for (r, n) in [(0.33 as CGFloat, 11), (0.21 as CGFloat, 7)] {
                for i in 0..<n {
                    let deg = a0 - 8 - (a0 - a1 - 16) * CGFloat(i) / CGFloat(n - 1)
                    let q = at(r, deg)
                    p.gLeaf(q.x, q.y, 0.05 * k, 0.04 * k * e, -deg)
                }
            }
            return p
        }
        return ZStack {
            // legs
            GPath { p in
                p.gLimb(0.48, 0.74, 0.25, 0.026, CGFloat(12 * step))
                p.gLimb(0.54, 0.74, 0.25, 0.026, CGFloat(-12 * step))
            }.fill(Color(hex: 0x8a7a66))
            // the fan: green with fine shafts, a pale fringe, then rows of eyes
            GPath { p in
                p.move(to: c)
                for i in 0...24 { p.addLine(to: at(R, a0 - (a0 - a1) * CGFloat(i) / 24)) }
                p.closeSubpath()
            }.fill(vgrad(Color(hex: 0x7aa846), Color(hex: 0x4f8f3e), Color(hex: 0x2e6a3c)))
            GPath { p in
                for i in 0..<17 {
                    let deg = a0 - (a0 - a1) * CGFloat(i) / 16
                    p.coLine([at(0.06, deg), at(R * 0.98, deg)], 0.005)
                }
                for i in 0...30 { let q = at(R, a0 - (a0 - a1) * CGFloat(i) / 30); p.coDot(q.x, q.y, 0.016) }
            }.fill(Color(hex: 0xa8c35a).opacity(0.85))
            GPath { $0.addPath(eyes(1.0, 1.0)) }.fill(Color(hex: 0xd2cf62))
            GPath { $0.addPath(eyes(0.74, 1.0)) }.fill(Color(hex: 0xa06c2c))
            GPath { $0.addPath(eyes(0.52, 1.0)) }.fill(Color(hex: 0x2459b0))
            GPath { $0.addPath(eyes(0.26, 1.0)) }.fill(Color(hex: 0x10204a))
            // body, barred wing, neck and head
            GPath { $0.coOval(0.3, 0.5, 0.36, 0.28) }.fill(blue)
            GPath { $0.gLeaf(0.53, 0.63, 0.14, 0.085, -12) }.fill(vgrad(Color(hex: 0xd2ab72), Color(hex: 0xa98250)))
            GPath { p in
                for i in 0..<5 { let x = 0.44 + CGFloat(i) * 0.045; p.coLine([coPt(x, 0.575 + CGFloat(i) * 0.004), coPt(x - 0.01, 0.68 - CGFloat(i) * 0.01)], 0.009) }
            }.fill(Color(hex: 0x6e4d26))
            GPath { p in
                p.move(to: coPt(0.31, 0.6)); p.addQuadCurve(to: coPt(0.235, 0.3), control: coPt(0.21, 0.47))
                p.addLine(to: coPt(0.305, 0.29)); p.addQuadCurve(to: coPt(0.45, 0.56), control: coPt(0.3, 0.45)); p.closeSubpath()
                p.coOval(0.215, 0.2, 0.105, 0.105)
            }.fill(blue)
            GPath { p in      // the green-blue sheen down the throat
                p.coQuad(coPt(0.245, 0.32), coPt(0.25, 0.47), coPt(0.33, 0.58), 0.02)
            }.fill(Color(hex: 0x4fb3c8).opacity(0.7))
            GPath { p in      // crest
                for x in [0.215, 0.245, 0.275, 0.305] as [CGFloat] { p.coLine([coPt(0.268, 0.205), coPt(x, 0.115)], 0.007) }
            }.fill(Color(hex: 0x2b5fa8))
            GPath { p in for x in [0.215, 0.245, 0.275, 0.305] as [CGFloat] { p.coDot(x, 0.11, 0.016) } }.fill(Color(hex: 0x3fa7b8))
            GPath { $0.gLeaf(0.27, 0.245, 0.03, 0.011, 0) }.fill(Color.white)
            GPath { $0.coDot(0.258, 0.245, 0.011) }.fill(Color(hex: 0x14100c))
            GPath { $0.coPoly([coPt(0.222, 0.238), coPt(0.168, 0.258), coPt(0.225, 0.272)]) }.fill(Color(hex: 0xd9c49a))
        }
    }
}

/// A black guard dog with a red collar, like the CAVE CANEM mosaic at Pompeii.
private struct DogArt: View {
    var step: Double = 0
    var body: some View {
        let coat = Color(hex: 0x3b3430), coatHi = Color(hex: 0x5b504a), farC = Color(hex: 0x27211e)
        let sw = CGFloat(18 * step)
        ZStack {
            GPath { p in p.gLeg(0.395, 0.56, 0.42, 0.055, -sw, paw: 0.035); p.gLeg(0.775, 0.58, 0.4, 0.055, sw, paw: 0.035) }.fill(farC)
            GPath { p in      // tail, raised and curled
                p.coQuad(coPt(0.8, 0.5), coPt(0.94, 0.48), coPt(0.93 + CGFloat(0.02 * step), 0.28), 0.045)
            }.fill(coat)
            GPath { p in
                p.move(to: coPt(0.28, 0.48))
                p.addCurve(to: coPt(0.82, 0.46), control1: coPt(0.42, 0.38), control2: coPt(0.7, 0.38))
                p.addQuadCurve(to: coPt(0.8, 0.64), control: coPt(0.88, 0.56))
                p.addQuadCurve(to: coPt(0.34, 0.64), control: coPt(0.56, 0.58))
                p.addQuadCurve(to: coPt(0.28, 0.48), control: coPt(0.24, 0.58))
                p.closeSubpath()
                p.coPoly([coPt(0.25, 0.52), coPt(0.38, 0.46), coPt(0.31, 0.27), coPt(0.18, 0.3)])
                p.gLeaf(0.73, 0.56, 0.085, 0.1, 15)          // thigh
                p.gLeaf(0.33, 0.57, 0.06, 0.09, -10)         // shoulder
            }.fill(vgrad(coatHi, coat))
            GPath { p in p.gLeg(0.32, 0.58, 0.4, 0.06, sw, paw: 0.038); p.gLeg(0.71, 0.6, 0.38, 0.06, -sw, paw: 0.038) }.fill(coat)
            // head: skull, long muzzle, pricked ear
            GPath { p in
                p.coOval(0.12, 0.2, 0.22, 0.17)
                p.coBox(0.02, 0.26, 0.16, 0.1, r: 0.04)
                p.coPoly([coPt(0.21, 0.24), coPt(0.25, 0.08), coPt(0.31, 0.24)])
            }.fill(coatHi)
            GPath { p in
                p.coDot(0.035, 0.285, 0.022)
                p.coLine([coPt(0.05, 0.345), coPt(0.13, 0.345)], 0.01)
            }.fill(Color(hex: 0x14100e))
            GPath { $0.coPoly([coPt(0.24, 0.2), coPt(0.255, 0.12), coPt(0.285, 0.21)]) }.fill(Color(hex: 0x8a5048))
            GPath { $0.coDot(0.16, 0.255, 0.018) }.fill(Color(hex: 0xf2e6c8))
            GPath { $0.coDot(0.157, 0.255, 0.01) }.fill(Color(hex: 0x14100e))
            GPath { $0.coLine([coPt(0.2, 0.33), coPt(0.32, 0.42)], 0.055) }.fill(Color(hex: 0xc8352a))
            GPath { p in for k in 0..<3 { p.coDot(0.22 + CGFloat(k) * 0.045, 0.345 + CGFloat(k) * 0.034, 0.011) } }.fill(Fr.gold)
        }
    }
}

/// A ginger tabby, tail up.
private struct CatArt: View {
    var step: Double = 0
    var body: some View {
        let fur = Color(hex: 0xdc8f3e), dark = Color(hex: 0xa85e22), farC = Color(hex: 0xb46a2a), light = Color(hex: 0xf3cf92)
        let sw = CGFloat(16 * step)
        ZStack {
            GPath { p in p.gLeg(0.38, 0.6, 0.38, 0.045, -sw, paw: 0.03); p.gLeg(0.755, 0.6, 0.38, 0.045, sw, paw: 0.03) }.fill(farC)
            GPath { p in p.coCurve(coPt(0.78, 0.52), coPt(0.94, 0.5), coPt(0.98, 0.3), coPt(0.9, 0.16), 0.055) }.fill(fur)
            GPath { p in for (a, b) in [(0.9, 0.42), (0.94, 0.32), (0.93, 0.22)] as [(CGFloat, CGFloat)] { p.gLeaf(a, b, 0.03, 0.012, -20) } }.fill(dark)
            GPath { p in
                p.coOval(0.26, 0.44, 0.56, 0.21)
                p.coPoly([coPt(0.22, 0.4), coPt(0.32, 0.38), coPt(0.36, 0.56), coPt(0.26, 0.56)])
                p.gLeaf(0.72, 0.56, 0.075, 0.085, 15)
            }.fill(vgrad(fur, Color(hex: 0xc97a30)))
            GPath { p in p.gLeg(0.32, 0.6, 0.38, 0.05, sw, paw: 0.032); p.gLeg(0.7, 0.6, 0.38, 0.05, -sw, paw: 0.032) }.fill(fur)
            GPath { p in for x in [0.42, 0.51, 0.6, 0.69] as [CGFloat] { p.coQuad(coPt(x, 0.445), coPt(x + 0.02, 0.5), coPt(x + 0.005, 0.56), 0.022) } }.fill(dark)
            GPath { $0.coOval(0.27, 0.5, 0.12, 0.13) }.fill(light)
            GPath { p in
                p.coDot(0.21, 0.37, 0.12, 0.11)
                p.coPoly([coPt(0.11, 0.33), coPt(0.12, 0.17), coPt(0.2, 0.27)])
                p.coPoly([coPt(0.22, 0.27), coPt(0.3, 0.17), coPt(0.32, 0.33)])
            }.fill(fur)
            GPath { p in
                p.coPoly([coPt(0.13, 0.3), coPt(0.135, 0.21), coPt(0.18, 0.27)])
                p.coPoly([coPt(0.24, 0.27), coPt(0.29, 0.21), coPt(0.3, 0.3)])
            }.fill(Color(hex: 0xe8a9a0))
            GPath { p in p.coQuad(coPt(0.18, 0.27), coPt(0.21, 0.3), coPt(0.24, 0.27), 0.014) }.fill(dark)
            GPath { $0.coDot(0.12, 0.42, 0.05, 0.04) }.fill(light)
            GPath { p in p.gLeaf(0.155, 0.365, 0.018, 0.022, 0); p.gLeaf(0.235, 0.365, 0.018, 0.022, 0) }.fill(Color(hex: 0x8fbf4a))
            GPath { p in p.gLeaf(0.155, 0.365, 0.005, 0.018, 0); p.gLeaf(0.235, 0.365, 0.005, 0.018, 0) }.fill(Color(hex: 0x14100c))
            GPath { $0.coPoly([coPt(0.1, 0.405), coPt(0.13, 0.405), coPt(0.115, 0.425)]) }.fill(Color(hex: 0xd77a7a))
            GPath { p in
                p.coLine([coPt(0.12, 0.43), coPt(0.0, 0.41)], 0.005); p.coLine([coPt(0.12, 0.44), coPt(0.01, 0.46)], 0.005)
            }.fill(Color.white.opacity(0.85))
        }
    }
}

/// A white nanny goat: swept-back horns, a beard, a flicked-up tail.
private struct GoatArt: View {
    var step: Double = 0
    var body: some View {
        let coat = Color(hex: 0xf1eadb), shade = Color(hex: 0xcfc4ae), horn = Color(hex: 0x7a6a55), hoof = Color(hex: 0x4a3f34)
        let sw = CGFloat(13 * step)
        ZStack {
            GPath { p in p.gLimb(0.37, 0.58, 0.4, 0.05, -sw); p.gLimb(0.76, 0.58, 0.4, 0.055, sw) }.fill(shade)
            GPath { p in p.gLimb(0.37, 0.58, 0.4, 0.05, -sw, from: 0.35); p.gLimb(0.76, 0.58, 0.4, 0.055, sw, from: 0.35) }.fill(hoof)
            GPath { p in p.coQuad(coPt(0.81, 0.42), coPt(0.85, 0.38), coPt(0.87, 0.31), 0.04) }.fill(coat)
            GPath { p in
                p.coBox(0.27, 0.38, 0.57, 0.25, r: 0.12)
                p.coPoly([coPt(0.22, 0.3), coPt(0.32, 0.27), coPt(0.38, 0.46), coPt(0.28, 0.5)])
                p.gLeaf(0.75, 0.55, 0.075, 0.09, 12)
            }.fill(vgrad(coat, shade))
            GPath { p in p.gLimb(0.32, 0.58, 0.4, 0.055, sw); p.gLimb(0.72, 0.6, 0.38, 0.06, -sw) }.fill(coat)
            GPath { p in p.gLimb(0.32, 0.58, 0.4, 0.055, sw, from: 0.35); p.gLimb(0.72, 0.6, 0.38, 0.06, -sw, from: 0.33) }.fill(hoof)
            // horns sweeping back from the crown
            GPath { p in p.coQuad(coPt(0.22, 0.17), coPt(0.26, 0.04), coPt(0.37, 0.09), 0.038) }.fill(horn)
            // head: a long face sloping down to the muzzle; the ear out sideways; a beard
            GPath { p in
                p.move(to: coPt(0.29, 0.21))
                p.addQuadCurve(to: coPt(0.18, 0.15), control: coPt(0.25, 0.13))
                p.addQuadCurve(to: coPt(0.065, 0.33), control: coPt(0.1, 0.2))
                p.addQuadCurve(to: coPt(0.12, 0.37), control: coPt(0.07, 0.38))
                p.addQuadCurve(to: coPt(0.3, 0.33), control: coPt(0.22, 0.36))
                p.closeSubpath()
            }.fill(vgrad(coat, Color(hex: 0xe3d9c5)))
            GPath { $0.gLeaf(0.31, 0.22, 0.06, 0.02, 25) }.fill(shade)
            GPath { $0.coPoly([coPt(0.1, 0.36), coPt(0.15, 0.36), coPt(0.12, 0.46)]) }.fill(shade)
            GPath { p in p.coDot(0.185, 0.215, 0.016); p.coDot(0.085, 0.33, 0.008) }.fill(Color(hex: 0x2a221c))
            GPath { $0.coLine([coPt(0.172, 0.215), coPt(0.198, 0.215)], 0.007) }.fill(Color(hex: 0xc9a14a))
        }
    }
}

/// A brown rabbit, crouched to hop.
private struct RabbitArt: View {
    var body: some View {
        let fur = Color(hex: 0xa88d6c), dark = Color(hex: 0x7d654b), belly = Color(hex: 0xddcbab)
        ZStack {
            GPath { p in p.gLeaf(0.33, 0.2, 0.05, 0.17, -14) }.fill(dark)
            GPath { $0.coDot(0.84, 0.6, 0.075) }.fill(Color.white)
            GPath { p in
                p.coOval(0.3, 0.44, 0.56, 0.5)
                p.coDot(0.25, 0.47, 0.15, 0.14)
                p.coOval(0.2, 0.6, 0.2, 0.32)              // chest
            }.fill(vgrad(Color(hex: 0xb89c79), fur))
            GPath { $0.coOval(0.44, 0.9, 0.34, 0.09) }.fill(dark)
            GPath { $0.coQuad(coPt(0.5, 0.6), coPt(0.7, 0.6), coPt(0.74, 0.86), 0.012) }.fill(dark.opacity(0.6))
            GPath { p in p.coOval(0.2, 0.9, 0.12, 0.08); p.coOval(0.27, 0.91, 0.11, 0.075) }.fill(dark)       // front paws
            GPath { p in p.gLeaf(0.27, 0.19, 0.055, 0.18, -4) }.fill(fur)
            GPath { p in p.gLeaf(0.27, 0.2, 0.025, 0.13, -4) }.fill(Color(hex: 0xe6a9a3))
            GPath { $0.coDot(0.2, 0.44, 0.022) }.fill(Color(hex: 0x1a1410))
            GPath { $0.coDot(0.207, 0.433, 0.007) }.fill(Color.white)
            GPath { $0.coDot(0.105, 0.5, 0.016) }.fill(Color(hex: 0xd77a7a))
            GPath { $0.coDot(0.17, 0.55, 0.06, 0.04) }.fill(belly)
            GPath { $0.coOval(0.24, 0.66, 0.09, 0.2) }.fill(belly.opacity(0.7))
        }
    }
}

/// A rooster: red comb and wattle, golden hackles, a chestnut body and a sweep of dark green sickle feathers.
private struct RoosterArt: View {
    var step: Double = 0
    var body: some View {
        let bob = CGFloat(0.015 * step)
        ZStack {
            GPath { p in
                p.coQuad(coPt(0.66, 0.5), coPt(0.84, 0.06), coPt(0.97, 0.46), 0.075)
                p.coQuad(coPt(0.66, 0.54), coPt(0.8, 0.2), coPt(0.9, 0.58), 0.06)
            }.fill(Color(hex: 0x24453a))
            GPath { $0.coQuad(coPt(0.64, 0.56), coPt(0.74, 0.32), coPt(0.83, 0.62), 0.05) }.fill(Color(hex: 0x3a6a52))
            GPath { p in
                p.gLimb(0.46, 0.72, 0.27, 0.035, CGFloat(14 * step))
                p.gLimb(0.55, 0.72, 0.27, 0.035, CGFloat(-14 * step))
            }.fill(Color(hex: 0xd9a63a))
            GPath { $0.coOval(0.28, 0.38, 0.46, 0.38) }.fill(vgrad(Color(hex: 0xb34a2c), Color(hex: 0x8a3220)))
            GPath { $0.gLeaf(0.52, 0.57, 0.15, 0.08, -12) }.fill(Color(hex: 0x6e2618))
            GPath { p in for i in 0..<3 { p.coQuad(coPt(0.42 + CGFloat(i) * 0.06, 0.56), coPt(0.48 + CGFloat(i) * 0.06, 0.6), coPt(0.55 + CGFloat(i) * 0.06, 0.58), 0.008) } }.fill(Color(hex: 0x24453a))
            GPath { p in      // golden hackles down the neck
                p.move(to: coPt(0.22, 0.2 + bob)); p.addQuadCurve(to: coPt(0.38, 0.22 + bob), control: coPt(0.3, 0.14 + bob))
                p.addQuadCurve(to: coPt(0.44, 0.52), control: coPt(0.4, 0.4))
                p.addQuadCurve(to: coPt(0.27, 0.5), control: coPt(0.34, 0.56))
                p.addQuadCurve(to: coPt(0.22, 0.2 + bob), control: coPt(0.2, 0.36)); p.closeSubpath()
            }.fill(vgrad(Color(hex: 0xf0b043), Color(hex: 0xd27a26)))
            // head, comb, wattle, beak, eye
            GPath { $0.coDot(0.28, 0.2 + bob, 0.075) }.fill(Color(hex: 0xd0632e))
            GPath { p in
                for (x, r) in [(0.23, 0.035), (0.28, 0.045), (0.33, 0.038)] as [(CGFloat, CGFloat)] { p.coDot(x, 0.12 + bob, r) }
                p.gLeaf(0.225, 0.29 + bob, 0.025, 0.045, 0)
            }.fill(Color(hex: 0xd8312a))
            GPath { $0.coPoly([coPt(0.215, 0.19 + bob), coPt(0.14, 0.215 + bob), coPt(0.215, 0.235 + bob)]) }.fill(Color(hex: 0xe7b84a))
            GPath { $0.coDot(0.26, 0.19 + bob, 0.013) }.fill(Color(hex: 0x1a1410))
        }
    }
}

/// A Mediterranean tortoise with a high, patterned shell.
private struct TortoiseArt: View {
    var step: Double = 0
    var body: some View {
        let skin = Color(hex: 0x948d5e), line = Color(hex: 0x5a4720)
        let k = CGFloat(0.02 * step)
        ZStack {
            GPath { p in
                p.coOval(0.24 + k, 0.8, 0.12, 0.18); p.coOval(0.66 - k, 0.8, 0.12, 0.18)
                p.coOval(0.04 + k * 0.5, 0.64, 0.17, 0.14)                          // head
                p.coBox(0.14 + k * 0.5, 0.68, 0.14, 0.11, r: 0.04)                  // neck
                p.coPoly([coPt(0.84, 0.82), coPt(0.93, 0.86), coPt(0.84, 0.88)])     // tail
            }.fill(skin)
            GPath { p in p.coDot(0.09 + k * 0.5, 0.69, 0.014) }.fill(Color(hex: 0x1a1410))
            GPath { p in
                p.move(to: coPt(0.16, 0.87)); p.addCurve(to: coPt(0.88, 0.87), control1: coPt(0.18, 0.4), control2: coPt(0.86, 0.4))
                p.closeSubpath()
            }.fill(vgrad(Color(hex: 0xd4ae5c), Color(hex: 0xa07c34)))
            GPath { p in
                p.coQuad(coPt(0.17, 0.8), coPt(0.52, 0.86), coPt(0.87, 0.8), 0.014)
                for x in [0.27, 0.38, 0.5, 0.62, 0.74] as [CGFloat] { p.coLine([coPt(x, 0.82), coPt(x + (x - 0.52) * 0.1, 0.87)], 0.01) }
                // the scutes up top
                p.addPath(Path { q in q.addLines([coPt(0.42, 0.56), coPt(0.62, 0.56), coPt(0.66, 0.68), coPt(0.6, 0.79), coPt(0.44, 0.79), coPt(0.38, 0.68)]); q.closeSubpath() }.strokedPath(StrokeStyle(lineWidth: 0.012, lineJoin: .round)))
                p.coLine([coPt(0.38, 0.68), coPt(0.24, 0.7)], 0.012); p.coLine([coPt(0.66, 0.68), coPt(0.8, 0.7)], 0.012)
                p.coLine([coPt(0.42, 0.56), coPt(0.36, 0.5)], 0.012); p.coLine([coPt(0.62, 0.56), coPt(0.68, 0.5)], 0.012)
                p.coLine([coPt(0.44, 0.79), coPt(0.4, 0.82)], 0.012); p.coLine([coPt(0.6, 0.79), coPt(0.64, 0.82)], 0.012)
            }.fill(line)
            GPath { $0.coOval(0.46, 0.62, 0.12, 0.08) }.fill(Color(hex: 0xe6c87a).opacity(0.6))
        }
    }
}

// MARK: Little garden details

/// A house sparrow perched on the bird bath's rim, facing left.
private struct Sparrow: View {
    var body: some View {
        ZStack {
            GPath { $0.coPoly([coPt(0.7, 0.55), coPt(0.98, 0.42), coPt(0.95, 0.56), coPt(0.74, 0.68)]) }.fill(Color(hex: 0x6b4a2e))
            GPath { $0.coOval(0.24, 0.42, 0.56, 0.4) }.fill(vgrad(Color(hex: 0xa07a50), Color(hex: 0xd9c8a8)))
            GPath { $0.gLeaf(0.58, 0.58, 0.2, 0.1, -14) }.fill(Color(hex: 0x7a5534))
            GPath { p in for i in 0..<3 { p.coLine([coPt(0.5 + CGFloat(i) * 0.08, 0.53), coPt(0.56 + CGFloat(i) * 0.08, 0.64)], 0.02) } }.fill(Color(hex: 0xe8dcc0))
            GPath { $0.coDot(0.3, 0.38, 0.15) }.fill(Color(hex: 0x8a6440))
            GPath { $0.coDot(0.3, 0.33, 0.12, 0.07) }.fill(Color(hex: 0x7a7470))
            GPath { $0.coDot(0.24, 0.47, 0.07, 0.05) }.fill(Color(hex: 0x2a221c))
            GPath { $0.coPoly([coPt(0.17, 0.36), coPt(0.04, 0.41), coPt(0.17, 0.44)]) }.fill(Color(hex: 0x3a3028))
            GPath { $0.coDot(0.25, 0.37, 0.025) }.fill(Color(hex: 0x14100c))
            GPath { p in p.coLine([coPt(0.42, 0.8), coPt(0.4, 0.98)], 0.025); p.coLine([coPt(0.52, 0.8), coPt(0.54, 0.98)], 0.025) }.fill(Color(hex: 0x8a6a50))
        }
    }
}

/// A water lily: a notched pad with a pink flower on it.
private struct WaterLily: View {
    var body: some View {
        ZStack {
            GPath { p in
                p.move(to: coPt(0.5, 0.72))
                p.addArc(center: coPt(0.5, 0.72), radius: 0.4, startAngle: .degrees(-70), endAngle: .degrees(250), clockwise: false)
                p.closeSubpath()
            }
            .fill(vgrad(Color(hex: 0x6f9e48), Color(hex: 0x4a7a36)))
            .scaleEffect(y: 0.45, anchor: UnitPoint(x: 0.5, y: 0.72))
            GPath { p in
                for (a, r) in [(-90.0, 0.2), (-40.0, 0.18), (-140.0, 0.18), (-10.0, 0.14), (-170.0, 0.14)] as [(Double, CGFloat)] {
                    let x = 0.5 + r * 0.6 * CGFloat(cos(a * .pi / 180)), y = 0.6 + r * 0.6 * CGFloat(sin(a * .pi / 180))
                    p.gLeaf(x, y, 0.05, 0.13, CGFloat(a + 90))
                }
            }.fill(vgrad(Color(hex: 0xfbd3dc), Color(hex: 0xe57d97)))
            GPath { $0.coDot(0.5, 0.6, 0.05) }.fill(Color(hex: 0xf3c94a))
        }
    }
}

/// A bunch of grapes hanging from the arbor.
private struct Grapes: View {
    var body: some View {
        ZStack {
            GPath { p in
                for (x, y) in [(0.36, 0.3), (0.52, 0.3), (0.68, 0.3), (0.44, 0.45), (0.6, 0.45), (0.36, 0.6) , (0.52, 0.6), (0.44, 0.75), (0.52, 0.88)] as [(CGFloat, CGFloat)] {
                    p.coDot(x, y, 0.1)
                }
            }.fill(vgrad(Color(hex: 0x7a4a8f), Color(hex: 0x4e2a63)))
            GPath { p in for (x, y) in [(0.33, 0.27), (0.49, 0.27), (0.41, 0.42), (0.33, 0.57)] as [(CGFloat, CGFloat)] { p.coDot(x, y, 0.03) } }.fill(Color.white.opacity(0.45))
            GPath { $0.coLine([coPt(0.52, 0.02), coPt(0.52, 0.2)], 0.05) }.fill(Fr.trunk)
        }
    }
}
