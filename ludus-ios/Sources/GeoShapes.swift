import SwiftUI

// MARK: - Country outline shapes
//
// Real, simplified country silhouettes (SVG paths) bundled as world-countries.json — the
// same map data behind the Lyceum geography drills. Parsed once into SwiftUI Paths and
// drawn as a gold relief for the "Orbis" name-the-country game. `rank` is a fame ranking
// (2 = the ~36 big, recognizable countries); we quiz only those so a kid stands a chance.

struct GeoShape: Identifiable {
    let name: String
    let continent: String
    let rank: Int
    let focus: CGRect     // bounding box of this country in map space
    let path: Path
    var id: String { name }
}

private struct WorldFile: Decodable {
    let countries: [Country]
    struct Country: Decodable {
        let name: String
        let continent: String
        let rank: Int
        let askable: Bool
        let focus: [Double]
        let path: String
    }
}

enum GeoShapes {
    static let all: [GeoShape] = loadAll()

    /// The famous, recognizable set — short names only so the answer buttons stay clean.
    static let quizPool: [GeoShape] = all.filter { $0.rank <= 2 && $0.name.count <= 20 }

    private static func loadAll() -> [GeoShape] {
        guard let url = Bundle.main.url(forResource: "world-countries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(WorldFile.self, from: data)
        else { return [] }
        return file.countries.compactMap { c in
            guard c.askable, c.focus.count == 4 else { return nil }
            return GeoShape(
                name: c.name, continent: c.continent, rank: c.rank,
                focus: CGRect(x: c.focus[0], y: c.focus[1], width: c.focus[2], height: c.focus[3]),
                path: parseSVGPath(c.path)
            )
        }
    }
}

/// Minimal SVG path parser for these decks — absolute M / L / Z (simplified polygons,
/// possibly multiple subpaths for island nations).
func parseSVGPath(_ d: String) -> Path {
    // Normalize so command letters and negative signs split into clean tokens.
    var s = ""
    for ch in d {
        if ch.isLetter { s += " \(ch) " }
        else if ch == "," { s += " " }
        else if ch == "-" { s += " -" }
        else { s.append(ch) }
    }
    let tokens = s.split(separator: " ").map(String.init)
    var path = Path()
    var i = 0
    var cmd = ""
    func nextNum() -> CGFloat? {
        guard i < tokens.count, let v = Double(tokens[i]) else { return nil }
        i += 1; return CGFloat(v)
    }
    while i < tokens.count {
        if let first = tokens[i].first, first.isLetter {
            cmd = tokens[i]; i += 1
            if cmd == "Z" || cmd == "z" { path.closeSubpath(); continue }
        }
        switch cmd {
        case "M":
            guard let x = nextNum(), let y = nextNum() else { i += 1; continue }
            path.move(to: CGPoint(x: x, y: y))
            cmd = "L"   // implicit line-tos follow a moveto
        case "L":
            guard let x = nextNum(), let y = nextNum() else { i += 1; continue }
            path.addLine(to: CGPoint(x: x, y: y))
        default:
            i += 1
        }
    }
    return path
}

/// Draws the target country highlighted in gold WITHIN its neighbourhood — the surrounding
/// countries render as dim "land" so you can use where-on-Earth it sits as a clue, not just
/// the silhouette. Zooms to a region a few times the country's own size.
struct CountryContextView: View {
    let target: GeoShape
    var zoom: CGFloat = 3.0

    var body: some View {
        Canvas { ctx, size in
            let f = target.focus
            guard f.width > 0, f.height > 0 else { return }
            let cx = f.midX, cy = f.midY
            // Region to show, centred on the country, matched to the canvas aspect ratio.
            let aspect = size.width / max(size.height, 1)
            var rw = f.width * zoom, rh = f.height * zoom
            if rw / rh < aspect { rw = rh * aspect } else { rh = rw / aspect }
            let pad: CGFloat = 8
            let scale = min((size.width - 2 * pad) / rw, (size.height - 2 * pad) / rh)

            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -cx, y: -cy)

            // Visible map rect (for culling).
            let viewport = CGRect(x: cx - (size.width / 2) / scale, y: cy - (size.height / 2) / scale,
                                  width: size.width / scale, height: size.height / scale)

            // Context landmasses — dim parchment.
            for c in GeoShapes.all where c.name != target.name && c.focus.intersects(viewport) {
                ctx.fill(c.path, with: .color(Color(hex: Lu.inkDim).opacity(0.20)))
                ctx.stroke(c.path, with: .color(Color(hex: Lu.inkDim).opacity(0.35)), lineWidth: 0.7 / scale)
            }
            // The target — bright gold.
            ctx.fill(target.path,
                     with: .linearGradient(Gradient(colors: [Color(hex: Lu.gold), Color(hex: Lu.tangerine)]),
                                           startPoint: CGPoint(x: f.minX, y: f.minY),
                                           endPoint: CGPoint(x: f.maxX, y: f.maxY)))
            ctx.stroke(target.path, with: .color(Color(hex: Lu.ink)), lineWidth: 1.6 / scale)
        }
    }
}
