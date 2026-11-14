import SwiftUI

// MARK: - Forum folk (Time Travelers · shared drawing kit)
//
// The people of the History world, drawn from shapes so they look intentional at any size: a
// round head with real eyes and brows, a mouth that reacts, a tunic, and a hat that says who they
// are (a legionary's crested helmet, an emperor's laurel, an archaeologist's sun hat, a stonemason's
// cap). Every Forum game uses them, so the world feels like one place with one cast.

struct ForumPerson: View {
    enum Mood: Equatable { case idle, happy, cheer, oops, think, talk }
    enum Hat: Equatable { case helmet, laurel, sunHat, cap, hair(UInt), hood }

    var mood: Mood = .idle
    var hat: Hat = .hair(0x4a2f1e)
    var tunic: UInt = 0xc0392b
    var skin: UInt = 0xf2c59a
    var size: CGFloat = 120          // overall height
    var beard = false
    var lookX: CGFloat = 0           // pupils -1 … 1

    var body: some View {
        let s = size / 100
        ZStack {
            // Arms (behind the body): raised for a cheer.
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(Color(hex: skin))
                    .frame(width: 9 * s, height: 30 * s)
                    .rotationEffect(.degrees(armAngle * side), anchor: .top)
                    .offset(x: CGFloat(side) * 21 * s, y: 13 * s)
            }
            // Body: tunic with a belt.
            ZStack {
                RoundedRectangle(cornerRadius: 14 * s)
                    .fill(LinearGradient(colors: [luShade(tunic, 18), luShade(tunic, -28)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 46 * s, height: 44 * s)
                Rectangle().fill(Color(hex: 0x5a3a1a)).frame(width: 46 * s, height: 4.5 * s).offset(y: 6 * s)
                Circle().fill(Color(hex: Lu.gold)).frame(width: 5 * s).offset(y: 6 * s)
            }
            .offset(y: 16 * s)
            // Neck + head.
            Rectangle().fill(Color(hex: skin)).frame(width: 12 * s, height: 10 * s).offset(y: -8 * s)
            head(s).offset(y: -28 * s)
        }
        .frame(width: 80 * s, height: 100 * s)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: mood)
    }

    private var armAngle: Double {
        switch mood {
        case .cheer: return 150
        case .happy: return 35
        case .oops: return 70
        case .think: return 20
        default: return 14
        }
    }

    private func head(_ s: CGFloat) -> some View {
        ZStack {
            // Hat behind the head (crest, hat brim back, hood).
            hatBack(s)
            Circle().fill(Color(hex: skin)).frame(width: 40 * s, height: 40 * s)
            // Ears.
            Circle().fill(luShade(skin, -18)).frame(width: 9 * s).offset(x: -20 * s, y: 2 * s)
            Circle().fill(luShade(skin, -18)).frame(width: 9 * s).offset(x: 20 * s, y: 2 * s)
            if beard {
                Ellipse().fill(Color(hex: 0x5a3a22)).frame(width: 34 * s, height: 22 * s).offset(y: 11 * s)
                    .mask(Rectangle().frame(width: 40 * s, height: 16 * s).offset(y: 14 * s))
            }
            // Cheeks.
            Circle().fill(Color(hex: Lu.coral).opacity(0.3)).frame(width: 8 * s).offset(x: -11 * s, y: 6 * s)
            Circle().fill(Color(hex: Lu.coral).opacity(0.3)).frame(width: 8 * s).offset(x: 11 * s, y: 6 * s)
            eyes(s).offset(y: -2 * s)
            brows(s).offset(y: -10 * s)
            mouth(s).offset(y: 10 * s)
            hatFront(s)
        }
    }

    @ViewBuilder private func eyes(_ s: CGFloat) -> some View {
        HStack(spacing: 9 * s) {
            ForEach(0..<2, id: \.self) { _ in
                if mood == .happy || mood == .cheer {
                    ForumArc().stroke(Color(hex: 0x2a1a10), style: StrokeStyle(lineWidth: 2.4 * s, lineCap: .round))
                        .frame(width: 8 * s, height: 4 * s)
                } else {
                    ZStack {
                        Ellipse().fill(.white).frame(width: 9 * s, height: mood == .oops ? 11 * s : 9 * s)
                        Circle().fill(Color(hex: 0x2a1a10)).frame(width: 5 * s)
                            .offset(x: lookX * 2 * s, y: mood == .think ? -2 * s : 0)
                    }
                }
            }
        }
    }

    private func brows(_ s: CGFloat) -> some View {
        let tilt: Double = mood == .oops ? 14 : (mood == .think ? -10 : 0)
        let lift: CGFloat = mood == .oops || mood == .cheer ? -2.5 * s : 0
        return HStack(spacing: 8 * s) {
            Capsule().fill(Color(hex: 0x3a2412)).frame(width: 9 * s, height: 2.2 * s).rotationEffect(.degrees(tilt))
            Capsule().fill(Color(hex: 0x3a2412)).frame(width: 9 * s, height: 2.2 * s).rotationEffect(.degrees(-tilt))
        }
        .offset(y: lift)
    }

    @ViewBuilder private func mouth(_ s: CGFloat) -> some View {
        switch mood {
        case .cheer, .talk:
            Ellipse().fill(Color(hex: 0x6a1f1f)).frame(width: 11 * s, height: (mood == .cheer ? 9 : 6) * s)
        case .happy:
            ForumArc().stroke(Color(hex: 0x6a1f1f), style: StrokeStyle(lineWidth: 2.4 * s, lineCap: .round))
                .frame(width: 13 * s, height: 5 * s).rotationEffect(.degrees(180))
        case .oops:
            Circle().fill(Color(hex: 0x6a1f1f)).frame(width: 7 * s)
        case .think:
            Capsule().fill(Color(hex: 0x6a1f1f)).frame(width: 8 * s, height: 2.2 * s).rotationEffect(.degrees(-10)).offset(x: 3 * s)
        case .idle:
            ForumArc().stroke(Color(hex: 0x6a1f1f), style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
                .frame(width: 9 * s, height: 3 * s).rotationEffect(.degrees(180))
        }
    }

    @ViewBuilder private func hatBack(_ s: CGFloat) -> some View {
        switch hat {
        case .helmet:
            // Red horsehair crest, front to back.
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xe0443a), Color(hex: 0x9a1f1a)], startPoint: .top, endPoint: .bottom))
                .frame(width: 40 * s, height: 16 * s).offset(y: -31 * s)
        case .hood:
            Circle().fill(Color(hex: 0x6b5a8a)).frame(width: 50 * s).offset(y: 2 * s)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private func hatFront(_ s: CGFloat) -> some View {
        switch hat {
        case .helmet:
            ZStack {
                // Bronze-iron bowl with a brow ridge and cheek guards.
                ForumDome().fill(LinearGradient(colors: [Color(hex: 0xd9dde3), Color(hex: 0x8d939c)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44 * s, height: 17 * s).offset(y: -20 * s)
                Capsule().fill(Color(hex: Lu.gold)).frame(width: 46 * s, height: 4 * s).offset(y: -12.5 * s)
                RoundedRectangle(cornerRadius: 3 * s).fill(Color(hex: 0xa9aeb6)).frame(width: 7 * s, height: 18 * s).offset(x: -19 * s, y: -3 * s)
                RoundedRectangle(cornerRadius: 3 * s).fill(Color(hex: 0xa9aeb6)).frame(width: 7 * s, height: 18 * s).offset(x: 19 * s, y: -3 * s)
            }
        case .laurel:
            ZStack {
                ForumDome().fill(Color(hex: 0x5a3a22)).frame(width: 40 * s, height: 16 * s).offset(y: -13 * s)
                ForEach(0..<7, id: \.self) { k in
                    let a = Double(k - 3) * 22
                    Ellipse().fill(Color(hex: k.isMultiple(of: 2) ? 0x5f9e3a : 0x7bbf4a))
                        .frame(width: 6 * s, height: 11 * s)
                        .rotationEffect(.degrees(a + 90))
                        .offset(x: CGFloat(sin(a * .pi / 180)) * 21 * s, y: -CGFloat(cos(a * .pi / 180)) * 15 * s - 2 * s)
                }
            }
        case .sunHat:
            ZStack {
                Ellipse().fill(Color(hex: 0xc9a46a)).frame(width: 62 * s, height: 12 * s).offset(y: -12 * s)
                ForumDome().fill(Color(hex: 0xd8b77c)).frame(width: 36 * s, height: 18 * s).offset(y: -24 * s)
                Rectangle().fill(Color(hex: 0x7a4a26)).frame(width: 36 * s, height: 4 * s).offset(y: -17 * s)
            }
        case .cap:
            ZStack {
                ForumDome().fill(Color(hex: 0x8a6a4a)).frame(width: 42 * s, height: 18 * s).offset(y: -12 * s)
                Capsule().fill(Color(hex: 0x6f5238)).frame(width: 44 * s, height: 4 * s).offset(y: -4 * s)
            }
        case .hair(let c):
            ForumDome().fill(Color(hex: c)).frame(width: 42 * s, height: 18 * s).offset(y: -12 * s)
        case .hood:
            ForumDome().fill(Color(hex: 0x7d6b9e)).frame(width: 46 * s, height: 22 * s).offset(y: -12 * s)
        }
    }
}

/// An arc bulging upward (a closed happy eye; flipped, a smile).
struct ForumArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.6))
        return p
    }
}

/// A half-disc sitting on its flat side (helmet bowls, hair, hats).
struct ForumDome: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                   control1: CGPoint(x: r.minX, y: r.minY - r.height * 0.3),
                   control2: CGPoint(x: r.maxX, y: r.minY - r.height * 0.3))
        p.closeSubpath()
        return p
    }
}

struct ForumTriangle: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
    }
}

/// A speech bubble with a tail pointing down-left toward the speaker.
struct ForumBubble<Content: View>: View {
    var fill: UInt = 0xfdf6e3
    var tailX: CGFloat = 0.18
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                GeometryReader { g in
                    ZStack {
                        RoundedRectangle(cornerRadius: 18).fill(Color(hex: fill))
                        ForumTriangle().fill(Color(hex: fill))
                            .frame(width: 18, height: 14).rotationEffect(.degrees(180))
                            .position(x: g.size.width * tailX, y: g.size.height + 6)
                    }
                }
            )
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
}

/// A side-to-side shake re-triggered by bumping `shakes`.
struct ForumShake: GeometryEffect {
    var amount: CGFloat = 9
    var shakes: CGFloat
    var animatableData: CGFloat { get { shakes } set { shakes = newValue } }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(shakes * .pi * 4), y: 0))
    }
}

/// Run `f` after `s` seconds if the model is still on the same round and still playing.
@MainActor
func forumAfter<M: ArcadeModel>(_ m: M, _ s: Double, round: @escaping (M) -> Int, _ f: @escaping (M) -> Void) {
    let n = round(m)
    DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak m] in
        guard let m, m.phase == .playing, round(m) == n else { return }
        f(m)
    }
}
