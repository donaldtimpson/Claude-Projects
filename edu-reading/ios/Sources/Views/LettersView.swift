import SwiftUI

// Deliberately no pictures. "A is for Apple" builds a letter -> picture -> NAME
// association and quietly trains guessing from images; this deck teaches the
// SOUND, which is the thing decoding actually needs.
struct LettersView: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    enum Mode: String, CaseIterable { case learn = "Learn", practice = "Shuffle" }
    @State private var mode: Mode = .learn
    @State private var set: Int = 1
    @State private var index = 0
    @State private var order: [Int] = []
    @State private var cycling = false
    @State private var timer: Timer?

    // Teaching order, not alphabetical: after set 1 (s a t p i n) a child can
    // already read sat, pat, tap, nap, pin, tin, sit.
    private var pool: [ReadingContent.Letter] {
        c.letters.filter { $0.set == set }
    }
    private var current: ReadingContent.Letter? {
        guard !pool.isEmpty else { return nil }
        let i = mode == .practice && order.count == pool.count ? order[index % pool.count] : index % pool.count
        return pool[i]
    }

    var body: some View {
        DeckShell(title: "Letter Sounds", count: pool.count, index: $index) {
            if let l = current {
                VStack(spacing: 18) {
                    Spacer()
                    // Capital and lowercase together; lowercase is what gets decoded,
                    // the capital earns its keep later at the start of a sentence.
                    (phonics(l.upper, size: 92) + phonics(l.lower, size: 92))
                        .kerning(4)

                    VStack(spacing: 4) {
                        Text("say \(l.sound) as in \(l.asIn)")
                            .font(.andika(19, bold: true)).foregroundStyle(Theme.go)
                        Text("not “\(l.avoid)”")
                            .font(.andika(15)).foregroundStyle(Theme.vowel)
                    }
                    // The schwa warning is aimed at the adult holding the phone:
                    // "buh-a-tuh" never blends into "bat", and that single habit
                    // stalls more beginning readers than anything else.

                    if Voice.shared.hasRecording(l.sound) {
                        SpeakButton(text: l.sound)
                    } else {
                        Text("record the 44 sounds to enable audio here")
                            .font(.andika(11)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(20)
                .cardSurface()
            }
        } controls: {
            VStack(spacing: 8) {
                ChipRow(items: Mode.allCases, label: \.rawValue, selection: $mode)
                ChipRow(items: [1, 2, 3, 4], label: { "Set \($0)" }, selection: $set, tint: Theme.go)
                Toggle(isOn: $cycling) {
                    Text("Cycle on its own").font(.andika(14)).foregroundStyle(Theme.inkSoft)
                }
                .tint(Theme.go)
            }
        }
        .onAppear { reshuffle() }
        .onChange(of: mode) { reshuffle() }
        .onChange(of: set) { index = 0; reshuffle() }
        .onChange(of: index) { if let l = current { progress.learn(letter: l.lower) } }
        .onChange(of: cycling) { _, on in on ? startCycle() : stopCycle() }
        .onDisappear { stopCycle() }
    }

    private func reshuffle() {
        order = Array(0..<max(pool.count, 1)).shuffled()
        if index >= pool.count { index = 0 }
    }
    private func startCycle() {
        stopCycle()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            guard !pool.isEmpty else { return }
            withAnimation { index = (index + 1) % pool.count }
        }
    }
    private func stopCycle() { timer?.invalidate(); timer = nil }
}
