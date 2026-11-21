import SwiftUI

// MARK: - Wing: Palaestra (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let palaestraItems: [VillaItem] = [
    .init(id: "pal_tali", name: "Knucklebones", category: .garden, price: .denarii(40), blurb: "Tali: toss them and see how they land.", place: "palaestra"),
    .init(id: "pal_sand", name: "Wrestling Sand", category: .garden, price: .denarii(45), blurb: "Wrestlers trained on soft sand.", place: "palaestra"),
    .init(id: "pal_discus", name: "Discus", category: .garden, price: .denarii(50), blurb: "Throw it far: a Greek and Roman sport.", place: "palaestra"),
    .init(id: "pal_dummy", name: "Training Post", category: .garden, price: .denarii(60), blurb: "Gladiators practised on a wooden post, the palus.", place: "palaestra"),
    .init(id: "pal_weights", name: "Jumping Weights", category: .garden, price: .denarii(70), blurb: "Halteres: athletes swung them to jump farther.", place: "palaestra"),
    .init(id: "pal_board", name: "Latrunculi Board", category: .garden, price: .denarii(75), blurb: "A Roman game of strategy, a little like chess.", place: "palaestra"),
    .init(id: "pal_maze", name: "Labyrinth Mosaic", category: .garden, price: .denarii(135), blurb: "A maze in tiles, like the one Theseus solved.", place: "palaestra"),
    .init(id: "pal_horse", name: "Racehorse", category: .garden, price: .denarii(225), blurb: "A champion of the Circus Maximus.", place: "palaestra"),
]

private let palaestraSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "pal_tali": (0.18, 0.95, 0.12, "🎲"),
    "pal_sand": (0.5, 0.96, 0.3, "🏖️"),
    "pal_discus": (0.84, 0.92, 0.12, "🥏"),
    "pal_dummy": (0.86, 0.66, 0.18, "🪵"),
    "pal_weights": (0.66, 0.92, 0.14, "🏋️"),
    "pal_board": (0.36, 0.86, 0.18, "♟️"),
    "pal_maze": (0.5, 0.62, 0.3, "🌀"),
    "pal_horse": (0.16, 0.7, 0.28, "🐎"),
]

struct PalaestraRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(palaestraItems.filter { s.has($0.id) }) { item in
                    if let p = palaestraSpots[item.id] {
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

struct PalaestraThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(palaestraSpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
