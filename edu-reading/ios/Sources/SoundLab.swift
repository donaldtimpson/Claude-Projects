import SwiftUI
import AudioToolbox

#if DEBUG
// A private audition bench for the reward sound: `-screen sounds`. I can't judge a
// sound by ear, so rather than guess, this plays a spread of distinct, clean
// candidates (and a few iOS system sounds) — tap through, pick the winner, and it
// gets wired into Voice.celebrate(). Never shipped (DEBUG only).
struct SoundLab: View {
    private typealias T = Voice.Tone

    private var candidates: [(String, Data?)] {
        [
            ("Harp glissando (current)", Voice.harpGliss()),
            ("Music box arpeggio",
             Voice.render([T(f: 523.25, start: 0, dur: 0.9, amp: 0.9),
                           T(f: 659.25, start: 0.1, dur: 0.9, amp: 0.8),
                           T(f: 783.99, start: 0.2, dur: 0.9, amp: 0.75),
                           T(f: 1046.5, start: 0.3, dur: 0.9, amp: 0.7)],
                          partials: [(1, 1), (2, 0.25)], decay: 3.6)),
            ("Marimba triad",
             Voice.render([T(f: 523.25, start: 0, dur: 0.7, amp: 0.9),
                           T(f: 659.25, start: 0, dur: 0.7, amp: 0.8),
                           T(f: 783.99, start: 0, dur: 0.7, amp: 0.8)],
                          partials: [(1, 1), (4, 0.35), (10, 0.08)], decay: 7)),
            ("Bell / glockenspiel",
             Voice.render([T(f: 880, start: 0, dur: 1.6, amp: 1)],
                          partials: [(1, 1), (2.76, 0.4), (5.4, 0.16)], decay: 2.2)),
            ("Star collect (game pickup)",
             Voice.render([T(f: 987.77, start: 0, dur: 0.28, amp: 0.9),
                           T(f: 1318.51, start: 0.09, dur: 0.5, amp: 0.9)],
                          partials: [(1, 1), (2, 0.3)], decay: 6)),
            ("Twinkle sprinkle",
             Voice.render((0..<7).map { i in
                 T(f: [1318.51, 1567.98, 1046.5, 1760, 1174.66, 987.77, 1396.91][i],
                   start: Double(i) * 0.06, dur: 0.5, amp: 0.7)
             }, partials: [(1, 1), (2, 0.15)], decay: 5)),
            ("Rising ta-da (two chords)",
             Voice.render([T(f: 392, start: 0, dur: 0.5, amp: 0.7), T(f: 493.88, start: 0, dur: 0.5, amp: 0.7),
                           T(f: 587.33, start: 0, dur: 0.5, amp: 0.7),
                           T(f: 523.25, start: 0.18, dur: 0.9, amp: 0.8), T(f: 659.25, start: 0.18, dur: 0.9, amp: 0.8),
                           T(f: 783.99, start: 0.18, dur: 0.9, amp: 0.8)],
                          partials: [(1, 1), (2, 0.2)], decay: 3.2)),
        ]
    }

    private let systemIDs: [UInt32] = [1013, 1025, 1057, 1109, 1114, 1150, 1313, 1322, 1327, 1335]

    var body: some View {
        List {
            Section("Synth candidates") {
                ForEach(candidates, id: \.0) { name, data in
                    Button {
                        if let data { Voice.shared.playEffect(data) }
                    } label: { row(name) }
                }
            }
            Section("iOS system sounds") {
                ForEach(systemIDs, id: \.self) { id in
                    Button {
                        AudioServicesPlaySystemSound(SystemSoundID(id))
                    } label: { row("System \(id)") }
                }
            }
        }
        .navigationTitle("Sound lab")
    }

    private func row(_ name: String) -> some View {
        HStack {
            Image(systemName: "play.circle.fill").foregroundStyle(Theme.go)
            Text(name).foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}
#endif
