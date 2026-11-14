import SwiftUI

// "Achievement unlocked": the web's toast. Any write that returns freshly unlocked
// badges (a watched lecture, a quiz, a review, a drill) hands them here, and the
// root view shows them for a few seconds.
@MainActor
final class Celebrations: ObservableObject {
    static let shared = Celebrations()
    @Published private(set) var current: [Badge] = []
    private var dismissTask: Task<Void, Never>?

    func celebrate(_ badges: [Badge]) {
        guard !badges.isEmpty else { return }
        Haptics.success()
        withAnimation(.spring(duration: 0.35)) { current = badges }
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(6))
            if !Task.isCancelled { dismiss() }
        }
    }

    func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { current = [] }
    }
}

struct CelebrationToast: View {
    @ObservedObject var celebrations = Celebrations.shared
    var body: some View {
        if !celebrations.current.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("✦ Achievement unlocked").font(.ui(13, .bold)).foregroundStyle(Theme.accentText)
                    Spacer()
                    Button { celebrations.dismiss() } label: {
                        Image(systemName: "xmark").font(.ui(12, .bold)).foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityLabel("Dismiss")
                }
                ForEach(celebrations.current) { badge in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(badge.name).font(.serif(17, .semibold)).foregroundStyle(Theme.ink)
                        Text(badge.blurb).font(.ui(13)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .padding(14)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ornament, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onTapGesture { celebrations.dismiss() }
        }
    }
}
