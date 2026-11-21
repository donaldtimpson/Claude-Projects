import SwiftUI

// MARK: - Wing: Library (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let libraryItems: [VillaItem] = [
    .init(id: "lib_tablet", name: "Wax Tablet", category: .garden, price: .denarii(45), blurb: "Write with a stylus, smooth the wax, write again.", place: "library"),
    .init(id: "lib_lamp", name: "Oil Lamp", category: .garden, price: .denarii(50), blurb: "Romans read at night by olive-oil lamps.", place: "library"),
    .init(id: "lib_shelf", name: "Scroll Shelf", category: .garden, price: .denarii(60), blurb: "Roman books were scrolls, kept in pigeonholes.", place: "library"),
    .init(id: "lib_capsa", name: "Scroll Bucket", category: .garden, price: .denarii(70), blurb: "A capsa: a round box for carrying scrolls.", place: "library"),
    .init(id: "lib_desk", name: "Writing Desk", category: .garden, price: .denarii(80), blurb: "Soot ink, a reed pen and a sheet of papyrus.", place: "library"),
    .init(id: "lib_couch", name: "Reading Couch", category: .garden, price: .denarii(120), blurb: "Romans often read lying down on a couch.", place: "library"),
    .init(id: "lib_homer", name: "Bust of Homer", category: .garden, price: .denarii(180), blurb: "The Greek poet who told of Odysseus and the Cyclops.", place: "library"),
    .init(id: "lib_virgil", name: "Virgil's Aeneid", category: .garden, price: .denarii(225), blurb: "Rome's great poem: Aeneas sails from Troy to Italy.", place: "library"),
]

private let librarySpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "lib_tablet": (0.2, 0.8, 0.14, "📝"),
    "lib_lamp": (0.8, 0.62, 0.1, "🪔"),
    "lib_shelf": (0.5, 0.62, 0.4, "📚"),
    "lib_capsa": (0.12, 0.95, 0.14, "🪣"),
    "lib_desk": (0.72, 0.88, 0.28, "🖋️"),
    "lib_couch": (0.38, 0.97, 0.34, "🛋️"),
    "lib_homer": (0.13, 0.62, 0.18, "🗿"),
    "lib_virgil": (0.88, 0.97, 0.16, "📜"),
]

struct LibraryRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(libraryItems.filter { s.has($0.id) }) { item in
                    if let p = librarySpots[item.id] {
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

struct LibraryThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(librarySpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
