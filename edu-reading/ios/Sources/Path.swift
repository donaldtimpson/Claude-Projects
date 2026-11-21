import SwiftUI

// The guided path: what this child should do next, decided by the app rather than
// by a grown-up choosing from a list of fourteen decks.
//
// Steps run in the order reading actually develops — naming things, hearing the
// sounds inside words, letters in teaching sets with blending started early, then
// the reading levels. A step is DONE on evidence the app can trust: right answers
// it can check (Find It, Sound Hunt, First Sound), letters traced, words spelled
// or read, a book finished with its question answered. Never on time spent.
//
// The path only ever moves forward from where the evidence puts the child, and a
// grown-up can set a floor ("start at letters") for a child who is past the start.

/// One activity inside a Play session: which game, and what to feed it.
enum Activity: Hashable {
    case lookMix(Int)                       // Look and Say Mix, n cards
    case find(Int)                          // Find It (by ear), n right
    case draw(Int)                          // Draw, n pictures
    case rhyme(Int)
    case soundHunt(Int)
    case firstSound(Int, [String])          // limited to these letters' sounds
    case letters([String])                  // these letters' cards
    case trace([String])                    // these letters
    case words(String, [String]?)           // a level, optionally only these graphemes
    case spell(Int, String)
    case sentences(Int)
    case book(String)                       // by title

    /// What the child sees between activities — one picture, no words needed.
    var emoji: String {
        switch self {
        case .lookMix: return "🖼️"
        case .find: return "🔎"
        case .draw: return "🖍️"
        case .rhyme: return "🎵"
        case .soundHunt: return "👂"
        case .firstSound: return "🔉"
        case .letters: return "🔤"
        case .trace: return "✏️"
        case .words: return "📝"
        case .spell: return "🧩"
        case .sentences: return "💬"
        case .book: return "📗"
        }
    }

    /// Activities that need the phoneme clips are dropped when there are none.
    var needsSounds: Bool {
        switch self { case .soundHunt, .firstSound: return true; default: return false }
    }
}

struct PathStep: Identifiable {
    let id: String
    let emoji: String
    let title: String          // for the grown-up
    let detail: String         // for the grown-up: what "done" means here
    let isDone: (Progress) -> Bool
    let activities: (Progress) -> [Activity]
}

enum LearningPath {
    static let steps: [PathStep] = build()

    /// Where the child is: the first step not yet done, never below the floor.
    static func currentIndex(_ p: Progress) -> Int {
        let first = steps.firstIndex { !$0.isDone(p) } ?? steps.count - 1
        return min(max(first, p.pathFloor), steps.count - 1)
    }
    static func current(_ p: Progress) -> PathStep { steps[currentIndex(p)] }

    /// Today's session: the current step's activities, plus one review from the
    /// step before, so earlier skills keep getting used.
    static func session(_ p: Progress) -> [Activity] {
        let i = currentIndex(p)
        var acts = steps[i].activities(p)
        if i > 0, let review = steps[i - 1].activities(p).first(where: { !acts.contains($0) }) {
            acts.insert(review, at: min(1, acts.count))
        }
        if !Voice.shared.hasAnyLetterAudio { acts.removeAll(where: \.needsSounds) }
        return Array(acts.prefix(5))
    }

    // MARK: building

    private static func build() -> [PathStep] {
        let c = ReadingContent.shared
        var out: [PathStep] = []

        out.append(PathStep(
            id: "words", emoji: "🖼️", title: "Naming things",
            detail: "Finds 15 different pictures by ear in Find It.",
            isDone: { $0.knownWords.count >= 15 },
            activities: { _ in [.lookMix(8), .find(5), .draw(1)] }))

        out.append(PathStep(
            id: "ear", emoji: "👂", title: "Hearing sounds",
            detail: "8 rhymes found and 8 words heard sound by sound (Sound Hunt).",
            isDone: { $0.rhymeRight >= 8 && ($0.blendRight >= 8 || !Voice.shared.hasAnyLetterAudio) },
            activities: { _ in [.rhyme(4), .soundHunt(4), .draw(1)] }))

        // Letters in their teaching sets (s a t p i n first). Blending starts after
        // the second set, with words made only of the letters met so far.
        let sets = Dictionary(grouping: c.letters, by: \.set).sorted { $0.key < $1.key }
        var taught: [String] = []
        for (n, letters) in sets {
            let lower = letters.map(\.lower)
            let phon = letters.map { c.phoneme(of: $0) }
            taught += lower
            out.append(PathStep(
                id: "letters-\(n)", emoji: "🔤",
                title: "Letters: " + lower.joined(separator: " "),
                detail: "Each sound picked out twice in First Sound, and each letter traced.",
                isDone: { p in
                    lower.allSatisfy { p.wroteLetters.contains($0) } &&
                    (phon.allSatisfy { (p.soundHits[$0] ?? 0) >= 2 } || !Voice.shared.hasAnyLetterAudio)
                },
                activities: { _ in [.letters(lower), .firstSound(5, lower), .trace(Array(lower.prefix(3)))] }))
            if n == 2 {
                let allowed = taught + ["ss", "ll", "ff", "zz"]
                let pool = c.words.filter { w in
                    w.level == "CVC" && c.sounds(of: w).allSatisfy { allowed.contains($0.grapheme.lowercased()) }
                }.map(\.word)
                out.append(PathStep(
                    id: "first-words", emoji: "📝", title: "First words: sat, pin, dog",
                    detail: "6 words read or built from the letters met so far.",
                    isDone: { p in pool.filter { p.knows(word: $0) || p.spelledWords.contains($0) }.count >= min(6, pool.count) },
                    activities: { _ in [.words("CVC", allowed), .spell(3, "CVC"), .soundHunt(4)] }))
            }
        }

        // The reading levels, each closed by its book.
        for (i, level) in c.wordLevels.enumerated() {
            let pool = c.words.filter { $0.level == level }.map(\.word)
            let book = c.books?.first { $0.level == i + 1 }
            let title = Self.levelTitle[level] ?? level
            out.append(PathStep(
                id: "level-\(level)", emoji: "📗", title: title,
                detail: "6 words read or built at this level" + (book.map { ", and \u{201C}\($0.title)\u{201D} finished" } ?? "") + ".",
                isDone: { p in
                    pool.filter { p.knows(word: $0) || p.spelledWords.contains($0) }.count >= min(6, pool.count)
                        && (book.map { p.books.contains($0.title) } ?? true)
                },
                activities: { p in
                    var a: [Activity] = [.words(level, nil)]
                    if level != "Endings" { a.append(.spell(3, level)) }
                    a.append(.sentences(i + 1))
                    if let book, !p.books.contains(book.title) { a.append(.book(book.title)) }
                    return a
                }))
        }
        return out
    }

    static let levelTitle: [String: String] = [
        "CVC": "Three-sound words", "Digraphs": "sh, ch, th, ck",
        "Blends": "Blends: frog, jump", "SilentE": "Magic e: cake, bike",
        "VowelTeams": "Vowel teams: rain, tree", "RControlled": "ar, or, er",
        "Diphthongs": "ou, ow, oi, oy", "Endings": "Endings: -s, -ing",
    ]
}

// MARK: - session plumbing

/// Present while an activity is running inside a Play session. A game counts its
/// right answers against `rounds` and calls `finish()` when it reaches them; a deck
/// calls it on reaching its last card. Absent everywhere else, so every game
/// behaves exactly as before when opened from home.
final class SessionStep {
    let rounds: Int
    private let onFinish: () -> Void
    private var finished = false
    init(rounds: Int, onFinish: @escaping () -> Void) { self.rounds = rounds; self.onFinish = onFinish }
    func finish() {
        guard !finished else { return }
        finished = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { self.onFinish() }
    }
    /// Convenience for games: report one more success; finishes at `rounds`.
    private var count = 0
    func scored() { count += 1; if count >= rounds { finish() } }
}

private struct SessionKey: EnvironmentKey { static let defaultValue: SessionStep? = nil }
extension EnvironmentValues {
    var session: SessionStep? {
        get { self[SessionKey.self] }
        set { self[SessionKey.self] = newValue }
    }
}
