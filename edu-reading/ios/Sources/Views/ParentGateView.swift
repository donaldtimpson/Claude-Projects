import SwiftUI

// App Store guideline 1.3: a Kids Category app may not link out, or present
// anything but child-appropriate content, unless it sits behind a parental gate.
// One gate serves all three of the adult-facing things here — the credits that
// satisfy CC BY attribution, the one mention of the Lyceum, and reset.
//
// The gate is a written-out multiplication, which is the standard shape: solvable
// by any adult, and not by the four-year-old the app is for.
struct ParentGateView: View {
    @State private var a = Int.random(in: 3...9)
    @State private var b = Int.random(in: 4...9)
    @State private var entry = ""
    @State private var open = false

    var body: some View {
        Group { if open { AdultView() } else { gate } }
            // Fill the screen first, then paint — otherwise the Group hugs its
            // content width and Theme.ground leaves white stripes down both sides.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.ground.ignoresSafeArea())
            .navigationTitle("For grown-ups")
            .navigationBarTitleDisplayMode(.inline)
    }

    private var gate: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("What is \(spell(a)) times \(spell(b))?")
                .font(.andika(24, bold: true)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            TextField("", text: $entry)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.andika(30, bold: true))
                .frame(width: 130, height: 62)
                .background(Theme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1.5))
                .onChange(of: entry) { _, v in
                    if Int(v) == a * b { withAnimation { open = true } }
                }
            Text("This keeps the grown-up area out of small hands.")
                .font(.andika(13)).foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(24)
    }

    private func spell(_ n: Int) -> String {
        ["zero","one","two","three","four","five","six","seven","eight","nine"][n]
    }
}

private struct AdultView: View {
    @Environment(Progress.self) private var progress
    @Environment(Settings.self) private var settings
    private let c = ReadingContent.shared
    @State private var confirmReset = false
    @State private var bump = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                section("THE PATH") {
                    PathSummary()
                }

                section("LETTERS") {
                    LetterGrid()
                }

                section("COUNTS") {
                    row("Words read", "\(progress.readWords.count)")
                    row("Words known by ear", "\(progress.knownWords.count)")
                    row("Letters met", "\(progress.seenLetters.count) of \(c.letters.count)")
                    row("Sentences read", "\(progress.readSentences.count)")
                    row("Badges", "\(progress.awards.count) of \(Awards.all.count)")
                    Text("Nothing here is uploaded. It never leaves this device.")
                        .font(.andika(13)).foregroundStyle(Theme.inkSoft)
                }

                section("SETTINGS") {
                    Toggle(isOn: Binding(
                        get: { settings.listenForVoice },
                        set: { want in
                            if want && !Listener.isAuthorized {
                                // Guideline 1.3: a Kids app may only request
                                // permissions from behind a parental gate. This is it.
                                Listener.requestAccess { ok in
                                    settings.listenForVoice = ok; settings.save()
                                }
                            } else {
                                settings.listenForVoice = want; settings.save()
                            }
                        })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Listen for their voice").font(.andika(16)).foregroundStyle(Theme.ink)
                            Text("The card listens while it's up — for a read word, a number, a colour or a shape — and moves on when they say it. It only ever says yes; it never tells a child they got it wrong.")
                                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .tint(Theme.go)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pictures").font(.andika(16)).foregroundStyle(Theme.ink)
                        Picker("", selection: Binding(
                            get: { settings.pictureStyle },
                            set: { settings.pictureStyle = $0; settings.save() })) {
                            ForEach(Settings.PictureStyle.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text(settings.pictureStyle == .both
                             ? "Photographs and drawings of the same word, spread apart. Meeting a real dog and a drawn one is how a child learns that both are \"dog\"."
                             : settings.pictureStyle == .photos
                             ? "Photographs only."
                             : "Drawings only — often easier for a younger child, with less to look past.")
                            .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Numbers go up to").font(.andika(16)).foregroundStyle(Theme.ink)
                        Picker("", selection: Binding(
                            get: { settings.numberLevel },
                            set: { settings.numberLevel = $0; settings.save() })) {
                            ForEach(ReadingContent.shared.numbers.levels, id: \.self) {
                                Text("\($0)").tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("Ten first. Twenty adds the teens, which are the irregular ones. Fifty and a hundred lay the counters out in rows of ten, which is the hundred-square.")
                            .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                    }

                    Toggle(isOn: Binding(get: { settings.autoTurn },
                                         set: { settings.autoTurn = $0; settings.save() })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cards turn themselves").font(.andika(16)).foregroundStyle(Theme.ink)
                            Text(settings.autoTurn
                                 ? "Tap and the card says its word, then turns on its own. Tapping again just says it again."
                                 : "Tap once to hear the card, tap again to turn it. Swiping works too.")
                                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .tint(Theme.go)

                    Toggle(isOn: Binding(get: { settings.showWordOnPictures },
                                         set: { settings.showWordOnPictures = $0; settings.save() })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show the word on picture cards").font(.andika(16)).foregroundStyle(Theme.ink)
                            Text("It's there for you, not them. Hide it once they start reading.")
                                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .tint(Theme.go)
                }

                section("GAMES") {
                    gamePicker("Find It — how many pictures",
                               "Two is a real question for a two-year-old; four is not.",
                               [2, 3, 4], get: { settings.quizChoices },
                               set: { settings.quizChoices = $0 })

                    Toggle(isOn: Binding(get: { settings.quizReads },
                                         set: { settings.quizReads = $0; settings.save() })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Find It shows the word").font(.andika(16)).foregroundStyle(Theme.ink)
                            Text(settings.quizReads
                                 ? "The word is printed — this is the reading test."
                                 : "The app says the word instead, so no reading is needed.")
                                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .tint(Theme.go)

                    gamePicker("Build a Word — extra letters",
                               "Decoy letters in the tray. None is an unscramble; more is a harder find.",
                               [0, 2, 4], get: { settings.spellDecoys },
                               set: { settings.spellDecoys = $0 })

                    gamePicker("Rhyme Time — how many words",
                               "How many words to choose the rhyme from.",
                               [2, 3, 4], get: { settings.rhymeChoices },
                               set: { settings.rhymeChoices = $0 })

                    gamePicker("Match Up — how many matches",
                               "Pairs on the board. More pairs is a longer, harder memory game.",
                               [3, 4, 6], get: { settings.matchPairs },
                               set: { settings.matchPairs = $0 })
                }

                section("THANK YOU") {
                    // CC BY / CC BY-SA attribution for everything the app ships.
                    credit("Andika", "SIL International, under the Open Font License. A typeface drawn for beginning readers — single-storey a and g, and letterforms that can't be confused with one another.")
                    credit("Phonics sounds", "Phonics sounds: Phonicademy (phonicademy.com). Used under the Phonicademy Audio License; trimmed and levelled.")
                    credit("Lingua Libre & Wikimedia Commons", "Recorded English pronunciations, contributed by volunteers under CC BY-SA.")
                    credit("Openverse", "How the photographs were found — an index of openly-licensed images.")
                    Text("If a recording or picture here is yours, thank you. Tell us and we'll name you properly.")
                        .font(.andika(13)).foregroundStyle(Theme.inkSoft)

                    NavigationLink {
                        PhotoCreditsView()
                    } label: {
                        HStack {
                            Text("The \(PhotoCredit.all.count) photographers")
                                .font(.andika(16, bold: true)).foregroundStyle(Theme.go)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }

                section("MORE FROM US") {
                    Text("Timpson Lyceum has free courses in maths, physics, history and grammar — for much older students than this app is for.")
                        .font(.andika(15)).foregroundStyle(Theme.ink)
                    Link("timpson-lyceum.vercel.app", destination: URL(string: "https://timpson-lyceum.vercel.app")!)
                        .font(.andika(15, bold: true)).foregroundStyle(Theme.go)
                }

                section("START OVER") {
                    Button(confirmReset ? "Tap again to erase everything" : "Erase all progress") {
                        if confirmReset { progress.reset(); confirmReset = false }
                        else { confirmReset = true }
                    }
                    .font(.andika(16, bold: true))
                    .foregroundStyle(confirmReset ? .white : Theme.vowel)
                    .padding(.horizontal, 16).padding(.vertical, 11)
                    .background(confirmReset ? Theme.vowel : Theme.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.vowel, lineWidth: 1.5))
                }
            }
            .padding(20)
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.andika(12, bold: true)).kerning(1.4).foregroundStyle(Theme.inkSoft)
            content()
        }
    }
    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.andika(16)).foregroundStyle(Theme.ink)
            Spacer()
            Text(v).font(.andika(16, bold: true)).foregroundStyle(Theme.go).monospacedDigit()
        }
    }
    /// A titled segmented picker over integer options, saving on change.
    private func gamePicker(_ title: String, _ blurb: String, _ options: [Int],
                            get: @escaping () -> Int, set: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.andika(16)).foregroundStyle(Theme.ink)
            Picker("", selection: Binding(get: get, set: { set($0); settings.save() })) {
                ForEach(options, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
            Text(blurb).font(.andika(12)).foregroundStyle(Theme.inkSoft)
        }
    }
    private func credit(_ name: String, _ what: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(.andika(16, bold: true)).foregroundStyle(Theme.ink)
            Text(what).font(.andika(13)).foregroundStyle(Theme.inkSoft)
        }
    }
}

/// Where the child is on the learning path, what finishing this step takes, the
/// steps around it, and a "start here" for a child who is past the beginning.
private struct PathSummary: View {
    @Environment(Progress.self) private var progress

    var body: some View {
        let steps = LearningPath.steps
        let at = LearningPath.currentIndex(progress)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(steps[at].emoji).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Now: \(steps[at].title)").font(.andika(16, bold: true)).foregroundStyle(Theme.ink)
                    Text("Step \(at + 1) of \(steps.count). Moves on when: \(steps[at].detail)")
                        .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                }
            }
            // Every step, done ones ticked — a map a grown-up can read at a glance.
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                    HStack(spacing: 8) {
                        Image(systemName: s.isDone(progress) ? "checkmark.circle.fill"
                              : (i == at ? "play.circle.fill" : "circle"))
                            .foregroundStyle(s.isDone(progress) ? Theme.go : (i == at ? Theme.heart : Theme.inkSoft.opacity(0.5)))
                        Text(s.title).font(.andika(13, bold: i == at))
                            .foregroundStyle(i == at ? Theme.ink : Theme.inkSoft)
                        Spacer()
                        if i < at, i >= progress.pathFloor, !s.isDone(progress) {
                            Text("skipped").font(.andika(11)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            HStack {
                Text("Start them at").font(.andika(14)).foregroundStyle(Theme.ink)
                Spacer()
                Menu {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                        Button(s.title) { progress.setPathFloor(i) }
                    }
                } label: {
                    Text(steps[min(progress.pathFloor, steps.count - 1)].title)
                        .font(.andika(14, bold: true)).foregroundStyle(Theme.go)
                }
            }
            Text("For a child who already knows the early steps. The path never places them below this, and moves on from it as usual.")
                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
        }
    }
}

/// All 26 letters, each with three marks: the sound picked out in First Sound
/// (twice = secure), traced, and met on a card. What to practise at the table.
private struct LetterGrid: View {
    @Environment(Progress.self) private var progress
    private let c = ReadingContent.shared

    var body: some View {
        let letters = c.letters.sorted { $0.lower < $1.lower }
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(letters, id: \.lower) { l in
                    let hits = progress.soundHits[c.phoneme(of: l)] ?? 0
                    let wrote = progress.wroteLetters.contains(l.lower)
                    let met = progress.seenLetters.contains(l.lower)
                    let secure = hits >= 2 && wrote
                    VStack(spacing: 3) {
                        Text(l.lower).font(.andika(20, bold: true))
                            .foregroundStyle(secure ? .white : Theme.ink)
                        HStack(spacing: 2) {
                            dot(hits >= 2, secure)
                            dot(wrote, secure)
                            dot(met, secure)
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(secure ? Theme.go : Theme.paperDim, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            Text("Dots: sound heard right twice · traced · met on a card. Green = secure.")
                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
            let shaky = letters.filter { l in
                progress.seenLetters.contains(l.lower) &&
                ((progress.soundHits[c.phoneme(of: l)] ?? 0) < 2 || !progress.wroteLetters.contains(l.lower))
            }.prefix(6).map(\.lower)
            if !shaky.isEmpty {
                Text("Worth practising: " + shaky.joined(separator: "  "))
                    .font(.andika(14, bold: true)).foregroundStyle(Theme.heart)
            }
        }
    }

    private func dot(_ on: Bool, _ secure: Bool) -> some View {
        Circle().fill(on ? (secure ? Color.white : Theme.go) : Theme.inkSoft.opacity(0.25))
            .frame(width: 5, height: 5)
    }
}
