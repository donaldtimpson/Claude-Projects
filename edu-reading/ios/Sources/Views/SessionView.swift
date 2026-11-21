import SwiftUI

// Play: one button, a few minutes, the right things for THIS child today. The path
// (Path.swift) picks four or five short activities; each runs with a small target
// (five right answers, one picture drawn, a short deck) and hands over to the next
// on its own. Between them, a single big picture says what's coming — nothing to
// read. At the end the child picks a sticker for their board, which is the reward
// a pre-reader can actually see accumulating.
struct SessionView: View {
    @Environment(Progress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    private let c = ReadingContent.shared

    @State private var plan: [Activity] = []
    @State private var at = 0
    @State private var showingNext = true
    @State private var finished = false
    @State private var stepToken = 0
    /// One per activity, kept in state: a fresh one on every render would reset
    /// the count of right answers.
    @State private var current: SessionStep?

    var body: some View {
        ZStack {
            Skin.current.appGround.ignoresSafeArea()
            if finished {
                StickerReward { dismiss() }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else if at < plan.count {
                if showingNext {
                    upNext(plan[at])
                        .transition(.opacity)
                } else {
                    activity(plan[at])
                        .environment(\.session, current)
                        .id(stepToken)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .overlay(alignment: .top) { if !finished { progressDots.padding(.top, 14) } }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onAppear {
            if plan.isEmpty { plan = LearningPath.session(progress) }
            introduce()
        }
    }

    /// Where we are in today's session — one dot per activity.
    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(plan.indices, id: \.self) { i in
                Capsule()
                    .fill(i < at ? Theme.go : (i == at ? Skin.live.accent : Skin.live.onSkySoft.opacity(0.3)))
                    .frame(width: i == at ? 22 : 9, height: 9)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: at)
        .allowsHitTesting(false)
    }

    private func upNext(_ a: Activity) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Text(a.emoji).font(.system(size: 130))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 6)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { start() }
    }

    private func introduce() {
        showingNext = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { if showingNext { start() } }
    }
    private func start() {
        guard at < plan.count else { return }
        current = SessionStep(rounds: rounds(plan[at])) { advance() }
        stepToken += 1
        withAnimation(.easeInOut(duration: 0.3)) { showingNext = false }
    }

    private func advance() {
        if at + 1 >= plan.count {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { finished = true }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { at += 1 }
            introduce()
        }
    }

    private func rounds(_ a: Activity) -> Int {
        switch a {
        case .find(let n), .draw(let n), .rhyme(let n), .soundHunt(let n),
             .firstSound(let n, _), .spell(let n, _): return n
        case .trace(let ls): return ls.count
        default: return 1        // decks finish at their last card; a book at its end
        }
    }

    @ViewBuilder private func activity(_ a: Activity) -> some View {
        switch a {
        case .lookMix(let n): PictureWordsView(mix: true, mixSize: n)
        case .find: QuizView()
        case .draw: TraceView(pictures: true, only: [nextPicture()])
        case .rhyme: RhymeView()
        case .soundHunt: SoundGameView(mode: .blend)
        case .firstSound(_, let ls): SoundGameView(mode: .first, only: ls)
        case .letters(let ls): LettersView(only: ls)
        case .trace(let ls): TraceView(only: ls)
        case .words(let level, let allowed): WordsView(level: level, allowed: allowed)
        case .spell(_, let level): SpellView(level: level)
        case .sentences(let n): SentencesView(level: n)
        case .book(let title):
            if let b = c.books?.first(where: { $0.title == title }) { BookReader(book: b) }
        }
    }

    /// The next picture not yet drawn, in the Draw lane's developmental order.
    private func nextPicture() -> String {
        Strokes.pictures.first { !progress.drawings.contains($0.name) }?.name
            ?? Strokes.pictures.randomElement()!.name
    }
}

/// The end of a session: three stickers, pick one, it goes on your board.
struct StickerReward: View {
    let done: () -> Void
    @Environment(Progress.self) private var progress
    @State private var offer: [String] = []
    @State private var chosen: String?

    static let pool = ["🦄", "🐳", "🦖", "🚀", "🌈", "🦋", "🐙", "🦁", "🌻", "🍩", "🎈", "⭐️",
                       "🐢", "🦊", "🐝", "🍓", "🚂", "🐧", "🌙", "🎸", "🐸", "🦒", "🍉", "🪐",
                       "🐬", "🦜", "🐞", "🧁", "🚁", "🦔", "🐼", "🏰", "⛵️", "🌋", "🦀", "🐿️"]

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            if let chosen {
                Text(chosen).font(.system(size: 150))
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                StickerBoard(stickers: progress.stickers, size: 30)
                    .padding(.horizontal, 24)
            } else {
                Text("🎉").font(.system(size: 70))
                HStack(spacing: 14) {
                    ForEach(offer, id: \.self) { s in
                        Button { pick(s) } label: {
                            Text(s).font(.system(size: 72))
                                .frame(width: 100, height: 112)
                                .background(Skin.live.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer()
            if chosen != nil {
                Button(action: done) {
                    Image(systemName: "house.fill").font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white).frame(width: 74, height: 74)
                        .background(Theme.go, in: Circle())
                        .shadow(color: Theme.go.opacity(0.4), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay { if chosen != nil { ReadItCelebration(accent: Skin.live.accent).allowsHitTesting(false) } }
        .onAppear {
            Voice.shared.celebrate()
            let fresh = Self.pool.filter { !progress.stickers.contains($0) }
            offer = Array((fresh.count >= 3 ? fresh : Self.pool).shuffled().prefix(3))
        }
    }

    private func pick(_ s: String) {
        Buzz.yes()
        progress.keptSticker(s)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { chosen = s }
    }
}

/// The sticker board: every sticker kept, scattered a little so it reads as a
/// board a child has stuck things on rather than a grid.
struct StickerBoard: View {
    let stickers: [String]
    var size: CGFloat = 34

    var body: some View {
        FlowLayout(spacing: 4, lineSpacing: 2) {
            ForEach(Array(stickers.enumerated()), id: \.offset) { i, s in
                Text(s).font(.system(size: size))
                    .rotationEffect(.degrees(Double((i * 37) % 30) - 15))
            }
        }
    }
}
