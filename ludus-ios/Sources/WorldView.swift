import SwiftUI

// MARK: - World screen — the game list for one subject
//
// Each game is a card carrying its title, mechanic tag, one-line premise and best score.
// Playable games launch full-screen; the rest are dimmed "coming soon" tiles.

struct WorldView: View {
    let world: LudusWorld
    @State private var active: GameID?

    var body: some View {
        ZStack {
            LudusBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Text(world.emoji).font(.system(size: 40))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(world.name).font(luSerif(26, .black)).foregroundStyle(Color(hex: Lu.ink))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(world.subject.uppercased()).font(luFont(11, .heavy)).tracking(1.4)
                                .foregroundStyle(Color(hex: world.colorHex))
                        }
                        Spacer()
                    }
                    .padding(.top, 6)
                    MeanderRule().padding(.horizontal, 40).padding(.bottom, 2)

                    ForEach(world.games) { spec in
                        GameCard(spec: spec, accent: world.colorHex) {
                            if let id = spec.game { active = id }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
        }
        .navigationTitle(world.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: $active) { id in
            ludusGame(id, onClose: { active = nil })
        }
    }
}

private struct GameCard: View {
    let spec: GameSpec
    let accent: UInt
    let onPlay: () -> Void

    private var best: Int { spec.game.map { LudusStore.best($0.rawValue) } ?? 0 }

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(spec.title).font(luSerif(19, .black)).foregroundStyle(Color(hex: Lu.ink))
                        Text(spec.mechanic.uppercased()).font(luFont(9, .heavy)).tracking(0.8)
                            .foregroundStyle(Color(hex: Lu.inkDark))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: accent)))
                    }
                    Text(spec.premise).font(luFont(13, .semibold))
                        .foregroundStyle(Color(hex: Lu.inkDim))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    if spec.playable && best > 0 {
                        Text("BEST \(best)").font(luFont(11, .heavy)).monospacedDigit()
                            .foregroundStyle(Color(hex: Lu.gold))
                    }
                }
                Spacer(minLength: 8)
                if spec.playable {
                    Image(systemName: "play.fill").font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color(hex: Lu.inkDark))
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color(hex: accent)))
                } else {
                    Text("SOON").font(luFont(11, .heavy)).tracking(1)
                        .foregroundStyle(Color(hex: Lu.inkDim))
                        .frame(width: 46, height: 46)
                        .background(Circle().stroke(Color(hex: Lu.line), lineWidth: 2))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(luPanelShape(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: Lu.goldLine).opacity(spec.playable ? 0.45 : 0.15), lineWidth: 1.5)))
            .opacity(spec.playable ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!spec.playable)
    }
}
