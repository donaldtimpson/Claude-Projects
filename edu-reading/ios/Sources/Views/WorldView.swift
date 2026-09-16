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
                                    .foregroundStyle(got ? Skin.live.cardInk : Skin.live.cardInkSoft)
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
                    // Choosing a world changes the WHOLE app, which is the point. A
                    // wrapping grid so the set can grow past what one row holds.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                        ForEach(World.all) { w in
                            let open = progress.opened(w)
                            Button {
                                guard open else { return }
                                withAnimation(.easeInOut(duration: 0.45)) { Skin.live.set(w) }
                                // This world is now this child's — it comes back with
                                // their card next time they play.
                                profiles.setWorld(w.id)
                            } label: {
                                VStack(spacing: 3) {
                                    Text(w.face).font(.system(size: 26))
                                        .grayscale(open ? 0 : 1).opacity(open ? 1 : 0.3)
                                    Text(w.name).font(.andika(10))
                                        .foregroundStyle(Skin.live.onSkySoft)
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
                    .foregroundStyle(Skin.live.onSkySoft)
                Spacer()
                Text(tally).font(.andika(12, bold: true)).foregroundStyle(Skin.live.accent)
            }
            content()
        }
    }
    private func hint(_ t: String) -> some View {
        Text(t).font(.andika(13)).foregroundStyle(Skin.live.onSkySoft)
    }
}

/// Signing in, for someone who cannot read: a wall of faces, and you point at your
/// own. Each card can also be opened and made your own — picking a face and a colour
/// is a small game a child enjoys, so the pencil is right there on the card rather
/// than hidden behind the grown-up gate.
struct ProfilePicker: View {
    @Environment(Profiles.self) private var profiles
    @Environment(Progress.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var editing: Profile?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Who's playing?").font(.andika(26, bold: true))
                    .foregroundStyle(Skin.live.onSky)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(profiles.all) { p in card(p) }
                    addTile
                }
            }
            .padding(20)
        }
        .background(Skin.live.ground.ignoresSafeArea())
        .sheet(isPresented: $adding) { ProfileEditor() }
        .sheet(item: $editing) { ProfileEditor(editing: $0) }
    }

    /// A child's card: their face on their own colour, big enough to point at. Tap to
    /// play as them; the small pencil opens the card for editing.
    private func card(_ p: Profile) -> some View {
        let mine = p.id == profiles.currentID
        return Button {
            play(p)
        } label: {
            VStack(spacing: 6) {
                Text(p.face).font(.system(size: 44))
                Text(p.name).font(.andika(15, bold: true)).foregroundStyle(Skin.live.cardInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: p.colour).opacity(0.14))
            .background(Skin.live.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: p.colour), lineWidth: mine ? 3 : 1.5))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button { editing = p } label: {
                Image(systemName: "pencil").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: p.colour))
                    .padding(7).background(Skin.live.card, in: Circle())
                    .overlay(Circle().stroke(Color(hex: p.colour).opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(6)
        }
    }

    private var addTile: some View {
        Button { adding = true } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Skin.live.onSkySoft)
                Text("New card").font(.andika(15)).foregroundStyle(Skin.live.onSkySoft)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 22)
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(Skin.live.onSkySoft.opacity(0.45),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
        }
        .buttonStyle(.plain)
    }

    private func play(_ p: Profile) {
        profiles.select(p)
        progress.load(profile: p.id)
        // Their world returns with them — but only if they have actually opened it
        // (a card from another device, or a locked pick, falls back to classroom).
        if let wid = p.world {
            let w = World.find(wid)
            if progress.opened(w) { Skin.live.set(w) }
        }
        dismiss()
    }
}

/// Making a card, or changing one. The same screen does both: a live preview at the
/// top shows the child exactly what they are building as they pick a face and a
/// colour. No reading required to use it — the name is the one optional, adult part.
struct ProfileEditor: View {
    @Environment(Profiles.self) private var profiles
    @Environment(Progress.self) private var progress
    @Environment(\.dismiss) private var dismiss

    /// nil while making a new card; the existing card while editing one.
    let editing: Profile?
    @State private var name: String
    @State private var face: String
    @State private var colour: UInt
    @State private var confirmDelete = false

    init(editing: Profile? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _face = State(initialValue: editing?.face ?? Profiles.faces.randomElement()!)
        _colour = State(initialValue: editing?.colour ?? Profiles.colours.randomElement()!)
    }

    private let faceColumns = [GridItem(.adaptive(minimum: 52), spacing: 8)]
    private let colourColumns = [GridItem(.adaptive(minimum: 46), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    preview
                    section("FACE") {
                        LazyVGrid(columns: faceColumns, spacing: 8) {
                            ForEach(Profiles.faces, id: \.self) { f in
                                Button { face = f; Buzz.pick() } label: {
                                    Text(f).font(.system(size: 30))
                                        .frame(width: 52, height: 52)
                                        .background(face == f ? Color(hex: colour).opacity(0.22) : .clear,
                                                    in: Circle())
                                        .overlay(Circle().stroke(face == f ? Color(hex: colour) : .clear,
                                                                 lineWidth: 2))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    section("COLOUR") {
                        LazyVGrid(columns: colourColumns, spacing: 10) {
                            ForEach(Profiles.colours, id: \.self) { c in
                                Button { colour = c; Buzz.pick() } label: {
                                    Circle().fill(Color(hex: c))
                                        .frame(width: 40, height: 40)
                                        .overlay(Circle().stroke(.white, lineWidth: colour == c ? 3 : 0))
                                        .overlay(Circle().stroke(Color(hex: c),
                                                                 lineWidth: colour == c ? 2 : 0)
                                            .padding(-3))
                                        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    section("NAME") {
                        TextField("Me", text: $name)
                            .font(.andika(20, bold: true))
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1.5))
                    }
                    if editing != nil, profiles.all.count > 1 { deleteButton }
                }
                .padding(20)
            }
            .background(Theme.ground.ignoresSafeArea())
            .navigationTitle(editing == nil ? "Make a card" : "Your card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { done() } }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    /// The card as it will appear in the picker, updating under the child's finger.
    private var preview: some View {
        VStack(spacing: 8) {
            Text(face).font(.system(size: 76))
            Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Me" : name)
                .font(.andika(22, bold: true)).foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 26)
        .background(Color(hex: colour).opacity(0.16), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: colour), lineWidth: 3))
    }

    private var deleteButton: some View {
        Button(confirmDelete ? "Tap again to remove this card" : "Remove this card") {
            if confirmDelete {
                let wasCurrent = editing?.id == profiles.currentID
                if let e = editing { profiles.remove(e) }
                if wasCurrent { progress.load(profile: profiles.currentID) }
                dismiss()
            } else { confirmDelete = true }
        }
        .font(.andika(16, bold: true))
        .foregroundStyle(confirmDelete ? .white : Theme.vowel)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(confirmDelete ? Theme.vowel : Theme.paper, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.vowel, lineWidth: 1.5))
    }

    private func done() {
        let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Me" : name.trimmingCharacters(in: .whitespaces)
        if let e = editing {
            profiles.update(e, name: finalName, face: face, colour: colour)
        } else {
            let p = profiles.add(name: finalName, face: face, colour: colour)
            progress.load(profile: p.id)
        }
        Voice.shared.chime()
        dismiss()
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.andika(12, bold: true)).kerning(1.3).foregroundStyle(Theme.inkSoft)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
