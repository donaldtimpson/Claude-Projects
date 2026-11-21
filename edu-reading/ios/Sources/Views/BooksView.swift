import SwiftUI

// The payoff of decoding: a whole little book. Sentences on cards are practice; a
// book is a milestone a child and a grown-up share — a cover, a few pages that
// make a story, and THE END. Every word is decodable at the book's level (checked
// by tools/phonics.py), so a child who has done that level can read it alone.
//
// Tapping a word is help: it is sounded out (or said). The page is never read
// aloud for them. At the end, one question answered by picture — the first check
// in the app that the child understood what they read, not just said it.
struct BooksView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared
    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 150), spacing: 14)] }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(c.books ?? [], id: \.title) { b in
                    NavigationLink { BookReader(book: b) } label: { cover(b) }
                        .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Skin.current.appGround.ignoresSafeArea())
        .navigationTitle("Little Books")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cover(_ b: ReadingContent.Book) -> some View {
        let read = progress.books.contains(b.title)
        let tint = Color(hex: BookReader.tints[(b.level - 1) % BookReader.tints.count])
        return VStack(spacing: 8) {
            Text(b.cover).font(.system(size: 64))
                .frame(maxWidth: .infinity).frame(height: 104)
                .background(tint.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(b.title).font(.andika(15, bold: true)).foregroundStyle(Skin.live.cardInk)
                .multilineTextAlignment(.center).lineLimit(2).frame(minHeight: 40)
            HStack(spacing: 3) {
                ForEach(0..<b.level, id: \.self) { _ in
                    Circle().fill(tint).frame(width: 6, height: 6)
                }
                if read { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.go).font(.system(size: 13)) }
            }
        }
        .padding(10)
        .background(Skin.live.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .leading) {
            // A spine, so it reads as a book rather than a tile.
            Rectangle().fill(tint).frame(width: 6)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18))
        }
        .shadow(color: .black.opacity(0.07), radius: 5, y: 3)
    }
}

struct BookReader: View {
    let book: ReadingContent.Book
    static let tints: [UInt] = [0xD9646E, 0x3E8FA8, 0x6FA368, 0xE0A038, 0x2E7D6E, 0x7A5EA8, 0xC98A3E, 0x4E7FBF]

    @Environment(Progress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session
    private let c = ReadingContent.shared
    @State private var page = 0
    @State private var picked: String?
    @State private var ruledOut: Set<String> = []
    @State private var tapped: String?        // word being helped with, for a highlight
    @State private var active: Int?

    private var tint: Color { Color(hex: Self.tints[(book.level - 1) % Self.tints.count]) }
    private var last: Int { book.pages.count + 1 }   // cover, pages…, question

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                coverPage.tag(0)
                ForEach(Array(book.pages.enumerated()), id: \.offset) { i, p in
                    pageView(p).tag(i + 1)
                }
                questionPage.tag(last)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            Dots(count: last + 1, index: $page, accent: tint).padding(.bottom, 10)
        }
        .background(Skin.current.ground(tint).ignoresSafeArea())
        .overlay(alignment: .topLeading) { BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6) }
        .overlay(alignment: .bottomTrailing) {
            if page < last {
                Button { withAnimation { page += 1 } } label: {
                    Image(systemName: "arrow.right").font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white).frame(width: 54, height: 54)
                        .background(tint, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                .buttonStyle(.plain).padding(.trailing, 20).padding(.bottom, 34)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onChange(of: page) { Voice.shared.cancelSoundOut(); tapped = nil; active = nil }
    }

    private var coverPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Text(book.cover).font(.system(size: 150))
            phonicsSentence(book.title, size: 40, sight: c.sightSet)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
            Spacer(); Spacer()
        }
        .card()
    }

    private func pageView(_ p: ReadingContent.Book.Page) -> some View {
        VStack(spacing: 26) {
            Spacer()
            Text(p.picture).font(.system(size: p.picture.count > 2 ? 90 : 130))
                .lineLimit(1).minimumScaleFactor(0.5)
            // Each word is its own button: tap for help sounding it out.
            WrapWords(words: p.text.split(separator: " ").map(String.init)) { token in
                Button { help(token) } label: {
                    word(token)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            Spacer(); Spacer()
        }
        .card()
    }

    @ViewBuilder private func word(_ token: String) -> some View {
        let bare = Self.bare(token)
        if tapped == bare, let w = c.words.first(where: { $0.word == bare }) {
            // Mid-help on a listed word: draw it grapheme by grapheme, lit as heard.
            let punct = String(token.drop { $0.isLetter })
            (phonicsParts(c.sounds(of: w), active: active, size: 40) + Text(punct).font(.andika(40)))
        } else {
            phonicsSentence(token, size: 40, sight: c.sightSet)
                .underline(tapped == bare, color: Theme.go)
        }
    }

    private static func bare(_ t: String) -> String {
        t.lowercased().trimmingCharacters(in: CharacterSet.letters.inverted)
    }

    private func help(_ token: String) {
        let bare = Self.bare(token)
        tapped = bare
        if Voice.shared.hasAnyLetterAudio, !c.sightSet.contains(bare),
           let w = c.words.first(where: { $0.word == bare }) {
            Voice.shared.soundOut(c.sounds(of: w), word: w.word,
                                  onStep: { i in withAnimation(.easeOut(duration: 0.12)) { active = i } },
                                  then: { tapped = nil })
        } else {
            Voice.shared.say(bare) { tapped = nil }
        }
    }

    private var questionPage: some View {
        let q = book.question
        return VStack(spacing: 26) {
            Spacer()
            Button { Voice.shared.say(q.prompt) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.wave.2.fill").foregroundStyle(tint)
                    Text(q.prompt).font(.andika(24, bold: true)).foregroundStyle(Skin.live.cardInk)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            HStack(spacing: 12) {
                ForEach(q.choices, id: \.self) { e in
                    let right = picked == e, out = ruledOut.contains(e)
                    Button { choose(e) } label: {
                        Text(e).font(.system(size: 58))
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(right ? Color(hex: 0x3E9B4F).opacity(0.22) : Skin.live.card)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(right ? Color(hex: 0x3E9B4F) : Skin.live.cardInk.opacity(0.12),
                                        lineWidth: right ? 4 : 1))
                            .opacity(out ? 0.35 : 1).grayscale(out ? 0.9 : 0)
                    }
                    .buttonStyle(.plain)
                    .disabled(out || picked != nil)
                }
            }
            .padding(.horizontal, 18)
            if picked != nil {
                Text("The End").font(.andika(30, bold: true)).foregroundStyle(tint)
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer(); Spacer()
        }
        .card()
        .overlay { if picked != nil { ReadItCelebration(accent: tint).allowsHitTesting(false) } }
        .onAppear { if picked == nil { Voice.shared.say(q.prompt) } }
    }

    private func choose(_ e: String) {
        if e == book.question.answer {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { picked = e }
            Buzz.yes()
            Voice.shared.celebrate()
            progress.finishedBook(book.title)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { session?.finish() }
            for p in book.pages { progress.readSentence(p.text) }
        } else {
            Buzz.no()
            withAnimation { _ = ruledOut.insert(e) }
        }
    }
}

private extension View {
    func card() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Skin.live.card)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            .padding(.horizontal, 20).padding(.top, 56).padding(.bottom, 12)
    }
}

/// Words laid out left to right, wrapping onto new lines, centred — a sentence
/// made of separate tappable words.
struct WrapWords<Item: View>: View {
    let words: [String]
    @ViewBuilder let item: (String) -> Item
    var body: some View {
        FlowLayout(spacing: 12, lineSpacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, w in item(w) }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? .infinity, subviews)
        let h = rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * lineSpacing
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(bounds.width, subviews) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for i in row.items {
                let s = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + row.height - s.height), proposal: .unspecified)
                x += s.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }
    private func arrange(_ maxW: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for (i, v) in subviews.enumerated() {
            let s = v.sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].items.isEmpty ? s.width : s.width + spacing
            if rows[rows.count - 1].width + extra > maxW, !rows[rows.count - 1].items.isEmpty {
                rows.append(Row())
            }
            let w = rows[rows.count - 1].items.isEmpty ? s.width : s.width + spacing
            rows[rows.count - 1].items.append(i)
            rows[rows.count - 1].width += w
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, s.height)
        }
        return rows
    }
}
