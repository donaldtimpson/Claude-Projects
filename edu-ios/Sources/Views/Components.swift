import SwiftUI

// Buttons follow the web's one button system: Inter semibold, sentence case.
// Primary = accent fill; secondary = quiet bordered fill; destructive = danger.
struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    var loading: Bool = false
    var role: ButtonRole? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Group {
                if loading {
                    ProgressView().tint(Theme.onAccent)
                } else {
                    Text(title).font(.ui(16, .semibold))
                }
            }
            .foregroundStyle(enabled ? Theme.onAccent : Theme.inkSoft.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(enabled ? (role == .destructive ? Theme.dangerLine : Theme.accent) : Theme.tint)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!enabled || loading)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title).font(.ui(16, .semibold))
            } icon: {
                if let systemImage { Image(systemName: systemImage) }
            }
            .labelStyle(.titleAndIcon)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.button)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

/// Section heading, as on the web: Cinzel caps beside a short gold bar, over a rule.
struct SectionTitle: View {
    let title: String
    var trailing: AnyView? = nil

    init(_ title: String) { self.title = title }
    init<T: View>(_ title: String, @ViewBuilder trailing: () -> T) {
        self.title = title
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.ornament)
                    .frame(width: 4, height: 17)
                    .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 3 }
                Text(title.uppercased())
                    .font(.display(15))
                    .kerning(1.1)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if let trailing { trailing }
            }
            Rectangle().fill(Theme.line).frame(height: 1)
        }
        .padding(.top, 8)
    }
}

/// Non-breaking spaces around = and the like, so "Ax = 0" never splits across lines.
func keepMathTogether(_ s: String) -> String {
    var out = s
    for op in ["=", "≠", "≤", "≥", "<", ">", "+", "−", "×", "→"] {
        out = out.replacingOccurrences(of: " \(op) ", with: "\u{00A0}\(op)\u{00A0}")
    }
    return out
}

/// For screens that open with their own big title: the nav bar stays empty until
/// that title scrolls under it, so the name isn't shown twice. Apply to the
/// ScrollView; the screen's navigationTitle still names the back button.
struct TitleRevealsOnScroll: ViewModifier {
    let title: String
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self, of: { $0.contentOffset.y + $0.contentInsets.top > 48 }) { _, past in
                withAnimation(.easeOut(duration: 0.15)) { shown = past }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        .lineLimit(1).opacity(shown ? 1 : 0)
                        .accessibilityHidden(!shown)
                }
            }
    }
}

extension View {
    func titleRevealsOnScroll(_ title: String) -> some View { modifier(TitleRevealsOnScroll(title: title)) }
}

/// Small uppercase label (the web's `.eyebrow`).
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.inkSoft
    init(_ text: String, color: Color = Theme.inkSoft) {
        self.text = text
        self.color = color
    }
    var body: some View {
        Text(text.uppercased())
            .font(.ui(12, .semibold, relativeTo: .caption))
            .kerning(0.8)
            .foregroundStyle(color)
    }
}

/// A compact status chip: "Live", "Test", "Draft", "You".
struct Pill: View {
    enum Tone { case accent, quiet, success, warning, danger }
    let text: String
    var tone: Tone = .quiet
    init(_ text: String, tone: Tone = .quiet) {
        self.text = text
        self.tone = tone
    }
    var body: some View {
        Text(text)
            .font(.ui(12, .semibold, relativeTo: .caption))
            .foregroundStyle(fg)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }
    private var fg: Color {
        switch tone {
        case .accent: Theme.onAccent
        case .quiet: Theme.inkSoft
        case .success: Theme.success
        case .warning: Theme.warning
        case .danger: Theme.danger
        }
    }
    private var bg: Color {
        switch tone {
        case .accent: Theme.accent
        case .quiet: Theme.tint
        case .success: Theme.successFill
        case .warning: Theme.warningFill
        case .danger: Theme.dangerFill
        }
    }
}

/// A load failure with a way out: what went wrong and a Try again button.
struct LoadFailedView: View {
    var title: String = "Couldn't load this"
    var message: String = "Check your connection and try again."
    let retry: () async -> Void
    @State private var retrying = false

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "wifi.slash")
                .font(.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
        } description: {
            Text(message).font(.serif(16)).foregroundStyle(Theme.inkSoft)
        } actions: {
            Button {
                Task {
                    retrying = true
                    await retry()
                    retrying = false
                }
            } label: {
                if retrying { ProgressView() } else { Text("Try again").font(.ui(16, .semibold)) }
            }
            .buttonStyle(.bordered)
            .tint(Theme.link)
        }
    }
}

/// A quiet empty state inside a section.
struct EmptyNote: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.serif(16))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lyceumCard()
    }
}

// App Store / Music–style expandable body text: truncated to `lineLimit`, with an
// inline "more" that expands it in place. The toggle only appears when the text
// actually overflows (measured against a hidden full-height copy).
struct ExpandableText: View {
    let text: String
    var lineLimit: Int = 3

    @State private var expanded = false
    @State private var isTruncated = false
    @State private var fullHeight: CGFloat = 0
    @State private var limitedHeight: CGFloat = 0

    private struct FullHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }
    private struct LimitedHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.serif(16))
                .foregroundStyle(Theme.ink)
                .lineLimit(expanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .background(measurers)

            if isTruncated {
                Button(expanded ? "Show less" : "More") {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                }
                .font(.ui(15, .semibold))
                .foregroundStyle(Theme.link)
            }
        }
        .onPreferenceChange(FullHeightKey.self) { fullHeight = $0; updateTruncation() }
        .onPreferenceChange(LimitedHeightKey.self) { limitedHeight = $0; updateTruncation() }
    }

    private var measurers: some View {
        ZStack {
            Text(text).font(.serif(16)).lineLimit(lineLimit).fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { g in Color.clear.preference(key: LimitedHeightKey.self, value: g.size.height) })
            Text(text).font(.serif(16)).fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { g in Color.clear.preference(key: FullHeightKey.self, value: g.size.height) })
        }
        .hidden()
    }

    private func updateTruncation() {
        isTruncated = fullHeight > limitedHeight + 1
    }
}

// Reusable multiple-choice question: select → check → continue. Give it a fresh
// `id` per question to reset. Shared by the quiz and review runners.
struct MCQCard: View {
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let progress: String
    var progressFraction: Double? = nil
    let onContinue: (_ chosen: Int, _ correct: Bool) -> Void

    @State private var selected: Int?
    @State private var revealed = false
    @State private var promptHeight: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let progressFraction { QuizProgressBar(fraction: progressFraction) }

            Text(progress)
                .font(.ui(14, .medium))
                .monospacedDigit()
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .center)

            if prompt.contains("$") {
                MathWebView(markdown: prompt, height: $promptHeight).frame(height: promptHeight)
            } else {
                Text(keepMathTogether(prompt)).font(.serif(20, .medium)).foregroundStyle(Theme.ink)
            }

            // Tap an option to answer — it grades and reveals immediately (no Check).
            OptionButtons(options: options, correctIndex: correctIndex, selected: selected, revealed: revealed) { i in
                guard !revealed else { return }
                selected = i
                withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
                if i == correctIndex { Haptics.success() } else { Haptics.error() }
            }

            if revealed {
                if !explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("Explanation")
                        Text(explanation).font(.serif(16)).foregroundStyle(Theme.ink)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.tint)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Text("Tap to continue")
                    .font(.ui(14)).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            }
        }
        // Once revealed, a tap anywhere advances (no Continue button).
        .contentShape(Rectangle())
        .onTapGesture { if revealed { onContinue(selected ?? 0, selected == correctIndex) } }
    }
}
