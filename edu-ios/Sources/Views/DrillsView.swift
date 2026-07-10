import SwiftUI

struct DrillsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(DrillCatalog.all) { drill in
                    NavigationLink(value: drill.slug) {
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
        .navigationDestination(for: String.self) { DrillRunnerView(slug: $0) }
    }
}
