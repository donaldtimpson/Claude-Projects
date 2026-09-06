import SwiftUI

/// One colour per deck, so a child knows where they are without reading the name —
/// which is the only wayfinding available to someone who cannot yet read.
enum DeckStyle {
    private static let colours: [String: UInt] = [
        "Pets & Farm": 0xC98A3E,     "Wild Animals": 0x9A7B4F,
        "In the Water": 0x3E8FA8,    "Little Ones": 0x7FA05A,
        "Fruit & Veg": 0xD9646E,     "Meals": 0xD98A4E,
        "At Home": 0x8A7BB5,         "In the Kitchen": 0x5E9B8A,
        "Getting Around": 0x4E7FBF,  "Sky & Weather": 0x5FA3D9,
        "Out in the Wild": 0x6FA368, "Places We Go": 0xB07BA8,
        "Toys & Play": 0xE0724E,     "People": 0xC77CB0,
        "What We Wear": 0x9B7BC7,    "Doing Things": 0x4FA08C,
    ]
    static func accent(for deck: String?) -> Color {
        Color(hex: colours[deck ?? ""] ?? 0xD9646E)
    }

    /// A single representative emoji per deck, for the hub. Chosen from what the
    /// deck actually contains rather than invented.
    static let icon: [String: String] = [
        "Pets & Farm": "🐄", "Wild Animals": "🦁", "In the Water": "🐟",
        "Little Ones": "🐝", "Fruit & Veg": "🍎", "Meals": "🍞",
        "At Home": "🛏️", "In the Kitchen": "🥄", "Getting Around": "🚂",
        "Sky & Weather": "☀️", "Out in the Wild": "🌳", "Places We Go": "🏫",
        "Toys & Play": "🧸", "People": "👶", "What We Wear": "👟",
        "Doing Things": "🏃",
    ]
}

/// The picture decks, as a grid. Sixteen small decks a child can finish, rather
/// than two of several hundred cards that simply never end.
struct PictureDecksHub: View {
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 150), spacing: 12)] }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(c.pictureCategories, id: \.self) { deck in
                    NavigationLink { PictureWordsView(deck: deck) } label: {
                        let tint = DeckStyle.accent(for: deck)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(DeckStyle.icon[deck] ?? "🔹").font(.system(size: 40))
                            Text(deck).font(.andika(17, bold: true))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(count(deck)) cards")
                                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Theme.paper.mixed(with: tint, amount: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(tint.mixed(with: Theme.paper, amount: 0.45), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Theme.ground)
        .navigationTitle("Look and Say")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func count(_ deck: String) -> Int {
        c.words(in: deck).reduce(0) { total, p in
            var n = 0
            if settings.pictureStyle != .drawings { n += photoCount(p.word) }
            if settings.pictureStyle != .photos { n += p.images.count }
            return total + n
        }
    }

    private func photoCount(_ word: String) -> Int {
        guard UIImage(named: word) != nil else { return 0 }
        var n = 1
        while UIImage(named: "\(word)-\(n + 1)") != nil, n < 6 { n += 1 }
        return n
    }
}
