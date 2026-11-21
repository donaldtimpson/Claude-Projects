import SwiftUI

// MARK: - Wing: Tablinum (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let tablinumItems: [VillaItem] = [
    .init(id: "coin_janus", name: "Janus As", category: .garden, price: .denarii(40), blurb: "A bronze coin with two-faced Janus, god of doorways.", place: "tablinum"),
    .init(id: "coin_wolf", name: "She-Wolf Coin", category: .garden, price: .denarii(45), blurb: "Romulus and Remus with the wolf that raised them.", place: "tablinum"),
    .init(id: "coin_nero", name: "Nero Sestertius", category: .garden, price: .denarii(75), blurb: "A big brass coin of the emperor Nero.", place: "tablinum"),
    .init(id: "coin_caesar", name: "Caesar Denarius", category: .garden, price: .denarii(90), blurb: "Julius Caesar: the first living Roman on a coin, 44 BC.", place: "tablinum"),
    .init(id: "coin_trajan", name: "Trajan Denarius", category: .garden, price: .denarii(90), blurb: "Under Trajan the empire was at its largest.", place: "tablinum"),
    .init(id: "coin_augustus", name: "Augustus Aureus", category: .garden, price: .denarii(120), blurb: "Rome's first emperor, in gold.", place: "tablinum"),
    .init(id: "coin_hadrian", name: "Hadrian Aureus", category: .garden, price: .denarii(135), blurb: "The emperor who built a wall across Britain.", place: "tablinum"),
    .init(id: "coin_constantine", name: "Constantine Solidus", category: .garden, price: .denarii(180), blurb: "A gold coin that stayed in use for over 700 years.", place: "tablinum"),
    .init(id: "tab_masks", name: "Ancestor Masks", category: .garden, price: .denarii(150), blurb: "Roman families kept wax masks of their ancestors.", place: "tablinum"),
]

private let tablinumSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "coin_janus": (0.3, 0.3, 0.12, "🪙"),
    "coin_wolf": (0.5, 0.3, 0.12, "🪙"),
    "coin_nero": (0.7, 0.3, 0.12, "🪙"),
    "coin_caesar": (0.3, 0.45, 0.12, "🪙"),
    "coin_trajan": (0.5, 0.45, 0.12, "🪙"),
    "coin_augustus": (0.7, 0.45, 0.12, "🪙"),
    "coin_hadrian": (0.4, 0.6, 0.12, "🪙"),
    "coin_constantine": (0.6, 0.6, 0.12, "🪙"),
    "tab_masks": (0.86, 0.62, 0.18, "🎭"),
]

struct TablinumRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(tablinumItems.filter { s.has($0.id) }) { item in
                    if let p = tablinumSpots[item.id] {
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            Text(p.emoji).font(.system(size: w * p.size * 0.8))
                        }
                        .onTapGesture { s.onTap(item.id) }
                    }
                }
            }
        }
    }
}

struct TablinumThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(tablinumSpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
