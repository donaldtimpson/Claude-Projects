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
            .background(Theme.ground)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                section("WHERE THEY ARE") {
                    row("Words collected", "\(progress.knownWords.count) of \(c.collectibles.count)")
                    row("Letter sounds seen", "\(progress.knownLetters.count) of \(c.letters.count)")
                    row("Sentences read", "\(progress.castSpells.count)")
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
                            Text("The card listens while it's up, and turns itself when they read it. It only ever says yes — it never tells a child they got it wrong.")
                                .font(.andika(12)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .tint(Theme.go)

                    Toggle(isOn: Binding(get: { settings.rimeBlending },
                                         set: { settings.rimeBlending = $0; settings.save() })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Blend by word family").font(.andika(16)).foregroundStyle(Theme.ink)
                            Text(settings.rimeBlending
                                 ? "at → fat → sat. Stable in English."
                                 : "fa, fe, fi. Works in Spanish; shakier in English.")
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

                section("THANK YOU") {
                    // CC BY / CC BY-SA attribution for everything the app ships.
                    credit("Andika", "SIL International, under the Open Font License. A typeface drawn for beginning readers — single-storey a and g, and letterforms that can't be confused with one another.")
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
    private func credit(_ name: String, _ what: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(.andika(16, bold: true)).foregroundStyle(Theme.ink)
            Text(what).font(.andika(13)).foregroundStyle(Theme.inkSoft)
        }
    }
}
