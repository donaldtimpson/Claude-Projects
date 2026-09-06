import SwiftUI
import UIKit

/// Finding a word's picture, in one place — the decks and the quiz both need it.
enum Pictures {
    static func photoCount(_ word: String) -> Int {
        guard UIImage(named: word) != nil else { return 0 }
        var n = 1
        while UIImage(named: "\(word)-\(n + 1)") != nil, n < 6 { n += 1 }
        return n
    }
    static func photo(_ word: String, _ variant: Int = 0) -> UIImage? {
        variant == 0 ? UIImage(named: word) : UIImage(named: "\(word)-\(variant + 1)")
    }
    static func drawing(_ word: String) -> String? {
        ReadingContent.shared.pictureWords.first { $0.word == word }?.images.first
    }
    /// Every word that can be shown as a picture at all.
    static var showable: [ReadingContent.PictureWord] {
        ReadingContent.shared.pictureWords.filter {
            photoCount($0.word) > 0 || !$0.images.isEmpty
        }
    }
}

/// One word's picture, drawn the way the decks draw it.
struct WordPicture: View {
    let word: String
    var preferPhoto = true

    var body: some View {
        if preferPhoto, let art = Pictures.photo(word) {
            Image(uiImage: art).resizable().aspectRatio(contentMode: .fit)
        } else if let e = Pictures.drawing(word) {
            GeometryReader { geo in
                Text(e)
                    .font(.system(size: min(geo.size.width, geo.size.height) * 0.62))
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        } else if let art = Pictures.photo(word) {
            Image(uiImage: art).resizable().aspectRatio(contentMode: .fit)
        }
    }
}
