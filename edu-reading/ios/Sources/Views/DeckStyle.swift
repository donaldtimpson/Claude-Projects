import SwiftUI

/// One colour per deck, so a child knows where they are without reading the name —
/// which is the only wayfinding available to someone who cannot yet read.
enum DeckStyle {
    private static let colours: [String: UInt] = [
        "Pets & Farm": 0xC98A3E,     "Wild Animals": 0x9A7B4F,
        "Sea & Pond": 0x3E8FA8,      "Bugs & Little Ones": 0x7FA05A,
        "Fruit & Veg": 0xD9646E,     "Food & Drink": 0xD98A4E,
        "At Home": 0x8A7BB5,         "Bath & Bedtime": 0x6C8FC7,
        "In the Kitchen": 0x5E9B8A,  "Things That Go": 0x4E7FBF,
        "Sky & Weather": 0x5FA3D9,   "Out in the Wild": 0x6FA368,
        "Places We Go": 0xB07BA8,    "Toys & Play": 0xE0724E,
        "Family & Helpers": 0xC77CB0, "My Body": 0xD9806E,
        "Feelings": 0xE0A038,        "Clothes": 0x9B7BC7,
        "Doing Things": 0x4FA08C,
    ]
    static func accent(for deck: String?) -> Color {
        Color(hex: colours[deck ?? ""] ?? 0xD9646E)
    }

    /// A single representative emoji per deck, for the hub. Chosen from what the
    /// deck actually contains rather than invented.
    static let icon: [String: String] = [
        "Pets & Farm": "🐄", "Wild Animals": "🦁", "Sea & Pond": "🐟",
        "Bugs & Little Ones": "🐝", "Fruit & Veg": "🍎", "Food & Drink": "🍞",
        "At Home": "🛋️", "Bath & Bedtime": "🛁", "In the Kitchen": "🥄",
        "Things That Go": "🚒", "Sky & Weather": "☀️", "Out in the Wild": "🌳",
        "Places We Go": "🏰", "Toys & Play": "🧸", "Family & Helpers": "👪",
        "My Body": "👂", "Feelings": "😀", "Clothes": "👕", "Doing Things": "🏃",
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
            // Mix: a short session from every deck, freshest words first. One
            // endless deck of all ~300 words could never be finished; twenty cards
            // can, and it is never the same twenty twice.
            NavigationLink { PictureWordsView(mix: true) } label: {
                HStack(spacing: 14) {
                    Text("🎲").font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mix").font(.andika(19, bold: true)).foregroundStyle(Skin.live.cardInk)
                        Text("A little of everything").font(.andika(12))
                            .foregroundStyle(Skin.live.cardInkSoft)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(["🐄", "🍎", "🚒", "😀"], id: \.self) { Text($0).font(.system(size: 24)) }
                    }
                }
                .padding(14)
                .background(Skin.current.tileFill.mixed(with: Skin.live.accent, amount: 0.12))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Skin.live.accent.mixed(with: Skin.live.card, amount: 0.45), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .padding([.horizontal, .top], 16)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(c.pictureCategories, id: \.self) { deck in
                    NavigationLink { PictureWordsView(deck: deck) } label: {
                        let tint = DeckStyle.accent(for: deck)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(DeckStyle.icon[deck] ?? "🔹").font(.system(size: 40))
                            Text(deck).font(.andika(17, bold: true))
                                .foregroundStyle(Skin.live.cardInk)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(count(deck)) cards")
                                .font(.andika(12)).foregroundStyle(Skin.live.cardInkSoft)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Skin.current.tileFill.mixed(with: tint, amount: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(tint.mixed(with: Skin.live.card, amount: 0.45), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Skin.current.appGround.ignoresSafeArea())
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
