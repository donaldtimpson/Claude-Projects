import SwiftUI

// MARK: - The Clock Tower (Market · Life skills) — telling time
//
// The town clock has stopped, and the townsfolk keep asking for the time they need ("Wake me at
// 7 o'clock!"). Grab the hands and turn them — the hour hand creeps along as the minute hand
// goes round, just like a real geared clock — then pull the bell rope. Gallus the rooster on the
// roof crows when it's right; on a miss the hands swing to the right time so you see it.
//
// Difficulty (continuous, `d`): o'clock (only the short hand moves) → half past → quarter
// past / quarter to → 5-minute times → times in words only ("twenty-five to nine") →
// to-the-minute (8:47) → elapsed time ("in at 2:40, bakes 35 minutes") → hours-and-minutes
// elapsed, forwards and backwards. From d≈4 the townsfolk get impatient (45 s, tightening to 15 s).

private let ctNums = ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
                      "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty",
                      "twenty-one", "twenty-two", "twenty-three", "twenty-four", "twenty-five", "twenty-six", "twenty-seven",
                      "twenty-eight", "twenty-nine"]

/// 0…719 minutes on a 12-hour dial → "7:05".
func ctDigital(_ t: Int) -> String {
    let t = ((t % 720) + 720) % 720
    let h = t / 60 == 0 ? 12 : t / 60
    return String(format: "%d:%02d", h, t % 60)
}

/// "quarter past seven", "twenty-five to nine", "three o'clock".
func ctWords(_ t: Int) -> String {
    let t = ((t % 720) + 720) % 720
    let h = t / 60 == 0 ? 12 : t / 60, m = t % 60
    let next = h % 12 + 1
    let hw = ctNums[h % 12 == 0 ? 0 : h], nw = ctNums[next % 12 == 0 ? 0 : next]
    switch m {
    case 0: return "\(hw) o'clock"
    case 15: return "quarter past \(hw)"
    case 30: return "half past \(hw)"
    case 45: return "quarter to \(nw)"
    case 1..<30: return "\(ctNums[m])\(ctMinutes(m)) past \(hw)"
    default: return "\(ctNums[60 - m])\(ctMinutes(60 - m)) to \(nw)"
    }
}

/// "ten past six" but "seven minutes past six" (and "one minute past") off the five-minute marks.
private func ctMinutes(_ n: Int) -> String { n % 5 == 0 ? "" : (n == 1 ? " minute" : " minutes") }

private func ctDuration(_ m: Int) -> String {
    let h = m / 60, mm = m % 60
    var parts: [String] = []
    if h > 0 { parts.append(h == 1 ? "1 hour" : "\(h) hours") }
    if mm > 0 { parts.append("\(mm) minutes") }
    return parts.joined(separator: " ")
}

struct CTTask {
    var target: Int              // minutes on the 12-hour dial
    var start: Int               // where the hands begin
    var snap: Int                // minute-hand snap
    var minuteLocked = false     // o'clock rounds: only the short hand turns
    var who = "👩‍🌾"
    var picture = "⏰"
    var big = ""                 // the big digital time on the card ("" = words only)
    var line = ""                // the request, written
    var say = ""                 // the request, spoken
}

/// Picture cues with sensible hours (o'clock rounds).
private let ctDay: [(String, String, String, ClosedRange<Int>)] = [
    ("🧑‍🌾", "🛏️", "Wake me up at", 6...8), ("👩‍🏫", "🏫", "School starts at", 8...9),
    ("🧑‍🍳", "🍝", "Lunch is at", 11...12), ("👵", "🍰", "Come for cake at", 2...4),
    ("👨‍🍳", "🍲", "Dinner is at", 5...7), ("👧", "🌙", "Bedtime is at", 7...9), ("🧔", "⚽️", "The game starts at", 1...5),
]

@MainActor
private func ctTask(_ m: ArcadeModel) -> CTTask {
    let anyStart = { Int.random(in: 0..<144) * 5 }
    func far(_ t: Int, _ s: Int) -> Int {          // a start at least 40 minutes from the target
        var x = s; var n = 0
        while (abs(x - t) < 40 || abs(x - t) > 680) && n < 50 { x = anyStart(); n += 1 }
        return x
    }
    let k = m.tier([1, 2.2, 3.2, 4.2, 5.4, 6.4, 7.5, 9])
    let h = Int.random(in: 1...12)
    switch k {
    case 0:
        let c = ctDay.randomElement()!
        let hr = Int.random(in: c.3)
        let t = (hr % 12) * 60
        var s = Int.random(in: 1...12) * 60 % 720
        while s == t { s = Int.random(in: 1...12) * 60 % 720 }
        return CTTask(target: t, start: s, snap: 60, minuteLocked: true, who: c.0, picture: c.1, big: ctDigital(t),
                      line: "\(c.2) \(hr) o'clock!", say: "\(c.2) \(ctWords(t)).")
    case 1, 2:
        let mins = k == 1 ? [30, 30, 0] : [15, 45, 30]
        let t = (h % 12) * 60 + mins.randomElement()!
        return CTTask(target: t, start: far(t, anyStart()), snap: 5, who: ["🧑‍🌾", "👵", "👨‍🍳", "👧"].randomElement()!,
                      picture: "⏰", big: ctDigital(t), line: "Set it to \(ctWords(t))!", say: "Set the clock to \(ctWords(t)).")
    case 3:
        let t = (h % 12) * 60 + 5 * Int.random(in: 0...11)
        return CTTask(target: t, start: far(t, anyStart()), snap: 5, who: ["🧔", "👩‍🏫", "🧑‍🍳"].randomElement()!,
                      picture: "⏰", big: ctDigital(t), line: "Set it to \(ctDigital(t))!", say: "Set the clock to \(ctDigital(t)).")
    case 4:
        let t = (h % 12) * 60 + 5 * Int.random(in: 1...11)
        return CTTask(target: t, start: far(t, anyStart()), snap: 5, who: ["👴", "👩‍🏫", "🧑‍🌾"].randomElement()!,
                      picture: "🗣️", big: "", line: "Set it to \(ctWords(t))!", say: "Set the clock to \(ctWords(t)).")
    case 5:
        var t = (h % 12) * 60 + Int.random(in: 1...59)
        if t % 5 == 0 { t += 1 }
        return CTTask(target: t, start: far(t, anyStart()), snap: 1, who: ["🧑‍🚀", "👩‍🔬", "🧑‍✈️"].randomElement()!,
                      picture: "⏱️", big: ctDigital(t), line: "Exactly \(ctDigital(t)), please!", say: "Set the clock to exactly \(ctDigital(t)).")
    case 6:
        let s = (h % 12) * 60 + 5 * Int.random(in: 0...11)
        let dur = 5 * Int.random(in: m.rampInt(3, 5, from: 7.5, to: 9)...m.rampInt(9, 11, from: 7.5, to: 9))
        let jobs = [("🧑‍🍳", "🍞", "The bread goes in at", "It bakes for"), ("👧", "📺", "The show starts at", "It lasts"),
                    ("🧔", "🚶", "We leave at", "The walk takes"), ("👩‍🏫", "📝", "The test starts at", "It takes")]
        let j = jobs.randomElement()!
        return CTTask(target: s + dur, start: s, snap: 5, who: j.0, picture: j.1, big: "",
                      line: "\(j.2) \(ctDigital(s)). \(j.3) \(dur) minutes. When is it over?",
                      say: "\(j.2) \(ctDigital(s)). \(j.3) \(dur) minutes. When is it over?")
    default:
        let s = (h % 12) * 60 + 5 * Int.random(in: 0...11)
        let dur = 60 + 5 * Int.random(in: 1...m.rampInt(14, 23, from: 9, to: 11))
        if Bool.random() {
            return CTTask(target: s + dur, start: s, snap: 5, who: "🧑‍✈️", picture: "🚂", big: "",
                          line: "The train leaves at \(ctDigital(s)). The trip takes \(ctDuration(dur)). When does it arrive?",
                          say: "The train leaves at \(ctDigital(s)). The trip takes \(ctDuration(dur)). When does it arrive?")
        }
        return CTTask(target: s - dur, start: s, snap: 5, who: "🧑‍🎤", picture: "🎬", big: "",
                      line: "The movie ends at \(ctDigital(s)). It is \(ctDuration(dur)) long. When did it start?",
                      say: "The movie ends at \(ctDigital(s)). It is \(ctDuration(dur)) long. When did it start?")
    }
}

// MARK: - Model

@MainActor
private final class ClockModel: ArcadeModel {
    enum Stage { case setting, done }
    @Published var task = CTTask(target: 180, start: 0, snap: 60, minuteLocked: true)
    @Published var time = 0              // minutes on the dial, 0…719
    @Published var stage: Stage = .setting
    @Published var right: Bool?
    @Published var serial = 0
    @Published var crows = 0
    @Published var deadline: Date?
    @Published var patience: Double = 0
    @Published var setBy = 0             // what the child had set (shown on a miss)

    init() { super.init(key: GameID.clockTower.rawValue) }
    override func perLevel(_ level: Int) -> Int { level == 1 ? 4 : 5 }

    override func onBegin() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_SELFTEST"] != nil { selfTest() }
        #endif
        next()
    }

    #if DEBUG
    private func selfTest() {
        var errs: [String] = []
        marketSweep(self) {
            let t = ctTask(self)
            let tg = (t.target % 720 + 720) % 720, st = (t.start % 720 + 720) % 720
            if tg == st { errs.append("start = target \(t.line)") }
            if tg % t.snap != 0 { errs.append("unreachable \(ctDigital(tg)) snap \(t.snap)") }
            if t.minuteLocked && (tg % 60 != 0 || st % 60 != 0) { errs.append("locked off the hour") }
            if ctWords(tg).isEmpty { errs.append("words") }
        }
        let checks: [(Int, String)] = [(0, "twelve o'clock"), (15, "quarter past twelve"), (7 * 60 + 45, "quarter to eight"),
                                        (8 * 60 + 35, "twenty-five to nine"), (11 * 60 + 50, "ten to twelve"), (6 * 60 + 10, "ten past six"),
                                        (3 * 60 + 30, "half past three"), (4 * 60 + 1, "one minute past four"), (9 * 60 + 53, "seven minutes to ten")]
        for (t, w) in checks where ctWords(t) != w { errs.append("words \(t): \(ctWords(t)) ≠ \(w)") }
        if ctDigital(0) != "12:00" || ctDigital(7 * 60 + 5) != "7:05" { errs.append("digital") }
        marketLog("CLOCK SELFTEST: \(errs.isEmpty ? "OK" : "\(errs.count) errors \(Array(Set(errs)).prefix(8))")")
    }
    #endif

    func next() {
        task = ctTask(self)
        time = ((task.start % 720) + 720) % 720
        stage = .setting; right = nil
        serial += 1
        patience = d < 4 ? 0 : ramp(45, 15, from: 4, to: 10)
        deadline = patience > 0 ? Date().addingTimeInterval(patience) : nil
        if d < 6.5 { LibraryVoice.say(task.say) }
        let s = serial
        if patience > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + patience) { [weak self] in
                guard let self, self.serial == s, self.stage == .setting, self.phase == .playing else { return }
                self.ring()
            }
        }
    }

    func sayAgain() { LibraryVoice.say(task.say) }

    /// Turn the minute hand to point at `minute` (0…59): the hour hand follows, as on a real clock.
    func setMinute(_ minute: Int) {
        guard stage == .setting, !task.minuteLocked else { return }
        let snapped = ((Int((Double(minute) / Double(task.snap)).rounded()) * task.snap) % 60 + 60) % 60
        var delta = snapped - time % 60
        if delta > 30 { delta -= 60 }
        if delta < -30 { delta += 60 }
        guard delta != 0 else { return }
        time = ((time + delta) % 720 + 720) % 720
        Haptics.tap(0.25); Sfx.play(.tick, volume: 0.5)
    }

    /// Turn the hour hand to `hour` (0…11), keeping the minutes.
    func setHour(_ hour: Int) {
        guard stage == .setting else { return }
        let t = ((hour % 12 + 12) % 12) * 60 + time % 60
        guard t != time else { return }
        time = t
        Haptics.tap(0.4); Sfx.play(.tick, volume: 0.6)
    }

    func ring() {
        guard phase == .playing, stage == .setting else { return }
        stage = .done; deadline = nil
        setBy = time
        let ok = time == ((task.target % 720) + 720) % 720
        right = ok
        Sfx.play(.thud, volume: 0.7)
        if ok {
            crows += 1
            hit()
        } else {
            miss(delay: 2.8)
            withAnimation(.easeInOut(duration: 1.0)) { time = ((task.target % 720) + 720) % 720 }
        }
        let s = serial
        DispatchQueue.main.asyncAfter(deadline: .now() + (ok ? 1.5 : 3.2)) { [weak self] in
            guard let self, self.serial == s, self.phase == .playing, !self.dying else { return }
            self.next()
        }
    }

    private var botSerial = -1, botGood = true
    override func botAct(correct: Bool) {
        guard stage == .setting else { return }
        if botSerial != serial { botSerial = serial; botGood = correct }
        let goal = ((task.target + (botGood ? 0 : (task.minuteLocked ? 60 : task.snap * [1, -1, 2].randomElement()!))) % 720 + 720) % 720
        if time == goal { ring(); return }
        // Like a child: hour hand first, then the minute hand.
        if time / 60 != goal / 60 { withAnimation(.spring()) { setHour(goal / 60) }; if time % 60 == goal % 60 { return } }
        withAnimation(.spring()) {
            // Walk the minute hand there (several snaps a move is fine).
            var guardN = 0
            while time != goal && guardN < 80 {
                let diff = ((goal - time) % 720 + 720) % 720
                let stepTo = (time % 60 + (diff <= 360 ? min(25, diff) : -min(25, 720 - diff)))
                setMinute(((stepTo % 60) + 60) % 60)
                if task.minuteLocked { break }
                guardN += 1
            }
        }
    }
}

// MARK: - Scene

/// Rolling hills under a morning sky.
private struct CTSky: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x5ba8e0), Color(hex: 0xa9d8f0), Color(hex: 0xf6e3b4)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hex: 0xfff2b0)).frame(width: 90).position(x: w * 0.85, y: h * 0.2)
                    .shadow(color: Color(hex: 0xffe27a).opacity(0.9), radius: 30)
                MarketCloud(w: 120).position(x: w * 0.18, y: h * 0.24)
                MarketCloud(w: 80).position(x: w * 0.62, y: h * 0.15)
                Ellipse().fill(Color(hex: 0x8cc06a)).frame(width: w * 1.3, height: h * 0.4).position(x: w * 0.2, y: h * 0.86)
                Ellipse().fill(Color(hex: 0x6fa651)).frame(width: w * 1.2, height: h * 0.36).position(x: w * 0.95, y: h * 0.92)
            }
        }
    }
}

// MARK: - View

struct ClockTowerView: View {
    let onClose: () -> Void
    @StateObject private var model = ClockModel()
    var body: some View {
        ArcadeShell(model: model, spec: GameID.clockTower.spec!, accent: Lu.sky,
                    onClose: { LibraryVoice.stop(); onClose() },
                    backdrop: { CTSky() }) {
            CTPlay(model: model)
        }
        .onDisappear { LibraryVoice.stop() }
    }
}

private struct CTPlay: View {
    @ObservedObject var model: ClockModel
    @State private var grabbing: Hand?
    @State private var hop = false
    enum Hand { case hour, minute }

    var body: some View {
        VStack(spacing: 8) {
            Color.clear.frame(height: 54)
            request
            patienceBar
            tower.frame(maxHeight: .infinity).padding(.top, 54)
            bell
        }
        .padding(.horizontal, 14).padding(.bottom, 6)
        .onChange(of: model.crows) { _ in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { hop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation(.spring()) { hop = false } }
        }
    }

    private var request: some View {
        let t = model.task
        return HStack(alignment: .center, spacing: 8) {
            Text(t.who).font(.system(size: 52))
            MarketBubble(fill: 0xfdf6e3) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        if model.stage == .done, let r = model.right {
                            Text(r ? "Cock-a-doodle-doo! 🎉" : "It should be \(ctDigital(t.target))")
                                .font(luFont(19, .heavy)).foregroundStyle(Color(hex: r ? 0x2f7a3a : 0xa33a24))
                            if !r {
                                Text("You set \(ctDigital(model.setBy)) — that's \(ctWords(model.setBy))")
                                    .font(luFont(14, .bold)).foregroundStyle(Color(hex: Lu.inkDark).opacity(0.75))
                                    .lineLimit(2).minimumScaleFactor(0.7)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Text(t.picture).font(.system(size: 30))
                                if !t.big.isEmpty {
                                    Text(t.big).font(luFont(40)).foregroundStyle(Color(hex: Lu.inkDark)).monospacedDigit()
                                }
                            }
                            Text(t.line).font(luFont(t.line.count > 70 ? 15 : 18, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(4).minimumScaleFactor(0.7)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    LibrarySpeakerButton(size: 40) { model.sayAgain() }
                }
            }
        }
        .frame(minHeight: 96)
        .id(model.serial)
        .transition(.opacity)
    }

    @ViewBuilder private var patienceBar: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: model.deadline == nil || model.phase != .playing)) { tl in
            let left = model.deadline.map { max(0, $0.timeIntervalSince(tl.date)) } ?? 0
            let f = model.patience > 0 ? CGFloat(left / model.patience) : 0
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.2))
                    Capsule().fill(Color(hex: f < 0.3 ? Lu.coral : Lu.mint)).frame(width: max(0, g.size.width * f))
                }
            }
            .frame(height: 8)
        }
        .frame(height: 8)
        .opacity(model.deadline != nil ? 1 : 0)
    }

    // The stone tower with its roof, Gallus on top, and the big clock face.
    private var tower: some View {
        GeometryReader { g in
            let face = min(g.size.width - 50, g.size.height - 110, 320)
            ZStack(alignment: .top) {
                // Tower body
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Color(hex: 0xd8c6a3), Color(hex: 0xb59f78)], startPoint: .leading, endPoint: .trailing))
                    .overlay(CTBricks().stroke(Color(hex: 0x8c7752).opacity(0.5), lineWidth: 1.5))
                    .frame(width: face + 36)
                    .padding(.top, 70)
                // Roof
                CTRoof().fill(LinearGradient(colors: [Color(hex: 0xc4552f), Color(hex: 0x8e3518)], startPoint: .top, endPoint: .bottom))
                    .frame(width: face + 64, height: 80)
                    .offset(y: -6)
                // Gallus on the weathervane
                VStack(spacing: -6) {
                    Text("🐓").font(.system(size: 46)).scaleEffect(x: -1)
                        .rotationEffect(.degrees(hop ? -14 : 0))
                        .offset(y: hop ? -18 : 0)
                    Rectangle().fill(Color(hex: 0x4a3a2a)).frame(width: 4, height: 16)
                }
                .offset(y: -60)
                .overlay(alignment: .topTrailing) {
                    if hop {
                        Text("Cock-a-doodle-doo!").font(luFont(15, .heavy)).foregroundStyle(Color(hex: Lu.inkDark))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Color.white))
                            .fixedSize()
                            .offset(x: 150, y: -70)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                CTFace(time: model.time, size: face, minuteLocked: model.task.minuteLocked,
                       grabbing: grabbing, labelsHours: model.d < 3.5, fiveMarks: model.d < 6)
                    .overlay(alignment: .center) {
                        if let r = model.right {
                            Circle().stroke(Color(hex: r ? Lu.mint : Lu.coral), lineWidth: 8).frame(width: face + 6, height: face + 6)
                        }
                    }
                    .contentShape(Circle())
                    .gesture(dragGesture(face: face))
                    .padding(.top, 88)
                    .modifier(MarketShake(shakes: CGFloat(model.lastMiss)))
                    .animation(.linear(duration: 0.4), value: model.lastMiss)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func dragGesture(face: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard model.phase == .playing, model.stage == .setting else { return }
                let c = CGPoint(x: face / 2, y: face / 2)
                let dx = v.location.x - c.x, dy = v.location.y - c.y
                var deg = atan2(dx, -dy) * 180 / .pi
                if deg < 0 { deg += 360 }
                if grabbing == nil {
                    let r = hypot(dx, dy) / (face / 2)
                    // Which hand? The one nearest the finger's angle; the inner circle prefers the hour hand.
                    let hourDeg = Double(model.time) / 720 * 360, minDeg = Double(model.time % 60) / 60 * 360
                    func gap(_ a: Double) -> Double { let x = abs(a - deg).truncatingRemainder(dividingBy: 360); return min(x, 360 - x) }
                    if model.task.minuteLocked { grabbing = .hour }
                    else if r < 0.45 { grabbing = gap(minDeg) < 20 && gap(hourDeg) > 30 ? .minute : .hour }
                    else { grabbing = gap(hourDeg) + 15 < gap(minDeg) && r < 0.7 ? .hour : .minute }
                    Haptics.light()
                }
                if grabbing == .minute {
                    model.setMinute(Int((deg / 6).rounded()) % 60)
                } else {
                    let m = Double(model.time % 60)
                    let hour = Int((deg / 30 - m / 60).rounded())
                    model.setHour(hour)
                }
            }
            .onEnded { _ in grabbing = nil }
    }

    private var bell: some View {
        Button(action: { model.ring() }) {
            HStack(spacing: 10) {
                Text("🔔").font(.system(size: 30))
                Text("Ring the bell").font(luSerif(22, .black)).textCase(.uppercase).tracking(1)
                    .foregroundStyle(Color(hex: 0x3a2708))
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(hex: Lu.gold), Color(hex: Lu.tangerine)], startPoint: .top, endPoint: .bottom)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xb96b1e), lineWidth: 3))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(model.stage != .setting)
        .opacity(model.stage == .setting ? 1 : 0.6)
    }
}

/// The clock face: numbers, minute ticks, and the two hands (with grab knobs).
private struct CTFace: View {
    let time: Int
    let size: CGFloat
    let minuteLocked: Bool
    let grabbing: CTPlay.Hand?
    let labelsHours: Bool
    let fiveMarks: Bool

    var body: some View {
        let r = size / 2
        let hourDeg = Double(time) / 720 * 360
        let minDeg = Double(time % 60) / 60 * 360
        ZStack {
            Circle().fill(Color(hex: 0x4a3a2a)).frame(width: size + 18, height: size + 18)
            Circle().fill(RadialGradient(colors: [Color(hex: 0xfffaf0), Color(hex: 0xf1e4c8)], center: .center, startRadius: 4, endRadius: r))
                .overlay(Circle().stroke(Color(hex: 0xc9a46a), lineWidth: 6))
            // Minute ticks
            ForEach(0..<60, id: \.self) { i in
                Capsule().fill(Color(hex: 0x4a3a2a).opacity(i % 5 == 0 ? 0.9 : 0.45))
                    .frame(width: i % 5 == 0 ? 4 : 2, height: i % 5 == 0 ? 14 : 8)
                    .offset(y: -r + 14)
                    .rotationEffect(.degrees(Double(i) * 6))
            }
            // Minute numbers around the rim (a helper while learning 5-minute times)
            if fiveMarks && !minuteLocked {
                ForEach(0..<12, id: \.self) { i in
                    let a = Double(i) * 30 * .pi / 180
                    Text(String(format: "%02d", i * 5)).font(luFont(size * 0.042, .heavy)).foregroundStyle(Color(hex: 0x2f6fa0))
                        .position(x: r + sin(a) * (r - 30), y: r - cos(a) * (r - 30))
                }
            }
            // Hour numbers
            ForEach(1...12, id: \.self) { n in
                let a = Double(n) * 30 * .pi / 180
                let rr = r - (fiveMarks && !minuteLocked ? 60 : 48)
                Text("\(n)").font(luSerif(size * (labelsHours ? 0.12 : 0.1), .black))
                    .foregroundStyle(Color(hex: 0x3a2a1a))
                    .position(x: r + sin(a) * rr, y: r - cos(a) * rr)
            }
            // Hour hand
            CTHand(length: r * 0.5, width: 14, color: 0x3a2a1a, knob: grabbing == .hour ? Lu.gold : 0xe0684f)
                .rotationEffect(.degrees(hourDeg))
            // Minute hand
            CTHand(length: r * 0.82, width: 8, color: 0x2a3a4a, knob: grabbing == .minute ? Lu.gold : 0x4fa6cf)
                .rotationEffect(.degrees(minDeg))
                .opacity(minuteLocked ? 0.85 : 1)
            Circle().fill(Color(hex: 0xc9a46a)).frame(width: 18, height: 18)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: time)
    }
}

/// A clock hand pointing up from the centre, with a round grab knob near its tip. The view is
/// twice the hand's length tall, so rotating it about its centre turns the hand about the dial's.
private struct CTHand: View {
    let length: CGFloat, width: CGFloat
    let color: UInt, knob: UInt
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Capsule().fill(Color(hex: color)).frame(width: width, height: length + width / 2)
                Circle().fill(Color(hex: knob)).frame(width: width * 2.4, height: width * 2.4)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(y: length * 0.08)
            }
            .frame(height: length, alignment: .top)
            Color.clear.frame(height: length)
        }
        .frame(width: width * 2.4)
    }
}

private struct CTRoof: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.closeSubpath()
        return p
    }
}

/// Staggered stone courses.
private struct CTBricks: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rowH: CGFloat = 22, brickW: CGFloat = 44
        var y = r.minY + rowH, row = 0
        while y < r.maxY {
            p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y))
            var x = r.minX + (row % 2 == 0 ? brickW / 2 : 0)
            while x < r.maxX { p.move(to: CGPoint(x: x, y: y - rowH)); p.addLine(to: CGPoint(x: x, y: y)); x += brickW }
            y += rowH; row += 1
        }
        return p
    }
}
