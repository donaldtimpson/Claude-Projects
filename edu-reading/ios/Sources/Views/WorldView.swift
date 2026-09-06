import SwiftUI

// One screen, three sections: what you have read, what you have won, and where you
// can go. The old version had a places tab that only changed the sky on that one
// screen — decoration wearing a progress bar's clothes. Worlds now apply to the
// whole app, so choosing one is actually moving somewhere.
struct WorldView: View {
    @Environment(Progress.self) private var progress
    @Environment(Profiles.self) private var profiles
    private let c = ReadingContent.shared

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 74), spacing: 10)] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {

                section("WHAT I'VE READ", "\(progress.readWords.count)") {
                    if progress.readWords.isEmpty {
                        hint("Read a word out loud and it comes to live here.")
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(collected, id: \.self) { w in
                                Button { Voice.shared.say(w) } label: {
                                    VStack(spacing: 3) {
                                        Text(face(for: w)).font(.system(size: 30))
                                        phonics(w, size: 13)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Skin.live.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                section("MY BADGES", "\(progress.awards.count) of \(Awards.all.count)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                        ForEach(Awards.all) { a in
                            let got = progress.has(a.id)
                            VStack(spacing: 4) {
                                Text(a.face).font(.system(size: 30))
                                    .grayscale(got ? 0 : 1).opacity(got ? 1 : 0.28)
                                Text(a.name).font(.andika(11, bold: true))
                                    .foregroundStyle(got ? Theme.ink : Theme.inkSoft)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Skin.live.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(got ? Color(hex: a.tint).opacity(0.6) : .clear, lineWidth: 2))
                        }
                    }
                }

                section("WHERE I CAN GO", "\(progress.worlds.count) of \(World.all.count)") {
                    // Choosing a world changes the WHOLE app, which is the point.
                    HStack(spacing: 10) {
                        ForEach(World.all) { w in
                            let open = progress.opened(w)
                            Button {
                                guard open else { return }
                                withAnimation(.easeInOut(duration: 0.45)) { Skin.live.set(w) }
                            } label: {
                                VStack(spacing: 3) {
                                    Text(w.face).font(.system(size: 26))
                                        .grayscale(open ? 0 : 1).opacity(open ? 1 : 0.3)
                                    Text(w.name).font(.andika(10))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Skin.live.world.id == w.id ? Skin.live.card : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Skin.live.world.id == w.id ? Skin.live.accent : .clear,
                                            lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    hint(nextWorldHint)
                }
            }
            .padding(18)
        }
        .background(Skin.live.ground.ignoresSafeArea())
        .navigationTitle(profiles.current.map { "\($0.face) \($0.name)" } ?? "My World")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var collected: [String] {
        c.pictureWords.map(\.word).filter { progress.knows(word: $0) }
    }
    private func face(for word: String) -> String {
        c.pictureWords.first { $0.word == word }?.images.first ?? "🔤"
    }
    private var nextWorldHint: String {
        if let next = Awards.all.first(where: { $0.unlocksWorld != nil && !progress.has($0.id) }) {
            return "\(next.name) opens a new place."
        }
        return "Every place is open."
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, _ tally: String,
                                  @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(title).font(.andika(12, bold: true)).kerning(1.3)
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(tally).font(.andika(12, bold: true)).foregroundStyle(Skin.live.accent)
            }
            content()
        }
    }
    private func hint(_ t: String) -> some View {
        Text(t).font(.andika(13)).foregroundStyle(Theme.inkSoft)
    }
}

/// Signing in, for someone who cannot read. Pick your own face.
struct ProfilePicker: View {
    @Environment(Profiles.self) private var profiles
    @Environment(Progress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var name = ""
    @State private var face = Profiles.faces[0]
    @State private var colour = Profiles.colours[0]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Who's playing?").font(.andika(26, bold: true)).foregroundStyle(Theme.ink)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                    ForEach(profiles.all) { p in
                        Button {
                            profiles.select(p); progress.load(profile: p.id); dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                Text(p.face).font(.system(size: 44))
                                Text(p.name).font(.andika(15, bold: true)).foregroundStyle(Theme.ink)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Skin.live.card)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: p.colour).opacity(0.6), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                    Button { adding = true } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(Theme.inkSoft)
                            Text("Add").font(.andika(15)).foregroundStyle(Theme.inkSoft)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(Theme.inkSoft.opacity(0.35),
                                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Skin.live.ground.ignoresSafeArea())
        .sheet(isPresented: $adding) {
            NavigationStack {
                Form {
                    Section("Name") { TextField("Name", text: $name) }
                    Section("Face") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 46))], spacing: 8) {
                            ForEach(Profiles.faces, id: \.self) { f in
                                Button { face = f } label: {
                                    Text(f).font(.system(size: 30))
                                        .padding(5)
                                        .background(face == f ? Skin.live.accent.opacity(0.2) : .clear)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .navigationTitle("New player")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let p = profiles.add(name: name.isEmpty ? "Me" : name,
                                                 face: face, colour: colour)
                            progress.load(profile: p.id)
                            adding = false; name = ""; dismiss()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { adding = false }
                    }
                }
            }
        }
    }
}
