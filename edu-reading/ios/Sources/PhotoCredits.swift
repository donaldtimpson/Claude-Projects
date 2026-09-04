import Foundation

// 72 of the bundled photos are CC BY, which legally requires naming the
// photographer. This is read by the grown-ups' area so every one of them is
// credited by name, and the licence and source link travel with it.
struct PhotoCredit: Codable, Hashable {
    let word: String, asset: String, title: String
    let creator: String, license: String, source: String

    static let all: [PhotoCredit] = {
        guard let url = Bundle.main.url(forResource: "photo-credits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([PhotoCredit].self, from: data)
        else { return [] }
        return list
    }()

    var licenseName: String {
        switch license.lowercased() {
        case "cc0": return "CC0 (public domain)"
        case "by": return "CC BY"
        case "by-sa": return "CC BY-SA"
        default: return license.uppercased()
        }
    }
}
