import SwiftUI

// MARK: - Wing: Odeum (see VillaEstate.swift)
//
// PLACEHOLDER art: emoji at each spot. Replace with fresco drawings.

let odeumItems: [VillaItem] = [
    .init(id: "ode_cymbals", name: "Cymbals", category: .garden, price: .denarii(45), blurb: "Little bronze cymbals clashed in parades.", place: "odeum"),
    .init(id: "ode_pipes", name: "Pan Pipes", category: .garden, price: .denarii(50), blurb: "Reeds of different lengths: short ones sing high.", place: "odeum"),
    .init(id: "ode_drum", name: "Tympanum", category: .garden, price: .denarii(60), blurb: "A Roman hand drum, beaten with the palm.", place: "odeum"),
    .init(id: "ode_aulos", name: "Aulos", category: .garden, price: .denarii(75), blurb: "Two pipes played at once, one in each hand.", place: "odeum"),
    .init(id: "ode_lyre", name: "Lyre", category: .garden, price: .denarii(90), blurb: "Strings over a tortoise-shell sound box.", place: "odeum"),
    .init(id: "ode_masks", name: "Theatre Masks", category: .garden, price: .denarii(105), blurb: "Actors wore masks: smiling for comedy, sad for tragedy.", place: "odeum"),
    .init(id: "ode_cornu", name: "Cornu", category: .garden, price: .denarii(135), blurb: "A great G-shaped bronze horn that signalled the legions.", place: "odeum"),
    .init(id: "ode_organ", name: "Water Organ", category: .garden, price: .denarii(300), blurb: "The hydraulis: water pressure pushed air through its pipes.", place: "odeum"),
]

private let odeumSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat, emoji: String)] = [
    "ode_cymbals": (0.86, 0.95, 0.12, "🥏"),
    "ode_pipes": (0.2, 0.62, 0.14, "🎋"),
    "ode_drum": (0.18, 0.95, 0.16, "🥁"),
    "ode_aulos": (0.4, 0.62, 0.14, "🎶"),
    "ode_lyre": (0.62, 0.88, 0.2, "🪕"),
    "ode_masks": (0.66, 0.5, 0.18, "🎭"),
    "ode_cornu": (0.86, 0.7, 0.24, "📯"),
    "ode_organ": (0.4, 0.9, 0.34, "🎹"),
]

struct OdeumRoom: View {
    let s: WingState
    var body: some View {
        WingRoom { w, h, _ in
            ZStack(alignment: .topLeading) {
                ForEach(odeumItems.filter { s.has($0.id) }) { item in
                    if let p = odeumSpots[item.id] {
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

struct OdeumThumb: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            Text(odeumSpots[id]?.emoji ?? "❔").font(.system(size: g.size.width * 0.55))
                .frame(width: g.size.width, height: g.size.height)
        }
    }
}
