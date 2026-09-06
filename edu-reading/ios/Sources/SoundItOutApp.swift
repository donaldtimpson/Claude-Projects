import SwiftUI

@main
struct SoundItOutApp: App {
    @State private var progress = Progress()
    @State private var settings = Settings()
    @State private var profiles = Profiles()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(progress)
                .environment(settings)
                .environment(profiles)
                // The palette is a single fixed light one, chosen for a lit room
                // with an adult and a child sharing a screen.
                .preferredColorScheme(.light)
                .onAppear {
                    progress.load(profile: profiles.currentID)
                    progress.openedToday()
                    #if DEBUG
                    Seed.applyIfAsked(progress)
                    #endif
                }
        }
    }
}

private struct RootView: View {
    @Environment(Profiles.self) private var profiles
    @Environment(Progress.self) private var progress
    @State private var picking = false

    var body: some View {
        content
            // Anything earned surfaces here, over whatever the child is doing, so
            // the moment is attached to the action that caused it.
            .awardToasts()
            .sheet(isPresented: $picking) { ProfilePicker() }
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-screen"),
           i + 1 < ProcessInfo.processInfo.arguments.count {
            let name = ProcessInfo.processInfo.arguments[i + 1]
            NavigationStack {
                switch name {
                case "letters":    LettersView(start: Int(ProcessInfo.processInfo.arguments.last ?? "") ?? 0)
                case "blending":   BlendingView()
                case "words":      WordsView()
                case "sentences":  SentencesView()
                case "heart":      HeartWordsView()
                case "pictures":   PictureWordsView()
                case "hub":        PictureDecksHub()
                case "colors":     ColorsView()
                case "shapes":     ShapesView()
                case "numbers":    NumbersView(start: Int(ProcessInfo.processInfo.arguments.last ?? "") ?? 0)
                case "world":      WorldView()
                case "profiles":   ProfilePicker()
                case "parent":     ParentGateView()
                case "shapesheet": ShapeSheet()
                case "colorsheet": ColourSheet()
                default:           HomeView()
                }
            }
            .tint(Skin.live.accent)
        } else {
            HomeView()
        }
        #else
        HomeView()
        #endif
    }
}

#if DEBUG
/// Puts the app in a state worth photographing: `-seed 30` reads thirty words and
/// grants whatever that earns, so the badge shelf and the worlds are populated.
enum Seed {
    static func applyIfAsked(_ p: Progress) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-seed"), i + 1 < a.count, let n = Int(a[i + 1]) else { return }
        p.reset()
        for w in ReadingContent.shared.pictureWords.prefix(n) { p.readWord(w.word) }
        for l in ReadingContent.shared.letters.prefix(min(n, 26)) { p.metLetter(l.lower) }
        p.pending.removeAll()          // seeding should not fire a stack of toasts
    }
}
#endif
