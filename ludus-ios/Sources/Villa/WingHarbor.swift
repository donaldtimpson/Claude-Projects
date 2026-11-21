import SwiftUI

// MARK: - Wing: Harbor (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let harborItems: [VillaItem] = [
    .init(id: "har_nets", name: "Fishing Nets", category: .garden, price: .denarii(45), blurb: "Fish was a favorite Roman dinner.", place: "harbor"),
    .init(id: "har_anchor", name: "Anchor", category: .garden, price: .denarii(60), blurb: "Roman anchors were made of wood and lead.", place: "harbor"),
    .init(id: "har_amphora", name: "Cargo Jars", category: .garden, price: .denarii(70), blurb: "Amphorae of oil and wine sailed across the sea.", place: "harbor"),
    .init(id: "har_boat", name: "Rowing Boat", category: .garden, price: .denarii(75), blurb: "Row out into the bay to fish.", place: "harbor"),
    .init(id: "har_dolphin", name: "Dolphins", category: .garden, price: .denarii(90), blurb: "Sailors thought dolphins brought good luck.", place: "harbor"),
    .init(id: "har_map", name: "Map Table", category: .garden, price: .denarii(120), blurb: "Romans called the Mediterranean Mare Nostrum: our sea.", place: "harbor"),
    .init(id: "har_lighthouse", name: "Little Lighthouse", category: .garden, price: .denarii(180), blurb: "Like the Pharos of Alexandria, a wonder of the world.", place: "harbor"),
    .init(id: "har_ship", name: "Merchant Ship", category: .garden, price: .denarii(270), blurb: "A big-bellied cargo ship with a square sail.", place: "harbor"),
]

private let harborSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "har_nets": (0.14, 0.8, 0.18, "🥅"),
    "har_anchor": (0.3, 0.95, 0.14, "⚓"),
    "har_amphora": (0.86, 0.92, 0.16, "🏺"),
    "har_boat": (0.3, 0.64, 0.24, "🛶"),
    "har_dolphin": (0.52, 0.56, 0.18, "🐬"),
    "har_map": (0.62, 0.96, 0.28, "🗺️"),
    "har_lighthouse": (0.88, 0.62, 0.26, "🗼"),
    "har_ship": (0.66, 0.6, 0.34, "⛵"),
]

struct HarborRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(harborItems.filter { s.has($0.id) }) { item in
                    if let p = harborSpots[item.id] {
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

struct HarborThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(harborSpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
