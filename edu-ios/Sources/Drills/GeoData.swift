import SwiftUI

// Bundled vector geography for the map drills — simplified Natural Earth boundaries
// projected (equirectangular) into a normalized viewBox and stored as SVG path
// strings (Resources/Geo/*.json). Parsed once into SwiftUI Paths and cached, so a
// full world map is ~175 filled shapes with no image assets and no network. The
// same geometry backs both "name the highlighted region" (MC) and, later, tap-to-locate.

struct GeoRegion: Identifiable {
    let id: String          // stable key (Natural Earth ADMIN)
    let name: String        // display / answer text
    let continent: String
    let rank: Int           // prominence: 2 (most famous) … 7 (obscure)
    let askable: Bool        // false for disputed/dependency territories (still drawn)
    let path: Path          // in viewBox coordinates
    let focus: CGRect       // bbox of the largest landmass (zoom target; ignores exclaves)
    var bounds: CGRect { path.boundingRect }
}

struct GeoMap {
    let viewBox: CGRect
    let regions: [GeoRegion]
    private let byId: [String: GeoRegion]

    init(viewBox: CGRect, regions: [GeoRegion]) {
        self.viewBox = viewBox
        self.regions = regions
        self.byId = Dictionary(regions.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    func region(_ id: String) -> GeoRegion? { byId[id] }
    var askable: [GeoRegion] { regions.filter(\.askable) }
    func askable(maxRank: Int) -> [GeoRegion] { regions.filter { $0.askable && $0.rank <= maxRank } }
}

enum GeoAtlas {
    static let world: GeoMap = load("world-countries", key: "countries")

    // Decode the bundled JSON and pre-parse every path. Fails loud in DEBUG (a
    // missing/renamed resource is a build mistake, not a runtime condition).
    private static func load(_ resource: String, key: String) -> GeoMap {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vb = root["viewBox"] as? [Double], vb.count == 4,
              let rows = root[key] as? [[String: Any]]
        else {
            assertionFailure("GeoAtlas: could not load \(resource).json")
            return GeoMap(viewBox: .zero, regions: [])
        }
        let viewBox = CGRect(x: vb[0], y: vb[1], width: vb[2], height: vb[3])
        let regions: [GeoRegion] = rows.compactMap { r in
            guard let id = r["id"] as? String,
                  let name = r["name"] as? String,
                  let d = r["path"] as? String else { return nil }
            let path = parsePath(d)
            let fb = (r["focus"] as? [Double]).flatMap { $0.count == 4 ? $0 : nil }
            let focus = fb.map { CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) } ?? path.boundingRect
            return GeoRegion(
                id: id, name: name,
                continent: r["continent"] as? String ?? "",
                rank: (r["rank"] as? NSNumber)?.intValue ?? 5,
                askable: r["askable"] as? Bool ?? true,
                path: path, focus: focus
            )
        }
        return GeoMap(viewBox: viewBox, regions: regions)
    }

    // Minimal SVG path parser — absolute M/L with implicit-lineto, and Z. That's the
    // full command set our converter emits ("M x yL x y…Z", subpaths concatenated).
    static func parsePath(_ s: String) -> Path {
        var path = Path()
        var nums: [Double] = []
        var token = ""
        var cmd: Character = " "
        var start = CGPoint.zero

        func flushNumber() {
            if !token.isEmpty { if let v = Double(token) { nums.append(v) }; token = "" }
        }
        func emit() {
            flushNumber()
            switch cmd {
            case "M":
                var i = 0
                while i + 1 < nums.count {
                    let p = CGPoint(x: nums[i], y: nums[i + 1])
                    if i == 0 { path.move(to: p); start = p } else { path.addLine(to: p) }
                    i += 2
                }
            case "L":
                var i = 0
                while i + 1 < nums.count { path.addLine(to: CGPoint(x: nums[i], y: nums[i + 1])); i += 2 }
            case "Z":
                path.closeSubpath()
                _ = start
            default: break
            }
            nums = []
        }

        for ch in s {
            if ch == "M" || ch == "L" || ch == "Z" {
                emit()
                cmd = ch
            } else if ch == " " || ch == "," {
                flushNumber()
            } else {   // digit, '-', or '.'
                if ch == "-" { flushNumber() }   // '-' starts a new number
                token.append(ch)
            }
        }
        emit()
        return path
    }
}
