import SwiftUI
import UIKit

// Shared building blocks for the quizzing/practice UI — used by the lecture quiz,
// daily review, and drills so they all look and feel like one interface.

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

// Loads a bundled flag PNG by resource name (e.g. "us-ca"), cached. Used for option
// tiles whose "flag" is an image rather than an emoji (US states have no flag emoji).
enum FlagImage {
    private static var cache: [String: UIImage?] = [:]
    static func load(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        let img = Bundle.main.url(forResource: name, withExtension: "png")
            .flatMap { UIImage(contentsOfFile: $0.path) }
        cache[name] = img
        return img
    }
}

// A slim gold progress bar (0...1).
struct QuizProgressBar: View {
    let fraction: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.tint)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.25), value: fraction)
    }
}

// A live streak pill (🔥 N), dimmed at zero.
struct StreakPill: View {
    let streak: Int
    var body: some View {
        HStack(spacing: 4) {
            Text("🔥").font(.caption)
            Text("\(streak)").font(.ui(15, .bold)).monospacedDigit().foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(Theme.tint).clipShape(Capsule())
        .opacity(streak > 0 ? 1 : 0.4)
    }
}

// The shared multiple-choice option list with reveal coloring. Parents own the
// selection/reveal state; used by MCQCard (lecture quiz + review) and drills.
struct OptionButtons: View {
    let options: [String]
    let correctIndex: Int
    let selected: Int?
    let revealed: Bool
    var grid: Bool = false   // 2×2 tiles for short math options (drills); list otherwise
    var optionImages: [String]? = nil   // per-option flag image resource names (e.g. "us-ca")
    let onSelect: (Int) -> Void

    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        if grid {
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(options.indices, id: \.self) { i in tile(i) }
            }
        } else {
            VStack(spacing: 8) {
                ForEach(options.indices, id: \.self) { i in row(i) }
            }
        }
    }

    // A leading flag emoji (🇯🇵 Japan) must render in the system emoji font: a custom
    // text font (our serif) can fail to compose the regional-indicator pair into a flag
    // glyph, leaving the two boxed letters. So split it out into its own Text run.
    private func flagSplit(_ s: String) -> (flag: String?, rest: String) {
        guard let first = s.first, let scalar = first.unicodeScalars.first,
              (0x1F1E6...0x1F1FF).contains(scalar.value) else { return (nil, s) }
        return (String(first), String(s.dropFirst().drop(while: { $0 == " " })))
    }

    // Big centered tile — larger tap target, harder to mis-tap. A flag (when present)
    // sits on its own line above the label, freeing horizontal room so long country
    // names fit the 2×2 grid without shrinking to nothing.
    private func tile(_ i: Int) -> some View {
        let (flag, rest) = flagSplit(options[i])
        let flagImg = optionImages.flatMap { i < $0.count ? FlagImage.load($0[i]) : nil }
        let hasVisual = flag != nil || flagImg != nil
        return Button { tap(i) } label: {
            VStack(spacing: 5) {
                if let flagImg {
                    Image(uiImage: flagImg).resizable().aspectRatio(contentMode: .fit)
                        .frame(height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.line, lineWidth: 0.5))
                } else if let flag {
                    Text(flag).font(.system(size: 30))
                }
                Text(rest)
                    .font(.ui(hasVisual ? 18 : 24, .semibold))
                    .foregroundStyle(foreground(i))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: flag == nil ? 76 : 92)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(background(i))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(border(i), lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }

    private func row(_ i: Int) -> some View {
        let (flag, rest) = flagSplit(options[i])
        return Button { tap(i) } label: {
            HStack(spacing: 8) {
                if let flag { Text(flag).font(.system(size: 20)) }
                Text(rest)
                    .font(.serif(17, revealed && i == correctIndex ? .semibold : .regular))
                    .foregroundStyle(foreground(i))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if revealed && i == correctIndex {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                } else if revealed && i == selected {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.danger)
                }
            }
            .padding()
            .background(background(i))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(border(i), lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }

    private func tap(_ i: Int) {
        if !revealed { Haptics.tap(); onSelect(i) }
    }

    // Same answer states as the web: the right answer solid green with ✓, a wrong
    // pick solid red with ✗, everything else dimmed.
    private func background(_ i: Int) -> Color {
        guard revealed else { return i == selected ? Theme.tint : Theme.field }
        if i == correctIndex { return Theme.successFill }
        if i == selected { return Theme.dangerFill }
        return Theme.field
    }
    private func border(_ i: Int) -> Color {
        guard revealed else { return i == selected ? Theme.accentText : Theme.line }
        if i == correctIndex { return Theme.successLine }
        if i == selected { return Theme.dangerLine }
        return Theme.line
    }
    private func foreground(_ i: Int) -> Color {
        guard revealed else { return Theme.ink }
        return i == correctIndex || i == selected ? Theme.ink : Theme.inkSoft
    }
}

// A custom on-screen number pad — big targets, always visible, no system keyboard.
// Integers only (non-negative), which fits the arithmetic drill.
struct NumericKeypad: View {
    @Binding var entry: String
    var unit: String?
    var disabled: Bool = false

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "⌫"]
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Spacer(minLength: 0)
                Text(entry.isEmpty ? "0" : entry)
                    .font(.ui(40, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(entry.isEmpty ? Theme.inkSoft : Theme.ink)
                    .contentTransition(.numericText())
                if let unit { Text(unit).font(.ui(20)).foregroundStyle(Theme.inkSoft) }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(Theme.tint).clipShape(RoundedRectangle(cornerRadius: 12))

            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(keys, id: \.self) { key in
                    Button { tap(key) } label: {
                        Text(key)
                            .font(.ui(26, .medium))
                            .foregroundStyle(key == "C" ? Theme.danger : Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Theme.field)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1)
    }

    private func tap(_ key: String) {
        Haptics.tap()
        switch key {
        case "C": entry = ""
        case "⌫": if !entry.isEmpty { entry.removeLast() }
        default: if entry.count < 7 { withAnimation(.easeOut(duration: 0.12)) { entry += key } }
        }
    }
}
