import SwiftUI

// The app's own materials, on top of the shared web palette. The web is paper and
// ink; the app is the bound book: oxblood leather for the mastheads that open each
// tab, gold leaf for progress, rules and numerals, and pages (grouped "codex" lists)
// in place of a stack of separate cards.

// MARK: - Materials

extension Theme {
    private static let giltStops: [Gradient.Stop] = [
        .init(color: Color(hex: 0x9a7420), location: 0),
        .init(color: Color(hex: 0xd6aa42), location: 0.32),
        .init(color: Color(hex: 0xf4e09c), location: 0.52),
        .init(color: Color(hex: 0xcf9f34), location: 0.74),
        .init(color: Color(hex: 0xa57b22), location: 1),
    ]
    /// Gold leaf, lit from the top left: rings, medallions, numerals.
    static let gilt = LinearGradient(stops: giltStops, startPoint: .topLeading, endPoint: .bottomTrailing)
    /// Gold leaf along a bar.
    static let giltBar = LinearGradient(stops: giltStops, startPoint: .leading, endPoint: .trailing)

    /// Leather for mastheads and primary buttons: crimson by day, oxblood by night.
    static let leatherTop = Color(light: 0x8e2424, dark: 0x431212)
    static let leatherBottom = Color(light: 0x5c1212, dark: 0x220808)
    static let leather = LinearGradient(colors: [leatherTop, leatherBottom], startPoint: .top, endPoint: .bottom)

    /// Text set on leather, in either theme.
    static let onLeather = Color(hex: 0xf7eedb)
    static let onLeatherSoft = Color(hex: 0xf7eedb).opacity(0.74)
    static let giltText = Color(hex: 0xe8c96e)
}

// MARK: - Leather masthead

/// Tooled leather: the gradient, a soft sheen, a faint blind-stamped lattice, and a
/// gilt rule along the bottom edge.
struct LeatherBackground: View {
    var body: some View {
        ZStack {
            Theme.leather
            RadialGradient(colors: [.white.opacity(0.13), .clear], center: .init(x: 0.15, y: 0.55),
                           startRadius: 0, endRadius: 380)
            Lattice().opacity(0.07)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 2) {
                Rectangle().fill(Theme.giltBar).frame(height: 1).opacity(0.85)
                Rectangle().fill(Theme.giltBar).frame(height: 0.5).opacity(0.45)
            }
        }
    }

    /// A blind-tooled diamond lattice, the kind stamped into old bindings.
    private struct Lattice: View {
        var body: some View {
            Canvas { ctx, size in
                let step: CGFloat = 26
                var path = Path()
                var y: CGFloat = 0
                var row = 0
                while y < size.height + step {
                    var x: CGFloat = row.isMultiple(of: 2) ? 0 : step / 2
                    while x < size.width + step {
                        let r: CGFloat = 3.2
                        path.move(to: CGPoint(x: x, y: y - r))
                        path.addLine(to: CGPoint(x: x + r, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + r))
                        path.addLine(to: CGPoint(x: x - r, y: y))
                        path.closeSubpath()
                        x += step
                    }
                    y += step / 2
                    row += 1
                }
                ctx.stroke(path, with: .color(Theme.giltText), lineWidth: 0.8)
            }
        }
    }
}

/// The leather band that opens a tab. Its background runs up under the navigation
/// bar and into the pull-down overscroll, so the top of the screen is always leather.
/// Leaves room at the bottom for the first card to overlap the edge.
struct Masthead<Content: View>: View {
    var overlap: CGFloat = 36
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 22 + overlap)
            .background(alignment: .bottom) {
                LeatherBackground().padding(.top, -900)
            }
    }
}

/// Small Cinzel caps in gold, for the line above a masthead's title.
struct GiltEyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.display(12))
            .kerning(2.4)
            .foregroundStyle(Theme.gilt)
    }
}

/// The navigation bar over a masthead: clear and light-on-leather at the top; the
/// standard bar with the screen's name once the masthead scrolls away.
/// A button in a masthead screen's bar, drawn by MastheadChrome so it matches the
/// back button in both states.
struct ChromeAction {
    let systemImage: String
    let label: String
    var identifier: String? = nil
    let action: () -> Void
}

/// The app's navigation bar: a slim band of leather with cream titles and dark,
/// gilt-ringed buttons. Over a masthead it starts clear (the masthead *is* the bar)
/// and turns to leather once the masthead has scrolled under it; on a screen without
/// one it's leather from the start. Titles: over a masthead the bar shows the crest
/// (or nothing) until the masthead's own title has gone.
struct MastheadChrome: ViewModifier {
    let title: String
    var threshold: CGFloat = 70
    var backButton = true
    var actions: [ChromeAction] = []
    /// false: a screen with no masthead, leather bar throughout.
    var masthead = true
    /// Show the Lyceum crest in the bar while it's over the masthead.
    var crest = false
    @State private var past = false
    @Environment(\.isPresented) private var presented
    @Environment(\.dismiss) private var dismiss
    private var pushed: Bool { presented && backButton }
    private var leatherBar: Bool { !masthead || past }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // The system back button keeps light-mode glass over leather (a pink
            // disc), so these screens draw their own. Swipe-back still works (below).
            .navigationBarBackButtonHidden(pushed)
            .toolbar {
                if pushed { backItem }
                if !actions.isEmpty { actionsItem }
                ToolbarItem(placement: .principal) { principal }
            }
            .onScrollGeometryChange(for: Bool.self, of: { $0.contentOffset.y + $0.contentInsets.top > threshold }) { _, now in
                guard masthead else { return }
                withAnimation(.easeOut(duration: 0.2)) { past = now }
            }
            // The scheme only reaches the bar while its background counts as visible,
            // so over the masthead it's a visible, clear one.
            .toolbarBackground(leatherBar ? AnyShapeStyle(Theme.leather) : AnyShapeStyle(Color.clear), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder private var principal: some View {
        ZStack {
            Text(title).font(.serif(17, .semibold)).foregroundStyle(Theme.onLeather)
                .lineLimit(1)
                .opacity(leatherBar ? 1 : 0)
                .accessibilityHidden(!leatherBar)
            if crest {
                LyceumCrest().opacity(leatherBar ? 0 : 1).accessibilityHidden(true)
            }
        }
    }
}

/// The wordmark that sits in the bar over a tab's masthead.
struct LyceumCrest: View {
    var body: some View {
        HStack(spacing: 7) {
            GiltDiamond(size: 4.5)
            Text("THE TIMPSON LYCEUM").font(.display(11.5)).kerning(2.2).foregroundStyle(Theme.gilt)
                .fixedSize()
            GiltDiamond(size: 4.5)
        }
    }
}

extension MastheadChrome {
    @ToolbarContentBuilder var backItem: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItem(placement: .topBarLeading) { backButtonView }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { backButtonView }
        }
    }

    @ToolbarContentBuilder var actionsItem: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItem(placement: .topBarTrailing) { actionsView }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarTrailing) { actionsView }
        }
    }

    private var backButtonView: some View {
        Button { dismiss() } label: { ChromeDisc(systemImage: "chevron.left") }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
    }

    private var actionsView: some View {
        HStack(spacing: 8) {
            ForEach(actions.indices, id: \.self) { i in
                let a = actions[i]
                Button(action: a.action) { ChromeDisc(systemImage: a.systemImage) }
                    .buttonStyle(.plain)
                    .accessibilityLabel(a.label)
                    .accessibilityIdentifier(a.identifier ?? a.label)
            }
        }
    }
}

/// A bar button's face: a dark disc with a gilt hairline and a cream glyph, at home
/// on leather in either theme.
struct ChromeDisc: View {
    let systemImage: String
    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.onLeather)
            .frame(width: 38, height: 38)
            .background(Circle().fill(Color.black.opacity(0.24)))
            .overlay(Circle().strokeBorder(Theme.gilt.opacity(0.6), lineWidth: 0.75))
            .contentShape(Circle())
    }
}

/// A toolbar item drawn in the chrome's own style (no system glass behind it).
struct ChromeItem<V: View>: ToolbarContent {
    var placement: ToolbarItemPlacement = .topBarTrailing
    @ViewBuilder let content: () -> V
    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItem(placement: placement, content: content).sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: placement, content: content)
        }
    }
}

extension View {
    /// A screen that opens with a masthead. `backButton: false` for a sheet's root,
    /// which has its own way out.
    func mastheadChrome(_ title: String, threshold: CGFloat = 70, backButton: Bool = true,
                        actions: [ChromeAction] = [], crest: Bool = false) -> some View {
        modifier(MastheadChrome(title: title, threshold: threshold, backButton: backButton,
                                actions: actions, crest: crest))
    }

    /// A screen without a masthead: the leather bar from the start.
    func leatherBar(_ title: String, backButton: Bool = true, actions: [ChromeAction] = []) -> some View {
        modifier(MastheadChrome(title: title, backButton: backButton, actions: actions, masthead: false))
    }
}

// MARK: - Codex (grouped list)

/// Rows bound together as one page: a single card with hairlines between rows, the
/// iOS inset-grouped list in the Lyceum's materials. Rows inside shouldn't draw
/// their own card.
struct Codex<Content: View>: View {
    var dividerInset: CGFloat = 16
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { subviews in
                ForEach(Array(subviews.enumerated()), id: \.element.id) { i, row in
                    if i > 0 {
                        Rectangle().fill(Theme.line).frame(height: 0.5).padding(.leading, dividerInset)
                    }
                    row
                }
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.line, lineWidth: 0.75))
        .shadow(color: scheme == .light ? Color(hex: 0x4a2c14).opacity(0.07) : .clear, radius: 10, y: 3)
    }
}

/// Press feedback for a row inside a Codex: the row lights, nothing moves.
struct LyceumRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(Theme.ink.opacity(configuration.isPressed ? 0.07 : 0))
            .animation(configuration.isPressed ? nil : .easeOut(duration: 0.25), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == LyceumRowStyle {
    static var lyceumRow: LyceumRowStyle { LyceumRowStyle() }
}

// MARK: - Gold leaf

/// A progress bar in gold leaf that fills in when it appears, then catches the
/// light once: a sheen runs along the leaf.
struct GiltBar: View {
    let fraction: Double
    var height: CGFloat = 7
    /// Set on leather: a dark inset track instead of the page tint.
    var onLeather = false
    @State private var shown: Double = 0
    @State private var sheen: CGFloat = -0.1

    private var target: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(onLeather ? AnyShapeStyle(Color.black.opacity(0.28)) : AnyShapeStyle(Theme.tint))
                    .overlay(Capsule().strokeBorder(onLeather ? Color.white.opacity(0.08) : Theme.line.opacity(0.7), lineWidth: 0.5))
                if shown > 0 {
                    let width = max(height, g.size.width * shown)
                    Capsule()
                        .fill(Theme.giltBar)
                        .overlay(alignment: .top) {
                            // The leaf's catch-light.
                            Capsule().fill(.white.opacity(0.45))
                                .frame(height: max(1, height * 0.28))
                                .padding(.horizontal, height / 2)
                                .padding(.top, height * 0.14)
                        }
                        .overlay {
                            LinearGradient(colors: [.clear, .white.opacity(0.75), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 36)
                                .offset(x: (sheen - 0.5) * width)
                                .blendMode(.plusLighter)
                        }
                        .clipShape(Capsule())
                        .frame(width: width)
                        .shadow(color: Color(hex: 0xb8860b).opacity(0.35), radius: 2.5, y: 0.5)
                }
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.12).delay(0.15)) { shown = target }
            withAnimation(.easeInOut(duration: 1.1).delay(0.9)) { sheen = 1.1 }
        }
        .onChange(of: fraction) { withAnimation(.spring(duration: 0.6)) { shown = target } }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((target * 100).rounded())) percent")
    }
}

/// A grade as a gold-leaf ring with the figure inside in its grade tier.
struct GradeRing: View {
    let pct: Double?
    var size: CGFloat = 64
    var lineWidth: CGFloat = 6
    var onLeather = false
    @State private var shown: Double = 0

    var body: some View {
        ZStack {
            Circle().stroke(onLeather ? Color.white.opacity(0.14) : Theme.tint, lineWidth: lineWidth)
            if let pct {
                Circle()
                    .trim(from: 0, to: shown)
                    .stroke(stroke(pct), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            // The ring is gold leaf; the figure carries the grade tier.
            Text(pct.map { "\(Int($0.rounded()))%" } ?? "—")
                .font(.ui(size * 0.25, .bold)).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1)
                .foregroundStyle(onLeather ? Theme.onLeather : Theme.grade(pct))
                .padding(.horizontal, lineWidth + 2)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.1).delay(0.15)) { shown = min(max((pct ?? 0) / 100, 0), 1) }
        }
        .accessibilityElement()
        .accessibilityLabel("Grade")
        .accessibilityValue(pct.map { "\(Int($0.rounded())) percent" } ?? "No grade yet")
    }

    private func stroke(_ pct: Double) -> AnyShapeStyle { AnyShapeStyle(Theme.gilt) }
}

/// The fill behind a primary action: tooled crimson leather by day, gold leaf by night.
struct AccentFill: View {
    var cornerRadius: CGFloat = 12
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            if scheme == .dark {
                shape.fill(Theme.gilt)
            } else {
                shape.fill(LinearGradient(colors: [Color(hex: 0x9a2828), Color(hex: 0x6a1515)],
                                          startPoint: .top, endPoint: .bottom))
            }
        }
        .overlay(
            // A bevel: light along the top edge, shade along the bottom.
            shape.strokeBorder(LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.5 : 0.28), .clear, .black.opacity(0.18)],
                                              startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .shadow(color: (scheme == .dark ? Color(hex: 0xb8860b) : Color(hex: 0x5c1212)).opacity(0.28), radius: 6, y: 3)
    }
}

/// A small gilt diamond, the app's fleuron.
struct GiltDiamond: View {
    var size: CGFloat = 6
    var body: some View {
        Rectangle().fill(Theme.gilt).frame(width: size, height: size).rotationEffect(.degrees(45))
            .frame(width: size * 1.42, height: size * 1.42)
    }
}

// MARK: - Cover hero

/// A course's cover art across the top of the screen (under the status bar, like a
/// film's page in the TV app), stretching on pull-down and dissolving into a band of
/// leather that carries the title. Use on a ScrollView that ignores the top safe area.
struct CoverHero<Content: View>: View {
    let imageURL: String?
    var overlap: CGFloat = 36
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { g in
                let pull = max(0, g.frame(in: .scrollView).minY)
                AsyncImage(url: URL(string: imageURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Theme.leatherTop
                }
                .frame(width: g.size.width, height: g.size.height + pull)
                .clipped()
                .overlay {
                    // Shade under the status bar and back button, and melt into the leather below.
                    LinearGradient(stops: [
                        .init(color: .black.opacity(0.45), location: 0),
                        .init(color: .clear, location: 0.3),
                        .init(color: .clear, location: 0.55),
                        .init(color: Theme.leatherTop, location: 1),
                    ], startPoint: .top, endPoint: .bottom)
                }
                .offset(y: -pull)
            }
            .aspectRatio(16.0 / 10.0, contentMode: .fit)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 2)
                .padding(.bottom, 22 + overlap)
                .background(alignment: .bottom) { LeatherBackground() }
        }
    }
}

// Hiding the system back button also turns off the edge swipe that goes back; this
// keeps it on for any stack deeper than its root.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

/// The loading state of a masthead screen: the leather band already in place, so
/// the bar and its buttons don't flash from page to leather when the content lands.
struct LoadingLeather: View {
    var body: some View {
        VStack(spacing: 0) {
            LeatherBackground().frame(height: 28).ignoresSafeArea(edges: .top)
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.page)
    }
}
