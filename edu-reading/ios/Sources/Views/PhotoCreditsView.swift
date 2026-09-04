import SwiftUI

/// One row per bundled photograph. CC BY obliges us to name the photographer, and
/// naming them properly is the price of the pictures being free.
struct PhotoCreditsView: View {
    private let credits = PhotoCredit.all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Every picture in Look and Say was taken by someone who chose to share it. Thank you.")
                    .font(.andika(15)).foregroundStyle(Theme.inkSoft)
                    .padding(.bottom, 4)

                ForEach(credits, id: \.asset) { c in
                    HStack(alignment: .top, spacing: 12) {
                        Image(c.asset)
                            .resizable().scaledToFill()
                            .frame(width: 46, height: 46)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(c.word).font(.andika(16, bold: true)).foregroundStyle(Theme.ink)
                            Text(c.creator).font(.andika(13)).foregroundStyle(Theme.inkSoft)
                            Text(c.licenseName).font(.andika(11)).foregroundStyle(Theme.go)
                        }
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.ground)
        .navigationTitle("Photographers")
        .navigationBarTitleDisplayMode(.inline)
    }
}
