import SwiftUI

// MARK: - World landing page — "entering" a landmark
//
// The landmark's own corner of the painted map (Vista<key>, baked by tools/chrome/landing_build.py)
// is the hero; below it the page turns to parchment: the seal with its laurel ring, the place's
// name, and one tablet per game — its emblem in a wax roundel, how far the child has climbed
// (Gradus) and the three laurels. Static apart from a one-off entrance, so it idles at 0%.
//
// On an iPad held sideways the vista becomes a full-height left column with the seal and name over
// its fade, and the five tablets stand beside it; upright, the vista is shorter so all five fit.

/// Where each world lives on the map (mirrors HomeView `landmarks`): the place's name, its chrome
/// key (Seal<key>, Vista<key>) and its wax colour.
struct WorldPlace {
    let name: String, key: String, wax: UInt
}

let worldPlaces: [String: WorldPlace] = [
    "Language Arts":       .init(name: "The Library",    key: "Library",    wax: 0x3f8a4a),
    "History":             .init(name: "The Forum",      key: "Forum",      wax: 0x8a5a34),
    "Science":             .init(name: "Mount Vesuvius", key: "Vesuvius",   wax: 0xc8642a),
    "Logic & Puzzles":     .init(name: "The Colosseum",  key: "Colosseum",  wax: 0x7a4aa8),
    "Math":                .init(name: "The Temple",     key: "Temple",     wax: 0xb8402e),
    "Money & Life Skills": .init(name: "The Market",     key: "Market",     wax: 0x1f7a6a),
    "Geography":           .init(name: "The Lighthouse", key: "Lighthouse", wax: 0x2f7fae),
    "Music":               .init(name: "The Theatre",    key: "Theatre",    wax: 0xa63a6a),
]

private enum Page {
    static let paper = Color(hex: 0xefdfba)
    static let paper2 = Color(hex: 0xe4cd9b)
    static let tablet = Color(hex: 0xf8edd3)
    static let gilt = Color(hex: 0xc99a3a)
    static let heroH: CGFloat = 318
    static let heroWideH: CGFloat = 236        // upright iPad: shorter, so all five tablets fit
}

struct WorldView: View {
    let world: LudusWorld
    var onBack: (() -> Void)? = nil               // nil = pushed in a NavigationStack (pop instead)
    @State private var active: GameID?
    @State private var shown = false
    @State private var refresh = 0                 // bumps when a game closes, to re-read laurels
    @Environment(\.dismiss) private var dismiss

    private var place: WorldPlace { worldPlaces[world.subject] ?? .init(name: world.name, key: "Temple", wax: 0x8a5a34) }
    private var games: [GameSpec] { world.games.filter(\.playable) }

    var body: some View {
        let _ = refresh
        #if DEBUG
        let _ = ludusSeedDemoLaurels()
        #endif
        GeometryReader { geo in
            let ins = geo.safeAreaInsets
            let wide = geo.size.width >= 600
            let landscape = wide && geo.size.width > geo.size.height && geo.size.width >= 900
            ZStack(alignment: .topLeading) {
                // flat paper where the vista fades out (no seam), deepening further down
                LinearGradient(stops: [.init(color: Page.paper, location: 0), .init(color: Page.paper, location: 0.45),
                                       .init(color: Page.paper2, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                if landscape {
                    sideBySide(size: geo.size, insets: ins)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            hero(width: geo.size.width, height: wide ? Page.heroWideH : Page.heroH, topInset: ins.top)
                            if wide {
                                // Upright iPad: seal beside the name, phone-sized tablets (the stage
                                // already scales them up), so all five fit under the vista.
                                sideHeader.padding(.top, -44)
                            } else {
                                header(wide: false).padding(.top, -48)
                            }
                            tablets(wide: false)
                                .frame(maxWidth: wide ? 600 : .infinity)
                                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, wide ? 24 : 40)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }
                backButton(wide: wide).padding(.leading, wide ? 20 : 14).padding(.top, wide ? 10 : 6)
            }
        }
        .navigationBarHidden(true)
        .onAppear { shown = true }
        .fullScreenCover(item: $active, onDismiss: { refresh += 1 }) { id in
            ludusGame(id, onClose: { active = nil })
        }
    }

    private func tablets(wide: Bool) -> some View {
        VStack(spacing: wide ? 14 : 12) {
            ForEach(Array(games.enumerated()), id: \.element.id) { i, spec in
                GameTablet(spec: spec, wax: place.wax, wide: wide) { if let id = spec.game { active = id } }
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown ? 0 : 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.12 + Double(i) * 0.06), value: shown)
            }
        }
    }

    // Sideways iPad: the vista as a full-height column (seal and name over its fade), tablets beside.
    private func sideBySide(size: CGSize, insets: EdgeInsets) -> some View {
        let fullH = size.height + insets.top + insets.bottom
        let heroW = (size.width * 0.42).rounded()
        return HStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Image("Vista" + place.key).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: heroW, height: fullH)
                    .scaleEffect(shown ? 1 : 1.12, anchor: .center)
                    .animation(.easeOut(duration: 0.9), value: shown)
                    .clipped()
                LinearGradient(stops: [.init(color: Page.paper.opacity(0), location: 0),
                                       .init(color: Page.paper.opacity(0.9), location: 0.5),
                                       .init(color: Page.paper, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: fullH * 0.52)
                LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: insets.top + 70).frame(maxHeight: .infinity, alignment: .top)
                header(wide: true).padding(.bottom, insets.bottom + 40)
            }
            .frame(width: heroW, height: fullH)
            // a soft seam where the painting meets the parchment
            .overlay(alignment: .trailing) {
                LinearGradient(colors: [Page.paper.opacity(0), Page.paper], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 90)
            }
            .clipped()

            ScrollView(showsIndicators: false) {
                tablets(wide: true)
                    .frame(maxWidth: 580)
                    .padding(.horizontal, 28)
                    .padding(.top, insets.top + 12).padding(.bottom, insets.bottom + 12)
                    .frame(maxWidth: .infinity, minHeight: fullH)
            }
        }
        .frame(width: size.width, height: fullH)
        .ignoresSafeArea()
    }

    // The landmark's corner of the map, fading into the page; stretches on pull-down.
    private func hero(width: CGFloat, height: CGFloat, topInset: CGFloat) -> some View {
        GeometryReader { g in
            let pull = max(0, g.frame(in: .named(LudusStage<EmptyView>.space)).minY)
            Image("Vista" + place.key).resizable().aspectRatio(contentMode: .fill)
                .frame(width: width, height: height + topInset + pull)
                .scaleEffect(shown ? 1 : 1.12, anchor: .center)
                .animation(.easeOut(duration: 0.9), value: shown)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [Page.paper.opacity(0), Page.paper.opacity(0.85), Page.paper],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                }
                .overlay(alignment: .top) {
                    LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: topInset + 60)
                }
                .offset(y: -pull)
        }
        .frame(height: height + topInset)
    }

    /// The upright-iPad header: seal on the left, subject / name / tally beside it.
    private var sideHeader: some View {
        let n = games.count
        let won = games.filter(\.won).count
        return HStack(spacing: 18) {
            SealStack(key: place.key, progress: SealProgress(n: n, done: won))
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(world.subject.uppercased())
                    .font(luCinzel(15, bold: true)).tracking(2).foregroundStyle(waxInk(place.wax, 25))
                ZStack {
                    Text(place.name.uppercased()).foregroundStyle(Color(hex: 0xfff5dc).opacity(0.6)).offset(y: 0.8)
                    Text(place.name.uppercased()).foregroundStyle(Prov.ink)
                }
                .font(luCinzel(32)).tracking(0.8).lineLimit(1).minimumScaleFactor(0.6)
                Text(won == 0 ? "\(n) games to win" : won >= n ? "Every game won — Ave!" : "\(won) of \(n) games won")
                    .font(luGaramond(18, semibold: true)).foregroundStyle(Prov.ink.opacity(0.75))
            }
            .padding(.top, 30)
        }
        .frame(maxWidth: 600 - 32, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private func header(wide: Bool) -> some View {
        let n = games.count
        let won = games.filter(\.won).count
        return VStack(spacing: 6) {
            SealStack(key: place.key, progress: SealProgress(n: n, done: won))
                .frame(width: wide ? 104 : 92, height: wide ? 104 : 92)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
            Text(world.subject.uppercased())
                .font(luCinzel(wide ? 15 : 13, bold: true)).tracking(2).foregroundStyle(waxInk(place.wax, 25))
            ZStack {
                Text(place.name.uppercased()).foregroundStyle(Color(hex: 0xfff5dc).opacity(0.6)).offset(y: 0.8)
                Text(place.name.uppercased()).foregroundStyle(Prov.ink)
            }
            .font(luCinzel(wide ? 34 : 30)).tracking(0.8).lineLimit(1).minimumScaleFactor(0.6)
            .padding(.horizontal, 20)
            Text(won == 0 ? "\(n) games to win" : won >= n ? "Every game won — Ave!" : "\(won) of \(n) games won")
                .font(luGaramond(wide ? 19 : 17, semibold: true)).foregroundStyle(Prov.ink.opacity(0.75))
            HStack(spacing: 14) {
                Rectangle().fill(Prov.rule.opacity(0.8)).frame(height: 0.8)
                Rectangle().fill(Prov.rule.opacity(0.8)).frame(height: 0.8)
            }
            .overlay(Rectangle().fill(Prov.red).frame(width: 6, height: 6).rotationEffect(.degrees(45)))
            .frame(maxWidth: 420)
            .padding(.horizontal, 40).padding(.top, 6)
        }
    }

    private func backButton(wide: Bool) -> some View {
        Button { if let onBack { onBack() } else { dismiss() } } label: {
            Image(systemName: "chevron.left").font(.system(size: wide ? 20 : 17, weight: .bold))
                .foregroundStyle(Color(hex: 0xfff3d6))
                .frame(width: wide ? 50 : 44, height: wide ? 50 : 44)
                .background(Circle().fill(Color(hex: 0x6a1a16).opacity(0.92))
                    .overlay(Circle().strokeBorder(Page.gilt, lineWidth: 2)))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        }
        .buttonStyle(PlaqueButtonStyle())
        .accessibilityLabel("Back to the map")
    }
}

/// One game on the landing page: emblem roundel, title, premise, laurels + highest Gradus.
/// `wide` = iPad: a size up all round. (Tap goes straight to the game — its intro card already
/// shows the how-to and the laurel goals, so expanding the tablet first would only add a tap.)
private struct GameTablet: View {
    let spec: GameSpec
    let wax: UInt
    var wide = false
    let onPlay: () -> Void

    var body: some View {
        let reached = spec.game.map { LudusProgress.maxLevel($0.rawValue) } ?? 0
        let medal = spec.medal
        Button(action: onPlay) {
            HStack(spacing: wide ? 16 : 14) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [luShade(wax, 40), Color(hex: wax), luShade(wax, -45)],
                                                 center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: 40))
                    Circle().strokeBorder(Page.gilt, lineWidth: 2.5)
                    Circle().strokeBorder(Color.black.opacity(0.2), lineWidth: 0.8).padding(4)
                    Text(spec.icon).font(.system(size: wide ? 36 : 30))
                }
                .frame(width: wide ? 72 : 62, height: wide ? 72 : 62)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1.5)

                VStack(alignment: .leading, spacing: 3) {
                    Text(spec.title.uppercased()).font(luCinzel(wide ? 18 : 16)).foregroundStyle(Prov.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(spec.premise).font(luGaramond(wide ? 17 : 15)).foregroundStyle(Prov.ink.opacity(0.75))
                        .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: wide ? 8 : 6) {
                        // metals tuned to read on parchment (the in-game silver is too pale here)
                        ForEach([(Medal.bronze, 0xa8612a), (.silver, 0x7f8b97), (.gold, 0xc28a12)], id: \.0) { m, hex in
                            HStack(spacing: -2.5) {
                                Image(systemName: "laurel.leading")
                                Image(systemName: "laurel.trailing")
                            }
                            .font(.system(size: wide ? 16 : 14, weight: .bold))
                            .foregroundStyle(Color(hex: medal >= m ? UInt(hex) : 0xc4ad80))
                        }
                        if reached > 0 {
                            Text("Gradus \(romanNumeral(reached))").font(luCinzel(wide ? 15 : 13, bold: true))
                                .foregroundStyle(waxInk(wax, 30)).padding(.leading, 4)
                        }
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 4)
                Image(systemName: "play.fill").font(.system(size: wide ? 19 : 15, weight: .black))
                    .foregroundStyle(Color(hex: 0xfff3d6))
                    .frame(width: wide ? 50 : 38, height: wide ? 50 : 38)
                    .background(Circle().fill(Prov.red).overlay(Circle().strokeBorder(Page.gilt, lineWidth: 1.5)))
            }
            .padding(.horizontal, wide ? 18 : 14).padding(.vertical, wide ? 14 : 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Page.tablet)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Page.gilt.opacity(0.75), lineWidth: 1.2))
                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(Page.gilt.opacity(0.3), lineWidth: 0.6).padding(4))
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0x7a5420).opacity(0.22)).offset(y: 2.5))
            )
        }
        .buttonStyle(PlaqueButtonStyle())
        .accessibilityLabel("\(spec.title). \(spec.premise)")
    }
}
