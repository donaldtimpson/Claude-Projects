import SwiftUI

// MARK: - Duel in the Arena — two players, one flat iPad
//
// The arena floor seen from above: raked sand, the stands' red-and-cream awning at both ends, and
// a marble spina across the middle carrying each player's laurel tally. The screen splits into two
// halves facing the two edges the children sit at; the top half is turned 180° so its player reads
// it the right way up. The halves always face the screen's top and bottom edges: lying flat, an
// iPad keeps whichever way it was last held, so the children simply sit at those two edges — across
// the long sides in landscape (each gets a wide strip, close enough to share), across the short ends
// in portrait. Every half is laid out from its own size, so the same code serves phone and iPad.
//
// Answers fire on touch-DOWN (a race shouldn't wait for a finger to lift), each on its own gesture,
// so presses on both halves land at the same time.

struct DuelView: View {
    let onClose: () -> Void
    @StateObject private var model = DuelModel()

    var body: some View {
        // The outer reader only learns the safe-area insets; the inner one spans the whole screen.
        GeometryReader { outer in
            let ins = outer.safeAreaInsets
            GeometryReader { g in
                let bandH: CGFloat = g.size.width < 500 ? 100 : 116
                let halfH = (g.size.height - bandH) / 2
                ZStack {
                    DuelArena(topWax: model.top.wax, bottomWax: model.bottom.wax)
                    VStack(spacing: 0) {
                        DuelHalf(model: model, side: .top, outer: max(ins.top, 12), onClose: onClose)
                            .frame(height: halfH)
                            .rotationEffect(.degrees(180))
                        DuelSpina(model: model)
                            .frame(height: bandH)
                        DuelHalf(model: model, side: .bottom, outer: max(ins.bottom, 12), onClose: onClose)
                            .frame(height: halfH)
                    }
                    if model.paused {
                        DuelLeaveCard(onStay: { withAnimation(.easeOut(duration: 0.2)) { model.paused = false } },
                                      onLeave: onClose)
                            .transition(.opacity)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
        .onAppear { Haptics.prime() }
    }
}

// MARK: - One player's half

private struct DuelHalf: View {
    @ObservedObject var model: DuelModel
    let side: DuelSide
    /// Room to leave at the player's own edge (the screen's safe-area inset there).
    let outer: CGFloat
    let onClose: () -> Void

    private var me: DuelPlayer { model[side] }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let wide = w >= 560
            content(width: w, wide: wide)
                .padding(.horizontal, wide ? 28 : 14)
                .padding(.top, 12)
                .padding(.bottom, outer + 16)
                .frame(maxWidth: wide ? 1000 : .infinity)
                .frame(width: w, height: g.size.height)
        }
    }

    @ViewBuilder private func content(width: CGFloat, wide: Bool) -> some View {
        switch model.phase {
        case .setup:
            DuelSetup(model: model, side: side, wide: wide)
        case .won(let winner):
            DuelResult(model: model, side: side, won: winner == side, onClose: onClose)
        case .countdown(let n):
            VStack(spacing: 10) {
                DuelBadge(player: me)
                Spacer(minLength: 0)
                Text(n == 0 ? "GO!" : romanNumeral(n))
                    .font(luSerif(wide ? 110 : 88, .black))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(hex: Lu.gold), Color(hex: Lu.tangerine)],
                                                    startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.45), radius: 0, x: 0, y: 4)
                    .id(n)
                    .transition(.scale(scale: 1.8).combined(with: .opacity))
                Text(me.level.label).font(luFont(18, .heavy)).foregroundStyle(Color(hex: 0x4a2a12))
                Spacer(minLength: 0)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: n)
        case .playing, .roundOver:
            DuelPlay(model: model, side: side, wide: wide)
        }
    }
}

/// Who's at this end: their emblem on a wax seal, and their name.
private struct DuelBadge: View {
    let player: DuelPlayer
    var trailing: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            Text(player.emblem).font(.system(size: 22))
                .frame(width: 38, height: 38)
                .background(Circle().fill(RadialGradient(colors: [luShade(player.wax, 40), Color(hex: player.wax)],
                                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: 24)))
                .overlay(Circle().stroke(luShade(player.wax, -50), lineWidth: 2))
            Text(player.name).font(luSerif(20, .black)).foregroundStyle(Color(hex: Lu.ink))
                .lineLimit(1).minimumScaleFactor(0.6)
            if let trailing {
                Text(trailing).font(luFont(13, .heavy)).foregroundStyle(Color(hex: Lu.inkDim))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .padding(.leading, 4).padding(.trailing, 16).padding(.vertical, 4)
        .background(Capsule().fill(Color(hex: Lu.ground).opacity(0.78))
            .overlay(Capsule().stroke(Color(hex: Lu.goldLine), lineWidth: 1.5)))
    }
}

// MARK: Setup — pick who you are, your challenge, then Ready

private struct DuelSetup: View {
    @ObservedObject var model: DuelModel
    @ObservedObject private var profiles = LudusProfiles.shared
    let side: DuelSide
    let wide: Bool

    private var me: DuelPlayer { model[side] }

    var body: some View {
        VStack(spacing: wide ? 14 : 10) {
            Spacer(minLength: 0)
            if profiles.all.count >= 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(profiles.all) { p in profileChip(p) }
                    }
                    .padding(.horizontal, 2)
                    .frame(minWidth: 1)
                }
                .frame(height: 46)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                DuelBadge(player: me)
            }
            Text("CHOOSE YOUR CHALLENGE").font(luFont(12, .heavy)).tracking(2)
                .foregroundStyle(Color(hex: 0x4a2a12))
            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: wide ? 4 : 2)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(DuelLevel.allCases) { lv in levelChip(lv) }
            }
            .opacity(me.ready ? 0.55 : 1)
            .padding(.bottom, wide ? 10 : 4)
            if me.ready {
                Button { model.toggleReady(side) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Color(hex: Lu.mint))
                        Text(model[side.other].ready ? "Here we go!" : "Ready! Waiting for \(model[side.other].name)…")
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .font(luFont(19, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                    .padding(.horizontal, 22).frame(height: 58)
                    .background(Capsule().fill(Color(hex: Lu.ground).opacity(0.8)))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("duel.\(side.rawValue).ready")
            } else {
                LudusButton(title: "Ready!") { model.toggleReady(side) }
                    .accessibilityIdentifier("duel.\(side.rawValue).ready")
            }
            Spacer(minLength: 0)
        }
    }

    private func levelChip(_ lv: DuelLevel) -> some View {
        let on = me.level == lv
        return Button { model.choose(side, level: lv) } label: {
            VStack(spacing: 3) {
                Text(lv.rank).font(luSerif(wide ? 15 : 13, .black)).textCase(.uppercase).tracking(1)
                    .foregroundStyle(Color(hex: on ? 0x5a3a08 : Lu.inkDim))
                Text(lv.label).font(luFont(wide ? 21 : 19, .heavy))
                    .foregroundStyle(Color(hex: on ? Lu.inkDark : Lu.ink))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity).frame(height: wide ? 74 : 62)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(on ? AnyShapeStyle(LinearGradient(colors: [Color(hex: Lu.gold), Color(hex: Lu.tangerine)],
                                                            startPoint: .top, endPoint: .bottom))
                             : AnyShapeStyle(Color(hex: Lu.ground).opacity(0.72)))
            )
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: on ? 0xfff1c0 : Lu.goldLine), lineWidth: on ? 2.5 : 1.5))
            .shadow(color: .black.opacity(on ? 0.3 : 0.15), radius: on ? 6 : 3, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("duel.\(side.rawValue).level.\(lv.rank)")
    }

    private func profileChip(_ p: LudusProfile) -> some View {
        let on = me.profileID == p.id
        let taken = model[side.other].profileID == p.id
        let wax = LudusProfiles.waxes[p.wax % LudusProfiles.waxes.count]
        return Button { model.choose(side, profile: p) } label: {
            HStack(spacing: 6) {
                Text(LudusProfiles.emblems[p.emblem % LudusProfiles.emblems.count]).font(.system(size: 20))
                    .frame(width: 32, height: 32).background(Circle().fill(Color(hex: wax)))
                Text(p.name).font(luSerif(17, .black)).foregroundStyle(Color(hex: Lu.ink)).lineLimit(1)
            }
            .padding(.leading, 5).padding(.trailing, 14).frame(height: 44)
            .background(Capsule().fill(Color(hex: Lu.ground).opacity(on ? 0.9 : 0.6)))
            .overlay(Capsule().stroke(Color(hex: on ? Lu.gold : Lu.goldLine), lineWidth: on ? 3 : 1))
            .opacity(taken ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(taken || me.ready)
    }
}

// MARK: Play — the wax tablet with the question, and the answer stones

private struct DuelPlay: View {
    @ObservedObject var model: DuelModel
    let side: DuelSide
    let wide: Bool

    private var me: DuelPlayer { model[side] }
    private var roundWinner: DuelSide? { if case .roundOver(let s) = model.phase { return s } else { return nil } }

    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            let badgeH: CGFloat = 46
            let stoneH = min(wide ? 140 : 108, max(80, h * 0.36))
            VStack(spacing: 0) {
                DuelBadge(player: me, trailing: me.level.label)
                    .frame(height: badgeH)
                tablet
                    .padding(.top, 24).padding(.bottom, 14)
                    .frame(maxHeight: .infinity)
                stones(height: stoneH)
            }
        }
    }

    // The question on a wax tablet (tabula cerata) in a wooden frame. Once the round is decided it
    // shows the answer: green if you took it, gold if the other side did ("too slow").
    private var tablet: some View {
        GeometryReader { g in
            let fs = min(wide ? 76 : 60, g.size.height * 0.56)
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x8a5a2e), Color(hex: 0x5e3a1a)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 5)
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x3b2618), Color(hex: 0x2a1a10)], startPoint: .top, endPoint: .bottom))
                    .padding(9)
                if let q = me.q {
                    HStack(spacing: fs * 0.25) {
                        Text(q.prompt + " =").foregroundStyle(Color(hex: 0xf3e2b8))
                        Text(roundWinner == nil ? "?" : "\(q.answer)")
                            .foregroundStyle(Color(hex: roundWinner == nil ? Lu.gold : (roundWinner == side ? Lu.mint : Lu.gold)))
                    }
                    .font(.system(size: fs, weight: .black, design: .rounded)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 24)
                    .id(model.round)
                    .transition(.asymmetric(insertion: .scale(scale: 0.6).combined(with: .opacity), removal: .opacity))
                }
                feedback(fs: fs)
            }
            .frame(maxWidth: wide ? 640 : .infinity)
            .frame(width: g.size.width, height: g.size.height)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: model.round)
        }
    }

    /// The little flag on the tablet's corner: a point won, too slow, or locked out.
    @ViewBuilder private func feedback(fs: CGFloat) -> some View {
        if let w = roundWinner {
            let mine = w == side
            HStack(spacing: 6) {
                if mine { Image(systemName: "laurel.leading"); Text("+1"); Image(systemName: "laurel.trailing") }
                else { Text("Too slow — next one!") }
            }
            .font(luFont(mine ? 22 : 17, .black))
            .foregroundStyle(Color(hex: mine ? 0x173d1a : 0x4a2a12))
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(Capsule().fill(Color(hex: mine ? Lu.mint : 0xf3e2b8)))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -16)
            .transition(.scale(scale: 0.4).combined(with: .opacity))
            .accessibilityIdentifier("duel.\(side.rawValue).\(mine ? "point" : "slow")")
        } else if me.locked {
            HStack(spacing: 8) {
                DuelLockRing().frame(width: 20, height: 20).id(me.lockID)
                Text("Oops! Wait a moment…")
            }
            .font(luFont(16, .heavy)).foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(Capsule().fill(Color(hex: Lu.coral)))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -16)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    private func stones(height: CGFloat) -> some View {
        let opts = me.q?.options ?? []
        return HStack(spacing: wide ? 16 : 10) {
            ForEach(Array(opts.enumerated()), id: \.offset) { i, v in
                let right = v == me.q?.answer
                DuelStone(value: v,
                          state: stoneState(i, right: right),
                          height: height,
                          id: "duel.\(side.rawValue).answer.\(right ? "right" : "wrong\(i)")") {
                    model.tap(side, option: i)
                }
            }
        }
        .frame(maxWidth: wide ? 860 : .infinity)
        .id(model.round)
        .animation(.easeOut(duration: 0.15), value: me.locked)
        .animation(.easeOut(duration: 0.15), value: model.phase)
    }

    private func stoneState(_ i: Int, right: Bool) -> DuelStone.Look {
        if me.wrong.contains(i) { return .crossed }
        if let w = roundWinner { return right ? (w == side ? .won : .shown) : .dim }
        return me.locked ? .dim : .normal
    }
}

/// An answer: a marble stone with a dark ledge. Fires the moment a finger lands on it.
private struct DuelStone: View {
    enum Look { case normal, dim, crossed, won, shown }
    let value: Int
    let look: Look
    let height: CGFloat
    let id: String
    let action: () -> Void

    init(value: Int, state: Look, height: CGFloat, id: String, action: @escaping () -> Void) {
        self.value = value; self.look = state; self.height = height; self.id = id; self.action = action
    }

    @State private var down = false
    @State private var shake: CGFloat = 0
    private let ledge: CGFloat = 7

    private var face: [UInt] {
        switch look {
        case .normal, .dim: return [0xfbf4e2, 0xe6d6b2]
        case .crossed: return [0xeea08f, Lu.coral]
        case .won: return [0xa4e0a0, Lu.mint]
        case .shown: return [0xfff1c0, Lu.gold]
        }
    }
    private var base: UInt {
        switch look {
        case .normal, .dim: return 0x9c8158
        case .crossed: return 0x9a3b28
        case .won: return 0x2f7a39
        case .shown: return 0xb98a1e
        }
    }

    var body: some View {
        let r: CGFloat = 20
        ZStack {
            RoundedRectangle(cornerRadius: r, style: .continuous).fill(Color(hex: base))
                .padding(.top, ledge)
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(LinearGradient(colors: face.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 1.5)
                    .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                Text("\(value)")
                    .font(.system(size: min(height * 0.48, 58), weight: .black, design: .rounded)).monospacedDigit()
                    .foregroundStyle(Color(hex: look == .crossed ? 0x5a1e12 : Lu.inkDark))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 6)
                if look == .crossed {
                    Image(systemName: "xmark").font(.system(size: height * 0.5, weight: .heavy))
                        .foregroundStyle(Color(hex: 0x5a1e12).opacity(0.45))
                }
            }
            .padding(.bottom, ledge)
            .offset(y: down && look == .normal ? ledge : 0)
        }
        .frame(height: height)
        .frame(maxWidth: 220)
        .opacity(look == .dim ? 0.45 : 1)
        .scaleEffect(look == .won ? 1.06 : 1)
        .shadow(color: look == .won ? Color(hex: Lu.mint).opacity(0.8) : .black.opacity(0.25),
                radius: look == .won ? 14 : 6, y: 4)
        .offset(x: shake)
        .contentShape(Rectangle())
        // Touch-down, on this stone's own gesture: presses on the other half are independent.
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !down else { return }
                down = true
                action()
            }
            .onEnded { _ in down = false })
        .onChange(of: look) { l in
            if l == .crossed {
                withAnimation(.linear(duration: 0.05).repeatCount(5, autoreverses: true)) { shake = 8 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = 0 }
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: look)
        .accessibilityElement()
        .accessibilityLabel("\(value)")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(id)
        .accessibilityAction { action() }
    }
}

/// The lockout countdown: a ring that drains over the lockout.
private struct DuelLockRing: View {
    @State private var left: CGFloat = 1
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.3), lineWidth: 4)
            Circle().trim(from: 0, to: left).stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onAppear { withAnimation(.linear(duration: DuelModel.lockSeconds)) { left = 0 } }
    }
}

// MARK: Result — the victor's laurel, and a kind word for the other side

private struct DuelResult: View {
    @ObservedObject var model: DuelModel
    let side: DuelSide
    let won: Bool
    let onClose: () -> Void
    @State private var pop = false

    var body: some View {
        let me = model[side], them = model[side.other]
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            if won {
                LaurelMedal(medal: .gold, earned: true, size: 66)
                    .scaleEffect(pop ? 1 : 0.3).rotationEffect(.degrees(pop ? 0 : -25))
                Text("Victor!").font(luSerif(46, .black)).textCase(.uppercase).tracking(2)
                    .foregroundStyle(LinearGradient(colors: [.white, Color(hex: Lu.gold), Color(hex: Lu.tangerine)],
                                                    startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 3)
                Text("\(me.emblem) \(me.name) wins \(me.score)–\(them.score)")
                    .font(luFont(20, .heavy)).foregroundStyle(Color(hex: Lu.ink))
                    .lineLimit(1).minimumScaleFactor(0.6)
            } else {
                Text(me.emblem).font(.system(size: 40))
                    .frame(width: 70, height: 70)
                    .background(Circle().fill(Color(hex: me.wax)))
                    .overlay(Circle().stroke(luShade(me.wax, -50), lineWidth: 3))
                    .scaleEffect(pop ? 1 : 0.5)
                Text("Well fought!").font(luSerif(36, .black))
                    .foregroundStyle(Color(hex: Lu.ink))
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 3)
                Text("\(them.name) wins \(them.score)–\(me.score) — rematch?")
                    .font(luFont(18, .heavy)).foregroundStyle(Color(hex: Lu.inkDim))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            HStack(spacing: 22) {
                LudusButton(title: "Rematch") { withAnimation(.easeOut(duration: 0.2)) { model.rematch() } }
                    .accessibilityIdentifier("duel.\(side.rawValue).rematch")
                Button("Done", action: onClose)
                    .font(luFont(18, .bold)).foregroundStyle(Color(hex: Lu.ink))
                    .padding(.horizontal, 18).frame(height: 54)
                    .background(Capsule().fill(Color(hex: Lu.ground).opacity(0.75)))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("duel.\(side.rawValue).done")
            }
        }
        .padding(.vertical, 18).padding(.horizontal, 24)
        .frame(maxWidth: 560)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(hex: Lu.ground).opacity(0.82))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color(hex: won ? Lu.gold : Lu.goldLine), lineWidth: won ? 3 : 1.5)))
        .shadow(color: won ? Color(hex: Lu.gold).opacity(0.4) : .black.opacity(0.3), radius: 16, y: 6)
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.15)) { pop = true } }
    }
}

// MARK: - The spina: the marble strip down the middle with both laurel tallies

private struct DuelSpina: View {
    @ObservedObject var model: DuelModel

    private var inSetup: Bool { model.phase == .setup }

    var body: some View {
        ZStack {
            // Marble with gilt edges.
            LinearGradient(colors: [Color(hex: 0xe9dcc0), Color(hex: 0xf8f0dc), Color(hex: 0xe1d2b1)],
                           startPoint: .top, endPoint: .bottom)
            VStack { gilt; Spacer(); gilt }
            Rectangle().fill(Color(hex: 0xc9b48a).opacity(0.6)).frame(height: 1)
            VStack(spacing: 0) {
                row(.top).rotationEffect(.degrees(180)).frame(maxHeight: .infinity)
                row(.bottom).frame(maxHeight: .infinity)
            }
            .padding(.vertical, 6)
            HStack {
                Button { withAnimation(.easeOut(duration: 0.2)) { model.paused = true } } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Color(hex: 0x6a5434))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(hex: 0xd9c8a2)))
                        .overlay(Circle().stroke(Color(hex: Lu.goldLine), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("duel.close")
                Spacer()
                // The goal, readable from either end (numerals are symmetric enough: a plain VII).
                Text(romanNumeral(model.targetPoints)).font(luSerif(18, .black))
                    .foregroundStyle(Color(hex: 0x6a5434))
                    .frame(width: 40, height: 40)
                    .background(Circle().stroke(Color(hex: Lu.goldLine), lineWidth: 1.5))
            }
            .padding(.horizontal, 14)
        }
        .shadow(color: .black.opacity(0.35), radius: 8)
    }

    private var gilt: some View {
        VStack(spacing: 2) {
            Rectangle().fill(Color(hex: Lu.goldLine)).frame(height: 3)
            Rectangle().fill(Color(hex: Lu.gold).opacity(0.7)).frame(height: 1)
        }
    }

    /// One player's line on the spina, facing them: the title while picking, then their tally.
    @ViewBuilder private func row(_ side: DuelSide) -> some View {
        if inSetup {
            HStack(spacing: 8) {
                Image(systemName: "laurel.leading")
                Text("Duel in the Arena").textCase(.uppercase).tracking(2)
                Image(systemName: "laurel.trailing")
            }
            .font(luSerif(19, .black)).foregroundStyle(Color(hex: 0x6a4a1c))
            .lineLimit(1).minimumScaleFactor(0.6)
            .padding(.horizontal, 60)
        } else {
            let p = model[side]
            let leading = p.score > model[side.other].score
            HStack(spacing: 6) {
                ForEach(0..<model.targetPoints, id: \.self) { i in
                    let got = i < p.score
                    HStack(spacing: -7) {
                        Image(systemName: "laurel.leading")
                        Image(systemName: "laurel.trailing")
                    }
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(hex: got ? 0xd9a520 : 0xcdbb94))
                    .shadow(color: got ? Color(hex: Lu.gold).opacity(0.8) : .clear, radius: 4)
                    .scaleEffect(got ? 1.1 : 0.9)
                    .animation(.spring(response: 0.35, dampingFraction: 0.5), value: got)
                }
                Text("\(p.score)").font(luFont(22, .black)).monospacedDigit()
                    .foregroundStyle(Color(hex: leading ? 0x9a6a08 : 0x6a5434))
                    .frame(minWidth: 28)
                    .accessibilityIdentifier("duel.\(side.rawValue).score")
            }
            .padding(.horizontal, 60)
        }
    }
}

/// ✕ on the spina: are we really leaving?
private struct DuelLeaveCard: View {
    let onStay: () -> Void
    let onLeave: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Leave the duel?").font(luSerif(30, .black)).foregroundStyle(Color(hex: Lu.ink))
                LudusButton(title: "Keep playing", fullWidth: true, action: onStay)
                Button("Leave the arena", action: onLeave)
                    .font(luFont(16, .bold)).foregroundStyle(Color(hex: Lu.inkDim))
                    .accessibilityIdentifier("duel.leave")
            }
            .padding(24)
            .frame(maxWidth: 400)
            .background(luGlass(24))
        }
    }
}

// MARK: - The arena floor from above

private struct DuelArena: View {
    let topWax: UInt
    let bottomWax: UInt

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                RadialGradient(colors: [Color(hex: 0xe6c48a), Color(hex: 0xcf9f5e)],
                               center: .center, startRadius: 0, endRadius: max(w, h) * 0.6)
                // Raked rings around the centre, as the arena hands leave the sand.
                ZStack {
                    ForEach(1..<9, id: \.self) { i in
                        Ellipse().stroke(Color(hex: 0x9c7440).opacity(0.16), lineWidth: 2)
                            .frame(width: w * 0.24 * CGFloat(i), height: h * 0.16 * CGFloat(i))
                    }
                }
                .frame(width: w, height: h)
                .clipped()
                // Each player's colours wash in from their own end.
                LinearGradient(colors: [Color(hex: topWax).opacity(0.3), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.22))
                LinearGradient(colors: [Color(hex: bottomWax).opacity(0.3), .clear], startPoint: .bottom, endPoint: UnitPoint(x: 0.5, y: 0.78))
                RadialGradient(colors: [.clear, Color(hex: 0x5a3414).opacity(0.3)],
                               center: .center, startRadius: min(w, h) * 0.3, endRadius: max(w, h) * 0.75)
            }
            .frame(width: w, height: h)
            // The stands' awning at both ends, scallops pointing in at the sand.
            .overlay(alignment: .top) { DuelAwning().rotationEffect(.degrees(180)).frame(height: 18) }
            .overlay(alignment: .bottom) { DuelAwning().frame(height: 18) }
        }
    }
}

/// A strip of red-and-cream scallops along an edge (points up, toward the sand above it).
private struct DuelAwning: View {
    var body: some View {
        GeometryReader { g in
            let n = max(8, Int(g.size.width / 46))
            HStack(spacing: 0) {
                ForEach(0..<n, id: \.self) { i in
                    DuelScallop().fill(Color(hex: i % 2 == 0 ? 0xa8322a : 0xf0dfbd))
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 4, y: -2)
        }
    }
}

private struct DuelScallop: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.6))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.6), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.5))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
