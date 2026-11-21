import SwiftUI

// MARK: - Wing: Counting (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let countingItems: [VillaItem] = [
    .init(id: "cnt_pebbles", name: "Counting Pebbles", category: .garden, price: .denarii(40), blurb: "Calculi: our word \"calculate\" comes from them.", place: "counting"),
    .init(id: "cnt_rods", name: "Measuring Rods", category: .garden, price: .denarii(60), blurb: "A Roman foot was a little shorter than ours.", place: "counting"),
    .init(id: "cnt_abacus", name: "Abacus", category: .garden, price: .denarii(70), blurb: "Romans counted with pebbles in grooves.", place: "counting"),
    .init(id: "cnt_scale", name: "Steelyard Scale", category: .garden, price: .denarii(90), blurb: "Slide the weight along the arm until it balances.", place: "counting"),
    .init(id: "cnt_chest", name: "Strongbox", category: .garden, price: .denarii(105), blurb: "An iron-bound chest for the family's coins.", place: "counting"),
    .init(id: "cnt_groma", name: "Groma", category: .garden, price: .denarii(135), blurb: "A surveyor's cross for laying out straight roads.", place: "counting"),
    .init(id: "cnt_mosaic", name: "Numeral Mosaic", category: .garden, price: .denarii(150), blurb: "I, V, X, L, C, D and M in tiny tiles.", place: "counting"),
    .init(id: "cnt_archimedes", name: "Bust of Archimedes", category: .garden, price: .denarii(180), blurb: "The genius of Syracuse: levers, circles, \"Eureka!\"", place: "counting"),
]

private let countingSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "cnt_pebbles": (0.22, 0.95, 0.12, "🪨"),
    "cnt_rods": (0.88, 0.62, 0.22, "📏"),
    "cnt_abacus": (0.42, 0.86, 0.24, "🧮"),
    "cnt_scale": (0.74, 0.88, 0.24, "⚖️"),
    "cnt_chest": (0.14, 0.62, 0.2, "🧰"),
    "cnt_groma": (0.6, 0.62, 0.26, "✝️"),
    "cnt_mosaic": (0.5, 1.0, 0.36, "🔢"),
    "cnt_archimedes": (0.34, 0.62, 0.18, "🗿"),
]

struct CountingRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(countingItems.filter { s.has($0.id) }) { item in
                    if let p = countingSpots[item.id] {
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

struct CountingThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(countingSpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
