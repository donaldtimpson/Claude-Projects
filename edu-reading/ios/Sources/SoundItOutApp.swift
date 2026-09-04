import SwiftUI

@main
struct SoundItOutApp: App {
    @State private var progress = Progress()
    @State private var settings = Settings()

    init() {
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-seed"), i + 1 < a.count, let n = Int(a[i + 1]) {
            let p = Progress(); p.reset()
            for w in ReadingContent.shared.collectibles.prefix(n) { p.learn(word: w.word) }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(progress)
                .environment(settings)
        }
    }
}

private struct RootView: View {
    var body: some View {
        #if DEBUG
        // Opens one screen directly for screenshots:
        //   xcrun simctl launch <dev> com.timpson.SoundItOut -screen world
        if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-screen"),
           i + 1 < ProcessInfo.processInfo.arguments.count {
            let name = ProcessInfo.processInfo.arguments[i + 1]
            NavigationStack {
                switch name {
                case "letters":   LettersView(start: Int(ProcessInfo.processInfo.arguments.last ?? "") ?? 0)
                case "blending":  BlendingView()
                case "words":     WordsView()
                case "sentences": SentencesView()
                case "heart":     HeartWordsView()
                case "pictures":  PictureWordsView(drawings: false)
                case "drawings":  PictureWordsView(drawings: true)
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
