import SwiftUI

struct DrillsView: View {
    // Drills run in a full-screen cover (over the tab bar) so the bottom feedback/keypad
    // isn't obscured and the experience feels like a focused mini-game.
    @State private var active: ActiveDrill?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(DrillCatalog.all) { drill in
                    Button { active = ActiveDrill(id: drill.slug) } label: {
                        HStack(spacing: 12) {
                            Text(drill.icon).font(.system(size: 34))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(drill.title).font(.headline).foregroundStyle(Theme.ink)
                                Text(drill.blurb).font(.subheadline).foregroundStyle(Theme.inkSoft).lineLimit(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .lyceumCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Theme.parchment)
        .navigationTitle("Practice Drills")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $active) { drill in
            NavigationStack {
                DrillRunnerView(slug: drill.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { active = nil } label: {
                                Image(systemName: "xmark").font(.body.weight(.semibold))
                            }
                            .tint(Theme.gold300)
                        }
                    }
            }
        }
    }
}

struct ActiveDrill: Identifiable { let id: String }
