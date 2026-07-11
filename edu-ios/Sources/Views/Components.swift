import SwiftUI

struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    var loading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if loading {
                    ProgressView().tint(Theme.onAccent)
                } else {
                    Text(title).font(.display(16)).kerning(1)
                }
            }
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(enabled ? 1 : 0.5)
        }
        .disabled(!enabled || loading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.display(16)).kerning(1)
                .foregroundStyle(Theme.gold300)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.parchmentDeep)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
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
                Button(expanded ? "Show less" : "more") {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                }
                .font(.serif(15))
                .foregroundStyle(Theme.gold400)
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
                .font(.serif(14))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .center)

            if prompt.contains("$") {
                MathWebView(markdown: prompt, height: $promptHeight).frame(height: promptHeight)
            } else {
                Text(prompt).font(.serif(20)).foregroundStyle(Theme.ink)
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Explanation").font(.display(11)).kerning(1).foregroundStyle(Theme.gold400)
                        Text(explanation).font(.serif(15)).foregroundStyle(Theme.ink)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.parchmentDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Text("Tap to continue")
                    .font(.footnote).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            }
        }
        // Once revealed, a tap anywhere advances (no Continue button).
        .contentShape(Rectangle())
        .onTapGesture { if revealed { onContinue(selected ?? 0, selected == correctIndex) } }
    }
}
