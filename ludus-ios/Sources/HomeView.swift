import SwiftUI

// MARK: - Home — the arcade hub as a painted Roman province you travel
//
// The home screen is a tall, hand-painted province map (`ProvinceMap`). It is "the world": eight
// landmarks are subject-worlds strung along one winding road, and the child is a traveler who walks
// the road to a landmark before entering its games. Two taps, two meanings —
//
//   • tap a landmark = GO THERE (the traveler walks the road; a parchment card opens on arrival)
//   • tap PLAY       = PLAY HERE (enter that subject's game list)
//
// The road and each landmark's stop (`arriveAt`, an arc-length position 0…1) were traced from a
// hand-drawn overlay on the art. Arrival is exact and authored — never projected. The camera is a
// manual vertical offset (`manualCamY`) driven by the SAME animation that walks the chip, so the
// two never fight (that was the old jitter bug). Free exploration is a drag pan.
//
// Re-tuning for new art: re-trace `roadPoints` + each landmark's `arriveAt`. Nothing else moves.

private enum Prov {
    static let red     = Color(hex: 0x9e2b25)
    static let redDeep = Color(hex: 0x7d211c)
    static let gold    = Color(hex: 0xc99a3a)
    static let goldHi  = Color(hex: 0xe6c15f)
    static let cream   = Color(hex: 0xfbe7bf)
    static let inkDim  = Color(hex: 0xeec98f)
    static let plate   = Color(hex: 0xf4ebd2)
    static let plateInk = Color(hex: 0x3a2a15)
}

/// Aged-parchment field the whole home rests on: a warm vellum wash, a lighter aged center, and a
/// worn edge vignette. Fills the status-bar area and any over-scroll so nothing ever reads as a
/// flat void behind the painted map.
struct ParchmentBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xe9d3a3), Color(hex: 0xd8bd88), Color(hex: 0xc2a878)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: 0xf3e5c2).opacity(0.75), .clear],
                           center: .center, startRadius: 20, endRadius: 480)
            RadialGradient(colors: [.clear, Color(hex: 0x8a6f42).opacity(0.38)],
                           center: .center, startRadius: 240, endRadius: 640)
        }
    }
}

/// A world on the map. Three DISTINCT authored things (do not conflate): the seal `x,y` is centered
/// UNDER the building (straddling its base so the destination shows above it); `arriveAt` is the
/// traveler's road stop — Donald's BLUE mark projected onto the road, on the road, NOT under the
/// building. The seal and the stop are different places on purpose.
private struct Landmark: Identifiable {
    let subject: String     // matches a LudusWorld.subject
    let name: String        // the landmark's own name (the hero label)
    let symbol: String      // SF Symbol for the seal
    let x: CGFloat          // seal position: 0…1 across the image (centered under the building)
    let y: CGFloat          // seal position: 0…1 down the image (at the building's base)
    let arriveAt: CGFloat   // 0…1 arc-length road position of the traveler's stop (his blue mark)
    var labelDX: CGFloat = 0 // nudge the nameplate horizontally so edge seals don't clip off-screen
    var id: String { subject }
    var world: LudusWorld? { ludusWorlds.first { $0.subject == subject } }
}

// Re-pinned Sep 2026 to the second painted province (724 × 2172), traced from Donald's red/blue
// markup. Ordered top→bottom. Seal (x,y) is centered UNDER the building so the destination stays
// visible above it; arriveAt is his BLUE traveler-stop mark projected onto the road (that's where
// the "you are here" token rests, on the road, not under the building).
private let landmarks: [Landmark] = [
    .init(subject: "Math",                name: "The Temple",     symbol: "building.columns.fill", x: 0.36,  y: 0.1480, arriveAt: 0.0791),
    .init(subject: "Geography",           name: "The Lighthouse", symbol: "globe",                 x: 0.805, y: 0.2058, arriveAt: 0.1776),
    .init(subject: "History",             name: "The Forum",      symbol: "building.columns",      x: 0.30,  y: 0.2444, arriveAt: 0.2028),
    .init(subject: "Science",             name: "Mount Vesuvius", symbol: "flame.fill",            x: 0.34,  y: 0.3409, arriveAt: 0.3632),
    .init(subject: "Logic & Puzzles",     name: "The Colosseum",  symbol: "puzzlepiece.fill",      x: 0.35,  y: 0.4662, arriveAt: 0.4999),
    .init(subject: "Language Arts",       name: "The Library",    symbol: "book.fill",             x: 0.40,  y: 0.5482, arriveAt: 0.5991),
    .init(subject: "Money & Life Skills", name: "The Market",     symbol: "dollarsign",            x: 0.40,  y: 0.6495, arriveAt: 0.7025),
    .init(subject: "Music",               name: "The Theatre",    symbol: "music.note",            x: 0.38,  y: 0.7459, arriveAt: 0.8369),
]

// The painted map's pixel aspect. Extended with +40px parchment top & bottom → 724 × 2252.
private let mapAspect: CGFloat = 2252.0 / 724.0

// Seal (x,y) is now pinned to the building center, so no extra drop is needed.
private let markerDrop: CGFloat = 0

// The invisible road — traced from Donald's hand-drawn RED line (skeletonized + walked as an ordered
// path), normalized, dense (100 pts) so the traveler hugs every wind instead of cutting across.
// Re-trace via scratchpad/trace_road.py when the map art changes.
private let roadPoints: [CGPoint] = [
    .init(x: 0.5028, y: 0.0884), .init(x: 0.524, y: 0.0953), .init(x: 0.5442, y: 0.1024), .init(x: 0.5514, y: 0.1095),
    .init(x: 0.5421, y: 0.1166), .init(x: 0.5259, y: 0.1244), .init(x: 0.5146, y: 0.1332), .init(x: 0.5026, y: 0.1416),
    .init(x: 0.484, y: 0.1484), .init(x: 0.4679, y: 0.155), .init(x: 0.4679, y: 0.1623), .init(x: 0.4755, y: 0.171),
    .init(x: 0.4764, y: 0.1793), .init(x: 0.4681, y: 0.1885), .init(x: 0.4663, y: 0.1971), .init(x: 0.4778, y: 0.2054),
    .init(x: 0.4989, y: 0.213), .init(x: 0.5205, y: 0.2205), .init(x: 0.5326, y: 0.2285), .init(x: 0.5311, y: 0.2369),
    .init(x: 0.5146, y: 0.2443), .init(x: 0.4971, y: 0.2516), .init(x: 0.491, y: 0.2587), .init(x: 0.5022, y: 0.2658),
    .init(x: 0.5227, y: 0.2729), .init(x: 0.5409, y: 0.2804), .init(x: 0.5459, y: 0.2891), .init(x: 0.5361, y: 0.2969),
    .init(x: 0.5148, y: 0.3038), .init(x: 0.498, y: 0.3103), .init(x: 0.498, y: 0.3171), .init(x: 0.5119, y: 0.3245),
    .init(x: 0.5296, y: 0.3324), .init(x: 0.5405, y: 0.3415), .init(x: 0.5437, y: 0.3512), .init(x: 0.5364, y: 0.3602),
    .init(x: 0.518, y: 0.3666), .init(x: 0.495, y: 0.3722), .init(x: 0.4793, y: 0.3787), .init(x: 0.4803, y: 0.3868),
    .init(x: 0.4955, y: 0.395), .init(x: 0.5181, y: 0.4024), .init(x: 0.5416, y: 0.4096), .init(x: 0.5637, y: 0.4172),
    .init(x: 0.5797, y: 0.4255), .init(x: 0.5852, y: 0.4347), .init(x: 0.5793, y: 0.444), .init(x: 0.5638, y: 0.4522),
    .init(x: 0.5426, y: 0.4592), .init(x: 0.5179, y: 0.4654), .init(x: 0.4985, y: 0.4719), .init(x: 0.4939, y: 0.4791),
    .init(x: 0.5047, y: 0.4869), .init(x: 0.5247, y: 0.4947), .init(x: 0.5408, y: 0.503), .init(x: 0.5528, y: 0.512),
    .init(x: 0.5599, y: 0.5215), .init(x: 0.5641, y: 0.5313), .init(x: 0.5588, y: 0.5404), .init(x: 0.5429, y: 0.5479),
    .init(x: 0.5219, y: 0.5546), .init(x: 0.5113, y: 0.5615), .init(x: 0.5175, y: 0.5692), .init(x: 0.5344, y: 0.5773),
    .init(x: 0.5451, y: 0.5857), .init(x: 0.5441, y: 0.5948), .init(x: 0.5315, y: 0.6036), .init(x: 0.5139, y: 0.6117),
    .init(x: 0.4974, y: 0.6198), .init(x: 0.4898, y: 0.6284), .init(x: 0.4931, y: 0.6376), .init(x: 0.5038, y: 0.6468),
    .init(x: 0.5089, y: 0.6559), .init(x: 0.5037, y: 0.6645), .init(x: 0.4875, y: 0.6729), .init(x: 0.473, y: 0.6814),
    .init(x: 0.4699, y: 0.6902), .init(x: 0.4812, y: 0.6986), .init(x: 0.5006, y: 0.7063), .init(x: 0.5203, y: 0.714),
    .init(x: 0.5355, y: 0.7225), .init(x: 0.5416, y: 0.7316), .init(x: 0.5344, y: 0.7396), .init(x: 0.52, y: 0.7467),
    .init(x: 0.5128, y: 0.7537), .init(x: 0.5156, y: 0.762), .init(x: 0.5194, y: 0.7713), .init(x: 0.5118, y: 0.7805),
    .init(x: 0.4952, y: 0.7887), .init(x: 0.4769, y: 0.7966), .init(x: 0.4653, y: 0.8052), .init(x: 0.4655, y: 0.8143),
    .init(x: 0.4749, y: 0.8235), .init(x: 0.4893, y: 0.8321), .init(x: 0.4994, y: 0.8411), .init(x: 0.5002, y: 0.8502),
    .init(x: 0.4909, y: 0.8593), .init(x: 0.4805, y: 0.8683), .init(x: 0.4774, y: 0.8776), .init(x: 0.482, y: 0.8872),
]
private let ludusRoad = RoadPath(roadPoints, aspect: mapAspect)

private func clampCG(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { max(lo, min(hi, v)) }

/// Soft resistance past the scroll bounds (rubber-banding), like a native scroll view.
private func rubberCG(_ x: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    if x > hi { return hi + (x - hi) * 0.35 }
    if x < lo { return lo + (x - lo) * 0.35 }
    return x
}

struct HomeView: View {
    @AppStorage(LudusStore.denariiKey) private var denarii = 0
    @AppStorage("ludus_last_world") private var lastSubject = ""

    @State private var navPath: [LudusWorld] = []
    @State private var travelerT: CGFloat = 0        // arc-length position on the road
    @State private var manualCamY: CGFloat = 0       // vertical camera offset (≤ 0); updated live while dragging
    @State private var dragging = false
    @State private var dragStartCam: CGFloat = 0     // camera offset at the start of a drag
    @State private var selected: Landmark?
    @State private var isTraveling = false
    @State private var showCard = false
    @State private var faceLeft = false
    @State private var travelSeq = 0
    @State private var didInit = false
    @State private var canvas: CGSize = .zero        // latest viewport size (for travel math)

    // Floating chrome the camera must keep the traveler clear of.
    private let topInset: CGFloat = 150
    private let cardBand: CGFloat = 280   // reserved bottom band (card + legend) used for framing
    private let travelPad: CGFloat = 56   // tiny over-scroll so the bottom node clears the card
    private let bottomPad: CGFloat = 80   // = legend-bar height, so max scroll stops with the map's
                                          // bottom edge at the legend top (no parchment gap below)
    private let topPad: CGFloat = 150     // parchment margin above the map top, so the painting rests
                                          // below the LVDVS banner and top landmarks clear it

    var body: some View {
        NavigationStack(path: $navPath) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = w * mapAspect
                // The map bleeds edge-to-edge over the FULL physical screen (under the status bar and
                // behind the legend). The safe-area GeometryReader can't report that height, so use the
                // screen's own height directly. Chrome (banner + legend) stays in the safe area.
                let vh = UIScreen.main.bounds.height
                let minIdle = min(0, vh - h - bottomPad)     // free-scroll bottom bound
                let minTravel = min(0, vh - h - travelPad)   // travel/card over-scroll
                let off = (isTraveling || showCard)
                    ? clampCG(manualCamY, minTravel, topPad)
                    : manualCamY
                ZStack(alignment: .top) {
                    topBanner
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        if showCard, let lm = selected, let world = lm.world {
                            DestinationCard(landmark: lm, world: world,
                                            onPlay: { navPath.append(world) },
                                            onClose: { dismissCard() })
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        legendBar
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(alignment: .top) {
                    ZStack(alignment: .top) {
                        ParchmentBackground()
                        mapLayer(w: w, h: h)
                            .offset(y: off)
                            .frame(width: w, height: vh, alignment: .top)
                            .clipped()
                            .contentShape(Rectangle())
                            .gesture(panGesture(minIdle: minIdle))
                    }
                    .ignoresSafeArea()
                }
                .onAppear { setup(CGSize(width: w, height: vh)) }
                .onChange(of: geo.size) { _ in setup(CGSize(width: w, height: vh)) }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: LudusWorld.self) { WorldView(world: $0) }
        }
        .tint(Prov.red)
    }

    // The scrolling world: painted map, the eight seals on their road stops, and the traveler.
    private func mapLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Clean base = the painting with the ships removed + water restored; the ambient layer
            // re-adds the real ship cutouts (rocking) and a drifting cloud haze over the art.
            Image("ProvinceBase").resizable().frame(width: w, height: h)
            AmbientMap(w: w, h: h, paused: !navPath.isEmpty)
            ForEach(landmarks) { lm in
                if let world = lm.world {
                    Button { travel(to: lm) } label: {
                        LandmarkSeal(name: lm.name, subject: world.subject, symbol: lm.symbol,
                                     colorHex: world.colorHex, highlighted: selected?.id == lm.id,
                                     labelDX: lm.labelDX)
                    }
                    .buttonStyle(.plain)
                    // Seal sits on the building; the traveler stops on the road nearby (arriveAt).
                    .position(x: lm.x * w, y: lm.y * h)
                    .offset(y: markerDrop)
                }
            }
            Traveler(walking: isTraveling, faceLeft: faceLeft)
                .modifier(AlongRoad(t: travelerT, road: ludusRoad, w: w, h: h, dx: 26, dy: -16))
        }
        .frame(width: w, height: h, alignment: .top)
    }

    // MARK: Travel

    /// GO THERE: walk the traveler along the road to the landmark's stop, panning the camera on the
    /// SAME timeline, then open its parchment card on arrival.
    private func travel(to lm: Landmark) {
        guard let world = lm.world, canvas.width > 0 else { return }
        let w = canvas.width, h = w * mapAspect, vh = canvas.height
        let desiredY = topInset + (vh - topInset - cardBand) / 2
        let minCam = min(0, vh - h - travelPad)

        Haptics.tap()
        if showCard { withAnimation(.easeIn(duration: 0.15)) { showCard = false } }
        // Set selection WITHOUT animation: any animated transaction on `selected` gets applied to the
        // selected seal's position too (it's in the same update as the pan), making it jump ahead of
        // the scroll. Instant highlight pop is fine; only the pan should animate.
        selected = lm

        let target = lm.arriveAt
        faceLeft = ludusRoad.point(at: target).x < ludusRoad.point(at: travelerT).x
        let dist = abs(target - travelerT)
        let dur = Double(0.5 + 2.0 * dist)
        let camTarget = clampCG(desiredY - ludusRoad.point(at: target).y * h, minCam, topPad)

        travelSeq += 1
        let seq = travelSeq
        isTraveling = true
        withAnimation(.easeInOut(duration: dur)) {
            travelerT = target
            manualCamY = camTarget
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + dur) {
            guard seq == travelSeq else { return }   // superseded by a later tap
            isTraveling = false
            lastSubject = world.subject
            Haptics.light()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { showCard = true }
        }
    }

    private func dismissCard() {
        withAnimation(.easeIn(duration: 0.2)) { showCard = false }
        selected = nil
        // If we were parked in the travel-only pad zone (last node), settle back into free-scroll bounds.
        let minIdle = min(0, canvas.height - canvas.width * mapAspect - bottomPad)
        if manualCamY < minIdle {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { manualCamY = minIdle }
        }
    }

    /// Free vertical exploration when not traveling. Drives manualCamY DIRECTLY (not via @GestureState)
    /// so lifting a finger can't snap the map back a frame before the fling — rubber-banded, spring fling.
    private func panGesture(minIdle: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                guard !isTraveling, !showCard else { return }
                if !dragging { dragging = true; dragStartCam = manualCamY }
                manualCamY = rubberCG(dragStartCam + v.translation.height, minIdle, topPad)
            }
            .onEnded { v in
                guard !isTraveling, !showCard else { return }
                dragging = false
                let end = clampCG(dragStartCam + v.predictedEndTranslation.height, minIdle, topPad)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { manualCamY = end }
            }
    }

    /// Track the viewport size and, once it's valid, run one-time setup: stand the traveler where
    /// the child last was and frame that place. (GeometryReader reports .zero at first onAppear, so
    /// this must also run from onChange when the real size arrives.)
    private func setup(_ size: CGSize) {
        canvas = size
        guard !didInit, size.width > 0 else { return }
        didInit = true
        let w = size.width, h = w * mapAspect, vh = size.height
        let desiredY = topInset + (vh - topInset - cardBand) / 2
        let minIdle = min(0, vh - h - bottomPad)
        // Stand where the child last was; on a first-ever launch, start at the first landmark so the
        // painting opens framed below the banner (on its parchment margin), not scrolled to the void.
        let lm = landmarks.first(where: { $0.subject == lastSubject }) ?? landmarks.first!
        travelerT = lm.arriveAt
        manualCamY = clampCG(desiredY - ludusRoad.point(at: lm.arriveAt).y * h, minIdle, topPad)
    }

    // MARK: Chrome

    // The LVDVS cartouche, floating on a red scrim that also darkens the status-bar area.
    private var topBanner: some View {
        LaurelFrame(color: 0xe6c15f, size: 20, spacing: 9) {
            VStack(spacing: 1) {
                Text("LVDVS").font(luSerif(30, .black)).tracking(4)
                    .foregroundStyle(LinearGradient(colors: [.white, Prov.cream, Prov.gold],
                                                    startPoint: .top, endPoint: .bottom))
                Text("Disce Ludendo").font(luSerif(9, .bold)).textCase(.uppercase).tracking(3)
                    .foregroundStyle(Prov.inkDim)
            }
        }
        .padding(.vertical, 9).padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: [Prov.red, Prov.redDeep], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Prov.gold, lineWidth: 1.5))
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 3)
        )
        .padding(.top, 6)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Prov.redDeep.opacity(0.9), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 150).ignoresSafeArea(edges: .top),
            alignment: .top
        )
    }

    // Rank + coinage, styled as a map legend along the foot.
    private var legendBar: some View {
        HStack(spacing: 6) {
            legendStat(emoji: "🥈", value: "\(denarii)", label: "DENARII")
            Rectangle().fill(Prov.gold.opacity(0.4)).frame(width: 1, height: 30)
            LaurelFrame(color: 0xe6c15f, size: 16, spacing: 5) {
                VStack(spacing: 0) {
                    Text(ludusRank(forDenarii: denarii)).font(luSerif(16, .black))
                        .textCase(.uppercase).tracking(1).foregroundStyle(Prov.goldHi)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text("RANK").font(luFont(7.5, .heavy)).tracking(1.5).foregroundStyle(Prov.inkDim)
                }
            }
            Rectangle().fill(Prov.gold.opacity(0.4)).frame(width: 1, height: 30)
            legendStat(emoji: "🥇", value: "\(denarii / 25)", label: "AVREI")
        }
        .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Prov.red, Prov.redDeep], startPoint: .top, endPoint: .bottom)
                .overlay(Rectangle().fill(Prov.gold).frame(height: 2), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func legendStat(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(emoji).font(.system(size: 13))
                Text(value).font(luSerif(16, .black)).monospacedDigit().foregroundStyle(Prov.cream)
            }
            Text(label).font(luFont(7.5, .heavy)).tracking(1.5).foregroundStyle(Prov.inkDim)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - A landmark seal: coloured wax disc + emblem, with a quiet nameplate

private struct LandmarkSeal: View {
    let name: String
    let subject: String
    let symbol: String
    let colorHex: UInt
    var highlighted: Bool = false
    var labelDX: CGFloat = 0

    var body: some View {
        // The DISC is the anchored element — `.position` in the map centers it on the building.
        // The nameplate is an overlay that hangs below WITHOUT enlarging the layout footprint, so
        // its width/height never shift where the disc lands.
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [luShade(colorHex, 46), Color(hex: colorHex)],
                                     center: UnitPoint(x: 0.38, y: 0.32), startRadius: 1, endRadius: 24))
                .overlay(Circle().stroke(Prov.cream, lineWidth: 2))
                .overlay(Circle().stroke(luShade(colorHex, -60), lineWidth: 0.5).padding(4))
                .shadow(color: .black.opacity(0.45), radius: 4, x: 0, y: 3)
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 38, height: 38)
        .overlay(
            Circle().stroke(Prov.goldHi, lineWidth: 3)
                .frame(width: 46, height: 46)
                .opacity(highlighted ? 1 : 0)
        )
        // Selection changes ONLY this ring's opacity — never any geometry (no scale, no size).
        // A geometry change tied to `selected` gets animated by the tap's ambient transaction on
        // its own timeline, making the selected seal slide ahead of the map pan. Opacity is safe.
        .overlay(alignment: .top) {
            VStack(spacing: 1) {
                Text(name).font(luSerif(11, .black)).foregroundStyle(Prov.plateInk)
                Text(subject.uppercased()).font(luFont(6.5, .heavy)).tracking(0.9)
                    .foregroundStyle(luShade(colorHex, -60))
            }
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(LinearGradient(colors: [luShade(0xf4ebd2, 12), luShade(0xf4ebd2, -14)],
                                         startPoint: .top, endPoint: .bottom).opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(luShade(0xc99a3a, 20).opacity(0.7), lineWidth: 0.8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(luShade(0xc99a3a, -30).opacity(0.35), lineWidth: 0.5)
                            .padding(1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2.5, x: 0, y: 1.5)
            )
            .fixedSize()
            // Hidden by default so the map art breathes — only the tapped (selected) landmark
            // reveals its name, and it stays through the walk until the card is dismissed. Opacity
            // + a small rise/scale are safe (overlay never affects where the disc lands).
            .opacity(highlighted ? 1 : 0)
            .scaleEffect(highlighted ? 1 : 0.9, anchor: .top)
            .offset(x: labelDX, y: highlighted ? 44 : 38)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: highlighted)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - The parchment destination card shown on arrival

private struct DestinationCard: View {
    let landmark: Landmark
    let world: LudusWorld
    let onPlay: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [luShade(world.colorHex, 46), Color(hex: world.colorHex)],
                                             center: UnitPoint(x: 0.38, y: 0.32), startRadius: 1, endRadius: 30))
                        .overlay(Circle().stroke(Prov.cream, lineWidth: 2))
                        .overlay(Circle().stroke(luShade(world.colorHex, -60), lineWidth: 0.5).padding(3))
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    Image(systemName: landmark.symbol)
                        .font(.system(size: 22, weight: .black)).foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(world.subject.uppercased()).font(luFont(10, .heavy)).tracking(1.6)
                        .foregroundStyle(luShade(world.colorHex, -55))
                    Text(landmark.name).font(luSerif(23, .black)).foregroundStyle(Prov.plateInk)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text("\(world.playableCount) game\(world.playableCount == 1 ? "" : "s")")
                        .font(luFont(11, .semibold)).foregroundStyle(Prov.plateInk.opacity(0.55))
                }
                Spacer(minLength: 4)
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Prov.plateInk.opacity(0.55))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle().fill(luShade(0xf4ebd2, -12))
                                .overlay(Circle().strokeBorder(Prov.gold.opacity(0.4), lineWidth: 0.8))
                        )
                }
                .buttonStyle(.plain)
            }
            // Thin gold rule separating header from the primary action.
            LinearGradient(colors: [Prov.gold.opacity(0), luShade(0xc99a3a, 15).opacity(0.7), Prov.gold.opacity(0)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
            LudusButton(title: "Play", fullWidth: true, action: onPlay)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [luShade(0xf4ebd2, 10), luShade(0xf4ebd2, -12)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(luShade(0xc99a3a, 15).opacity(0.7), lineWidth: 1.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(luShade(0xc99a3a, -30).opacity(0.3), lineWidth: 0.75)
                        .padding(4)
                )
                .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 6)
        )
        .padding(.horizontal, 16).padding(.bottom, 8)
    }
}
