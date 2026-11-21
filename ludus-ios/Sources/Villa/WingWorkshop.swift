import SwiftUI

// MARK: - Wing: Workshop (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let workshopItems: [VillaItem] = [
    .init(id: "wrk_herbs", name: "Herb Garden", category: .garden, price: .denarii(50), blurb: "Mint, rosemary and thyme, for cooking and medicine.", place: "workshop"),
    .init(id: "wrk_anvil", name: "Anvil and Hammer", category: .garden, price: .denarii(60), blurb: "Beat hot iron into shape.", place: "workshop"),
    .init(id: "wrk_wheel", name: "Potter's Wheel", category: .garden, price: .denarii(80), blurb: "Spin wet clay into pots.", place: "workshop"),
    .init(id: "wrk_forge", name: "Forge", category: .garden, price: .denarii(105), blurb: "Hot enough to soften iron for the smith.", place: "workshop"),
    .init(id: "wrk_glass", name: "Glass Furnace", category: .garden, price: .denarii(120), blurb: "Romans blew glass into cups and bottles.", place: "workshop"),
    .init(id: "wrk_clock", name: "Water Clock", category: .garden, price: .denarii(135), blurb: "A clepsydra: dripping water tells the time.", place: "workshop"),
    .init(id: "wrk_screw", name: "Archimedes' Screw", category: .garden, price: .denarii(165), blurb: "Turn the handle and water climbs uphill.", place: "workshop"),
    .init(id: "wrk_steam", name: "Steam Ball", category: .garden, price: .denarii(240), blurb: "Hero of Alexandria's aeolipile, spun by steam.", place: "workshop"),
]

private let workshopSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "wrk_herbs": (0.88, 0.95, 0.16, "🌿"),
    "wrk_anvil": (0.34, 0.92, 0.16, "🔨"),
    "wrk_wheel": (0.62, 0.92, 0.2, "🏺"),
    "wrk_forge": (0.16, 0.66, 0.26, "🔥"),
    "wrk_glass": (0.86, 0.66, 0.22, "🫙"),
    "wrk_clock": (0.4, 0.62, 0.18, "⏳"),
    "wrk_screw": (0.62, 0.62, 0.24, "🌀"),
    "wrk_steam": (0.14, 0.97, 0.2, "♨️"),
]

struct WorkshopRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(workshopItems.filter { s.has($0.id) }) { item in
                    if let p = workshopSpots[item.id] {
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

struct WorkshopThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(workshopSpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
