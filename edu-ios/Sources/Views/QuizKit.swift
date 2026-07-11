import SwiftUI
import UIKit

// Shared building blocks for the quizzing/practice UI — used by the lecture quiz,
// daily review, and drills so they all look and feel like one interface.

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

// A slim gold progress bar (0...1).
struct QuizProgressBar: View {
    let fraction: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.parchmentDeep)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.gold500, Theme.gold300],
                                         startPoint: .leading, endPoint: .trailing))
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
            Text("\(streak)").font(.subheadline.weight(.bold)).foregroundStyle(Theme.gold300)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(Theme.parchmentDeep).clipShape(Capsule())
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

    // Big centered tile — larger tap target, harder to mis-tap.
    private func tile(_ i: Int) -> some View {
        Button { tap(i) } label: {
            Text(options[i])
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 76)
                .padding(.horizontal, 8)
                .background(background(i))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(border(i), lineWidth: 2))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }

    private func row(_ i: Int) -> some View {
        Button { tap(i) } label: {
            HStack {
                Text(options[i])
                    .font(.serif(17)).foregroundStyle(Theme.ink)
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

    private func background(_ i: Int) -> Color {
        guard revealed else { return i == selected ? Theme.parchmentDeep : Theme.card }
        if i == correctIndex { return Color(hex: 0x1e3a24) }
        if i == selected { return Color(hex: 0x3a1e1e) }
        return Theme.card
    }
    private func border(_ i: Int) -> Color {
        guard revealed else { return i == selected ? Theme.gold300 : Theme.line }
        if i == correctIndex { return Theme.success }
        if i == selected { return Theme.danger }
        return Theme.line
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
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(entry.isEmpty ? Theme.inkSoft : Theme.ink)
                    .contentTransition(.numericText())
                if let unit { Text(unit).font(.title3).foregroundStyle(Theme.inkSoft) }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(Theme.parchmentDeep).clipShape(RoundedRectangle(cornerRadius: 12))

            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(keys, id: \.self) { key in
                    Button { tap(key) } label: {
                        Text(key)
                            .font(.system(size: 26, weight: .medium, design: .rounded))
                            .foregroundStyle(key == "C" ? Theme.danger : Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Theme.card)
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
