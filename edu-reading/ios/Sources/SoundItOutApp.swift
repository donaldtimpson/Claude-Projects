import SwiftUI

@main
struct SoundItOutApp: App {
    @State private var progress = Progress()

    init() {
        #if DEBUG
        // `-seed N` pre-collects N words so the populated world can be captured
        // without tapping through the whole app. Debug builds only.
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-seed"), i + 1 < a.count, let n = Int(a[i + 1]) {
            let p = Progress()
            p.reset()
            for w in ReadingContent.shared.collectibles.prefix(n) { p.learn(word: w.word) }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView().environment(progress)
        }
    }
}

private struct RootView: View {
    var body: some View {
        #if DEBUG
        // Lets tooling open one screen directly for a screenshot, e.g.
        //   xcrun simctl launch <dev> com.timpson.SoundItOut -screen world
        // Debug-only; the shipped app always starts at home.
        if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-screen"),
           i + 1 < ProcessInfo.processInfo.arguments.count {
            let name = ProcessInfo.processInfo.arguments[i + 1]
            NavigationStack {
                switch name {
                case "letters":   LettersView()
                case "blending":  BlendingView()
                case "words":     WordsView()
                case "sentences": SentencesView()
                case "heart":     HeartWordsView()
                case "pictures":  PictureWordsView()
                case "world":     WorldView()
                case "parent":    ParentGateView()
                default:          HomeView()
                }
            }
            .tint(Theme.go)
        } else {
            HomeView()
        }
        #else
        HomeView()
        #endif
    }
}
