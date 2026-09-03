import SwiftUI

// The reward layer, and deliberately not points, badges or a streak.
//
// A pre-reader cannot read a scoreboard: points and prices are text and abstract
// number, the two things this child does not have yet. So the world filling up IS
// the progress bar, legible at a glance to a four-year-old and to an adult.
//
// And tapping a collected thing replays its word — a child who taps the frog forty
// times has read "frog" forty times, which makes the reward layer double as the
// review layer.
struct WorldView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    enum Mode: String, CaseIterable {
        case collect = "What I've read", cast = "Read a sentence", places = "Places"
    }
    @State private var mode: Mode = .collect
    @State private var saying: String?
    @State private var effect: (target: String, kind: String)?

    private var biome: ReadingContent.Biome { c.world.biomes[min(progress.biomeIndex, c.world.biomes.count - 1)] }

    var body: some View {
        VStack(spacing: 12) {
            ChipRow(items: Mode.allCases, label: \.rawValue, selection: $mode)
                .padding(.horizontal, 18)

            scene
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.line, lineWidth: 1.5))
                .padding(.horizontal, 18)

            Group {
                switch mode {
                case .collect: collectFooter
                case .cast: castFooter
                case .places: placesFooter
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .background(Theme.ground)
        .navigationTitle("My World")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scene: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
                GeometryReader { geo in
                    ScrollView {
                        // Centred when the collection is short, scrolling once it
                        // outgrows the sky — so an early world doesn't read as a
                        // mostly-empty grid pinned to the top.
                        VStack {
                            Spacer(minLength: 0)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                                                     count: 5), spacing: 10) {
                                ForEach(c.collectibles, id: \.word) { w in thing(w) }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .frame(minHeight: geo.size.height)
                    }
                }
            }
            Rectangle().fill(groundColor).frame(height: 30)
        }
    }

    private func thing(_ w: ReadingContent.Word) -> some View {
        let known = progress.knows(word: w.word)
        let fx = effect?.target == w.word ? effect?.kind : nil
        return Button {
            guard known else { return }
            Voice.shared.say(w.word)
            saying = w.word
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                if saying == w.word { saying = nil }
            }
        } label: {
            Text(w.image ?? "")
                .font(.system(size: 34))
                .scaleEffect(fx == "big" ? 1.9 : 1)
                .offset(y: fx == "hop" ? -18 : 0)
                .saturation(fx == "red" ? 3 : 1)
                .hueRotation(.degrees(fx == "red" ? -40 : 0))
                .shadow(color: fx == "hot" ? .orange : .clear, radius: fx == "hot" ? 14 : 0)
                .grayscale(known ? 0 : 1)
                .opacity(known ? 1 : 0.3)
                .overlay(alignment: .top) {
                    if saying == w.word {
                        phonics(w.word, size: 15)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Theme.paper)
                            .clipShape(Capsule())
                            .offset(y: -20)
                    }
                }
                .animation(.spring(duration: 0.45), value: fx)
        }
        .buttonStyle(.plain)
    }

    private var collectFooter: some View {
        let got = progress.knownWords.count
        return VStack(spacing: 4) {
            Text(got == 0 ? "Nothing here yet — go and read a word."
                          : "Tap anything to hear it. \(got) collected.")
                .font(.andika(15)).foregroundStyle(Theme.inkSoft)
            Text("Grey things are words not met yet.")
                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    // The mechanic the whole app is built around: reading a sentence CHANGES the
    // world. Not a metaphor bolted on — it is the literal truth about literacy,
    // handed to the child as a game, and it turns the decodable-sentence deck from
    // the driest rung into the one they ask for.
    private var castFooter: some View {
        VStack(spacing: 7) {
            ForEach(c.world.spells, id: \.text) { spell in
                Button {
                    Voice.shared.say(spell.text)
                    progress.cast(spell.text)
                    progress.learn(word: spell.target)
                    withAnimation { effect = (spell.target, spell.effect) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation { effect = nil }
                    }
                } label: {
                    phonicsSentence(spell.text, size: 19, sight: c.sightSet)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 13).padding(.vertical, 10)
                        .background(Theme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.line, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // Themes as PLACES, opened by reading, rather than a shop. A shop needs prices
    // and item names — reading, which is the thing they haven't got yet.
    private var placesFooter: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                ForEach(Array(c.world.biomes.enumerated()), id: \.offset) { i, b in
                    let open = progress.unlocked(b)
                    Button { if open { progress.choose(biome: i) } } label: {
                        Text(b.icon).font(.system(size: 28))
                            .grayscale(open ? 0 : 1).opacity(open ? 1 : 0.35)
                            .padding(6)
                            .background(progress.biomeIndex == i ? Theme.paper : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(progress.biomeIndex == i ? Theme.go : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(nextPlaceHint)
                .font(.andika(13)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var nextPlaceHint: String {
        if let next = c.world.biomes.first(where: { !progress.unlocked($0) }) {
            let need = next.unlockAt - progress.knownWords.count
            return "\(need) more word\(need == 1 ? "" : "s") opens a new place."
        }
        return "Every place is open."
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
