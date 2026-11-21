import SwiftUI

// MARK: - Wing: Kitchen (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let kitchenItems: [VillaItem] = [
    .init(id: "kit_figs", name: "Fig Basket", category: .garden, price: .denarii(40), blurb: "Fresh figs from the villa's own trees.", place: "kitchen"),
    .init(id: "kit_honey", name: "Honey Pots", category: .garden, price: .denarii(45), blurb: "Romans sweetened food with honey; there was no sugar.", place: "kitchen"),
    .init(id: "kit_garum", name: "Garum Jar", category: .garden, price: .denarii(50), blurb: "A salty fish sauce Romans put on almost everything.", place: "kitchen"),
    .init(id: "kit_amphorae", name: "Olive Oil Jars", category: .garden, price: .denarii(60), blurb: "Olive oil for cooking, lamps and even soap.", place: "kitchen"),
    .init(id: "kit_hearth", name: "Cooking Hearth", category: .garden, price: .denarii(80), blurb: "Pots bubbled on a raised stone hearth.", place: "kitchen"),
    .init(id: "kit_quern", name: "Grain Mill", category: .garden, price: .denarii(90), blurb: "Two stones grind wheat into flour.", place: "kitchen"),
    .init(id: "kit_oven", name: "Bread Oven", category: .garden, price: .denarii(105), blurb: "Round loaves were marked in eight slices before baking.", place: "kitchen"),
    .init(id: "kit_table", name: "Market Table", category: .garden, price: .denarii(120), blurb: "Fruit, cheese and eggs, ready to sell.", place: "kitchen"),
]

private let kitchenSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "kit_figs": (0.86, 0.95, 0.14, "🧺"),
    "kit_honey": (0.4, 0.62, 0.12, "🍯"),
    "kit_garum": (0.56, 0.62, 0.12, "🫙"),
    "kit_amphorae": (0.12, 0.95, 0.18, "🏺"),
    "kit_hearth": (0.72, 0.66, 0.26, "🍲"),
    "kit_quern": (0.32, 0.92, 0.18, "⚙️"),
    "kit_oven": (0.18, 0.66, 0.26, "🍞"),
    "kit_table": (0.6, 0.95, 0.3, "🧀"),
]

struct KitchenRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(kitchenItems.filter { s.has($0.id) }) { item in
                    if let p = kitchenSpots[item.id] {
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

struct KitchenThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(kitchenSpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
