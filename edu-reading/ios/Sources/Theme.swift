import SwiftUI
import UIKit
import CoreText

extension Color {
    /// Mixes toward another colour and stays OPAQUE. A translucent tint composites
    /// over whatever is behind it, so in dark mode an accent wash turned near-black
    /// and swallowed anything dark drawn on top of it. Every tinted surface in the
    /// app is built with this instead.
    func mixed(with other: Color, amount: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let t = CGFloat(amount)
        return Color(.sRGB, red: Double(ar + (br - ar) * t),
                     green: Double(ag + (bg - ag) * t),
                     blue: Double(ab + (bb - ab) * t), opacity: 1)
    }

    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255)
    }
}

// A bright, calm classroom palette — this app is used in a lit room by a child
// and an adult sharing one screen, so it stays light and high-contrast rather
// than following the Lyceum's dark look. Vowels are red everywhere: that is a
// real phonics convention, and holding it consistently across all six decks is
// the single strongest visual cue in the app.
enum Theme {
    static let ground   = Color(hex: 0xE8EDEB)
    static let paper    = Color(hex: 0xFFFFFF)
    static let paperDim = Color(hex: 0xF4F7F6)
    static let line     = Color(hex: 0xD3DCD9)
    static let ink      = Color(hex: 0x1B2A33)
    static let inkSoft  = Color(hex: 0x63777F)
    static let vowel    = Color(hex: 0xC8433A)
    static let go       = Color(hex: 0x2E7D6E)
    static let heart    = Color(hex: 0xE0A038)
    static let heartSoft = Color(hex: 0xFAEBCE)
}

// Andika (SIL, OFL) is the point of this app's typography: single-story `a` and
// `g` matching how children are taught to write, and disambiguated I / l / 1.
// No system font on iOS has those letterforms, which is why it is bundled.
extension Font {
    static func andika(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Andika-Bold" : "Andika", size: size)
    }
}

let VOWELS = Set("aeiouAEIOU")

// Andika's ascenders overshoot its cap height, so a lowercase b, d, f, h, k or l —
// and the dots on i and j — render TALLER than the matching capital. Eight of the
// twenty-six pairs are affected.
//
// That reads as a mistake, and it quietly contradicts what a child is taught:
// capitals are the big letters. The fix is not to shrink the lowercase arbitrarily,
// because on handwriting paper a tall lowercase letter reaches exactly the same top
// line as a capital. They should finish LEVEL. So: measure both glyphs and scale the
// lowercase down only when it overshoots.
enum LetterFit {
    private static var cache: [String: CGFloat] = [:]

    /// Built from the bundled file rather than by name. CTFontCreateWithName
    /// silently falls back to a system font when a name doesn't resolve, and a
    /// fallback's metrics would give a plausible-looking but wrong scale.
    private static let font: CTFont? = {
        guard let url = Bundle.main.url(forResource: "Andika-Bold", withExtension: "ttf"),
              let provider = CGDataProvider(url: url as CFURL),
              let cg = CGFont(provider) else { return nil }
        return CTFontCreateWithGraphicsFont(cg, 100, nil, nil)
    }()

    private static func top(_ ch: Character, _ font: CTFont) -> CGFloat {
        var uni = Array(String(ch).utf16)
        var glyph = CGGlyph()
        guard CTFontGetGlyphsForCharacters(font, &uni, &glyph, 1) else { return 0 }
        var rect = CGRect.zero
        _ = withUnsafePointer(to: glyph) {
            CTFontGetBoundingRectsForGlyphs(font, .default, $0, &rect, 1)
        }
        return rect.maxY
    }

    /// 1.0 when the lowercase already sits at or below the capital's height;
    /// otherwise the factor that brings its top down level.
    static func lowerScale(upper: String, lower: String) -> CGFloat {
        let key = upper + lower
        if let hit = cache[key] { return hit }
        guard let font, let u = upper.first, let l = lower.first else { return 1 }
        let tu = top(u, font), tl = top(l, font)
        let scale = (tl > tu && tu > 0) ? tu / tl : 1
        cache[key] = scale
        return scale
    }
}

/// Builds a word with its vowels in red. Used by every deck.
func phonics(_ s: String, size: CGFloat, bold: Bool = true) -> Text {
    s.reduce(Text("")) { acc, ch in
        acc + Text(String(ch)).foregroundColor(VOWELS.contains(ch) ? Theme.vowel : Theme.ink)
    }
    .font(.andika(size, bold: bold))
}

/// Builds a sentence: vowels red, and any sight word underlined in amber so the
/// child can see at a glance which words are learned rather than sounded out.
func phonicsSentence(_ s: String, size: CGFloat, sight: Set<String>) -> Text {
    s.split(separator: " ", omittingEmptySubsequences: false).enumerated().reduce(Text("")) { acc, pair in
        let (i, token) = pair
        let bare = token.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!?,"))
        var piece = String(token).reduce(Text("")) { a, ch in
            a + Text(String(ch)).foregroundColor(VOWELS.contains(ch) ? Theme.vowel : Theme.ink)
        }
        if sight.contains(bare) { piece = piece.underline(true, color: Theme.heart) }
        return acc + (i == 0 ? Text("") : Text(" ")) + piece
    }
    .font(.andika(size))
}

struct CardSurface: ViewModifier {
    var tint: Color = Theme.line
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paperDim)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(tint, lineWidth: 1.5))
    }
}
extension View {
    func cardSurface(tint: Color = Theme.line) -> some View { modifier(CardSurface(tint: tint)) }
}
