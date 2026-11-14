import SwiftUI

// MARK: - The Tabularium — the hall of records
//
// Opened by tapping the rank on the home bar. One place to see how far you've come: your rank and
// how many aurei to the next, every world's games with the laurels you hold, and the sound switch.

private let sealFor: [String: String] = [
    "Math": "SealTemple", "Geography": "SealLighthouse", "Language Arts": "SealLibrary",
    "Logic & Puzzles": "SealColosseum", "Science": "SealVesuvius", "History": "SealForum",
    "Money & Life Skills": "SealMarket", "Music": "SealTheatre",
]
private let placeFor: [String: String] = [
    "Math": "The Temple", "Geography": "The Lighthouse", "Language Arts": "The Library",
    "Logic & Puzzles": "The Colosseum", "Science": "Mount Vesuvius", "History": "The Forum",
    "Money & Life Skills": "The Market", "Music": "The Theatre",
]

private enum Tb {
    static let red = Color(hex: 0x8f2a1e)
    static let redDeep = Color(hex: 0x5e1812)
    static let gold = Color(hex: 0xd9a944)
    static let parchment = Color(hex: 0xf4e7c9)
    static let parchment2 = Color(hex: 0xe6d1a3)
    static let ink = Color(hex: 0x3a2412)
}

struct TabulariumView: View {
    let onClose: () -> Void
    @State private var sound = LudusSettings.sound

    var body: some View {
        let rank = LudusEconomy.rank
        let earned = LudusEconomy.aureiEarned
        ZStack {
            LinearGradient(colors: [Tb.red, Tb.redDeep], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "chevron.left").font(.system(size: 17, weight: .heavy))
                                .foregroundStyle(Tb.gold).frame(width: 42, height: 42)
                                .background(Circle().fill(Tb.redDeep).overlay(Circle().stroke(Tb.gold, lineWidth: 1.5)))
                        }
                        .buttonStyle(.plain).accessibilityLabel("Back to the map")
                        Spacer()
                        Button {
                            sound.toggle(); LudusSettings.sound = sound
                            if sound { Sfx.play(.tick) }
                        } label: {
                            Image(systemName: sound ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 16, weight: .bold)).foregroundStyle(Tb.gold)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Tb.redDeep).overlay(Circle().stroke(Tb.gold, lineWidth: 1.5)))
                        }
                        .buttonStyle(.plain).accessibilityLabel(sound ? "Sound on" : "Sound off")
                    }

                    Text("TABULARIUM").font(luCinzel(28)).tracking(3).foregroundStyle(Tb.parchment)
                    Text("The hall of records").font(luGaramond(15, semibold: true)).foregroundStyle(Tb.gold)

                    rankCard(rank: rank, earned: earned)

                    ForEach(ludusWorlds) { w in worldCard(w) }

                    Text("Laurels earn gold aurei: bronze 1, silver 2 more, gold 3 more.")
                        .font(luGaramond(13)).foregroundStyle(Tb.parchment.opacity(0.75))
                        .multilineTextAlignment(.center).padding(.bottom, 24)
                }
                .padding(.horizontal, 16).padding(.top, 6)
            }
        }
        .statusBarHidden(true)
    }

    private func rankCard(rank: LudusEconomy.Rank, earned: Int) -> some View {
        VStack(spacing: 10) {
            Image("Rank\(rank.index)").resizable().scaledToFit().frame(height: 70)
            // The ladder: four rungs, the reached ones gilt.
            HStack(spacing: 0) {
                ForEach(Array(LudusEconomy.rankSteps.enumerated()), id: \.offset) { i, step in
                    VStack(spacing: 3) {
                        Circle().fill(i <= rank.index ? Tb.gold : Tb.parchment2)
                            .overlay(Circle().stroke(Tb.ink.opacity(0.3), lineWidth: 1))
                            .frame(width: 16, height: 16)
                        Text(step.0).font(luCinzel(10, bold: true)).foregroundStyle(Tb.ink.opacity(i <= rank.index ? 1 : 0.45))
                        Text("\(step.1)").font(luGaramond(11)).foregroundStyle(Tb.ink.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            if let next = rank.next {
                let prev = LudusEconomy.rankSteps[rank.index].1
                let f = CGFloat(earned - prev) / CGFloat(max(1, next - prev))
                VStack(spacing: 4) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Tb.parchment2)
                            Capsule().fill(LinearGradient(colors: [Color(hex: 0xf3cb5c), Color(hex: 0xc78c24)], startPoint: .top, endPoint: .bottom))
                                .frame(width: max(10, g.size.width * min(1, f)))
                        }
                    }
                    .frame(height: 12)
                    HStack(spacing: 4) {
                        Image("CoinGold").resizable().frame(width: 16, height: 16)
                        Text("\(next - earned) more aure\(next - earned == 1 ? "us" : "i") to become \(LudusEconomy.rankSteps[rank.index + 1].0)")
                            .font(luGaramond(14, semibold: true)).foregroundStyle(Tb.ink)
                    }
                }
            } else {
                Text("The highest rank in Rome. Ave, Consul!").font(luGaramond(15, semibold: true)).foregroundStyle(Tb.ink)
            }
        }
        .padding(16)
        .background(parchment)
    }

    private func worldCard(_ w: LudusWorld) -> some View {
        let games = w.games.filter(\.playable)
        let won = games.filter(\.won).count
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let s = sealFor[w.subject] { Image(s).resizable().frame(width: 46, height: 46) }
                VStack(alignment: .leading, spacing: 1) {
                    Text(placeFor[w.subject] ?? w.name).font(luCinzel(17)).foregroundStyle(Tb.ink)
                    Text(w.subject.uppercased()).font(luCinzel(9.5, bold: true)).tracking(1).foregroundStyle(Tb.ink.opacity(0.55))
                }
                Spacer()
                Text("\(won)/\(games.count) won").font(luGaramond(14, semibold: true)).foregroundStyle(Tb.ink.opacity(0.7))
            }
            ForEach(games) { g in
                HStack(spacing: 10) {
                    Text(g.icon).font(.system(size: 22)).frame(width: 30)
                    Text(g.title).font(luGaramond(16, semibold: true)).foregroundStyle(Tb.ink).lineLimit(1).minimumScaleFactor(0.75)
                    Spacer(minLength: 4)
                    HStack(spacing: 6) {
                        ForEach([Medal.bronze, .silver, .gold], id: \.self) { m in
                            HStack(spacing: -4) {
                                Image(systemName: "laurel.leading"); Image(systemName: "laurel.trailing")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(g.medal >= m ? Color(hex: m == .silver ? 0x9aa0a8 : m.hex) : Tb.ink.opacity(0.15))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .background(parchment)
    }

    private var parchment: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: [Tb.parchment, Tb.parchment2], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Tb.gold, lineWidth: 1.5))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Tb.gold.opacity(0.4), lineWidth: 0.75).padding(3))
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
    }
}
