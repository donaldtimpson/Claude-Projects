import SwiftUI

// MARK: - Wing: Palaestra (see VillaEstate.swift)
//
// Open air: a shady colonnade along the back, a herm of Hermes and raked sand (PalaestraBackdrop).
// Every item is drawn in WingPalaestraArt.swift.

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

/// Where each thing stands (its feet, in canvas fractions) and how big its box is (canvas widths).
private let palaestraSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat)] = [
    "pal_horse": (0.17, 0.665, 0.32),          // at its rail by the colonnade
    "pal_dummy": (0.85, 0.675, 0.24),
    "pal_maze": (0.5, 0.815, 0.46),            // laid flat in the middle of the yard
    "pal_board": (0.82, 0.865, 0.22),
    "pal_sand": (0.205, 0.955, 0.3),
    "pal_tali": (0.44, 0.96, 0.13),
    "pal_weights": (0.6, 0.975, 0.15),
    "pal_discus": (0.86, 0.985, 0.13),
]

@ViewBuilder
private func palaestraArt(_ id: String, t: Double = 0) -> some View {
    switch id {
    case "pal_tali": PlTali()
    case "pal_sand": PlSandPit()
    case "pal_discus": PlDiscus()
    case "pal_dummy": PlPost()
    case "pal_weights": PlWeights()
    case "pal_board": PlBoard()
    case "pal_maze": PlMaze()
    case "pal_horse": PlHorse(t: t)
    default: EmptyView()
    }
}

struct PalaestraRoom: View {
    let s: WingState
    var body: some View {
        WingRoom(floor: Pl.sand, floorLine: PalaestraBackdrop.floorLine, outdoor: true) { w, h, t in
            ZStack(alignment: .topLeading) {
                PalaestraBackdrop(w: w, h: h, t: t)
                ForEach(palaestraItems.filter { s.has($0.id) }) { item in
                    if let p = palaestraSpots[item.id] {
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            palaestraArt(item.id, t: t)
                        }
                        .onTapGesture { s.onTap(item.id) }
                        // the mosaic lies flat on the ground: always under whatever stands near it
                        .zIndex(item.id == "pal_maze" ? 0 : Double(p.y))
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
            let w = g.size.width, h = g.size.height, side = min(w, h)
            Group {
                switch id {
                // flat things: show them tipped up toward the viewer so the pattern reads
                case "pal_maze": PlMaze(tilt: 38).frame(width: side * 0.9, height: side * 0.9)
                case "pal_tali": PlTali().frame(width: side * 0.95, height: side * 0.95).offset(y: side * 0.04)
                case "pal_sand": PlSandPit().frame(width: side * 1.12, height: side * 1.12).offset(y: side * 0.03)
                default: palaestraArt(id).frame(width: side * 0.98, height: side * 0.98)
                }
            }
            .frame(width: w, height: h, alignment: .bottom)
            .padding(.bottom, h * 0.03)
        }
    }
}
