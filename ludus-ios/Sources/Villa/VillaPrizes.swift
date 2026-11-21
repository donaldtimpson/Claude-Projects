import SwiftUI

// MARK: - Prizes — real rewards a grown-up sets, paid for in gold aurei
//
// Laurels can earn 240 aurei; the garden's grand works and the eight wings take about 75. The rest goes
// here: a grown-up writes the prizes ("Pick tonight's dinner", "20 minutes extra play") and prices them
// in aurei; the child claims one, the gold is spent, and the claim waits on the board — "Show a
// grown-up!" — until a grown-up marks it given. Prizes can be claimed again and again, so gold never
// runs out of uses. Grown-up mode is a two-second hold, like the player picker's.
//
// Saved per player: `ludus_prizes` and `ludus_prize_claims` (JSON) in the player's store.

struct VillaPrize: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var name: String
    var emoji: String
    var cost: Int
}

struct PrizeClaim: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    let name: String
    let emoji: String
    let date: Date
    var given = false
}

@MainActor
final class PrizeBook: ObservableObject {
    static let shared = PrizeBook()
    @Published private(set) var prizes: [VillaPrize] = []
    @Published private(set) var claims: [PrizeClaim] = []

    private let prizesKey = "ludus_prizes", claimsKey = "ludus_prize_claims"

    /// Ideas a grown-up can add with one tap.
    static let suggestions: [VillaPrize] = [
        .init(name: "Pick tonight's dinner", emoji: "🍝", cost: 5),
        .init(name: "20 minutes extra play", emoji: "⏰", cost: 4),
        .init(name: "Choose the family movie", emoji: "🎬", cost: 6),
        .init(name: "Stay up 15 minutes later", emoji: "🌙", cost: 5),
        .init(name: "A trip to the park", emoji: "🛝", cost: 8),
        .init(name: "A special treat", emoji: "🍦", cost: 6),
        .init(name: "Skip one chore", emoji: "🧹", cost: 7),
        .init(name: "A new book", emoji: "📕", cost: 15),
    ]

    func reload() {
        #if DEBUG
        // LUDUS_PRIZES_DEMO: four of the suggested prizes and one claim waiting (for screenshots).
        if !didDemo, ProcessInfo.processInfo.environment["LUDUS_PRIZES_DEMO"] != nil {
            didDemo = true
            prizes = Array(Self.suggestions.prefix(4)); claims = [PrizeClaim(name: "A trip to the park", emoji: "🛝", date: Date())]
            save(); return
        }
        #endif
        prizes = decode(prizesKey) ?? []
        claims = decode(claimsKey) ?? []
    }
    #if DEBUG
    private var didDemo = false
    #endif

    var pending: [PrizeClaim] { claims.filter { !$0.given } }

    func add(_ p: VillaPrize) { prizes.append(VillaPrize(name: p.name, emoji: p.emoji, cost: p.cost)); save() }
    func update(_ p: VillaPrize) { if let i = prizes.firstIndex(where: { $0.id == p.id }) { prizes[i] = p; save() } }
    func remove(_ p: VillaPrize) { prizes.removeAll { $0.id == p.id }; save() }

    /// Spends the gold and puts the claim on the board. False if the child can't afford it.
    func claim(_ p: VillaPrize) -> Bool {
        guard LudusEconomy.aurei >= p.cost else { return false }
        LudusEconomy.spendAurei(p.cost)
        claims.append(PrizeClaim(name: p.name, emoji: p.emoji, date: Date()))
        save()
        return true
    }

    func markGiven(_ c: PrizeClaim) {
        if let i = claims.firstIndex(where: { $0.id == c.id }) { claims[i].given = true; save() }
    }

    private func save() {
        LudusStore.defaults.set(try? JSONEncoder().encode(prizes), forKey: prizesKey)
        LudusStore.defaults.set(try? JSONEncoder().encode(Array(claims.suffix(60))), forKey: claimsKey)
        objectWillChange.send()
    }
    private func decode<T: Decodable>(_ key: String) -> T? {
        LudusStore.defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
}

// MARK: - The scene frame: the prize board (claims waiting for a grown-up)

struct PrizeHall: View {
    let refresh: Int
    @ObservedObject private var book = PrizeBook.shared
    @State private var manage = false

    var body: some View {
        WingRoom(wall: Color(hex: 0x5a2a1c), panel: Color(hex: 0x7a3a26)) { w, h, t in
            ZStack(alignment: .topLeading) {
                // the family strongbox (an arca) on the floor, a glint running over its gold bands
                Arca(glint: 0.5 + 0.5 * sin(t * 1.6))
                    .frame(width: w * 0.34, height: w * 0.25)
                    .position(x: w * 0.5, y: h * 0.80)
                // the board
                VStack(spacing: w * 0.02) {
                    Text("PRAEMIA · PRIZES").font(luCinzel(w * 0.05, bold: true)).tracking(1.5).foregroundStyle(Fr.gold)
                    if book.pending.isEmpty {
                        Text(book.prizes.isEmpty ? "No prizes yet." : "Claim a prize below with your gold!")
                            .font(luGaramond(w * 0.045, semibold: true)).foregroundStyle(Fr.parchment.opacity(0.85))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("SHOW A GROWN-UP!").font(luCinzel(w * 0.04, bold: true)).foregroundStyle(Fr.parchment)
                        ForEach(book.pending.prefix(3)) { c in
                            HStack(spacing: 8) {
                                Text(c.emoji).font(.system(size: w * 0.06))
                                Text(c.name).font(luGaramond(w * 0.045, semibold: true)).foregroundStyle(Fr.ink)
                                    .lineLimit(1).minimumScaleFactor(0.6)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, w * 0.03).padding(.vertical, w * 0.012)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Fr.parchment))
                        }
                        if book.pending.count > 3 {
                            Text("+\(book.pending.count - 3) more").font(luGaramond(w * 0.04)).foregroundStyle(Fr.parchment)
                        }
                    }
                }
                .padding(w * 0.04)
                .frame(width: w * 0.8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x2c1810).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Fr.gold, lineWidth: 2)))
                .position(x: w * 0.5, y: h * 0.32)
                GrownUpHold { manage = true }
                    .position(x: w * 0.5, y: h * 0.96)
            }
        }
        .onAppear { book.reload() }
        .sheet(isPresented: $manage) { PrizeManager() }
    }
}

// MARK: - The shop area: the prizes the child can claim

struct PrizeList: View {
    @Binding var refresh: Int
    @Binding var note: String?
    @ObservedObject private var book = PrizeBook.shared

    var body: some View {
        VStack(spacing: 8) {
            if book.prizes.isEmpty {
                VStack(spacing: 6) {
                    Text("🎁").font(.system(size: 34))
                    Text("Ask a grown-up to add prizes you can buy with gold.")
                        .font(luGaramond(16, semibold: true)).foregroundStyle(Fr.ink).multilineTextAlignment(.center)
                    Text("Grown-ups: hold the button on the board for 2 seconds.")
                        .font(luGaramond(13)).foregroundStyle(Fr.ink.opacity(0.65))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) { ForEach(book.prizes) { row($0) } }.padding(.vertical, 2)
                }
                Text(note ?? "Prizes cost gold aurei. You can claim one again and again.")
                    .font(luGaramond(14, semibold: true)).foregroundStyle(Fr.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear { book.reload() }
    }

    private func row(_ p: VillaPrize) -> some View {
        let afford = LudusEconomy.aurei >= p.cost
        return HStack(spacing: 10) {
            Text(p.emoji).font(.system(size: 28))
            Text(p.name).font(luCinzel(13, bold: true)).foregroundStyle(Fr.ink).lineLimit(2).minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            Button {
                if book.claim(p) {
                    Sfx.play(.coin); Haptics.success()
                    refresh += 1
                    note = "\(p.name)! Show a grown-up to get your prize."
                } else {
                    Sfx.play(.wrong); Haptics.error()
                    let need = p.cost - LudusEconomy.aurei
                    note = "You need \(need) more gold aure\(need == 1 ? "us" : "i"). Win laurels to earn them!"
                }
            } label: {
                HStack(spacing: 4) {
                    Image("CoinGold").resizable().frame(width: 18, height: 18)
                    Text("\(p.cost)").font(luCinzel(14)).monospacedDigit().fixedSize()
                }
                .foregroundStyle(afford ? Fr.parchment : Fr.ink.opacity(0.45))
                .padding(.horizontal, 12).frame(height: 30)
                .background(Capsule().fill(afford ? Fr.frame : Color(hex: 0xd6c39b)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.4))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Fr.gold.opacity(0.5), lineWidth: 1)))
    }
}

// MARK: - Grown-up mode: write prizes, hand out claimed ones

private struct PrizeManager: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var book = PrizeBook.shared
    @State private var name = ""
    @State private var emoji = "🎁"
    @State private var cost = 5

    private let emojis = ["🎁", "🍝", "🍦", "🎬", "⏰", "🌙", "🛝", "📕", "🧸", "🎮", "🧹", "🚲", "🎨", "⚽", "🏊", "🍕"]

    var body: some View {
        NavigationStack {
            List {
                if !book.pending.isEmpty {
                    Section("Waiting for you") {
                        ForEach(book.pending) { c in
                            HStack {
                                Text(c.emoji)
                                Text(c.name)
                                Spacer()
                                Button("Given ✓") { book.markGiven(c) }.buttonStyle(.borderedProminent).tint(.green)
                            }
                        }
                    }
                }
                Section("Add a prize") {
                    TextField("Prize (e.g. Pick tonight's dinner)", text: $name)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(emojis, id: \.self) { e in
                            Text(e).font(.title2).padding(4)
                                .background(Circle().fill(e == emoji ? Color.yellow.opacity(0.4) : .clear))
                                .onTapGesture { emoji = e }
                        } }
                    }
                    Stepper("Costs \(cost) gold aure\(cost == 1 ? "us" : "i")", value: $cost, in: 1...60)
                    Button("Add prize") {
                        book.add(VillaPrize(name: name.trimmingCharacters(in: .whitespaces), emoji: emoji, cost: cost))
                        name = ""
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Section("Ideas — tap to add") {
                    ForEach(PrizeBook.suggestions.filter { s in !book.prizes.contains { $0.name == s.name } }) { s in
                        Button { book.add(s) } label: {
                            HStack { Text(s.emoji); Text(s.name).foregroundStyle(.primary); Spacer(); Text("\(s.cost) 🪙").foregroundStyle(.secondary) }
                        }
                    }
                }
                if !book.prizes.isEmpty {
                    Section("Prizes (swipe to remove)") {
                        ForEach(book.prizes) { p in
                            HStack {
                                Text(p.emoji); Text(p.name); Spacer()
                                Stepper("\(p.cost) 🪙", value: Binding(get: { p.cost }, set: { var q = p; q.cost = $0; book.update(q) }), in: 1...60)
                                    .fixedSize()
                            }
                        }
                        .onDelete { idx in idx.map { book.prizes[$0] }.forEach(book.remove) }
                    }
                }
                Section {
                    Text("A laurel in a game earns gold: bronze 1, silver 2 more, gold 3 more. All 40 games can earn 240 in total; the villa's wings and grand works use about 75.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Prizes")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

/// A Roman strongbox: oak body, domed lid, gilt bands and a lock plate.
private struct Arca: View {
    var glint: Double
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let wood = LinearGradient(colors: [Color(hex: 0x8a5a32), Color(hex: 0x5e3a1e)], startPoint: .top, endPoint: .bottom)
            let gold = LinearGradient(colors: [Color(hex: 0xf7d36b), Fr.gold, Color(hex: 0xa87a1f)], startPoint: .top, endPoint: .bottom)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.25)).frame(width: w * 1.05, height: h * 0.16).offset(x: -w * 0.025, y: h * 0.9)
                // body
                RoundedRectangle(cornerRadius: w * 0.03).fill(wood)
                    .frame(width: w, height: h * 0.62).offset(y: h * 0.36)
                // domed lid
                UnevenRoundedRectangle(topLeadingRadius: w * 0.2, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: w * 0.2)
                    .fill(LinearGradient(colors: [Color(hex: 0x9c6a3c), Color(hex: 0x6e4524)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: h * 0.38).offset(y: 0)
                // gilt bands
                ForEach([0.16, 0.5, 0.84], id: \.self) { f in
                    Rectangle().fill(gold).frame(width: w * 0.07, height: h * 0.98)
                        .offset(x: w * f - w * 0.035, y: h * 0.01)
                }
                Rectangle().fill(gold).frame(width: w, height: h * 0.06).offset(y: h * 0.34)
                // lock plate
                RoundedRectangle(cornerRadius: 3).fill(gold).frame(width: w * 0.16, height: h * 0.24).offset(x: w * 0.42, y: h * 0.4)
                Capsule().fill(Color(hex: 0x3a2412)).frame(width: w * 0.035, height: h * 0.1).offset(x: w * 0.4825, y: h * 0.47)
                // a glint running over the bands
                Rectangle().fill(Color.white.opacity(0.3 * glint)).frame(width: w * 0.035, height: h * 0.8)
                    .offset(x: w * CGFloat(0.08 + 0.82 * glint), y: h * 0.12)
                    .blendMode(.screen)
            }
            .frame(width: w, height: h, alignment: .topLeading)
        }
    }
}

/// A small "Grown-ups" control: hold for two seconds (a gilt ring fills).
struct GrownUpHold: View {
    let action: () -> Void
    @State private var holding = false
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().stroke(Fr.gold.opacity(0.3), lineWidth: 2)
                Circle().trim(from: 0, to: holding ? 1 : 0).stroke(Fr.gold, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold)).foregroundStyle(Fr.gold)
            }
            .frame(width: 20, height: 20)
            Text("Grown-ups").font(luGaramond(13, semibold: true)).foregroundStyle(Fr.parchment.opacity(0.85))
        }
        .padding(.horizontal, 10).frame(height: 30)
        .background(Capsule().fill(Color.black.opacity(0.35)).overlay(Capsule().stroke(Fr.gold.opacity(0.4), lineWidth: 1)))
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 2, maximumDistance: 30) {
            holding = false; action()
        } onPressingChanged: { down in
            withAnimation(down ? .linear(duration: 2) : .easeOut(duration: 0.2)) { holding = down }
        }
        .accessibilityLabel("Grown-ups: hold for two seconds to manage prizes")
        .accessibilityIdentifier("prize-grownups")
    }
}
