import SwiftUI

// What counts as EARNING something is the whole question, and the old answer was
// wrong: a word was collected by swiping past its card, which is attendance
// rather than achievement. That is why the reward layer felt hollow.
//
// A word is now read when the child SAYS IT — the on-device listener already
// existed for this — or, with the microphone off, when the grown-up marks it.
// Both are real moments, which is what a badge and a toast need to hang on.

struct Award: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    let face: String
    let tint: UInt
    /// Nil unless earning this opens a world.
    var unlocksWorld: String? = nil
}

enum Awards {
    static let all: [Award] = [
        // Early and easy: the first one should land in the first minute.
        Award(id: "first-word", name: "First Word", blurb: "You read a word out loud",
              face: "🌱", tint: 0x6FA368),
        Award(id: "ten-words", name: "Ten Words", blurb: "Ten words read", face: "🔟",
              tint: 0x4E8FBF, unlocksWorld: "beach"),
        Award(id: "letters-half", name: "Halfway Through", blurb: "Thirteen letters met",
              face: "🔤", tint: 0xE0A038),
        Award(id: "all-letters", name: "Every Letter", blurb: "All twenty-six letters met",
              face: "🅰️", tint: 0xC8433A, unlocksWorld: "snow"),
        Award(id: "twenty-five", name: "Twenty-Five", blurb: "Twenty-five words read",
              face: "🎯", tint: 0xC98A3E),
        Award(id: "a-sentence", name: "A Whole Sentence", blurb: "You read a sentence",
              face: "📖", tint: 0x7A5EA8),
        Award(id: "all-colours", name: "Every Colour", blurb: "All eleven colours",
              face: "🌈", tint: 0xD9646E),
        Award(id: "all-shapes", name: "Every Shape", blurb: "All fifteen shapes",
              face: "🔷", tint: 0x3E8FA8),
        Award(id: "count-ten", name: "Count to Ten", blurb: "One to ten", face: "🔢",
              tint: 0x2E7D6E),
        Award(id: "fifty", name: "Fifty Words", blurb: "Fifty words read", face: "⭐️",
              tint: 0xF0A93B, unlocksWorld: "night"),
        Award(id: "a-deck", name: "A Whole Deck", blurb: "You finished a set of cards",
              face: "🏅", tint: 0xC77CB0),
        Award(id: "hundred", name: "One Hundred", blurb: "A hundred words read",
              face: "🏆", tint: 0xD62828, unlocksWorld: "space"),
        // Rewards coming BACK rather than never leaving. A streak punishes a family
        // holiday; this cannot be lost, only gained.
        Award(id: "came-back", name: "Welcome Back", blurb: "You came back another day",
              face: "👋", tint: 0x8A7BB5),
    ]
    static func find(_ id: String) -> Award? { all.first { $0.id == id } }
}

/// The one thing on screen when something is earned. Deliberately brief and
/// wordless-ish: the child sees the face and the colour, the adult reads the name.
struct AwardToast: View {
    let award: Award
    var body: some View {
        HStack(spacing: 12) {
            Text(award.face).font(.system(size: 34))
            VStack(alignment: .leading, spacing: 1) {
                Text(award.name).font(.andika(18, bold: true)).foregroundStyle(Theme.ink)
                Text(award.blurb).font(.andika(13)).foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.paper)
                .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: award.tint).opacity(0.55), lineWidth: 2)
        )
        .padding(.horizontal, 18)
    }
}

/// Shows anything the engine has queued, one at a time, over whatever screen the
/// child is on. Attached once at the root so no deck has to know about it.
private struct AwardToastHost: ViewModifier {
    @Environment(Progress.self) private var progress
    @State private var showing: Award?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let a = showing {
                    AwardToast(award: a)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 6)
                }
            }
            .onChange(of: progress.pending.count) { _, n in
                guard n > 0, showing == nil else { return }
                next()
            }
    }

    private func next() {
        guard !progress.pending.isEmpty else { return }
        let a = progress.pending.removeFirst()
        Voice.shared.chime()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showing = a }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeOut(duration: 0.3)) { showing = nil }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { next() }
        }
    }
}

extension View {
    func awardToasts() -> some View { modifier(AwardToastHost()) }
}
