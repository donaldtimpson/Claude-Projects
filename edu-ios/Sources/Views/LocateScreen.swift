import SwiftUI

// Flag beside the "Find X" prompt: emoji for countries (system font so it composes), a
// bundled PNG for U.S. states (whose iso is a postal code, not a country code).
struct LocateFlag: View {
    let kind: GeoMapKind
    let id: String
    var body: some View {
        switch kind {
        case .world:
            let flag = GeoAtlas.world.region(id)?.flag ?? ""
            if !flag.isEmpty { Text(flag).font(.system(size: 26)) }
        case .usStates:
            if let iso = GeoAtlas.usStates.region(id)?.iso,
               let img = FlagImage.load("us-\(iso.lowercased())") {
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.line, lineWidth: 0.5))
            }
        }
    }
}

// The full-screen landscape tap-to-locate screen, shared by Practice, Learn, and Rapid Fire
// so they present identically. The map fills the frame; the caller supplies a mode-specific
// top bar (close/progress, mastered count, timer/score…), the reveal state, and the tap
// handler. Real landscape rotation (either direction) via `.landscapeWhilePresented()`.
struct LocateScreen<TopBar: View>: View {
    let kind: GeoMapKind
    let targetId: String
    let prompt: String
    let revealed: Bool
    let tappedId: String?
    let flash: Bool?
    var showCard: Bool = true
    var resultOK: Bool = false
    var resultDetail: String? = nil
    var onAdvanceTap: (() -> Void)? = nil
    let onTap: (String?) -> Void
    @ViewBuilder var topBar: TopBar

    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            DrillFlash(correct: flash)
            VStack(spacing: 6) {
                topBar
                HStack(spacing: 8) {
                    Text("Find \(prompt)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    LocateFlag(kind: kind, id: targetId)
                }
                MapTapCard(kind: kind, targetId: targetId, revealed: revealed,
                           tappedId: tappedId, fillFrame: true, onTap: onTap)
                    .frame(maxHeight: .infinity)
                    // Tap anywhere after answering to skip ahead early (modes that auto-advance).
                    .overlay {
                        if revealed, let onAdvanceTap {
                            Color.clear.contentShape(Rectangle()).onTapGesture { onAdvanceTap() }
                        }
                    }
                    .overlay(alignment: .bottomLeading) {
                        if revealed && showCard {
                            DrillResultCard(ok: resultOK, detail: resultDetail)
                                .padding(10)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .statusBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .landscapeWhilePresented()
    }
}
