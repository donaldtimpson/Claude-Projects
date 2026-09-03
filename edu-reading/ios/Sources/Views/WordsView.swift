import SwiftUI

// Two ways to run this deck, built to be A/B'd on real children.
//
// "Tap to flip" is the child-driven one: read it, tap, and the picture confirms.
// It is delightful on cat / frog / kite — and it hits a wall on sat, chat, mud,
// which cannot be drawn. That wall is why the back of the card falls through to
// audio: a recording works for every word, a picture works for about four in five.
struct WordsView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    enum Mode: String, CaseIterable { case parent = "Grown-up checks", flip = "Tap to flip" }
    @State private var mode: Mode = .flip
    @State private var level: String = "CVC"
    @State private var index = 0
    @State private var flipped = false

    private var pool: [ReadingContent.Word] { c.words.filter { $0.level == level } }
    private var current: ReadingContent.Word? {
        pool.isEmpty ? nil : pool[index % pool.count]
    }

    var body: some View {
        DeckShell(title: "Words", count: pool.count, index: $index,
                  advanceLabel: mode == .parent ? "Got it" : "Next") {
            if let w = current {
                ZStack {
                    if flipped { back(w) } else { front(w) }
                }
                .cardSurface(tint: flipped ? Theme.go : Theme.line)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .animation(.easeInOut(duration: 0.45), value: flipped)
                .onTapGesture {
                    guard mode == .flip else { return }
                    if flipped { flipped = false; index = (index + 1) % max(pool.count, 1) }
                    else { flipped = true; Voice.shared.say(w.word); progress.learn(word: w.word) }
                }
            }
        } controls: {
            VStack(spacing: 8) {
                ChipRow(items: Mode.allCases, label: \.rawValue, selection: $mode)
                ChipRow(items: c.wordLevels, label: { $0 == "SilentE" ? "Silent e" : $0 },
                        selection: $level, tint: Theme.go)
            }
        }
        .onChange(of: level) { index = 0; flipped = false }
        .onChange(of: mode) { flipped = false }
        .onChange(of: index) {
            flipped = false
            if mode == .parent, let w = current { progress.learn(word: w.word) }
        }
    }

    private func front(_ w: ReadingContent.Word) -> some View {
        VStack(spacing: 16) {
            Spacer()
            phonics(w.word, size: 76)
            if mode == .flip {
                Text("Read it out loud, then tap.")
                    .font(.andika(14)).foregroundStyle(Theme.inkSoft)
            } else {
                SpeakButton(text: w.word)
            }
            Spacer()
        }.padding(20)
    }

    private func back(_ w: ReadingContent.Word) -> some View {
        VStack(spacing: 14) {
            Spacer()
            if let img = w.image {
                Text(img).font(.system(size: 96))
            } else {
                // The honest case. Roughly one word in five has nothing to draw,
                // so the reward is the word spoken back instead of a picture.
                Image(systemName: "speaker.wave.2.circle.fill")
                    .font(.system(size: 76)).foregroundStyle(Theme.go)
                phonics(w.word, size: 40)
            }
            Text("Tap for the next word.")
                .font(.andika(13)).foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(20)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    }
}
