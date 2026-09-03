import SwiftUI

/// Every deck is the same machine: show a card, advance, sometimes shuffle,
/// sometimes reveal. Only the card face differs, so the chrome, the ordering,
/// the counter and the buttons live here once.
struct DeckShell<Card: View, Controls: View>: View {
    let title: String
    let count: Int
    @Binding var index: Int
    var shuffled: Bool = false
    var advanceLabel: String = "Next"
    @ViewBuilder var card: () -> Card
    @ViewBuilder var controls: () -> Controls

    @State private var order: [Int] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            controls()
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

            card()
                .padding(.horizontal, 18)

            HStack(spacing: 10) {
                Button { step(-1) } label: {
                    Text("Back").font(.andika(19, bold: true))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.ink)
                .background(Theme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1.5))

                Button { step(1) } label: {
                    Text(advanceLabel).font(.andika(19, bold: true))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Theme.go)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(18)
        }
        .background(Theme.ground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(min(index + 1, max(count, 1))) / \(count)")
                    .font(.andika(15)).foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
            }
        }
    }

    private func step(_ d: Int) {
        guard count > 0 else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            index = (index + d + count) % count
        }
    }
}

/// A row of small toggle chips — used for every deck's mode / level / category picker.
struct ChipRow<T: Hashable>: View {
    let items: [T]
    let label: (T) -> String
    @Binding var selection: T
    var tint: Color = Theme.ink

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(items, id: \.self) { item in
                    let on = item == selection
                    Button { selection = item } label: {
                        Text(label(item))
                            .font(.andika(14, bold: true))
                            .padding(.horizontal, 13).padding(.vertical, 8)
                            .background(on ? tint : Theme.paper)
                            .foregroundStyle(on ? Color.white : Theme.inkSoft)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(on ? tint : Theme.line, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

/// The small round speaker used on cards.
struct SpeakButton: View {
    let text: String
    var body: some View {
        Button { Voice.shared.say(text) } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.go)
                .frame(width: 46, height: 46)
                .background(Theme.paper)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
