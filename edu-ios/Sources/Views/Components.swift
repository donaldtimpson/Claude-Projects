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

// Reusable multiple-choice question: select → check → continue. Give it a fresh
// `id` per question to reset. Shared by the quiz and review runners.
struct MCQCard: View {
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let progress: String
    let onContinue: (_ chosen: Int, _ correct: Bool) -> Void

    @State private var selected: Int?
    @State private var revealed = false
    @State private var promptHeight: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(progress)
                .font(.serif(14))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .center)

            if prompt.contains("$") {
                MathWebView(markdown: prompt, height: $promptHeight).frame(height: promptHeight)
            } else {
                Text(prompt).font(.serif(20)).foregroundStyle(Theme.ink)
            }

            VStack(spacing: 8) {
                ForEach(options.indices, id: \.self) { i in
                    Button {
                        if !revealed { selected = i }
                    } label: {
                        Text(options[i])
                            .font(.serif(17))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(optionBackground(i))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(optionBorder(i), lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(revealed)
                }
            }

            if revealed && !explanation.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explanation").font(.display(11)).kerning(1).foregroundStyle(Theme.gold400)
                    Text(explanation).font(.serif(15)).foregroundStyle(Theme.ink)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.parchmentDeep)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if !revealed {
                PrimaryButton(title: "Check", enabled: selected != nil) { revealed = true }
            } else {
                PrimaryButton(title: "Continue") {
                    onContinue(selected ?? 0, selected == correctIndex)
                }
            }
        }
    }

    private func optionBackground(_ i: Int) -> Color {
        guard revealed else { return i == selected ? Theme.parchmentDeep : Theme.card }
        if i == correctIndex { return Color(hex: 0x1e3a24) }
        if i == selected { return Color(hex: 0x3a1e1e) }
        return Theme.card
    }

    private func optionBorder(_ i: Int) -> Color {
        guard revealed else { return i == selected ? Theme.gold300 : Theme.line }
        if i == correctIndex { return Theme.success }
        if i == selected { return Theme.danger }
        return Theme.line
    }
}
