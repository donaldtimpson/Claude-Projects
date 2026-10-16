import SwiftUI

// MARK: - World landing page — "entering" a landmark
//
// The landmark's own corner of the painted map (Vista<key>, baked by tools/chrome/landing_build.py)
// is the hero; below it the page turns to parchment: the seal with its laurel ring, the place's
// name, and one tablet per game — its emblem in a wax roundel, how far the child has climbed
// (Gradus) and the three laurels. Static apart from a one-off entrance, so it idles at 0%.

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
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Page.paper, Page.paper2], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero(width: geo.size.width, topInset: topInset)
                        header.padding(.top, -48)
                        VStack(spacing: 12) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { i, spec in
                                GameTablet(spec: spec, wax: place.wax) { if let id = spec.game { active = id } }
                                    .opacity(shown ? 1 : 0)
                                    .offset(y: shown ? 0 : 24)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.12 + Double(i) * 0.06), value: shown)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 40)
                    }
                }
                .ignoresSafeArea(edges: .top)
                backButton.padding(.leading, 14).padding(.top, 6)
            }
        }
        .navigationBarHidden(true)
        .onAppear { shown = true }
        .fullScreenCover(item: $active, onDismiss: { refresh += 1 }) { id in
            ludusGame(id, onClose: { active = nil })
        }
    }

    // The landmark's corner of the map, fading into the page; stretches on pull-down.
    private func hero(width: CGFloat, topInset: CGFloat) -> some View {
        GeometryReader { g in
            let pull = max(0, g.frame(in: .global).minY)
            Image("Vista" + place.key).resizable().aspectRatio(contentMode: .fill)
                .frame(width: width, height: Page.heroH + topInset + pull)
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
        .frame(height: Page.heroH + topInset)
    }

    private var header: some View {
        let n = games.count
        let won = games.filter(\.won).count
        return VStack(spacing: 6) {
            SealStack(key: place.key, progress: SealProgress(n: n, done: won))
                .frame(width: 92, height: 92)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
            Text(world.subject.uppercased())
                .font(luCinzel(12, bold: true)).tracking(2).foregroundStyle(waxInk(place.wax, 25))
            ZStack {
                Text(place.name.uppercased()).foregroundStyle(Color(hex: 0xfff5dc).opacity(0.6)).offset(y: 0.8)
                Text(place.name.uppercased()).foregroundStyle(Prov.ink)
            }
            .font(luCinzel(30)).tracking(0.8).lineLimit(1).minimumScaleFactor(0.6)
            .padding(.horizontal, 20)
            Text(won == 0 ? "\(n) games to win" : won >= n ? "Every game won — Ave!" : "\(won) of \(n) games won")
                .font(luGaramond(17, semibold: true)).foregroundStyle(Prov.ink.opacity(0.7))
            HStack(spacing: 14) {
                Rectangle().fill(Prov.rule.opacity(0.8)).frame(height: 0.8)
                Rectangle().fill(Prov.rule.opacity(0.8)).frame(height: 0.8)
            }
            .overlay(Rectangle().fill(Prov.red).frame(width: 6, height: 6).rotationEffect(.degrees(45)))
            .padding(.horizontal, 40).padding(.top, 6)
        }
    }

    private var backButton: some View {
        Button { if let onBack { onBack() } else { dismiss() } } label: {
            Image(systemName: "chevron.left").font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: 0xfff3d6))
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color(hex: 0x6a1a16).opacity(0.92))
                    .overlay(Circle().strokeBorder(Page.gilt, lineWidth: 2)))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        }
        .buttonStyle(PlaqueButtonStyle())
        .accessibilityLabel("Back to the map")
    }
}

/// One game on the landing page: emblem roundel, title, premise, laurels + highest Gradus.
private struct GameTablet: View {
    let spec: GameSpec
    let wax: UInt
    let onPlay: () -> Void

    var body: some View {
        let reached = spec.game.map { LudusProgress.maxLevel($0.rawValue) } ?? 0
        let medal = spec.medal
        Button(action: onPlay) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [luShade(wax, 40), Color(hex: wax), luShade(wax, -45)],
                                                 center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: 40))
                    Circle().strokeBorder(Page.gilt, lineWidth: 2.5)
                    Circle().strokeBorder(Color.black.opacity(0.2), lineWidth: 0.8).padding(4)
                    Text(spec.icon).font(.system(size: 30))
                }
                .frame(width: 62, height: 62)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1.5)

                VStack(alignment: .leading, spacing: 3) {
                    Text(spec.title.uppercased()).font(luCinzel(16)).foregroundStyle(Prov.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(spec.premise).font(luGaramond(15)).foregroundStyle(Prov.ink.opacity(0.72))
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        ForEach([Medal.bronze, .silver, .gold], id: \.self) { m in
                            LaurelMedal(medal: m, earned: medal >= m, size: 13)
                                .opacity(medal >= m ? 1 : 0.35)
                                .colorMultiply(medal >= m ? .white : Color(hex: 0x8a6a3a))
                        }
                        if reached > 0 {
                            Text("Gradus \(romanNumeral(reached))").font(luCinzel(11, bold: true))
                                .foregroundStyle(waxInk(wax, 30)).padding(.leading, 4)
                        }
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 4)
                Image(systemName: "play.fill").font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color(hex: 0xfff3d6))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Prov.red).overlay(Circle().strokeBorder(Page.gilt, lineWidth: 1.5)))
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
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
