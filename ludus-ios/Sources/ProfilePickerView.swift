import SwiftUI

// MARK: - "Who's playing?" — the player picker
//
// One wax seal per child on a parchment sheet in the Tabularium's red lacquer hall. Tap your seal:
// it stamps down and the arcade re-opens as you. The last seal, an empty impression, adds a player.
//
// Grown-ups: press and hold the small "Grown-ups" control for two seconds to manage players — then
// tapping a seal opens it to rename, re-emblem, re-colour or erase (never the last player).
//
// First use: a device that has never named anyone has no players (the one child's save just lives
// in `.standard`). Opening the picker then asks "Who has been playing so far?" first — that name
// becomes player one and keeps the save — and only then offers "Add a player".

private enum Pk {
    static let red = Color(hex: 0x8f2a1e)
    static let redDeep = Color(hex: 0x5e1812)
    static let gold = Color(hex: 0xd9a944)
    static let parchment = Color(hex: 0xf4e7c9)
    static let parchment2 = Color(hex: 0xe6d1a3)
    static let ink = Color(hex: 0x3a2412)
}

// MARK: Player seal (reusable)

/// A player's wax seal: their wax colour, a pressed rim and their emblem in the middle.
/// Use anywhere a player is shown, e.g. `PlayerSeal(profile: LudusProfiles.shared.current!, size: 36)`.
/// Pure drawing (no assets), so any size works; below ~40 pt the rim detail simply blends away.
struct PlayerSeal: View {
    let emblem: String
    let wax: UInt
    var size: CGFloat = 96

    init(profile: LudusProfile, size: CGFloat = 96) {
        emblem = LudusProfiles.emblems[safe: profile.emblem] ?? "🦁"
        wax = LudusProfiles.waxes[safe: profile.wax] ?? LudusProfiles.waxes[0]
        self.size = size
    }

    init(emblem: String, wax: UInt, size: CGFloat = 96) {
        self.emblem = emblem; self.wax = wax; self.size = size
    }

    var body: some View {
        ZStack {
            WaxBlob()
                .fill(RadialGradient(colors: [luShade(wax, 38), Color(hex: wax), luShade(wax, -55)],
                                     center: UnitPoint(x: 0.36, y: 0.3), startRadius: 0, endRadius: size * 0.62))
                .overlay(WaxBlob().stroke(luShade(wax, -70).opacity(0.5), lineWidth: max(0.5, size * 0.008)))
            // The pressed disc: shadowed at the top-left, caught by light at the bottom-right.
            Circle()
                .fill(RadialGradient(colors: [luShade(wax, -18), Color(hex: wax)],
                                     center: .center, startRadius: 0, endRadius: size * 0.36))
                .overlay(Circle().stroke(LinearGradient(colors: [luShade(wax, -75).opacity(0.75), luShade(wax, 70).opacity(0.85)],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing),
                                         lineWidth: max(1, size * 0.03)))
                .frame(width: size * 0.7, height: size * 0.7)
            Text(emblem)
                .font(.system(size: size * 0.4))
                .shadow(color: luShade(wax, -80).opacity(0.55), radius: 0, x: size * 0.006, y: size * 0.012)
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: .black.opacity(0.3), radius: size * 0.04, y: size * 0.03)
        .accessibilityHidden(true)
    }
}

/// A wax puddle: a circle whose edge swells and dips the way poured wax spreads.
struct WaxBlob: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        let steps = 120
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let k = 0.935 + 0.03 * sin(9 * t + 0.4) + 0.018 * sin(5 * t + 2.1) + 0.012 * sin(13 * t)
            let pt = CGPoint(x: c.x + r * k * cos(t), y: c.y + r * k * sin(t))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

// MARK: - The picker

struct ProfilePickerView: View {
    @ObservedObject private var profiles = LudusProfiles.shared
    @State private var editing: EditorMode?
    @State private var manage = false              // grown-ups mode: seals open the editor
    @State private var stamping: String?           // the seal mid-stamp (input frozen meanwhile)
    @State private var shown = false
    @State private var fresh: String?              // a just-added seal (stamps in)

    var body: some View {
        GeometryReader { g in
            let wide = g.size.width > g.size.height
            ZStack {
                LinearGradient(colors: [Pk.red, Pk.redDeep], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                RadialGradient(colors: [Color(hex: 0xd9a944).opacity(0.16), .clear], center: UnitPoint(x: 0.5, y: 0.3),
                               startRadius: 0, endRadius: max(g.size.width, g.size.height) * 0.6)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar.padding(.horizontal, 16).padding(.top, 6)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: wide ? 14 : 18) {
                            title
                            sheet(width: min(g.size.width - 32, wide ? 920 : 640))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: g.size.height - 140)     // centred when it fits
                        .padding(.bottom, 12)
                    }
                    grownUps.padding(.bottom, 10)
                }

                if let mode = editing {
                    PlayerEditor(mode: mode, wide: wide, onDone: { added in
                        editing = nil
                        if let added { fresh = added }
                    })
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(1)
                }
            }
        }
        .statusBarHidden(true)
        .animation(.easeOut(duration: 0.2), value: editing)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { shown = true }
            // Never named anyone: the first question is who has been playing so far.
            if profiles.all.isEmpty { editing = .first }
        }
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack {
            if !profiles.mustPick {
                Button {
                    Haptics.light(); Sfx.play(.tick)
                    profiles.showPicker = false
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Pk.gold).frame(width: 44, height: 44)
                        .background(Circle().fill(Pk.redDeep).overlay(Circle().stroke(Pk.gold, lineWidth: 1.5)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("close-picker")
            }
            Spacer()
        }
        .frame(height: 44)
    }

    private var title: some View {
        VStack(spacing: 4) {
            Text("QUIS LUDIT?").font(luCinzel(13, bold: true)).tracking(3).foregroundStyle(Pk.gold)
            Text(manage ? "Change a player" : "Who’s playing?")
                .font(luCinzel(32)).foregroundStyle(Pk.parchment)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(subtitle)
                .font(luGaramond(16, semibold: true)).foregroundStyle(Pk.parchment.opacity(0.8))
                .multilineTextAlignment(.center).padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
    }

    private var subtitle: String {
        if manage { return "Tap a seal to rename it, change it, or erase it." }
        switch profiles.all.count {
        case 0: return "First, tell us who has been playing so far."
        case 1: return "Now add everyone else who plays — or tap your seal to keep going."
        default: return "Tap your seal."
        }
    }

    // MARK: The sheet of seals

    private func sheet(width: CGFloat) -> some View {
        let tileW: CGFloat = 148, gap: CGFloat = 10, inner = width - 28
        let items = tiles
        // As many columns as fit, then evened out so the last row isn't a lone straggler (6 → 3 + 3).
        let fit = max(1, min(items.count, Int((inner + gap) / (tileW + gap))))
        let rowCount = (items.count + fit - 1) / fit
        let cols = (items.count + rowCount - 1) / rowCount
        let rows = stride(from: 0, to: items.count, by: cols).map { Array(items[$0..<min($0 + cols, items.count)]) }
        return VStack(spacing: 14) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(alignment: .top, spacing: gap) {
                    ForEach(rows[r]) { t in tile(t).frame(width: tileW) }
                }
            }
        }
        .padding(.vertical, 22).padding(.horizontal, 14)
        // Hugs its seals (a couple of players shouldn't float on a wide empty sheet).
        .frame(width: min(width, max(340, CGFloat(cols) * (tileW + gap) - gap + 28 + 48)))
        .background(parchment)
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : 20)
    }

    private enum Tile: Identifiable {
        case player(LudusProfile), add, unnamed
        var id: String {
            switch self { case .player(let p): return p.id; case .add: return "+add"; case .unnamed: return "+unnamed" }
        }
    }

    private var tiles: [Tile] {
        if profiles.all.isEmpty { return [.unnamed] }
        return profiles.all.map(Tile.player) + (manage ? [] : [.add])
    }

    @ViewBuilder private func tile(_ t: Tile) -> some View {
        switch t {
        case .player(let p):
            let now = !profiles.mustPick && p.id == profiles.currentID
            Button { tap(p) } label: {
                VStack(spacing: 6) {
                    ZStack(alignment: .topTrailing) {
                        PlayerSeal(profile: p, size: 112)
                            .scaleEffect(stamping == p.id ? 0.9 : 1)
                            .overlay(Circle().stroke(Pk.gold, lineWidth: 3).frame(width: 124, height: 124)
                                .opacity(stamping == p.id ? 1 : 0).scaleEffect(stamping == p.id ? 1 : 1.25))
                        if manage {
                            Image(systemName: "pencil").font(.system(size: 14, weight: .black)).foregroundStyle(Pk.parchment)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Pk.red).overlay(Circle().stroke(Pk.gold, lineWidth: 1.5)))
                                .offset(x: 4, y: -2)
                        }
                    }
                    .frame(width: 124, height: 124)
                    Text(p.name.uppercased()).font(luCinzel(17)).foregroundStyle(Pk.ink)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text(now ? "PLAYING NOW" : " ").font(luCinzel(9.5, bold: true)).tracking(1.2)
                        .foregroundStyle(Prov.red)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(SealPressStyle())
            .disabled(stamping != nil)
            .modifier(StampIn(active: fresh == p.id))
            .accessibilityLabel(manage ? "Change \(p.name)" : p.name)
            .accessibilityIdentifier("seal-\(p.name)")
        case .add, .unnamed:
            let first = t.id == "+unnamed"
            Button {
                Haptics.tap(0.5); Sfx.play(.tick)
                editing = first ? .first : .add
            } label: {
                VStack(spacing: 6) {
                    ZStack {
                        Circle().fill(Pk.ink.opacity(0.07))
                        Circle().strokeBorder(Pk.ink.opacity(0.35), style: StrokeStyle(lineWidth: 2.5, dash: [7, 6]))
                        Image(systemName: first ? "questionmark" : "plus").font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(Pk.ink.opacity(0.55))
                    }
                    .frame(width: 100, height: 100)
                    .frame(width: 124, height: 124)
                    .modifier(Beckon(on: profiles.all.count <= 1))
                    Text(first ? "NAME ME" : "ADD A PLAYER").font(luCinzel(first ? 17 : 14)).foregroundStyle(Pk.ink.opacity(0.75))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text(" ").font(luCinzel(9.5, bold: true))
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(SealPressStyle())
            .disabled(stamping != nil)
            .accessibilityLabel(first ? "Name the player who has been playing" : "Add a player")
            .accessibilityIdentifier(first ? "name-first-player" : "add-player")
        }
    }

    private func tap(_ p: LudusProfile) {
        if manage {
            Haptics.tap(0.5); Sfx.play(.tick)
            editing = .edit(p)
            return
        }
        // The stamp: the seal presses down with a thud, the gilt ring closes in, then the arcade
        // re-opens as this player.
        Sfx.play(.thud); Haptics.tap(1)
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { stamping = p.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { Sfx.play(.sparkle, volume: 0.6) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Haptics.success()
            profiles.select(p.id)
        }
    }

    // MARK: Grown-ups

    @ViewBuilder private var grownUps: some View {
        if manage {
            Button {
                Haptics.light(); Sfx.play(.tick)
                withAnimation(.easeOut(duration: 0.2)) { manage = false }
            } label: {
                Text("DONE").font(luCinzel(15)).tracking(1.5).foregroundStyle(Pk.redDeep)
                    .padding(.horizontal, 30).frame(height: 44)
                    .background(Capsule().fill(Pk.gold))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("grownups-done")
        } else if !profiles.all.isEmpty {
            HoldToUnlock {
                Haptics.success(); Sfx.play(.sparkle, volume: 0.6)
                withAnimation(.easeOut(duration: 0.2)) { manage = true }
            }
        }
    }

    private var parchment: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(LinearGradient(colors: [Pk.parchment, Pk.parchment2], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Pk.gold, lineWidth: 1.5))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Pk.gold.opacity(0.4), lineWidth: 0.75).padding(3))
            .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
    }
}

/// Seals sink a little under the finger.
private struct SealPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A just-added seal drops onto the sheet like a stamp.
private struct StampIn: ViewModifier {
    @State private var landed: Bool
    let active: Bool
    init(active: Bool) { self.active = active; _landed = State(initialValue: !active) }
    func body(content: Content) -> some View {
        content
            .scaleEffect(landed ? 1 : 1.7)
            .opacity(landed ? 1 : 0)
            .onAppear {
                guard !landed else { return }
                withAnimation(.spring(response: 0.32, dampingFraction: 0.55).delay(0.25)) { landed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { Sfx.play(.thud); Haptics.tap(0.9) }
            }
    }
}

/// A gentle breathing pulse that says "tap me next".
private struct Beckon: ViewModifier {
    let on: Bool
    @State private var up = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on && up ? 1.06 : 1)
            .onAppear {
                guard on else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { up = true }
            }
    }
}

/// The small "Grown-ups" control: hold it for two seconds (a gilt ring fills) to unlock.
private struct HoldToUnlock: View {
    let action: () -> Void
    @State private var holding = false
    @State private var hint = false

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().stroke(Pk.gold.opacity(0.3), lineWidth: 2.5)
                    Circle().trim(from: 0, to: holding ? 1 : 0)
                        .stroke(Pk.gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Pk.gold)
                }
                .frame(width: 26, height: 26)
                Text("Grown-ups").font(luGaramond(15, semibold: true)).foregroundStyle(Pk.parchment.opacity(0.75))
            }
            .padding(.horizontal, 14).frame(height: 40)
            .background(Capsule().fill(Pk.redDeep.opacity(0.7)).overlay(Capsule().stroke(Pk.gold.opacity(0.35), lineWidth: 1)))
            Text("Hold for 2 seconds").font(luGaramond(12)).foregroundStyle(Pk.parchment.opacity(hint ? 0.75 : 0))
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 2, maximumDistance: 30) {
            holding = false
            action()
        } onPressingChanged: { down in
            if down {
                hint = true
                withAnimation(.linear(duration: 2)) { holding = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { holding = false }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Grown-ups: hold for two seconds to manage players")
        .accessibilityIdentifier("grownups")
    }
}

// MARK: - Add / edit a player

private struct ContentHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

enum EditorMode: Equatable, Identifiable {
    case first                 // naming the child who has been playing (becomes player one)
    case add
    case edit(LudusProfile)
    var id: String {
        switch self { case .first: return "first"; case .add: return "add"; case .edit(let p): return p.id }
    }
}

private struct PlayerEditor: View {
    let mode: EditorMode
    let wide: Bool
    /// Called when the editor closes; carries the new player's id when one was added.
    let onDone: (String?) -> Void

    @ObservedObject private var profiles = LudusProfiles.shared
    @State private var name = ""
    @State private var emblem = 0
    @State private var wax = 0
    @State private var confirmErase = false
    @State private var contentH: CGFloat = 0
    @FocusState private var nameFocused: Bool

    private var editingProfile: LudusProfile? { if case .edit(let p) = mode { return p } else { return nil } }
    private var clean: String { LudusProfiles.clean(name) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { nameFocused = false }
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    Group {
                        if wide {
                            HStack(alignment: .top, spacing: 26) {
                                VStack(spacing: 14) { preview; nameField }.frame(width: 300)
                                VStack(spacing: 14) { emblemPicker; waxPicker; actions }
                            }
                        } else {
                            VStack(spacing: 14) { preview; nameField; emblemPicker; waxPicker; actions }
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)
                    .background(GeometryReader { Color.clear.preference(key: ContentHeight.self, value: $0.size.height) })
                }
                // The card hugs its content, and scrolls only when the screen is shorter than that.
                .frame(maxHeight: contentH > 0 ? contentH : nil)
                .onPreferenceChange(ContentHeight.self) { contentH = $0 }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: wide ? 820 : 460)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Pk.parchment, Pk.parchment2], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Pk.gold, lineWidth: 1.5))
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(Pk.gold.opacity(0.4), lineWidth: 0.75).padding(3))
                    .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
            )
            .padding(.horizontal, 14).padding(.vertical, 18)
        }
        .onAppear(perform: load)
        .alert("Erase \(editingProfile?.name ?? "this player")?", isPresented: $confirmErase) {
            Button("Erase", role: .destructive) {
                if let p = editingProfile { profiles.remove(p.id) }
                Haptics.tap(); onDone(nil)
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Their coins, laurels, levels and villa will be gone for good. This can’t be undone.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                if mode == .first {
                    Text("STEP 1 OF 2").font(luCinzel(10.5, bold: true)).tracking(1.5).foregroundStyle(Prov.red)
                }
                Text(heading).font(luCinzel(wide ? 24 : 21)).foregroundStyle(Pk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let note {
                    Text(note).font(luGaramond(15)).foregroundStyle(Pk.ink.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Button {
                Haptics.light(); Sfx.play(.tick); onDone(nil)
            } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .heavy)).foregroundStyle(Pk.ink.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Pk.ink.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel")
            .accessibilityIdentifier("editor-cancel")
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 8)
    }

    private var heading: String {
        switch mode {
        case .first: return "Who has been playing so far?"
        case .add: return "A new player"
        case .edit(let p): return "Change \(p.name)"
        }
    }

    private var note: String? {
        switch mode {
        case .first: return "Their coins, laurels and villa stay theirs. Next you can add another player."
        case .add: return "A fresh start: their own coins, laurels and villa."
        case .edit: return nil
        }
    }

    private var preview: some View {
        PlayerSeal(emblem: LudusProfiles.emblems[emblem], wax: LudusProfiles.waxes[wax], size: wide ? 132 : 108)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: emblem)
            .animation(.easeOut(duration: 0.2), value: wax)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            label("NAME")
            TextField("", text: $name, prompt: Text("Your name").foregroundColor(Pk.ink.opacity(0.35)))
                .font(luCinzel(22)).foregroundStyle(Pk.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textContentType(.givenName)
                .keyboardType(.default)
                .submitLabel(.done)
                .focused($nameFocused)
                .onSubmit { nameFocused = false }
                .onChange(of: name) { v in
                    if v.count > LudusProfiles.maxNameLength { name = String(v.prefix(LudusProfiles.maxNameLength)) }
                }
                .padding(.horizontal, 14).frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(nameFocused ? Pk.gold : Pk.ink.opacity(0.25),
                                                                       lineWidth: nameFocused ? 2 : 1)))
                .accessibilityIdentifier("name-field")
        }
    }

    private var emblemPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("PICK AN ANIMAL")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(LudusProfiles.emblems.indices, id: \.self) { i in
                    Button {
                        Haptics.light(); Sfx.play(.tick); emblem = i
                    } label: {
                        Text(LudusProfiles.emblems[i]).font(.system(size: 30))
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(emblem == i ? Color(hex: LudusProfiles.waxes[wax]).opacity(0.22) : Color.white.opacity(0.35))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(emblem == i ? Pk.gold : Pk.ink.opacity(0.12), lineWidth: emblem == i ? 2.5 : 1)))
                    }
                    .buttonStyle(SealPressStyle())
                    .accessibilityLabel("Animal \(i + 1)")
                }
            }
        }
    }

    private var waxPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("PICK YOUR WAX")
            HStack(spacing: 0) {
                ForEach(LudusProfiles.waxes.indices, id: \.self) { i in
                    Button {
                        Haptics.light(); Sfx.play(.tick); wax = i
                    } label: {
                        ZStack {
                            WaxBlob().fill(RadialGradient(colors: [luShade(LudusProfiles.waxes[i], 35), Color(hex: LudusProfiles.waxes[i]),
                                                                   luShade(LudusProfiles.waxes[i], -45)],
                                                          center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 26))
                                .frame(width: 38, height: 38)
                            if wax == i {
                                Circle().stroke(Pk.gold, lineWidth: 3).frame(width: 47, height: 47)
                                Image(systemName: "checkmark").font(.system(size: 15, weight: .black)).foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SealPressStyle())
                    .accessibilityLabel("Wax colour \(i + 1)")
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 14) {
            LudusButton(title: saveTitle, fullWidth: true, action: commit)
                .opacity(clean.isEmpty ? 0.45 : 1)
                .disabled(clean.isEmpty)
                .accessibilityIdentifier("save-player")
            if let p = editingProfile {
                if profiles.all.count > 1 {
                    Button {
                        Haptics.error(); confirmErase = true
                    } label: {
                        Label("Erase \(p.name) and their save", systemImage: "trash")
                            .font(luGaramond(16, semibold: true)).foregroundStyle(Prov.red)
                            .frame(minHeight: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("erase-player")
                } else {
                    Text("The only player can’t be erased.").font(luGaramond(14)).foregroundStyle(Pk.ink.opacity(0.55))
                }
            }
        }
        .padding(.top, 4)
    }

    private var saveTitle: String {
        switch mode {
        case .first: return "That’s me!"
        case .add: return "Add player"
        case .edit: return "Save"
        }
    }

    private func label(_ s: String) -> some View {
        Text(s).font(luCinzel(11, bold: true)).tracking(1.5).foregroundStyle(Pk.ink.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func load() {
        if let p = editingProfile {
            name = p.name; emblem = p.emblem % LudusProfiles.emblems.count; wax = p.wax % LudusProfiles.waxes.count
        } else {
            // Something nobody else on this device has yet.
            let usedE = Set(profiles.all.map(\.emblem)), usedW = Set(profiles.all.map(\.wax))
            emblem = LudusProfiles.emblems.indices.first { !usedE.contains($0) } ?? 0
            wax = LudusProfiles.waxes.indices.first { !usedW.contains($0) } ?? 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { nameFocused = true }
        }
    }

    private func commit() {
        guard !clean.isEmpty else { return }
        nameFocused = false
        Sfx.play(.win); Haptics.success()
        if var p = editingProfile {
            p.name = clean; p.emblem = emblem; p.wax = wax
            profiles.update(p)
            onDone(nil)
        } else {
            let p = profiles.add(name: clean, emblem: emblem, wax: wax)
            onDone(p.id)
        }
    }
}

#if DEBUG
/// LUDUS_PROFILE_SELFTEST=1 LUDUS_DEMO_PLAYERS=0 LUDUS_DEMO_BANK=n: runs `LudusProfiles.selfTest` once
/// and shows the verdict (UITests/ProfilePickerTests reads it).
struct ProfileSelfTestView: View {
    @MainActor private static var result: [String]?
    var body: some View {
        let fails = Self.result ?? {
            let r = LudusProfiles.shared.selfTest(); Self.result = r; return r
        }()
        VStack(spacing: 10) {
            Text(fails.isEmpty ? "PROFILE SELFTEST PASS" : "PROFILE SELFTEST FAIL")
                .font(.headline).accessibilityIdentifier("selftest-verdict")
            ForEach(fails, id: \.self) { Text($0).font(.caption) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundStyle(.white)
    }
}
#endif
