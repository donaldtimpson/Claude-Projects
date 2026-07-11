import SwiftUI

// Wrapping flow layout for the ace handle chips (iOS 16+ Layout).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, rowHeight: CGFloat = 0, totalHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                totalHeight += rowHeight + spacing
                widest = max(widest, x - spacing)
                x = 0; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        widest = max(widest, x - spacing)
        return CGSize(width: maxWidth == .infinity ? widest : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// Mirrors the web Hall of Aces: pseudonymous handles of everyone who scored 100%
// on this lecture's quiz. "You" is always shown (even past the cap) and highlighted.
struct QuizAcesView: View {
    let aces: [QuizAce]
    let myUserId: String?

    private let cap = 24

    private var shown: [QuizAce] {
        var s = Array(aces.prefix(cap))
        if let myUserId,
           let mine = aces.first(where: { $0.userId == myUserId }),
           !s.contains(where: { $0.userId == myUserId }) {
            s = [mine] + Array(s.prefix(cap - 1))
        }
        return s
    }
    private var more: Int { aces.count - shown.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("✦ HALL OF ACES")
                    .font(.display(13)).kerning(2).foregroundStyle(Theme.gold400)
                Spacer(minLength: 8)
                if !aces.isEmpty {
                    Text("\(aces.count) perfect \(aces.count == 1 ? "score" : "scores")")
                        .font(.caption).foregroundStyle(Theme.inkSoft)
                }
            }

            if aces.isEmpty {
                Text("No one has aced this lecture yet — be the first.")
                    .font(.serif(15)).foregroundStyle(Theme.inkSoft)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(shown) { ace in
                        chip(ace)
                    }
                    if more > 0 {
                        Text("+\(more) more")
                            .font(.caption).foregroundStyle(Theme.inkSoft)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .lyceumCard()
    }

    @ViewBuilder private func chip(_ ace: QuizAce) -> some View {
        let isMe = ace.userId == myUserId
        Text(isMe ? "\(ace.handle) (you)" : ace.handle)
            .font(.caption)
            .foregroundStyle(isMe ? Theme.gold300 : Theme.inkSoft)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(isMe ? Theme.parchmentDeep : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isMe ? Theme.gold500 : Theme.line, lineWidth: 1)
            )
    }
}
