import SwiftUI

// MARK: - Villa placement — where each owned thing stands, per player
//
// The villa is drawn on one fixed DESIGN CANVAS (`canvas`, 400 × 450) that is scaled to fit whatever
// room the screen gives it, so a spot means the same place on a phone, an upright iPad and a sideways
// one. A spot is the thing's FEET: x as a fraction of the canvas width, y of its height.
//
// Things the child can drag live in ZONES: garden, water, pets and the grand pieces stand anywhere on
// the lawn; statues snap onto marble plinth spots (swapping if one is taken); the owl perches along
// the roof. Roses, banners, the golden roof and the eagle belong to the house and stay put.
//
// Saved as [x, y] under `ludus_villa_place_<spot id>` in the player's store. Nothing saved = the
// default spot (where it has always stood). Buying an item clears its saved spots, so a new
// purchase always lands at home.

enum VillaZone { case lawn, plinth, roof }

enum VillaPlacement {
    static let canvas = CGSize(width: 400, height: 450)

    /// Lawn bounds for feet (canvas fractions): from just in front of the house to the bottom edge.
    static let lawnTop: CGFloat = 0.58, lawnBottom: CGFloat = 1.02
    /// Pets keep a little further from the house and the bottom edge.
    static let petTop: CGFloat = 0.62, petBottom: CGFloat = 0.99
    /// The roof ridge the owl walks along.
    static let roofY: CGFloat = 0.20, roofX: ClosedRange<CGFloat> = 0.20...0.80

    /// Statue plinths: the three original spots first, then three more.
    static let plinths: [CGPoint] = [
        .init(x: 0.33, y: 0.67), .init(x: 0.67, y: 0.67), .init(x: 0.70, y: 0.87),
        .init(x: 0.30, y: 0.87), .init(x: 0.38, y: 0.98), .init(x: 0.62, y: 0.98),
    ]

    static func key(_ id: String) -> String { "ludus_villa_place_\(id)" }

    static func saved(_ id: String) -> CGPoint? {
        guard let a = LudusStore.defaults.array(forKey: key(id)) as? [Double], a.count == 2,
              a.allSatisfy(\.isFinite) else { return nil }
        return CGPoint(x: a[0], y: a[1])
    }

    static func save(_ id: String, _ p: CGPoint) {
        LudusStore.defaults.set([Double(p.x), Double(p.y)], forKey: key(id))
    }

    /// Clears the saved spots of a catalog item (the cypress item is two trees: `cypress`, `cypress2`).
    static func reset(item: String) {
        for id in [item, item + "2"] { LudusStore.defaults.removeObject(forKey: key(id)) }
    }

    /// Every saved spot among `ids`.
    static func loadAll(_ ids: [String]) -> [String: CGPoint] {
        #if DEBUG
        // LUDUS_VILLA_RESET: start from the default spots (for tests), once per launch.
        if !didDebugReset, ProcessInfo.processInfo.environment["LUDUS_VILLA_RESET"] != nil {
            didDebugReset = true
            for id in ids { LudusStore.defaults.removeObject(forKey: key(id)) }
        }
        #endif
        var out: [String: CGPoint] = [:]
        for id in ids { if let p = saved(id) { out[id] = p } }
        return out
    }
    #if DEBUG
    nonisolated(unsafe) private static var didDebugReset = false
    #endif

    /// The nearest point of a zone (for a thing whose box is `size` canvas-widths wide).
    static func clamp(_ p: CGPoint, zone: VillaZone, size: CGFloat, pet: Bool = false) -> CGPoint {
        switch zone {
        case .lawn:
            let m = max(0.03, size * 0.35)
            let (top, bottom) = pet ? (petTop, petBottom) : (lawnTop, lawnBottom)
            return CGPoint(x: min(max(p.x, m), 1 - m), y: min(max(p.y, top), bottom))
        case .roof:
            return CGPoint(x: min(max(p.x, roofX.lowerBound), roofX.upperBound), y: roofY)
        case .plinth:
            return plinths[nearestPlinth(p)]
        }
    }

    static func nearestPlinth(_ p: CGPoint) -> Int {
        // y counts a little more, since plinth rows are close together on screen
        plinths.indices.min { dist(plinths[$0], p) < dist(plinths[$1], p) } ?? 0
    }

    static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x, dy = (a.y - b.y) * 1.2
        return (dx * dx + dy * dy).squareRoot()
    }
}
