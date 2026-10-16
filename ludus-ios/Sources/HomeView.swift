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
// The road (Donald's RED line), each landmark's seal (his BLUE marks) and each traveler stop (his
// GREEN marks) are traced from his markup of the art. Every stop is a VERTEX of the road, so the chip
// walks the red line and rests exactly on the green mark — nothing is projected or estimated. The
// camera is a manual vertical offset (`manualCamY`) driven by the SAME animation that walks the
// chip, so the two never fight. Free exploration is a drag pan.
//
// Re-tuning for new art: mark up the art (red road, blue seals, green stops), run
// `tools/map_trace.py CLEAN.png MARKED.png`, and paste its `roadXY` + seal/stop values. Nothing else
// moves. Validate with a LUDUS_TOUR=all screen recording (see `startDebugTour`).

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

/// A world on the map. Two DISTINCT authored places (do not conflate): the seal `x,y` is his BLUE
/// mark on the building; `stop` is the road vertex at his GREEN mark, where the traveler rests.
private struct Landmark: Identifiable {
    let subject: String     // matches a LudusWorld.subject
    let name: String        // the landmark's own name (the hero label)
    let symbol: String      // SF Symbol for the seal
    let x: CGFloat          // seal center: 0…1 across the image (blue mark)
    let y: CGFloat          // seal center: 0…1 down the image (blue mark)
    let stop: Int           // index into `roadXY` points of the traveler's rest (green mark)
    var labelDX: CGFloat = 0 // nudge the nameplate sideways where the resting chip would cover it
    var id: String { subject }
    var world: LudusWorld? { ludusWorlds.first { $0.subject == subject } }
    var arriveAt: CGFloat { ludusRoad.t(atVertex: stop) }
}

// Mediterranean map (Oct 2026), ordered top→bottom along the road.
private let landmarks: [Landmark] = [
    .init(subject: "Language Arts",       name: "The Library",    symbol: "book.fill",             x: 0.5683, y: 0.1459, stop: 11, labelDX: 32),
    .init(subject: "History",             name: "The Forum",      symbol: "building.columns",      x: 0.2754, y: 0.2641, stop: 79),
    .init(subject: "Science",             name: "Mount Vesuvius", symbol: "flame.fill",            x: 0.6700, y: 0.3257, stop: 124),
    .init(subject: "Logic & Puzzles",     name: "The Colosseum",  symbol: "puzzlepiece.fill",      x: 0.2785, y: 0.4108, stop: 164),
    .init(subject: "Math",                name: "The Temple",     symbol: "building.columns.fill", x: 0.5005, y: 0.4848, stop: 211),
    .init(subject: "Money & Life Skills", name: "The Market",     symbol: "dollarsign",            x: 0.7406, y: 0.5696, stop: 269),
    .init(subject: "Geography",           name: "The Lighthouse", symbol: "globe",                 x: 0.2583, y: 0.6449, stop: 289),
    .init(subject: "Music",               name: "The Theatre",    symbol: "music.note",            x: 0.7019, y: 0.7927, stop: 334),
]

// The painted map's pixel aspect (724 × 2172, parchment border baked into the art).
private let mapAspect: CGFloat = 2172.0 / 724.0

// The road: the centerline of Donald's RED line, detouring to each GREEN center along a path that
// stays inside the drawn ink (simplified to ≤0.35 px). Normalized x, y pairs, top→bottom.
private let roadXY: [CGFloat] = [
    0.56354, 0.15562, 0.55816, 0.15705, 0.54714, 0.16198, 0.53938, 0.16459, 0.53522, 0.16568, 0.52919, 0.16639,
    0.52263, 0.16667, 0.50744, 0.16667, 0.50357, 0.16644, 0.50023, 0.16580, 0.48841, 0.16198, 0.48606, 0.16163,
    0.48851, 0.16243, 0.49030, 0.16426, 0.49023, 0.16976, 0.48760, 0.17170, 0.48080, 0.17399, 0.47527, 0.17509,
    0.46527, 0.17594, 0.44687, 0.17663, 0.43659, 0.17762, 0.43219, 0.17872, 0.42966, 0.17981, 0.42711, 0.18242,
    0.42776, 0.18377, 0.43002, 0.18491, 0.43706, 0.18635, 0.45192, 0.19046, 0.45939, 0.19164, 0.47253, 0.19302,
    0.47710, 0.19403, 0.48055, 0.19546, 0.48293, 0.19761, 0.48296, 0.19852, 0.48092, 0.19971, 0.47653, 0.20081,
    0.47136, 0.20145, 0.42785, 0.20389, 0.42234, 0.20399, 0.40616, 0.20516, 0.37206, 0.21015, 0.36146, 0.21117,
    0.33839, 0.21245, 0.33480, 0.21312, 0.32978, 0.21469, 0.32748, 0.21582, 0.32728, 0.21672, 0.33083, 0.21919,
    0.33517, 0.22029, 0.34866, 0.22122, 0.35886, 0.22262, 0.36690, 0.22326, 0.38347, 0.22330, 0.38890, 0.22362,
    0.39287, 0.22403, 0.40759, 0.22654, 0.41956, 0.22760, 0.43604, 0.22996, 0.44786, 0.23124, 0.47503, 0.23277,
    0.49078, 0.23447, 0.51380, 0.23600, 0.52150, 0.23703, 0.52714, 0.23833, 0.53010, 0.23987, 0.53039, 0.24446,
    0.52958, 0.24582, 0.52741, 0.24751, 0.52490, 0.24860, 0.51806, 0.25088, 0.51243, 0.25221, 0.49715, 0.25433,
    0.47368, 0.25701, 0.46238, 0.25872, 0.44508, 0.26216, 0.43990, 0.26243, 0.42059, 0.26241, 0.40897, 0.26175,
    0.40059, 0.26071, 0.39515, 0.26055, 0.39235, 0.26065, 0.38899, 0.26129, 0.37233, 0.26677, 0.36708, 0.26811,
    0.34917, 0.27037, 0.34308, 0.27147, 0.33820, 0.27322, 0.33623, 0.27442, 0.33564, 0.27670, 0.33646, 0.27804,
    0.33886, 0.27916, 0.34960, 0.28274, 0.35502, 0.28415, 0.38397, 0.28713, 0.40587, 0.28994, 0.41727, 0.29157,
    0.44423, 0.29621, 0.44959, 0.29765, 0.45319, 0.29904, 0.45559, 0.30167, 0.45570, 0.30351, 0.45388, 0.30522,
    0.44995, 0.30650, 0.42077, 0.31170, 0.40761, 0.31505, 0.38474, 0.32019, 0.37311, 0.32474, 0.37014, 0.32629,
    0.36798, 0.32894, 0.36906, 0.33071, 0.37134, 0.33186, 0.37589, 0.33289, 0.38244, 0.33360, 0.39065, 0.33387,
    0.40401, 0.33500, 0.41883, 0.33834, 0.43190, 0.33966, 0.45381, 0.33981, 0.46015, 0.34026, 0.47052, 0.34192,
    0.48552, 0.34208, 0.49179, 0.34157, 0.50071, 0.33986, 0.50564, 0.33938, 0.50844, 0.33938, 0.49364, 0.34420,
    0.49058, 0.34608, 0.49033, 0.34835, 0.49101, 0.34964, 0.49555, 0.35223, 0.49921, 0.35541, 0.50560, 0.35774,
    0.50997, 0.35867, 0.52386, 0.36002, 0.53504, 0.36272, 0.54361, 0.36419, 0.56301, 0.36659, 0.58799, 0.36920,
    0.59629, 0.37083, 0.60972, 0.37405, 0.61583, 0.37652, 0.61701, 0.37784, 0.61695, 0.37875, 0.61624, 0.37964,
    0.60922, 0.38412, 0.60298, 0.38923, 0.59931, 0.39117, 0.59376, 0.39322, 0.58943, 0.39436, 0.57864, 0.39641,
    0.54546, 0.40094, 0.53061, 0.40338, 0.52035, 0.40474, 0.50320, 0.40648, 0.46871, 0.41117, 0.46685, 0.41114,
    0.46479, 0.41171, 0.45414, 0.41314, 0.43303, 0.41727, 0.42790, 0.41759, 0.41417, 0.41752, 0.40950, 0.41683,
    0.40239, 0.41477, 0.39877, 0.41440, 0.39508, 0.41440, 0.40577, 0.41795, 0.40836, 0.41943, 0.40884, 0.42351,
    0.40754, 0.42655, 0.40746, 0.42884, 0.40806, 0.43014, 0.40992, 0.43126, 0.41571, 0.43322, 0.41894, 0.43396,
    0.43195, 0.43561, 0.45137, 0.43974, 0.46316, 0.44101, 0.49051, 0.44202, 0.50663, 0.44326, 0.51615, 0.44379,
    0.52303, 0.44389, 0.54883, 0.44543, 0.57439, 0.44887, 0.58620, 0.45013, 0.62022, 0.45194, 0.64267, 0.45416,
    0.65212, 0.45483, 0.66171, 0.45663, 0.67339, 0.45802, 0.68668, 0.46043, 0.69716, 0.46158, 0.71340, 0.46262,
    0.73371, 0.46551, 0.75583, 0.46809, 0.76056, 0.46902, 0.76428, 0.47038, 0.77184, 0.47423, 0.77360, 0.47547,
    0.77431, 0.47683, 0.77386, 0.47819, 0.77180, 0.47990, 0.76487, 0.48333, 0.76068, 0.48451, 0.73995, 0.48816,
    0.73226, 0.48919, 0.72435, 0.48998, 0.72238, 0.48987, 0.69677, 0.49261, 0.68716, 0.49261, 0.68082, 0.49216,
    0.66701, 0.48993, 0.65906, 0.48767, 0.65864, 0.48846, 0.65591, 0.48993, 0.63735, 0.49611, 0.63193, 0.49731,
    0.61142, 0.49859, 0.58864, 0.49909, 0.57773, 0.49961, 0.53454, 0.50260, 0.51390, 0.50522, 0.46882, 0.50945,
    0.44466, 0.51136, 0.40453, 0.51629, 0.38577, 0.51781, 0.38162, 0.51899, 0.37749, 0.52188, 0.37722, 0.52509,
    0.38182, 0.52842, 0.38619, 0.53020, 0.39901, 0.53439, 0.40259, 0.53507, 0.41993, 0.53658, 0.43797, 0.53885,
    0.45566, 0.53978, 0.46689, 0.54153, 0.48634, 0.54387, 0.49232, 0.54501, 0.49839, 0.54689, 0.50144, 0.54842,
    0.50356, 0.55060, 0.50414, 0.55196, 0.50363, 0.55563, 0.50251, 0.55646, 0.49900, 0.55788, 0.48383, 0.56186,
    0.47128, 0.56613, 0.46342, 0.56799, 0.44900, 0.57070, 0.43172, 0.57530, 0.42504, 0.57762, 0.42057, 0.58046,
    0.41861, 0.58362, 0.41991, 0.58587, 0.42262, 0.58746, 0.42679, 0.58866, 0.43040, 0.58934, 0.43948, 0.59043,
    0.45555, 0.59168, 0.47496, 0.59518, 0.48992, 0.59752, 0.49171, 0.59761, 0.50166, 0.60072, 0.50742, 0.60164,
    0.52068, 0.60208, 0.53325, 0.60309, 0.55114, 0.60313, 0.55615, 0.60271, 0.56688, 0.60096, 0.56947, 0.60095,
    0.56711, 0.60148, 0.55168, 0.60672, 0.55009, 0.60788, 0.54953, 0.61010, 0.54819, 0.61130, 0.53766, 0.61481,
    0.50162, 0.62232, 0.47411, 0.62658, 0.44530, 0.63202, 0.42300, 0.63566, 0.41721, 0.63690, 0.40785, 0.63961,
    0.40540, 0.64126, 0.40331, 0.64411, 0.40345, 0.64869, 0.40510, 0.65077, 0.41452, 0.65499, 0.41766, 0.65686,
    0.41851, 0.65858, 0.41886, 0.66549, 0.42127, 0.66529, 0.44199, 0.66529, 0.44588, 0.66549, 0.46003, 0.66744,
    0.47526, 0.66852, 0.47995, 0.66919, 0.48546, 0.67043, 0.50671, 0.67629, 0.51257, 0.67825, 0.52605, 0.68407,
    0.53375, 0.68671, 0.54531, 0.69187, 0.56174, 0.69746, 0.57645, 0.70412, 0.59858, 0.71036, 0.62149, 0.71547,
    0.62833, 0.71775, 0.63786, 0.72169, 0.64257, 0.72448, 0.64365, 0.72628, 0.64420, 0.73041, 0.64353, 0.73315,
    0.64263, 0.73449, 0.64062, 0.73570, 0.63553, 0.73723, 0.61540, 0.74124, 0.59592, 0.74357, 0.56530, 0.74884,
    0.50161, 0.75769, 0.48875, 0.76038, 0.46749, 0.76548, 0.45981, 0.76813, 0.45524, 0.77095, 0.45304, 0.77594,
    0.45566, 0.78138, 0.45747, 0.78312, 0.46472, 0.78703, 0.46863, 0.78997, 0.47458, 0.79249, 0.49698, 0.79699,
    0.51845, 0.79971, 0.53461, 0.80226, 0.53849, 0.80248, 0.56058, 0.80249, 0.56836, 0.80169, 0.56768, 0.80249,
    0.56821, 0.80471, 0.57367, 0.81041, 0.57746, 0.81219, 0.58819, 0.81577, 0.59072, 0.81726, 0.59070, 0.82261,
    0.58765, 0.82432, 0.58045, 0.82645, 0.51808, 0.83919, 0.50134, 0.84133, 0.48125, 0.84293, 0.47422, 0.84436,
    0.47024, 0.84620, 0.46986, 0.84756, 0.47206, 0.85163, 0.47614, 0.85650, 0.48380, 0.86388, 0.48887, 0.87151,
    0.48890, 0.87657, 0.48785, 0.87838, 0.48427, 0.88136, 0.48043, 0.88327, 0.46734, 0.88860, 0.44835, 0.89317,
    0.43666, 0.89456, 0.42424, 0.89655, 0.37337, 0.90234, 0.35620, 0.90527, 0.34850, 0.90629, 0.33260, 0.90778,
    0.31859, 0.90973, 0.30399, 0.91233, 0.29707, 0.91455, 0.29040, 0.91804, 0.28636, 0.92147, 0.28453, 0.92555,
]
private let roadPoints: [CGPoint] = stride(from: 0, to: roadXY.count, by: 2).map {
    CGPoint(x: roadXY[$0], y: roadXY[$0 + 1])
}
private let ludusRoad = RoadPath(roadPoints, aspect: mapAspect)

private func clampCG(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { max(lo, min(hi, v)) }

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
                                          // bottom edge at the legend top
    // The camera never scrolls past the map's top edge (offset ≤ 0) — the art's own parchment border
    // is the margin, so nothing but the painting is ever on screen.

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
                    ? clampCG(manualCamY, minTravel, 0)
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
            // Static art — no ambient layers (they idled at ~75% CPU). Light motion gets re-added selectively.
            Image("ProvinceMap").resizable().frame(width: w, height: h)
            ForEach(landmarks) { lm in
                if let world = lm.world {
                    Button { travel(to: lm) } label: {
                        LandmarkSeal(name: lm.name, subject: world.subject, symbol: lm.symbol,
                                     colorHex: world.colorHex, highlighted: selected?.id == lm.id,
                                     labelDX: lm.labelDX)
                    }
                    .buttonStyle(.plain)
                    // Seal on the building (blue mark); the traveler rests at the green mark (stop).
                    .position(x: lm.x * w, y: lm.y * h)
                }
            }
            // Chip CENTER sits on the road point — no stand offset, so it rests exactly on the green mark.
            Traveler(walking: isTraveling, faceLeft: faceLeft)
                .modifier(AlongRoad(t: travelerT, road: ludusRoad, w: w, h: h))
        }
        .frame(width: w, height: h, alignment: .top)
    }

    // MARK: Travel

    /// GO THERE: walk the traveler along the road to the landmark's stop, panning the camera on the
    /// SAME timeline, then open its parchment card on arrival.
    @discardableResult
    private func travel(to lm: Landmark) -> Double {
        guard let world = lm.world, canvas.width > 0 else { return 0 }
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
        let camTarget = clampCG(desiredY - ludusRoad.point(at: target).y * h, minCam, 0)

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
        return dur
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
    /// so lifting a finger can't snap the map back a frame before the fling. Hard-clamped to the map's
    /// edges (no rubber-band) so nothing behind the painting is ever revealed.
    private func panGesture(minIdle: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                guard !isTraveling, !showCard else { return }
                if !dragging { dragging = true; dragStartCam = manualCamY }
                manualCamY = clampCG(dragStartCam + v.translation.height, minIdle, 0)
            }
            .onEnded { v in
                guard !isTraveling, !showCard else { return }
                dragging = false
                let end = clampCG(dragStartCam + v.predictedEndTranslation.height, minIdle, 0)
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
        // Stand where the child last was; on a first-ever launch, start at the first landmark.
        let lm = landmarks.first(where: { $0.subject == lastSubject }) ?? landmarks.first!
        travelerT = lm.arriveAt
        manualCamY = clampCG(desiredY - ludusRoad.point(at: lm.arriveAt).y * h, minIdle, 0)
        #if DEBUG
        startDebugTour()
        #endif
    }

    #if DEBUG
    /// Validation hook: launch with env LUDUS_TOUR = comma-separated subjects (or "all" = every stop
    /// top→bottom then back up) and the traveler walks the route unattended, holding at each stop,
    /// so a screen recording can be checked against the traced road.
    private func startDebugTour() {
        guard let spec = ProcessInfo.processInfo.environment["LUDUS_TOUR"], !spec.isEmpty else { return }
        let stops: [Landmark] = spec == "all"
            ? landmarks + landmarks.reversed().dropFirst()
            : spec.split(separator: ",").compactMap { s in landmarks.first { $0.subject == s } }
        func step(_ i: Int) {
            guard i < stops.count else { return }
            let dur = travel(to: stops[i])
            DispatchQueue.main.asyncAfter(deadline: .now() + dur + 1.5) { step(i + 1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { step(0) }
    }
    #endif

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
