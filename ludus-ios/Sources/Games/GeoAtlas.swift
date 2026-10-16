import SwiftUI

// MARK: - GeoAtlas — the whole bundled world map, for the Lighthouse games
//
// `GeoShapes` keeps only the askable countries; the map games also want Greenland & co. so the
// coastlines look whole. The map space is the bundled file's Web-Mercator: x = (lon + 180)·1000/360,
// y = 500.1 − 159.15·ln tan(45° + lat/2) (fitted against several countries' extents), so a straight
// line on it is a rhumb line and local directions are true compass directions.

struct AtlasCountry {
    let name: String
    let continent: String
    let box: CGRect       // bounding box of the whole outline (islands included)
    let path: Path
}

enum GeoAtlas {
    static let countries: [AtlasCountry] = load()

    static func point(lat: Double, lon: Double) -> CGPoint {
        let m = log(tan(.pi / 4 + lat * .pi / 360))
        return CGPoint(x: (lon + 180) * 1000 / 360, y: 500.1 - 159.15 * m)
    }

    /// Countries of a continent (Russia is filed under Europe — see `uralsX`).
    static func of(continent c: String) -> [AtlasCountry] { countries.filter { $0.continent == c } }

    static func named(_ n: String) -> AtlasCountry? { countries.first { $0.name == n } }

    /// The Urals, roughly: Russia west of 60°E is drawn as Europe, east of it as Asia.
    static let uralsX: CGFloat = (60 + 180) * 1000 / 360

    private struct File: Decodable {
        let countries: [C]
        struct C: Decodable { let name: String; let continent: String; let path: String }
    }

    private static func load() -> [AtlasCountry] {
        guard let url = Bundle.main.url(forResource: "world-countries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.countries.map { c in
            let p = parseSVGPath(c.path)
            return AtlasCountry(name: c.name, continent: c.continent, box: p.boundingRect, path: p)
        }
    }
}
