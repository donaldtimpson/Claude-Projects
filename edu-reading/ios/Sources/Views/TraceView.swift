import SwiftUI

// Writing, taught as FORMATION. Each letter is drawn stroke by stroke, in order,
// from a green start dot in the direction of its arrow — because a correctly formed
// letter is the whole point of handwriting practice, and the old coverage check let
// a backwards or scribbled letter pass.
//
// It stays forgiving: the band around each stroke is wide, the finger can lift and
// carry on from where it stopped, and wandering off simply doesn't advance — there
// is still no wrong and no scolding. A pen-tip demo shows each new letter first.
//
// The same engine runs the Draw lane: pictures built from the pre-writing strokes
// (lines, circles, crosses, zigzags), which finish by turning into their emoji.

/// One thing to trace, already parsed into strokes.
struct TraceItem: Equatable {
    let key: String
    let strokes: [Strokes.Stroke]
    let ruled: Bool           // letters sit on three-line paper; pictures don't
    let emoji: String?        // a picture's reward

    static func == (a: TraceItem, b: TraceItem) -> Bool { a.key == b.key }
}

struct TraceView: View {
    /// Letters (a / A / 1) or the Draw lane's pictures.
    var pictures = false
    /// In a Play session: just these letters.
    var only: [String]? = nil

    @Environment(Progress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session
    private let c = ReadingContent.shared
    private var accent: Color { pictures ? Color(hex: 0xE0724E) : Color(hex: 0x7A5EA8) }

    enum Mode: CaseIterable {
        case lower, upper, digit
        var next: Mode {
            switch self { case .lower: return .upper; case .upper: return .digit; case .digit: return .lower }
        }
        var badge: String {
            switch self { case .lower: return "a"; case .upper: return "A"; case .digit: return "1" }
        }
    }

    @State private var index = 0
    @State private var mode: Mode = .lower    // lowercase first: it's most of what's read

    private var keys: [String] {
        if let only { return only }
        if pictures { return Strokes.pictures.map(\.name) }
        switch mode {
        case .lower: return c.letters.map(\.lower).sorted()
        case .upper: return c.letters.map(\.upper).sorted()
        case .digit: return (0...9).map(String.init)
        }
    }

    private var item: TraceItem {
        let k = keys[index % max(keys.count, 1)]
        if pictures, let p = Strokes.pictures.first(where: { $0.name == k }) {
            return TraceItem(key: k, strokes: Strokes.parse(p.path), ruled: false, emoji: p.emoji)
        }
        return TraceItem(key: k, strokes: Strokes.strokes(for: k) ?? [], ruled: true, emoji: nil)
    }

    var body: some View {
        ZStack {
            Skin.current.appGround.ignoresSafeArea()
            VStack(spacing: 16) {
                StrokeTracer(item: item, accent: accent, onStroke: strokeDone, onDone: finished)
                    .id(item.key)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(CardSurfaceStyle(skin: Skin.current))
                controls
            }
            .padding(18)
        }
        .overlay(alignment: .topLeading) { BackChevron { dismiss() }.padding(.leading, 10).padding(.top, 6) }
        .overlay(alignment: .topTrailing) {
            if !pictures && only == nil { modeToggle.padding(.trailing, 10).padding(.top, 6) }
        }
        .toolbar(.hidden, for: .navigationBar)
        .noBackSwipe()
        .onAppear { announce() }
    }

    private var controls: some View {
        HStack {
            glass("arrow.left") { step(-1) }
            Spacer()
            Text("\(index % max(keys.count, 1) + 1) / \(keys.count)")
                .font(.andika(14, bold: true)).monospacedDigit().foregroundStyle(Skin.live.onSkySoft)
            Spacer()
            glass("arrow.right") { step(1) }
        }
        .padding(.horizontal, 4)
    }

    private var modeToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mode = mode.next; index = 0 }
            announce()
        } label: {
            Text(mode.badge).font(.andika(19, bold: true)).foregroundStyle(Skin.live.cardInk)
                .frame(width: 42, height: 42).contentShape(Circle())
        }
        .buttonStyle(.plain).modifier(GlassCircle())
        .accessibilityLabel("Small letters, capitals or numbers")
    }

    private func glass(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Skin.live.cardInk).frame(width: 42, height: 42).contentShape(Circle())
        }
        .buttonStyle(.plain).modifier(GlassCircle())
    }

    private func step(_ d: Int) {
        index = (index + d + keys.count) % keys.count
        announce()
    }

    /// A letter says its SOUND as it appears; a picture says its name.
    private func announce() {
        let k = item.key
        if pictures { Voice.shared.say(k); return }
        if mode == .digit { Voice.shared.say(k); return }
        if let l = c.letters.first(where: { $0.lower == k.lowercased() }) {
            Voice.shared.phoneme(c.phoneme(of: l))
        }
    }

    private func strokeDone() { Buzz.pick() }

    private func finished() {
        Buzz.yes()
        Voice.shared.celebrate()
        let k = item.key
        if pictures {
            progress.drewPicture(k)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { Voice.shared.say(k) }
        } else {
            progress.wroteLetter(k)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { announce() }
        }
        session?.scored()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { step(1) }
    }
}

/// The tracing surface: guide, start dot and arrow, a pen-tip demo, and the judging.
struct StrokeTracer: View {
    let item: TraceItem
    let accent: Color
    var onStroke: () -> Void = {}
    var onDone: () -> Void = {}

    @State private var strokeIndex = 0
    @State private var progress = 0          // points of the current stroke traced
    @State private var live: [CGPoint] = []  // the finger, in view space
    @State private var started = false       // this touch began at the right place
    @State private var done = false
    @State private var demo: (stroke: Int, t: CGFloat)?
    @State private var demoTimer: Timer?
    @State private var nudge = false

    var body: some View {
        GeometryReader { geo in
            let map = Mapper(item: item, size: geo.size)
            ZStack {
                if item.ruled { paper(map, geo.size) }
                // The whole shape, faint and wide — where the ink should go.
                ForEach(item.strokes.indices, id: \.self) { i in
                    path(item.strokes[i].points, map)
                        .stroke(Skin.live.cardInkSoft.opacity(0.14),
                                style: StrokeStyle(lineWidth: map.band * 1.5, lineCap: .round, lineJoin: .round))
                }
                // Finished strokes, and the traced part of the current one, in ink.
                ForEach(0..<min(strokeIndex, item.strokes.count), id: \.self) { i in
                    ink(item.strokes[i], map)
                }
                if !done, strokeIndex < item.strokes.count {
                    let s = item.strokes[strokeIndex]
                    if !s.isDot {
                        path(s.points, map)
                            .stroke(accent.opacity(0.55),
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 9]))
                        path(Array(s.points.prefix(progress + 1)), map)
                            .stroke(accent, style: StrokeStyle(lineWidth: map.ink, lineCap: .round, lineJoin: .round))
                    }
                    startMarker(s, map)
                }
                if let demo, demo.stroke < item.strokes.count {
                    let pts = item.strokes[demo.stroke].points
                    let p = map.view(pts[min(Int(demo.t * CGFloat(pts.count - 1)), pts.count - 1)])
                    Circle().fill(accent).frame(width: map.ink * 1.4, height: map.ink * 1.4)
                        .shadow(color: accent.opacity(0.5), radius: 6)
                        .position(p)
                }
                if done, let e = item.emoji {
                    Text(e).font(.system(size: min(geo.size.width, geo.size.height) * 0.55))
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
                if done { ReadItCelebration(accent: accent).allowsHitTesting(false) }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(drag(map))
            .overlay(alignment: .bottomTrailing) {
                // Show me again: replays the pen-tip demo.
                Button { runDemo() } label: {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(accent)
                        .frame(width: 40, height: 40).contentShape(Circle())
                }
                .buttonStyle(.plain).padding(10)
                .opacity(done ? 0 : 1)
            }
        }
        .onAppear { runDemo() }
        .onDisappear { demoTimer?.invalidate() }
    }

    // MARK: drawing

    /// Three-line paper: top line, dashed midline, baseline — the lines a child
    /// writes on at school, so lowercase sits at the right height.
    private func paper(_ m: Mapper, _ size: CGSize) -> some View {
        let lineColor = Skin.live.cardInkSoft.opacity(0.35)
        return ZStack {
            Path { p in
                for y in [0.0, 1.0] { let v = m.view(CGPoint(x: 0, y: y)).y
                    p.move(to: CGPoint(x: 16, y: v)); p.addLine(to: CGPoint(x: size.width - 16, y: v)) }
            }.stroke(lineColor, lineWidth: 1.5)
            Path { p in
                let v = m.view(CGPoint(x: 0, y: 0.5)).y
                p.move(to: CGPoint(x: 16, y: v)); p.addLine(to: CGPoint(x: size.width - 16, y: v))
            }.stroke(lineColor, style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
        }
    }

    private func path(_ pts: [CGPoint], _ m: Mapper) -> Path {
        var p = Path()
        guard let f = pts.first else { return p }
        p.move(to: m.view(f))
        for q in pts.dropFirst() { p.addLine(to: m.view(q)) }
        return p
    }

    @ViewBuilder private func ink(_ s: Strokes.Stroke, _ m: Mapper) -> some View {
        if s.isDot, let p = s.points.first {
            Circle().fill(accent).frame(width: m.ink * 1.3, height: m.ink * 1.3).position(m.view(p))
        } else {
            path(s.points, m).stroke(accent, style: StrokeStyle(lineWidth: m.ink, lineCap: .round, lineJoin: .round))
        }
    }

    /// The green dot where the finger goes next, numbered for the stroke, with an
    /// arrow pointing the way the stroke runs.
    @ViewBuilder private func startMarker(_ s: Strokes.Stroke, _ m: Mapper) -> some View {
        let at = s.points[min(progress, s.points.count - 1)]
        let p = m.view(at)
        let d = m.band * 1.25
        ZStack {
            Circle().fill(Theme.go).frame(width: d, height: d)
                .shadow(color: Theme.go.opacity(0.45), radius: nudge ? 10 : 3)
                .scaleEffect(nudge ? 1.25 : 1)
            if progress == 0 {
                Text("\(strokeIndex + 1)").font(.andika(d * 0.55, bold: true)).foregroundStyle(.white)
            }
        }
        .position(p)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: nudge)
        if !s.isDot, progress < s.points.count - 4 {
            let ahead = m.view(s.points[min(progress + 5, s.points.count - 1)])
            let angle = atan2(ahead.y - p.y, ahead.x - p.x)
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: d * 0.5)).foregroundStyle(Theme.go)
                .rotationEffect(.radians(Double(angle)))
                .position(x: p.x + cos(angle) * d * 0.95, y: p.y + sin(angle) * d * 0.95)
        }
    }

    // MARK: judging

    private func drag(_ m: Mapper) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard !done, strokeIndex < item.strokes.count else { return }
                if demo != nil { stopDemo() }
                let s = item.strokes[strokeIndex]
                let target = m.view(s.points[min(progress, s.points.count - 1)])
                if live.isEmpty {
                    // A touch counts only if it starts on the green dot (or where the
                    // finger last left off). Anywhere else, the dot pulses: start here.
                    started = dist(v.location, target) < m.band * 1.4
                    if !started { pulse() }
                }
                live.append(v.location)
                guard started else { return }
                if s.isDot { completeStroke(); return }
                // Advance along the stroke only, never back: the nearest of the next
                // few points within the band. Off the band, nothing happens.
                let window = progress + 1 ..< min(progress + 14, s.points.count)
                if let j = window.last(where: { dist(v.location, m.view(s.points[$0])) < m.band }) {
                    progress = j
                }
                if progress >= s.points.count - 2 { completeStroke() }
            }
            .onEnded { _ in live = []; started = false }
    }

    private func completeStroke() {
        started = false
        live = []
        progress = 0
        strokeIndex += 1
        onStroke()
        if strokeIndex >= item.strokes.count {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { done = true }
            onDone()
        }
    }

    private func pulse() {
        nudge = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { nudge = false }
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    // MARK: demo

    /// A pen tip runs through every stroke in order — watch, then do.
    private func runDemo() {
        stopDemo()
        guard !done, !item.strokes.isEmpty else { return }
        demo = (strokeIndex, 0)
        demoTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            guard let d = demo else { return }
            let pts = item.strokes[d.stroke].points.count
            let dt = item.strokes[d.stroke].isDot ? 0.06 : max(0.012, 1.4 / CGFloat(pts))
            var t = d.t + dt
            var s = d.stroke
            if t >= 1 { s += 1; t = 0 }
            if s >= item.strokes.count { stopDemo(); return }
            demo = (s, t)
        }
    }

    private func stopDemo() { demoTimer?.invalidate(); demoTimer = nil; demo = nil }
}

/// Unit coordinates (the stroke language) to view coordinates for one item.
private struct Mapper {
    let scale: CGFloat
    let origin: CGPoint
    let band: CGFloat
    let ink: CGFloat

    init(item: TraceItem, size: CGSize) {
        let xs = item.strokes.flatMap { $0.points.map(\.x) }
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
        if item.ruled {
            // Paper spans y 0…1.5 (descenders) with a margin; letters centred across.
            let s = min(size.height / 1.7, (size.width - 60) / max(maxX - minX + 0.2, 0.6))
            scale = s
            origin = CGPoint(x: size.width / 2 - (minX + maxX) / 2 * s, y: size.height * 0.5 - 0.72 * s)
        } else {
            let s = min(size.width, size.height) * 0.86
            scale = s
            origin = CGPoint(x: (size.width - s) / 2, y: (size.height - s) / 2)
        }
        let short = min(size.width, size.height)
        band = max(26, short * 0.085)
        ink = max(10, short * 0.04)
    }

    func view(_ p: CGPoint) -> CGPoint { CGPoint(x: origin.x + p.x * scale, y: origin.y + p.y * scale) }
}
