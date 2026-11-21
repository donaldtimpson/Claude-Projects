import SwiftUI

struct HomeView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    @Environment(Profiles.self) private var profiles
    private let c = ReadingContent.shared

    private let grid = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    // ONE thing to press. The path decides what's inside; a child who
                    // can't read the rest of this screen can still start here.
                    NavigationLink { SessionView() } label: { PlayCard() }
                        .buttonStyle(.plain)

                    if !progress.stickers.isEmpty {
                        NavigationLink { WorldView() } label: {
                            StickerBoard(stickers: Array(progress.stickers.suffix(14)), size: 28)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Skin.live.card.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }

                    // Everything else, to explore freely — big pictures rather than a
                    // list of names, so a pre-reader still has somewhere to aim.
                    section("LISTEN AND LOOK") {
                        GridTile(emoji: "🖼️", tint: 0xD9646E, name: "Look and Say") { PictureDecksHub() }
                        GridTile(emoji: "🔎", tint: 0x3E8FA8, name: "Find It") { QuizView() }
                        if Voice.shared.hasAnyLetterAudio {
                            GridTile(emoji: "👂", tint: 0x2E7D6E, name: "Sound Hunt") { SoundGameView(mode: .blend) }
                            GridTile(emoji: "🔉", tint: 0xC8433A, name: "First Sound") { SoundGameView(mode: .first) }
                        }
                        GridTile(emoji: "🎵", tint: 0x7A5EA8, name: "Rhyme Time") { RhymeView() }
                        GridTile(emoji: "🃏", tint: 0x3E8FA8, name: "Match Up") { MatchView() }
                        GridTile(emoji: "🎨", tint: 0x4E8FBF, name: "Colours") { ColorsView() }
                        GridTile(emoji: "🔷", tint: 0x6FA368, name: "Shapes") { ShapesView() }
                        GridTile(emoji: "🔢", tint: 0xC98A3E, name: "Numbers") { NumbersView() }
                    }
                    section("READ") {
                        GridTile(emoji: "🔤", tint: 0xE0A038, name: "Letters") { LettersView() }
                        GridTile(emoji: "🤝", tint: 0x2E7D6E, name: "Blending") { BlendingView() }
                        GridTile(emoji: "🐱", tint: 0x3E9077, name: "Word Families") { WordBlendingView() }
                        GridTile(emoji: "📝", tint: 0x3B7EA1, name: "Words") { WordsView() }
                        GridTile(emoji: "❤️", tint: 0xC8433A, name: "By Heart") { HeartWordsView() }
                        GridTile(emoji: "💬", tint: 0x7A5EA8, name: "Sentences") { SentencesView() }
                        GridTile(emoji: "📚", tint: 0x2E9E4F, name: "Little Books") { BooksView() }
                    }
                    section("WRITE") {
                        GridTile(emoji: "🖍️", tint: 0xE0724E, name: "Draw") { TraceView(pictures: true) }
                        GridTile(emoji: "✏️", tint: 0x7A5EA8, name: "Trace") { TraceView() }
                        GridTile(emoji: "🧩", tint: 0xC98A3E, name: "Build a Word") { SpellView() }
                    }

                    NavigationLink { ParentGateView() } label: {
                        Label("For grown-ups", systemImage: "lock.fill")
                            .font(.andika(14))
                            .foregroundStyle(Skin.live.onSkySoft)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
            }
            .background(Skin.current.appGround.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(Theme.go)
    }

    /// Who is playing (tap your face to change) and the way into My World.
    private var header: some View {
        HStack(spacing: 12) {
            NavigationLink { ProfilePicker() } label: {
                HStack(spacing: 10) {
                    Text(profiles.current?.face ?? "🌱").font(.system(size: 38))
                        .frame(width: 58, height: 58)
                        .background(Skin.live.card, in: Circle())
                        .overlay(Circle().stroke(Skin.live.accent.opacity(0.5), lineWidth: 2))
                    Text(profiles.current?.name ?? "")
                        .font(.andika(22, bold: true)).foregroundStyle(Skin.live.onSky)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            NavigationLink { WorldView() } label: {
                HStack(spacing: 6) {
                    Text("🏆").font(.system(size: 22))
                    Text("\(progress.awards.count)").font(.andika(17, bold: true))
                        .foregroundStyle(Skin.live.cardInk)
                }
                .padding(.horizontal, 14).frame(height: 46)
                .background(Skin.live.card, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder _ tiles: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.andika(12, bold: true)).kerning(1.4)
                .foregroundStyle(Skin.live.onSkySoft)
            LazyVGrid(columns: grid, spacing: 12) { tiles() }
        }
    }
}

/// The big button. The child sees a play triangle and today's picture; the small
/// line underneath is for the grown-up — what today is working on.
private struct PlayCard: View {
    @Environment(Progress.self) private var progress

    var body: some View {
        let step = LearningPath.current(progress)
        // A fixed warm colour, not the theme accent: the plain Classroom theme's
        // accent is grey, and this must be the brightest thing on the screen.
        let accent = Color(hex: 0xE0724E)
        HStack(spacing: 18) {
            ZStack {
                Circle().fill(.white).frame(width: 92, height: 92)
                Image(systemName: "play.fill").font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(accent).offset(x: 4)
            }
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            VStack(alignment: .leading, spacing: 6) {
                Text(step.emoji).font(.system(size: 44))
                Text(step.title)
                    .font(.andika(14, bold: true)).foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            LinearGradient(colors: [accent, accent.mixed(with: .black, amount: 0.18)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: accent.opacity(0.35), radius: 12, y: 6)
    }
}

/// An explore tile: a big picture and a short name, in the deck's colour.
private struct GridTile<Destination: View>: View {
    let emoji: String
    var tint: UInt = 0x63777F
    let name: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        let colour = Color(hex: tint)
        let skin = Skin.current
        NavigationLink { destination() } label: {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 44))
                Text(name).font(.andika(15, bold: true)).foregroundStyle(Skin.live.cardInk)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(skin.tileFill.mixed(with: colour, amount: 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colour.mixed(with: skin.tileFill, amount: 0.55), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }
}
