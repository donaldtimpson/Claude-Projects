import SwiftUI

// MARK: - Wing: Harbor (see VillaEstate.swift)
//
// Open air: sky and a far headland, the sea with a gentle swell, a stone mole and the paved quay
// (HarborBackdrop). Every item is drawn in WingHarborArt.swift.

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

/// Where each thing stands (its feet, in canvas fractions) and how big its box is (canvas widths).
private let harborSpots: [String: (x: CGFloat, y: CGFloat, size: CGFloat)] = [
    "har_lighthouse": (0.87, 0.507, 0.28),     // at the end of the stone mole
    "har_ship": (0.4, 0.578, 0.44),            // riding at anchor in the bay
    "har_dolphin": (0.68, 0.64, 0.25),
    "har_boat": (0.22, 0.662, 0.22),           // moored against the quay
    "har_anchor": (0.36, 0.8, 0.15),
    "har_nets": (0.14, 0.87, 0.26),
    "har_amphora": (0.86, 0.9, 0.22),
    "har_map": (0.58, 0.975, 0.3),
]

@ViewBuilder
private func harborArt(_ id: String, t: Double, still: Bool = false) -> some View {
    switch id {
    case "har_nets": HbNets()
    case "har_anchor": HbAnchor()
    case "har_amphora": HbAmphorae()
    case "har_boat": HbBoat(t: t)
    case "har_dolphin": HbDolphins(t: t, still: still)
    case "har_map": HbMapTable()
    case "har_lighthouse": HbLighthouse(t: t)
    case "har_ship": HbShip(t: t)
    default: EmptyView()
    }
}

struct HarborRoom: View {
    let s: WingState
    var body: some View {
        WingRoom(floor: Hb.quay, floorLine: HarborBackdrop.quayEdge, outdoor: true) { w, h, t in
            ZStack(alignment: .topLeading) {
                HarborBackdrop(w: w, h: h, t: t)
                ForEach(harborItems.filter { s.has($0.id) }) { item in
                    if let p = harborSpots[item.id] {
                        // things on the water ride the swell
                        let afloat = ["har_ship", "har_boat"].contains(item.id)
                        let bob = afloat ? CGFloat(sin(t * 1.1 + p.x * 5)) * h * 0.004 : 0
                        let roll = afloat ? sin(t * 0.9 + p.x * 3) * 1.2 : 0
                        WingSpot(x: p.x, y: p.y, size: p.size, w: w, h: h, lift: s.lift(item.id)) {
                            harborArt(item.id, t: t)
                                .rotationEffect(.degrees(roll), anchor: .bottom)
                                .offset(y: bob)
                        }
                        .onTapGesture { s.onTap(item.id) }
                        .zIndex(Double(p.y))
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
            let w = g.size.width, h = g.size.height
            let afloat = ["har_ship", "har_boat", "har_dolphin"].contains(id)
            ZStack(alignment: .bottom) {
                if afloat {
                    RoundedRectangle(cornerRadius: 7).fill(LinearGradient(colors: [Hb.seaFar, Hb.sea], startPoint: .top, endPoint: .bottom))
                        .frame(height: h * 0.3)
                }
                harborArt(id, t: 1.2, still: true)
                    .frame(width: min(w, h) * 0.98, height: min(w, h) * 0.98)
                    .padding(.bottom, afloat ? h * 0.02 : h * 0.03)
            }
            .frame(width: w, height: h, alignment: .bottom)
        }
    }
}
