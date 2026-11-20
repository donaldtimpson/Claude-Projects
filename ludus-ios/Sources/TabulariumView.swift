import SwiftUI

// MARK: - The Tabularium — the hall of records
//
// Opened by tapping the rank on the home bar. One place to see how far you've come: the rank
// ladder (Tiro → Consul) with how many aurei to the next rung, and the laurel wall — every world's
// games as wax emblems, ringed in the metal of the best laurel held, three pips each for the
// laurels still to win. Plus the sound switch and "Switch player".
//
// Sideways iPad: the ladder is a column on the left, the whole wall on the right, no scrolling.
// Upright (iPad and phone): the ladder sits above the wall.

private enum Tb {
    static let red = Color(hex: 0x8f2a1e)
    static let redDeep = Color(hex: 0x5e1812)
    static let gold = Color(hex: 0xd9a944)
    static let parchment = Color(hex: 0xf4e7c9)
    static let parchment2 = Color(hex: 0xe6d1a3)
    static let ink = Color(hex: 0x3a2412)
    /// Laurel metals, tuned to read on parchment (the in-game silver is too pale here).
    static func metal(_ m: Medal) -> Color {
        switch m {
        case .none: return ink.opacity(0.18)
        case .bronze: return Color(hex: 0xa8612a)
        case .silver: return Color(hex: 0x8a96a3)
        case .gold: return Color(hex: 0xc9910f)
        }
    }
}

struct TabulariumView: View {
    let onClose: () -> Void
    @State private var sound = LudusSettings.sound
    @ObservedObject private var profiles = LudusProfiles.shared

    var body: some View {
        #if DEBUG
        let _ = ludusSeedDemoLaurels()
        #endif
        GeometryReader { geo in
            let wide = geo.size.width >= 600
            let landscape = wide && geo.size.width > geo.size.height && geo.size.width >= 900
            ZStack {
                LinearGradient(colors: [Tb.red, Tb.redDeep], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                if landscape {
                    HStack(alignment: .top, spacing: 28) {
                        VStack(spacing: 14) {
                            topBar(wide: true)
                            Spacer(minLength: 0)
                            ladder(vertical: true)
                            Spacer(minLength: 0)
                            playerButton(wide: true)
                        }
                        .frame(width: 320)
                        ScrollView(showsIndicators: false) {
                            wall(columns: 2, wide: true, emblem: 54)
                                .frame(minHeight: geo.size.height - 24)
                        }
                        .frame(width: geo.size.width - 320 - 3 * 28)
                    }
                    .padding(.vertical, 12)
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            topBar(wide: wide)
                            ladder(vertical: false, compact: wide)
                            wall(columns: wide ? 2 : 1, wide: wide, emblem: wide ? 44 : 54)
                            playerButton(wide: wide).padding(.top, 6)
                        }
                        .frame(maxWidth: wide ? 640 : .infinity)
                        .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 24)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .statusBarHidden(true)
    }

    // MARK: Chrome

    private func topBar(wide: Bool) -> some View {
        let d: CGFloat = wide ? 54 : 46
        return HStack(alignment: .top) {
            Button(action: onClose) {
                Image(systemName: "chevron.left").font(.system(size: wide ? 21 : 18, weight: .heavy))
                    .foregroundStyle(Tb.gold).frame(width: d, height: d)
                    .background(Circle().fill(Tb.redDeep).overlay(Circle().stroke(Tb.gold, lineWidth: 1.5)))
            }
            .buttonStyle(PlaqueButtonStyle()).accessibilityLabel("Back to the map")
            Spacer(minLength: 4)
            VStack(spacing: 2) {
                Text("TABULARIUM").font(luCinzel(wide ? 30 : 26)).tracking(wide ? 3 : 2.5).foregroundStyle(Tb.parchment)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("The hall of records").font(luGaramond(wide ? 18 : 16, semibold: true)).foregroundStyle(Tb.gold)
            }
            .padding(.top, 2)
            Spacer(minLength: 4)
            Button {
                sound.toggle(); LudusSettings.sound = sound
                if sound { Sfx.play(.tick) }
            } label: {
                Image(systemName: sound ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: wide ? 20 : 17, weight: .bold)).foregroundStyle(Tb.gold)
                    .frame(width: d, height: d)
                    .background(Circle().fill(Tb.redDeep).overlay(Circle().stroke(Tb.gold, lineWidth: 1.5)))
            }
            .buttonStyle(PlaqueButtonStyle()).accessibilityLabel(sound ? "Sound on" : "Sound off")
        }
    }

    /// Who's playing — tap to hand the iPad to someone else (or, with one child, to add a second).
    private func playerButton(wide: Bool) -> some View {
        let p = profiles.current
        let d: CGFloat = wide ? 48 : 40
        return Button {
            // The picker is presented from the app root, so step out of this cover first.
            onClose()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { LudusProfiles.shared.showPicker = true }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    if let p {
                        Circle().fill(Color(hex: LudusProfiles.waxes[p.wax % LudusProfiles.waxes.count]))
                        Text(LudusProfiles.emblems[p.emblem % LudusProfiles.emblems.count]).font(.system(size: d * 0.55))
                    } else {
                        Circle().fill(Tb.red)
                        Image(systemName: "person.fill.badge.plus").font(.system(size: d * 0.42, weight: .bold))
                            .foregroundStyle(Tb.parchment)
                    }
                    Circle().strokeBorder(Tb.gold, lineWidth: 2)
                }
                .frame(width: d, height: d)
                VStack(alignment: .leading, spacing: 0) {
                    Text(p?.name ?? "Add a player").font(luCinzel(wide ? 19 : 16)).foregroundStyle(Tb.parchment)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(p == nil ? "One save for each child" : "Switch player")
                        .font(luGaramond(wide ? 17 : 15, semibold: true)).foregroundStyle(Tb.gold)
                }
                Spacer(minLength: 6)
                Image(systemName: p == nil ? "plus" : "arrow.left.arrow.right")
                    .font(.system(size: wide ? 18 : 15, weight: .heavy)).foregroundStyle(Tb.gold)
            }
            .padding(.leading, 8).padding(.trailing, 18).padding(.vertical, 8)
            .frame(maxWidth: wide ? 360 : 320, minHeight: wide ? 64 : 56)
            .background(Capsule().fill(Tb.redDeep).overlay(Capsule().stroke(Tb.gold, lineWidth: 1.5)))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(PlaqueButtonStyle())
        .accessibilityLabel(p.map { "\($0.name). Switch player" } ?? "Add a player")
    }

    // MARK: The rank ladder

    /// Vertical (sideways iPad): the four gilt rank inscriptions as rungs, Consul at the top, the
    /// child's rung on a plate, the climb to the next as a bar between. Horizontal (upright): the
    /// current inscription large over a four-stop track (`compact`, upright iPad: side by side, so
    /// the whole wall fits below).
    private func ladder(vertical: Bool, compact: Bool = false) -> some View {
        let earned = LudusEconomy.aureiEarned
        let rank = LudusEconomy.rank
        return VStack(spacing: vertical ? 8 : 12) {
            if vertical {
                ForEach((0..<LudusEconomy.rankSteps.count).reversed(), id: \.self) { i in
                    if i == rank.index + 1 { nextBar(rank: rank, earned: earned) }
                    rung(i, rank: rank)
                }
            } else if compact {
                HStack(spacing: 18) {
                    VStack(spacing: 6) {
                        rankArt(rank.index, width: 220)
                        nextBar(rank: rank, earned: earned, short: true)
                    }
                    .frame(width: 230)
                    track(rank: rank)
                }
            } else {
                rankArt(rank.index, width: 300)
                track(rank: rank)
                nextBar(rank: rank, earned: earned)
            }
            laurelTally(explain: !compact)
        }
        .padding(vertical ? 12 : compact ? 14 : 16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Tb.gold.opacity(0.45), lineWidth: 1)))
    }

    /// The baked rank inscription (Rank<i>: laurels, name, pips), cropped to its lettering.
    private func rankArt(_ i: Int, width: CGFloat) -> some View {
        Image("Rank\(i)").resizable().frame(width: width, height: width * 228 / 660)
            .frame(width: width, height: width * 0.2).clipped()
    }

    private func rung(_ i: Int, rank: LudusEconomy.Rank) -> some View {
        let here = i == rank.index
        let reached = i <= rank.index
        let need = LudusEconomy.rankSteps[i].1
        return HStack(spacing: 0) {
            rankArt(i, width: 244).opacity(reached ? 1 : 0.4).saturation(reached ? 1 : 0.2)
            Spacer(minLength: 0)
            Group {
                if here {
                    Text("YOU").font(luCinzel(15)).tracking(1.5).foregroundStyle(Tb.ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Tb.gold))
                } else if !reached {
                    HStack(spacing: 4) {
                        Image("CoinGold").resizable().frame(width: 18, height: 18)
                        Text("\(need)").font(luCinzel(16, bold: true)).foregroundStyle(Tb.parchment.opacity(0.75))
                    }
                } else {
                    Image(systemName: "checkmark").font(.system(size: 16, weight: .heavy)).foregroundStyle(Tb.gold)
                }
            }
            .frame(width: 66)
        }
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12).fill(here ? Tb.redDeep : .clear)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(here ? Tb.gold : .clear, lineWidth: 1.5)))
    }

    private func track(rank: LudusEconomy.Rank) -> some View {
        let steps = LudusEconomy.rankSteps
        return HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                VStack(spacing: 4) {
                    Circle().fill(i <= rank.index ? Tb.gold : Tb.redDeep)
                        .overlay(Circle().stroke(Tb.gold, lineWidth: 1.5))
                        .frame(width: i == rank.index ? 22 : 16, height: i == rank.index ? 22 : 16)
                        .frame(height: 22)
                    Text(step.0).font(luCinzel(13, bold: true))
                        .foregroundStyle(Tb.parchment.opacity(i <= rank.index ? 1 : 0.55))
                        .lineLimit(1).minimumScaleFactor(0.8)
                    HStack(spacing: 3) {
                        Image("CoinGold").resizable().frame(width: 13, height: 13)
                        Text("\(step.1)").font(luGaramond(14, semibold: true)).foregroundStyle(Tb.parchment.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(alignment: .top) {
            Rectangle().fill(Tb.gold.opacity(0.5)).frame(height: 2).padding(.horizontal, 40).padding(.top, 10)
        }
    }

    /// The climb to the next rank, in aurei.
    @ViewBuilder private func nextBar(rank: LudusEconomy.Rank, earned: Int, short: Bool = false) -> some View {
        if let next = rank.next {
            let prev = LudusEconomy.rankSteps[rank.index].1
            let f = CGFloat(earned - prev) / CGFloat(max(1, next - prev))
            VStack(spacing: 6) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Tb.redDeep).overlay(Capsule().stroke(Tb.gold.opacity(0.6), lineWidth: 1))
                        Capsule().fill(LinearGradient(colors: [Color(hex: 0xf3cb5c), Color(hex: 0xc78c24)], startPoint: .top, endPoint: .bottom))
                            .frame(width: max(14, g.size.width * min(1, f)))
                    }
                }
                .frame(height: 14)
                HStack(spacing: 5) {
                    Image("CoinGold").resizable().frame(width: 18, height: 18)
                    let more = "\(next - earned) more aure\(next - earned == 1 ? "us" : "i")"
                    let to = LudusEconomy.rankSteps[rank.index + 1].0
                    Text(short ? "\(more) → \(to)" : "\(more) to become \(to)")
                        .font(luGaramond(16, semibold: true)).foregroundStyle(Tb.parchment)
                        .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.85)
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
        } else {
            Text(short ? "Ave, Consul!" : "The highest rank in Rome. Ave, Consul!").font(luGaramond(17, semibold: true)).foregroundStyle(Tb.parchment)
                .multilineTextAlignment(.center)
        }
    }

    /// Laurels held and still to win, across the arcade — and what each is worth.
    private func laurelTally(explain: Bool) -> some View {
        let specs = ludusWorlds.flatMap { $0.games.filter(\.playable) }
        let held = specs.reduce(0) { $0 + $1.medal.rawValue }
        let left = specs.count * 3 - held
        return VStack(spacing: 3) {
            HStack(spacing: 6) {
                LaurelPair(size: 15).foregroundStyle(Tb.gold)
                Text(left == 0 ? "Every laurel won!" : "\(held) laurels won · \(left) to win")
                    .font(luGaramond(17, semibold: true)).foregroundStyle(Tb.parchment)
                if !explain {
                    Text("· each earns aurei: bronze 1, silver 2, gold 3")
                        .font(luGaramond(15)).foregroundStyle(Tb.parchment.opacity(0.75))
                }
            }
            if explain {
                Text("Each laurel earns aurei: bronze 1, silver 2, gold 3")
                    .font(luGaramond(14)).foregroundStyle(Tb.parchment.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, explain ? 4 : 0)
    }

    // MARK: The laurel wall

    /// The eight worlds' plaques under a heading that keys the pips.
    private func wall(columns: Int, wide: Bool, emblem: CGFloat) -> some View {
        let grid = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: columns)
        return VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("THE LAUREL WALL").font(luCinzel(wide ? 21 : 18)).tracking(1.5).foregroundStyle(Tb.parchment)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                ForEach([Medal.bronze, .silver, .gold], id: \.self) { m in
                    HStack(spacing: 4) {
                        Circle().fill(Tb.metal(m)).overlay(Circle().stroke(Tb.parchment.opacity(0.6), lineWidth: 1))
                            .frame(width: 11, height: 11)
                        Text(["", "bronze", "silver", "gold"][m.rawValue]).font(luGaramond(15, semibold: true))
                            .foregroundStyle(Tb.parchment.opacity(0.85))
                    }
                }
            }
            .padding(.horizontal, 4)
            LazyVGrid(columns: grid, spacing: 12) {
                ForEach(ludusWorlds) { w in WorldPlaque(world: w, emblem: emblem) }
            }
        }
    }
}

/// One world on the laurel wall: seal, place, laurels left; its games as wax emblems.
private struct WorldPlaque: View {
    let world: LudusWorld
    let emblem: CGFloat

    var body: some View {
        let place = worldPlaces[world.subject] ?? .init(name: world.name, key: "Temple", wax: 0x8a5a34)
        let games = world.games.filter(\.playable)
        let left = games.count * 3 - games.reduce(0) { $0 + $1.medal.rawValue }
        let won = games.filter(\.won).count
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SealStack(key: place.key, progress: SealProgress(n: games.count, done: won))
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text(place.name).font(luCinzel(17)).foregroundStyle(Tb.ink).lineLimit(1).minimumScaleFactor(0.75)
                    Text(world.subject.uppercased()).font(luCinzel(13, bold: true)).tracking(0.8)
                        .foregroundStyle(waxInk(place.wax, 25)).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 2)
                if left == 0 {
                    Image(systemName: "crown.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Tb.metal(.gold))
                } else {
                    VStack(spacing: -2) {
                        Text("\(left)").font(luCinzel(19)).foregroundStyle(Tb.ink)
                        Text("to win").font(luGaramond(13, semibold: true)).foregroundStyle(Tb.ink.opacity(0.65))
                    }
                    .fixedSize()
                }
            }
            HStack(spacing: 6) {
                ForEach(games) { g in Emblem(spec: g, wax: place.wax, size: emblem) }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Tb.parchment, Tb.parchment2], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Tb.gold, lineWidth: 1.5))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Tb.gold.opacity(0.4), lineWidth: 0.75).padding(3))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        )
    }
}

/// A game's wax emblem, ringed in the metal of its best laurel; three pips under it, one per
/// laurel (bronze, silver, gold) — hollow until won.
private struct Emblem: View {
    let spec: GameSpec
    let wax: UInt
    let size: CGFloat

    var body: some View {
        let medal = spec.medal
        VStack(spacing: 5) {
            ZStack {
                Circle().fill(RadialGradient(colors: [luShade(wax, 40), Color(hex: wax), luShade(wax, -45)],
                                             center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: size * 0.6))
                    .padding(medal == .none ? 2 : 4)
                Circle().strokeBorder(medal == .none ? Tb.ink.opacity(0.22) : Tb.metal(medal),
                                      lineWidth: medal == .none ? 1.5 : 4)
                Text(spec.icon).font(.system(size: size * 0.46))
            }
            .frame(width: size, height: size)
            .saturation(medal == .none ? 0.55 : 1)
            HStack(spacing: 3) {
                ForEach([Medal.bronze, .silver, .gold], id: \.self) { m in
                    Circle().fill(medal >= m ? Tb.metal(m) : .clear)
                        .overlay(Circle().stroke(medal >= m ? .clear : Tb.ink.opacity(0.3), lineWidth: 1.2))
                        .frame(width: size * 0.17, height: size * 0.17)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(medal == .none ? "\(spec.title): no laurel yet" : "\(spec.title): \(medal.name)")
    }
}

/// The two laurel branches as one glyph.
private struct LaurelPair: View {
    let size: CGFloat
    var body: some View {
        HStack(spacing: -size * 0.2) {
            Image(systemName: "laurel.leading"); Image(systemName: "laurel.trailing")
        }
        .font(.system(size: size, weight: .bold))
    }
}

#if DEBUG
/// LUDUS_DEMO_LAURELS=1 fakes a spread of levels across every game (once per launch), so the
/// records wall and the world pages can be checked with progress on them (=0 wipes every level).
func ludusSeedDemoLaurels() {
    guard let v = ProcessInfo.processInfo.environment["LUDUS_DEMO_LAURELS"], !DemoLaurels.done else { return }
    DemoLaurels.done = true
    let spread = v == "0" ? [0] : [0, 1, 3, 0, 5, 8, 2, 4, 9, 0, 6]
    var k = 0
    for w in ludusWorlds {
        for g in w.games { if let id = g.game {
            LudusStore.defaults.set(spread[(k * 7) % spread.count], forKey: LudusProgress.levelKey(id.rawValue)); k += 1
        } }
    }
}
private enum DemoLaurels { nonisolated(unsafe) static var done = false }
#endif
