import SwiftUI

// The reward layer, and deliberately not points, badges or streaks.
//
// One interaction, no modes: tap a thing you own and it says its word. If a
// sentence exists about it, the sentence happens — tap the pig and it says
// "The pig is big" while actually getting big. That is the whole idea in one
// gesture: reading changes the world.
//
// A pre-reader cannot read a scoreboard, so how full the world is IS the progress
// bar. Tapping a thing replays its word, which makes the reward layer double as
// the review layer: a child who taps the frog forty times has read it forty times.
struct WorldView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    @State private var saying: String?
    @State private var effect: (target: String, kind: String)?

    private var biome: ReadingContent.Biome {
        c.world.biomes[min(progress.biomeIndex, c.world.biomes.count - 1)]
    }
    private func spell(for word: String) -> ReadingContent.Spell? {
        c.world.spells.first { $0.target == word }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
                GeometryReader { geo in
                    ScrollView {
                        VStack {
                            Spacer(minLength: 0)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6),
                                                     count: 5), spacing: 16) {
                                ForEach(c.collectibles, id: \.word) { thing($0) }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(18)
                        .frame(minHeight: geo.size.height)
                    }
                }
            }
            Rectangle().fill(groundColor).frame(height: 34)

            // Places, as pictures. Five taps, each of which visibly changes the
            // world — that is play, not a settings row.
            HStack(spacing: 10) {
                ForEach(Array(c.world.biomes.enumerated()), id: \.offset) { i, b in
                    let open = progress.unlocked(b)
                    Button {
                        guard open else { return }
                        withAnimation(.easeInOut(duration: 0.5)) { progress.choose(biome: i) }
                    } label: {
                        Text(b.icon).font(.system(size: 30))
                            .grayscale(open ? 0 : 1).opacity(open ? 1 : 0.28)
                            .padding(7)
                            .background(progress.biomeIndex == i ? Theme.paper : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
        }
        .background(Theme.ground)
        .navigationTitle("My World")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func thing(_ w: ReadingContent.Word) -> some View {
        let known = progress.knows(word: w.word)
        let fx = effect?.target == w.word ? effect?.kind : nil
        return Button {
            guard known else { return }
            if let sp = spell(for: w.word) {
                Voice.shared.say(sp.text)
                progress.cast(sp.text)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    effect = (w.word, sp.effect)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.4)) { effect = nil }
                }
            } else {
                Voice.shared.say(w.word)
            }
            saying = w.word
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if saying == w.word { saying = nil }
            }
        } label: {
            Text(w.image ?? "")
                .font(.system(size: 38))
                .scaleEffect(fx == "big" ? 2.0 : 1)
                .offset(y: fx == "hop" ? -22 : 0)
                .saturation(fx == "red" ? 3 : 1)
                .hueRotation(.degrees(fx == "red" ? -40 : 0))
                .shadow(color: fx == "hot" ? .orange : .clear, radius: fx == "hot" ? 16 : 0)
                .grayscale(known ? 0 : 1)
                .opacity(known ? 1 : 0.26)
                .overlay(alignment: .top) {
                    if saying == w.word {
                        phonics(w.word, size: 15)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Theme.paper)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                            .offset(y: -22)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: fx)
                .animation(.spring(response: 0.3), value: saying)
        }
        .buttonStyle(.plain)
    }

    private var skyColors: [Color] {
        switch biome.id {
        case "beach": return [Color(hex: 0xFBE4C0), Color(hex: 0xFDF3E2)]
        case "snow":  return [Color(hex: 0xDCE9F0), Color(hex: 0xF4F9FB)]
        case "night": return [Color(hex: 0x1E2C46), Color(hex: 0x3A4A6B)]
        case "space": return [Color(hex: 0x120C24), Color(hex: 0x2A1B47)]
        default:      return [Color(hex: 0xCFE7F2), Color(hex: 0xEAF4F8)]
        }
    }
    private var groundColor: Color {
        switch biome.id {
        case "beach": return Color(hex: 0xE8C88A)
        case "snow":  return Color(hex: 0xE8F0F4)
        case "night": return Color(hex: 0x26304A)
        case "space": return Color(hex: 0x1A1230)
        default:      return Color(hex: 0x7FB069)
        }
    }
}
