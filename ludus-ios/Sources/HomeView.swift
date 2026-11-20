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
// Re-tuning for new art: mark up the ORIGINAL art (red road, blue seals, green stops), run
//   tools/map_trace.py CLEAN.png MARKED.png --pad-top 100 --write-padded tools/art/province_original.png
// and paste its `roadXY` + seal/stop values. Then `tools/ambient_build.py` builds `ProvinceMap` (ships
// painted out) and the ambience assets (MapAmbience.swift). Nothing else moves. Validate with a
// LUDUS_TOUR=all screen recording (see `startDebugTour`).

enum Prov {
    static let red     = Color(hex: 0x9e2b25)
    static let ink     = Color(hex: 0x3a2412)   // scroll ink
    static let tint    = Color(hex: 0x6a1a16)   // the red wash behind the plaque (and its echo at the bar)
    static let coinInk = Color(hex: 0xfdf0d2)
    static let rule    = Color(hex: 0x9a7a3c)
}

/// The baked chrome's geometry (pt). Mirrors tools/chrome/chrome_build.py — change both together.
enum Chrome {
    static let barW: CGFloat = 440, barSide: CGFloat = 52, barTab: CGFloat = 76, barShadow: CGFloat = 8
    static let barWideW: CGFloat = 1000               // BottomBarWide: stages wider than a phone
    static let panel = CGSize(width: 420, height: 820), panelShadow: CGFloat = 12   // SidePanel (+ its shadow margin)
    static let plaque = CGSize(width: 262, height: 72)
    static let rank = CGSize(width: 220, height: 76)   // spans the whole tab; rank block centred in it
    static let coin: CGFloat = 25
    static let sealBox: CGFloat = 84                  // seal/ring/halo images are drawn in this square…
    static let mapSeal: CGFloat = 0.85, cardSeal: CGFloat = 1.06   // …shown at these scales
    static let cardW: CGFloat = 344, cardH: CGFloat = 150, cardRod: CGFloat = 13
    static let plateH: CGFloat = 40, plateRod: CGFloat = 5
    static let play = CGSize(width: 308, height: 54)  // PLAY plaque image incl. its 6-pt shadow margin
    static let standard = CGSize(width: 42, height: 62), standardFoot: CGFloat = 58, standardScale: CGFloat = 0.92
}

/// Darken a packed-hex colour by `pct` percent (matches the bake's `shade(c, -pct)`).
func waxInk(_ hex: UInt, _ pct: Double) -> Color {
    func ch(_ s: UInt) -> Double { Double((hex >> s) & 0xff) / 255 * (1 - pct / 100) }
    return Color(.sRGB, red: ch(16), green: ch(8), blue: ch(0))
}

/// A world on the map. Two DISTINCT authored places (do not conflate): the seal `x,y` is his BLUE
/// mark on the building; `stop` is the road vertex at his GREEN mark, where the traveler rests.
private struct Landmark: Identifiable {
    let subject: String     // matches a LudusWorld.subject
    let name: String        // the landmark's own name (the hero label)
    let key: String         // chrome asset key: Seal<key> (tools/chrome/chrome_build.py)
    let wax: UInt           // the seal's wax colour (also tints its subject label)
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
    .init(subject: "Language Arts",       name: "The Library",    key: "Library",    wax: 0x3f8a4a, x: 0.5683, y: 0.1835, stop: 11, labelDX: 32),
    .init(subject: "History",             name: "The Forum",      key: "Forum",      wax: 0x8a5a34, x: 0.2754, y: 0.2965, stop: 79),
    .init(subject: "Science",             name: "Mount Vesuvius", key: "Vesuvius",   wax: 0xc8642a, x: 0.6700, y: 0.3554, stop: 124),
    .init(subject: "Logic & Puzzles",     name: "The Colosseum",  key: "Colosseum",  wax: 0x7a4aa8, x: 0.2785, y: 0.4367, stop: 164),
    .init(subject: "Math",                name: "The Temple",     key: "Temple",     wax: 0xb8402e, x: 0.5005, y: 0.5075, stop: 211),
    .init(subject: "Money & Life Skills", name: "The Market",     key: "Market",     wax: 0x1f7a6a, x: 0.7406, y: 0.5886, stop: 269),
    .init(subject: "Geography",           name: "The Lighthouse", key: "Lighthouse", wax: 0x2f7fae, x: 0.2583, y: 0.6605, stop: 289),
    .init(subject: "Music",               name: "The Theatre",    key: "Theatre",    wax: 0xa63a6a, x: 0.7019, y: 0.8018, stop: 334),
]

// The painted map's pixel aspect: 724 × 2272 — the 2172-px art plus 100 px of extra top parchment
// (its torn top edge kept, then the parchment below it mirrored down) so the painting clears the banner.
private let mapAspect: CGFloat = 2272.0 / 724.0

// The road: the centerline of Donald's RED line, detouring to each GREEN center along a path that
// stays inside the drawn ink (simplified to ≤0.35 px). Normalized x, y pairs, top→bottom.
private let roadXY: [CGFloat] = [
    0.56354, 0.19278, 0.55816, 0.19415, 0.54714, 0.19886, 0.53938, 0.20136, 0.53522, 0.20240, 0.52919, 0.20308,
    0.52263, 0.20335, 0.50744, 0.20335, 0.50357, 0.20313, 0.50023, 0.20251, 0.48841, 0.19887, 0.48606, 0.19853,
    0.48851, 0.19930, 0.49030, 0.20104, 0.49023, 0.20631, 0.48760, 0.20816, 0.48080, 0.21034, 0.47527, 0.21140,
    0.46527, 0.21221, 0.44687, 0.21287, 0.43659, 0.21382, 0.43219, 0.21487, 0.42966, 0.21591, 0.42711, 0.21840,
    0.42776, 0.21970, 0.43002, 0.22079, 0.43706, 0.22216, 0.45192, 0.22610, 0.45939, 0.22722, 0.47253, 0.22854,
    0.47710, 0.22950, 0.48055, 0.23087, 0.48293, 0.23293, 0.48296, 0.23380, 0.48092, 0.23493, 0.47653, 0.23599,
    0.47136, 0.23660, 0.42785, 0.23893, 0.42234, 0.23903, 0.40616, 0.24015, 0.37206, 0.24492, 0.36146, 0.24589,
    0.33839, 0.24711, 0.33480, 0.24775, 0.32978, 0.24926, 0.32748, 0.25034, 0.32728, 0.25120, 0.33083, 0.25356,
    0.33517, 0.25461, 0.34866, 0.25550, 0.35886, 0.25683, 0.36690, 0.25745, 0.38347, 0.25748, 0.38890, 0.25780,
    0.39287, 0.25818, 0.40759, 0.26058, 0.41956, 0.26160, 0.43604, 0.26385, 0.44786, 0.26507, 0.47503, 0.26654,
    0.49078, 0.26816, 0.51380, 0.26963, 0.52150, 0.27061, 0.52714, 0.27185, 0.53010, 0.27332, 0.53039, 0.27772,
    0.52958, 0.27901, 0.52741, 0.28063, 0.52490, 0.28168, 0.51806, 0.28386, 0.51243, 0.28512, 0.49715, 0.28715,
    0.47368, 0.28971, 0.46238, 0.29135, 0.44508, 0.29463, 0.43990, 0.29489, 0.42059, 0.29487, 0.40897, 0.29424,
    0.40059, 0.29325, 0.39515, 0.29310, 0.39235, 0.29320, 0.38899, 0.29380, 0.37233, 0.29905, 0.36708, 0.30032,
    0.34917, 0.30248, 0.34308, 0.30353, 0.33820, 0.30521, 0.33623, 0.30636, 0.33564, 0.30854, 0.33646, 0.30982,
    0.33886, 0.31088, 0.34960, 0.31431, 0.35502, 0.31566, 0.38397, 0.31850, 0.40587, 0.32119, 0.41727, 0.32275,
    0.44423, 0.32719, 0.44959, 0.32857, 0.45319, 0.32990, 0.45559, 0.33241, 0.45570, 0.33416, 0.45388, 0.33580,
    0.44995, 0.33702, 0.42077, 0.34200, 0.40761, 0.34520, 0.38474, 0.35011, 0.37311, 0.35446, 0.37014, 0.35594,
    0.36798, 0.35847, 0.36906, 0.36017, 0.37134, 0.36127, 0.37589, 0.36225, 0.38244, 0.36293, 0.39065, 0.36319,
    0.40401, 0.36427, 0.41883, 0.36746, 0.43190, 0.36872, 0.45381, 0.36886, 0.46015, 0.36930, 0.47052, 0.37089,
    0.48552, 0.37104, 0.49179, 0.37055, 0.50071, 0.36891, 0.50564, 0.36846, 0.50844, 0.36846, 0.49364, 0.37307,
    0.49058, 0.37486, 0.49033, 0.37703, 0.49101, 0.37826, 0.49555, 0.38074, 0.49921, 0.38378, 0.50560, 0.38601,
    0.50997, 0.38690, 0.52386, 0.38819, 0.53504, 0.39077, 0.54361, 0.39218, 0.56301, 0.39447, 0.58799, 0.39696,
    0.59629, 0.39852, 0.60972, 0.40160, 0.61583, 0.40397, 0.61701, 0.40522, 0.61695, 0.40610, 0.61624, 0.40694,
    0.60922, 0.41123, 0.60298, 0.41611, 0.59931, 0.41797, 0.59376, 0.41993, 0.58943, 0.42102, 0.57864, 0.42297,
    0.54546, 0.42730, 0.53061, 0.42964, 0.52035, 0.43094, 0.50320, 0.43260, 0.46871, 0.43709, 0.46685, 0.43706,
    0.46479, 0.43760, 0.45414, 0.43897, 0.43303, 0.44292, 0.42790, 0.44322, 0.41417, 0.44316, 0.40950, 0.44250,
    0.40239, 0.44053, 0.39877, 0.44017, 0.39508, 0.44018, 0.40577, 0.44356, 0.40836, 0.44498, 0.40884, 0.44888,
    0.40754, 0.45179, 0.40746, 0.45398, 0.40806, 0.45522, 0.40992, 0.45630, 0.41571, 0.45817, 0.41894, 0.45887,
    0.43195, 0.46045, 0.45137, 0.46440, 0.46316, 0.46561, 0.49051, 0.46658, 0.50663, 0.46776, 0.51615, 0.46827,
    0.52303, 0.46837, 0.54883, 0.46984, 0.57439, 0.47313, 0.58620, 0.47433, 0.62022, 0.47606, 0.64267, 0.47819,
    0.65212, 0.47882, 0.66171, 0.48054, 0.67339, 0.48187, 0.68668, 0.48418, 0.69716, 0.48528, 0.71340, 0.48627,
    0.73371, 0.48903, 0.75583, 0.49150, 0.76056, 0.49239, 0.76428, 0.49369, 0.77184, 0.49737, 0.77360, 0.49856,
    0.77431, 0.49985, 0.77386, 0.50116, 0.77180, 0.50279, 0.76487, 0.50607, 0.76068, 0.50720, 0.73995, 0.51069,
    0.73226, 0.51167, 0.72435, 0.51242, 0.72238, 0.51232, 0.69677, 0.51494, 0.68716, 0.51494, 0.68082, 0.51451,
    0.66701, 0.51238, 0.65906, 0.51022, 0.65864, 0.51098, 0.65591, 0.51238, 0.63735, 0.51829, 0.63193, 0.51943,
    0.61142, 0.52066, 0.58864, 0.52114, 0.57773, 0.52163, 0.53454, 0.52449, 0.51390, 0.52700, 0.46882, 0.53104,
    0.44466, 0.53286, 0.40453, 0.53758, 0.38577, 0.53903, 0.38162, 0.54016, 0.37749, 0.54293, 0.37722, 0.54599,
    0.38182, 0.54918, 0.38619, 0.55088, 0.39901, 0.55488, 0.40259, 0.55554, 0.41993, 0.55698, 0.43797, 0.55915,
    0.45566, 0.56004, 0.46689, 0.56171, 0.48634, 0.56395, 0.49232, 0.56504, 0.49839, 0.56683, 0.50144, 0.56829,
    0.50356, 0.57038, 0.50414, 0.57168, 0.50363, 0.57519, 0.50251, 0.57599, 0.49900, 0.57734, 0.48383, 0.58115,
    0.47128, 0.58523, 0.46342, 0.58701, 0.44900, 0.58960, 0.43172, 0.59399, 0.42504, 0.59621, 0.42057, 0.59893,
    0.41861, 0.60195, 0.41991, 0.60410, 0.42262, 0.60562, 0.42679, 0.60677, 0.43040, 0.60741, 0.43948, 0.60846,
    0.45555, 0.60965, 0.47496, 0.61299, 0.48992, 0.61524, 0.49171, 0.61532, 0.50166, 0.61829, 0.50742, 0.61917,
    0.52068, 0.61960, 0.53325, 0.62056, 0.55114, 0.62060, 0.55615, 0.62020, 0.56688, 0.61853, 0.56947, 0.61851,
    0.56711, 0.61902, 0.55168, 0.62403, 0.55009, 0.62514, 0.54953, 0.62726, 0.54819, 0.62841, 0.53766, 0.63177,
    0.50162, 0.63894, 0.47411, 0.64301, 0.44530, 0.64822, 0.42300, 0.65169, 0.41721, 0.65288, 0.40785, 0.65548,
    0.40540, 0.65704, 0.40331, 0.65977, 0.40345, 0.66415, 0.40510, 0.66614, 0.41452, 0.67018, 0.41766, 0.67196,
    0.41851, 0.67361, 0.41886, 0.68021, 0.42127, 0.68002, 0.44199, 0.68002, 0.44588, 0.68021, 0.46003, 0.68208,
    0.47526, 0.68311, 0.47995, 0.68375, 0.48546, 0.68494, 0.50671, 0.69054, 0.51257, 0.69241, 0.52605, 0.69798,
    0.53375, 0.70050, 0.54531, 0.70543, 0.56174, 0.71077, 0.57645, 0.71714, 0.59858, 0.72311, 0.62149, 0.72799,
    0.62833, 0.73017, 0.63786, 0.73394, 0.64257, 0.73661, 0.64365, 0.73833, 0.64420, 0.74227, 0.64353, 0.74489,
    0.64263, 0.74618, 0.64062, 0.74733, 0.63553, 0.74880, 0.61540, 0.75263, 0.59592, 0.75485, 0.56530, 0.75990,
    0.50161, 0.76835, 0.48875, 0.77093, 0.46749, 0.77581, 0.45981, 0.77833, 0.45524, 0.78103, 0.45304, 0.78580,
    0.45566, 0.79100, 0.45747, 0.79266, 0.46472, 0.79640, 0.46863, 0.79922, 0.47458, 0.80162, 0.49698, 0.80593,
    0.51845, 0.80852, 0.53461, 0.81096, 0.53849, 0.81117, 0.56058, 0.81118, 0.56836, 0.81042, 0.56768, 0.81118,
    0.56821, 0.81331, 0.57367, 0.81875, 0.57746, 0.82045, 0.58819, 0.82388, 0.59072, 0.82530, 0.59070, 0.83042,
    0.58765, 0.83205, 0.58045, 0.83409, 0.51808, 0.84627, 0.50134, 0.84832, 0.48125, 0.84984, 0.47422, 0.85121,
    0.47024, 0.85297, 0.46986, 0.85427, 0.47206, 0.85816, 0.47614, 0.86281, 0.48380, 0.86987, 0.48887, 0.87717,
    0.48890, 0.88200, 0.48785, 0.88373, 0.48427, 0.88658, 0.48043, 0.88841, 0.46734, 0.89350, 0.44835, 0.89787,
    0.43666, 0.89920, 0.42424, 0.90110, 0.37337, 0.90663, 0.35620, 0.90944, 0.34850, 0.91041, 0.33260, 0.91184,
    0.31859, 0.91370, 0.30399, 0.91619, 0.29707, 0.91831, 0.29040, 0.92165, 0.28636, 0.92492, 0.28453, 0.92883,
]
private let roadPoints: [CGPoint] = stride(from: 0, to: roadXY.count, by: 2).map {
    CGPoint(x: roadXY[$0], y: roadXY[$0 + 1])
}
private let ludusRoad = RoadPath(roadPoints, aspect: mapAspect)

private func clampCG(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { max(lo, min(hi, v)) }

// Where the painting itself begins under the map's top parchment (fraction of the image height):
// the first cloud tops, measured on the 724-px art. And where it ends above the bottom parchment.
private let paintTop: CGFloat = 268.0 / 2272.0
private let paintBottom: CGFloat = 2132.0 / 2272.0

/// The map's viewport and the chrome floating over it — everything the camera and travel math
/// need, measured per layout (so the map works the same in a phone, an upright iPad or a column).
private struct MapFrame: Equatable {
    var w: CGFloat = 0, vh: CGFloat = 0   // viewport (map width × visible height)
    var topInset: CGFloat = 150           // floating chrome the camera keeps the traveler clear of
    var cardBand: CGFloat = 280           // reserved bottom band (card + bar) used for framing
    var travelPad: CGFloat = Chrome.barSide   // over-scroll for the bottom node — never past the bar
                                              // beside the tab, or the void shows
    var bottomPad: CGFloat = Chrome.barSide   // max scroll stops with the map's bottom edge at the
                                              // bar's top (beside the tab)
    var paintY: CGFloat = 163             // the painting's top edge may rise to here on screen: on a
                                          // phone (≤ 440 wide) the top clamp (offset 0) holds first,
                                          // on a wider stage this trims the scaled-up top parchment
    var paintKeep: CGFloat = (1 - paintBottom) * 440 * mapAspect   // …and at most this much parchment
                                          // shows below the painting (a 440-wide phone's whole margin)
    var h: CGFloat { w * mapAspect }
    private var bottomTrim: CGFloat { max(0, (1 - paintBottom) * h - paintKeep) }
    // The camera never scrolls past the map's top edge (offset ≤ 0) — the art's own parchment border
    // is the margin, so nothing but the painting is ever on screen.
    var camMax: CGFloat { min(0, paintY - paintTop * h) }
    var minIdle: CGFloat { min(camMax, vh - h - bottomPad + bottomTrim) }     // free-scroll bottom bound
    var minTravel: CGFloat { min(camMax, vh - h - travelPad + bottomTrim) }   // travel/card over-scroll
    /// The camera offset that frames road position `t` between the chrome bands.
    func cam(at t: CGFloat, travel: Bool) -> CGFloat {
        let desiredY = topInset + (vh - topInset - cardBand) / 2
        return clampCG(desiredY - ludusRoad.point(at: t).y * h, travel ? minTravel : minIdle, camMax)
    }
}

/// The home's two shapes. Portrait (phones, upright iPads): the map fills the stage under the
/// plaque and the bar. Sideways iPads ("Atlas and Ledger"): the map is a left column and the
/// chrome lives in a lacquer side panel on the right.
private struct HomeLayout: Equatable {
    var stage: CGSize = .zero              // the whole physical stage (under status bar + home indicator)
    var insets = EdgeInsets()
    var atlas: Bool { stage.width > stage.height && stage.width >= 900 }
    var panelW: CGFloat { atlas ? clampCG((stage.width * 0.35).rounded(), 380, Chrome.panel.width) : 0 }
    var map: MapFrame {
        var m = MapFrame(w: stage.width - panelW, vh: stage.height)
        if m.w > Chrome.barW { m.paintY = 150 }   // wide portrait: the painting starts where an iPhone's does
        if atlas {   // nothing floats over the column but the status bar's tint
            m.topInset = insets.top + 40; m.cardBand = insets.bottom + 40
            m.travelPad = 0; m.bottomPad = 0
            m.paintY = insets.top + 30; m.paintKeep = insets.bottom + 16
        }
        return m
    }

    init() {}
    init(_ g: GeometryProxy) {
        let ins = g.safeAreaInsets
        insets = ins
        // The map bleeds edge-to-edge over the FULL physical stage (under the status bar and behind
        // the bar), so measure the safe area plus its insets. On iPhone SE the first sizes arrive
        // 0 wide (setup would never run), so fall back to the screen itself until a real size lands.
        stage = g.size.width > 0
            ? CGSize(width: g.size.width + ins.leading + ins.trailing, height: g.size.height + ins.top + ins.bottom)
            : LudusStage<EmptyView>.screen
    }
}


/// A world's progress as its seal shows it: `n` ring segments (one per game in that world, ≤ 6
/// baked), `done` of them gilded (games the child has won — GameKit's bronze laurel). All won = the
/// laurel crown.
struct SealProgress {
    let n: Int, done: Int
    var ringAsset: String? {
        guard n > 0 else { return nil }
        if done >= n { return "RingCrown" }
        let segs = min(n, 6)
        return "Ring\(segs)_\(min(segs - 1, done * segs / n))"
    }
}

struct HomeView: View {
    @AppStorage(LudusStore.denariiKey, store: LudusStore.defaults) private var denarii = 0
    @AppStorage("ludus_last_world", store: LudusStore.defaults) private var lastSubject = ""

    @State private var travelerT: CGFloat = 0        // arc-length position on the road
    @State private var manualCamY: CGFloat = 0       // vertical camera offset (≤ 0); updated live while dragging
    @State private var dragging = false
    @State private var dragStartCam: CGFloat = 0     // camera offset at the start of a drag
    @State private var selected: Landmark?
    @State private var isTraveling = false
    @State private var travelSeq = 0
    @State private var didInit = false
    @State private var layout = HomeLayout()         // latest stage shape (for travel math)
    // The arrival card: a scroll that rises furled onto the bar's tab, then its top rod rolls up.
    // (Sideways it slides into the side panel from its outer edge instead.)
    @State private var cardLM: Landmark?             // non-nil while the card is on screen
    @State private var cardRise: CGFloat = 1         // 1 = lowered/out + transparent, 0 = docked
    @State private var cardOpen: CGFloat = 0         // 0 = furled, 1 = unrolled
    @State private var cardSeq = 0
    @State private var plateOpen: CGFloat = 0        // the selected seal's hanging name scroll
    // Entering a landmark: the map zooms into its building, then the landing page fades up over it.
    @State private var entered: LudusWorld?
    @State private var zoom: CGFloat = 0             // 0 = map, 1 = zoomed into the landmark
    @State private var zoomAnchor = UnitPoint.center
    @State private var mapHidden = false             // map + its ambience off while a landing page covers it
    @State private var showRecords = false           // the Tabularium (rank, laurels, sound) — opened from the rank
    @State private var showVilla = false             // the Villa (where coins are spent) — opened from the bar's coins

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let lay = HomeLayout(geo)
                let mf = lay.map
                let off = (isTraveling || cardLM != nil)
                    ? clampCG(manualCamY, mf.minTravel, mf.camMax)
                    : manualCamY
                ZStack(alignment: .top) {
                    if !lay.atlas {
                        plaque.padding(.top, -4)
                        cardLayer(w: mf.w)
                    }
                }
                .opacity(1 - zoom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(alignment: .topLeading) {
                    // Physical-screen layer: the map, then the static chrome painted over it. The map
                    // stays the first child in every layout, so rotating never rebuilds it.
                    ZStack(alignment: .topLeading) {
                        mapLayer(w: mf.w, h: mf.h)
                            .offset(y: off)
                            .frame(width: mf.w, height: mf.vh, alignment: .top)
                            .scaleEffect(1 + zoom * 1.6, anchor: zoomAnchor)
                            .clipped()
                            .contentShape(Rectangle())
                            .gesture(panGesture(mf))
                        topTint(height: lay.atlas ? 64 : 158)
                            .frame(width: mf.w)
                            .opacity(1 - zoom)
                        if lay.atlas {
                            sidePanel(lay)
                                .offset(x: mf.w - Chrome.panelShadow)
                                .opacity(1 - zoom)
                        } else {
                            bottomBar(w: mf.w)
                                .frame(width: mf.w, height: mf.vh, alignment: .bottom)
                                .opacity(1 - zoom)
                        }
                    }
                    .frame(width: lay.stage.width, height: lay.stage.height, alignment: .topLeading)
                    .opacity(mapHidden ? 0 : 1)          // fully covered: let the render server skip it
                    .ignoresSafeArea()
                }
                .overlay {
                    if let world = entered {
                        WorldView(world: world, onBack: { leave() })
                            .transition(.opacity)
                    }
                }
                .onAppear { setup(lay) }
                .onChange(of: lay) { setup($0) }
            }
            .navigationBarHidden(true)
        }
        .tint(Prov.red)
        .fullScreenCover(isPresented: $showVilla) { LudusStage { VillaView(onClose: { showVilla = false }) } }
        .fullScreenCover(isPresented: $showRecords) { LudusStage { TabulariumView(onClose: { showRecords = false }) } }
    }

    // The scrolling world: painted map, the eight seals on their buildings, and the traveler.
    private func mapLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Static art; motion is added selectively and only via Core Animation (no per-frame app work).
            Image("ProvinceMap").resizable().frame(width: w, height: h)
            MapAmbience(w: w, h: h)
            ForEach(Array(landmarks.enumerated()), id: \.element.id) { i, lm in
                if let world = lm.world {
                    let isSel = selected?.id == lm.id
                    Button { travel(to: lm) } label: {
                        // Selection changes ONLY the halo's opacity — never any geometry. A geometry
                        // change tied to `selected` gets animated by the tap's ambient transaction on
                        // its own timeline, making the selected seal slide ahead of the map pan.
                        SealStack(key: lm.key, progress: progress(world, index: i), halo: isSel)
                            .frame(width: Chrome.sealBox * Chrome.mapSeal, height: Chrome.sealBox * Chrome.mapSeal)
                            .frame(width: 48, height: 48)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(lm.name), \(world.subject)")
                    // The name hangs below the seal on a little scroll (overlay: never moves the seal).
                    // It unrolls on tap and stays open while the traveler is there.
                    .overlay(alignment: .top) {
                        NamePlate(name: lm.name, subject: world.subject, wax: lm.wax,
                                  open: isSel ? plateOpen : 0)
                            .offset(x: lm.labelDX, y: 47)
                            .allowsHitTesting(false)
                    }
                    // Seal on the building (blue mark); the traveler rests at the green mark (stop).
                    .position(x: lm.x * w, y: lm.y * h)
                }
            }
            // The standard's FOOT stands on the road point, so it rests exactly on the green mark.
            Traveler(walking: isTraveling, rank: rankIndex)
                .modifier(AlongRoad(t: travelerT, road: ludusRoad, w: w, h: h, dy: Traveler.centerToFoot))
        }
        .frame(width: w, height: h, alignment: .top)
    }

    private var rankIndex: Int {
        _ = denarii   // re-read on every bank change
        return LudusEconomy.rank.index
    }

    /// Games in a world vs. games the child has WON (reached the bronze-laurel level) (re-read whenever the view updates, e.g.
    /// on returning from a game).
    private func progress(_ world: LudusWorld, index: Int = 0) -> SealProgress {
        let n = world.games.filter(\.playable).count
        var done = world.games.filter(\.won).count
        #if DEBUG
        if ProcessInfo.processInfo.environment["LUDUS_DEMO_PROGRESS"] != nil { done = (index * 2) % (n + 1) }
        #endif
        return SealProgress(n: n, done: done)
    }

    // MARK: Travel

    /// GO THERE: walk the traveler along the road to the landmark's stop, panning the camera on the
    /// SAME timeline, then raise its arrival card.
    @discardableResult
    private func travel(to lm: Landmark) -> Double {
        guard let world = lm.world, layout.map.w > 0 else { return 0 }

        Haptics.tap()
        if cardLM != nil { hideCard() }
        // Set selection WITHOUT animation: any animated transaction on `selected` gets applied to the
        // selected seal's position too (it's in the same update as the pan), making it jump ahead of
        // the scroll. Only the pan (and the name scroll's own unroll) animate.
        var still = Transaction(); still.disablesAnimations = true
        withTransaction(still) { selected = lm; plateOpen = 0 }
        DispatchQueue.main.async { withAnimation(.easeOut(duration: 0.32)) { plateOpen = 1 } }

        let target = lm.arriveAt
        let dist = abs(target - travelerT)
        let dur = Double(0.5 + 2.0 * dist)
        let camTarget = layout.map.cam(at: target, travel: true)

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
            showCard(lm)
        }
        return dur
    }

    /// The card rises furled onto the bar's tab, then unrolls upward (title first, PLAY last).
    private func showCard(_ lm: Landmark) {
        cardSeq += 1
        let seq = cardSeq
        var still = Transaction(); still.disablesAnimations = true
        withTransaction(still) { cardLM = lm; cardRise = 1; cardOpen = 0 }
        DispatchQueue.main.async {
            guard seq == cardSeq else { return }
            withAnimation(.easeOut(duration: 0.22)) { cardRise = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                guard seq == cardSeq else { return }
                withAnimation(.easeOut(duration: 0.36)) { cardOpen = 1 }
            }
        }
    }

    /// Reverse: roll the card back down onto its bottom rod, then sink it away.
    private func hideCard() {
        cardSeq += 1
        let seq = cardSeq
        withAnimation(.easeIn(duration: 0.2)) { cardOpen = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            guard seq == cardSeq else { return }
            withAnimation(.easeIn(duration: 0.18)) { cardRise = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard seq == cardSeq else { return }
                cardLM = nil
            }
        }
    }

    private func dismissCard() {
        hideCard()
        selected = nil
        // If we were parked in the travel-only pad zone (last node), settle back into free-scroll bounds.
        let minIdle = layout.map.minIdle
        if manualCamY < minIdle {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { manualCamY = minIdle }
        }
    }

    /// Free vertical exploration when not traveling. Drives manualCamY DIRECTLY (not via @GestureState)
    /// so lifting a finger can't snap the map back a frame before the fling. Hard-clamped to the map's
    /// edges (no rubber-band) so nothing behind the painting is ever revealed.
    /// An open arrival card doesn't block scrolling: it stays up while its landmark is in view and
    /// rolls itself away once the landmark scrolls off (or behind the card), so it never points at
    /// something the child can't see. Sideways the card lives in the side panel, covering nothing,
    /// so it stays while its landmark is selected.
    private func panGesture(_ mf: MapFrame) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                guard !isTraveling else { return }
                if !dragging { dragging = true; dragStartCam = manualCamY }
                manualCamY = clampCG(dragStartCam + v.translation.height, mf.minIdle, mf.camMax)
                dropCardIfOffscreen(mf)
            }
            .onEnded { v in
                guard !isTraveling else { return }
                dragging = false
                let end = clampCG(dragStartCam + v.predictedEndTranslation.height, mf.minIdle, mf.camMax)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { manualCamY = end }
                dropCardIfOffscreen(mf, camY: end)   // judge where the fling lands
            }
    }

    private func dropCardIfOffscreen(_ mf: MapFrame, camY: CGFloat? = nil) {
        guard !layout.atlas, let lm = selected, cardLM != nil else { return }
        let y = lm.y * mf.h + (camY ?? manualCamY)          // the seal's screen position
        if y < 40 || y > mf.vh - mf.cardBand + 60 {
            hideCard()
            selected = nil
        }
    }

    /// Track the viewport size and, once it's valid, run one-time setup: stand the traveler where
    /// the child last was and frame that place. (GeometryReader reports .zero at first onAppear, so
    /// this must also run from onChange when the real size arrives.)
    /// PLAY: zoom the camera into the landmark's building, then fade its landing page up over it.
    private func enter(_ world: LudusWorld, at lm: Landmark) {
        let mf = layout.map
        guard entered == nil, mf.w > 0 else { return }
        let sy = lm.y * mf.h + clampCG(manualCamY, mf.minTravel, mf.camMax) - 40   // aim at the building, above its seal
        zoomAnchor = UnitPoint(x: lm.x, y: clampCG(sy / mf.vh, 0.05, 0.95))
        withAnimation(.easeIn(duration: 0.42)) { zoom = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) { entered = world }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { if entered != nil { mapHidden = true } }
        }
    }

    /// Back from a landing page: fade it out and pull the camera back out to the map.
    private func leave() {
        mapHidden = false
        withAnimation(.easeIn(duration: 0.22)) { entered = nil }
        withAnimation(.easeOut(duration: 0.5).delay(0.12)) { zoom = 0 }
    }

    private func setup(_ lay: HomeLayout) {
        let was = layout
        layout = lay
        guard lay.map.w > 0 else { return }
        guard didInit else {
            didInit = true
            // Stand where the child last was; on a first-ever launch, start at the first landmark.
            let lm = landmarks.first(where: { $0.subject == lastSubject }) ?? landmarks.first!
            travelerT = lm.arriveAt
            manualCamY = lay.map.cam(at: lm.arriveAt, travel: false)
            #if DEBUG
            startDebugTour()
            #endif
            return
        }
        // Rotated (or resized) mid-session: the map rescales to its new width, so re-frame the
        // camera on the traveler (on its destination if walking — `travelerT` already holds it).
        // The selection and card carry over; the card just moves between the bar and the panel.
        guard was.map != lay.map else { return }
        dragging = false
        var still = Transaction(); still.disablesAnimations = true
        withTransaction(still) {
            manualCamY = lay.map.cam(at: travelerT, travel: isTraveling || cardLM != nil)
        }
    }

    #if DEBUG
    /// Validation hook: launch with env LUDUS_TOUR = comma-separated subjects (or "all" = every stop
    /// top→bottom then back up) and the traveler walks the route unattended, holding at each stop
    /// (LUDUS_TOUR_HOLD seconds, default 1.5), so a screen recording can be checked against the
    /// traced road and the map ambience. LUDUS_DEMO_PROGRESS fakes varied seal progress.
    private func startDebugTour() {
        let env = ProcessInfo.processInfo.environment
        // LUDUS_ENTER=<subject>: walk there, then press PLAY (zoom in); back out after 4 s.
        if let sub = env["LUDUS_ENTER"], let lm = landmarks.first(where: { $0.subject == sub }), let w = lm.world {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let dur = travel(to: lm)
                DispatchQueue.main.asyncAfter(deadline: .now() + dur + 1.6) { enter(w, at: lm) }
                DispatchQueue.main.asyncAfter(deadline: .now() + dur + 6) { leave() }
            }
        }
        guard let spec = env["LUDUS_TOUR"], !spec.isEmpty else { return }
        let hold = Double(env["LUDUS_TOUR_HOLD"] ?? "") ?? 1.5
        let stops: [Landmark] = spec == "all"
            ? landmarks + landmarks.reversed().dropFirst()
            : spec.split(separator: ",").compactMap { s in landmarks.first { $0.subject == s } }
        func step(_ i: Int) {
            guard i < stops.count else { return }
            let dur = travel(to: stops[i])
            DispatchQueue.main.asyncAfter(deadline: .now() + dur + hold) { step(i + 1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { step(0) }
    }
    #endif

    // MARK: Chrome — every piece is a baked image (tools/chrome/chrome_build.py); only text is live.

    private var plaque: some View {
        Image("TopPlaque").resizable()
            .frame(width: Chrome.plaque.width, height: Chrome.plaque.height)
            .accessibilityLabel("Ludus")
    }

    // The red wash the plaque hovers over (also darkens the status-bar area).
    private func topTint(height: CGFloat) -> some View {
        LinearGradient(stops: [.init(color: Prov.tint.opacity(0.92), location: 0),
                               .init(color: Prov.tint.opacity(0.61), location: 0.25),
                               .init(color: Prov.tint.opacity(0.35), location: 0.5),
                               .init(color: Prov.tint.opacity(0.13), location: 0.75),
                               .init(color: Prov.tint.opacity(0), location: 1)],
                       startPoint: .top, endPoint: .bottom)
            .frame(height: height)
            .allowsHitTesting(false)
    }

    // The slim lacquer bar: a raised centre tab carrying the rank, coin totals in the corners, and
    // the same gilt moulding as the plaque along its top edge. Baked 440 pt wide and centre-cropped;
    // wider stages (iPad) take the 1000-pt bake, so the corners' coins always sit on lacquer.
    private func bottomBar(w: CGFloat) -> some View {
        let wide = w > Chrome.barW
        return VStack(spacing: 0) {
            // a short whisper of the top's tint, just above the bar
            LinearGradient(stops: [.init(color: Prov.tint.opacity(0), location: 0),
                                   .init(color: Prov.tint.opacity(0.1), location: 0.5),
                                   .init(color: Prov.tint.opacity(0.3), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 46)
                .padding(.bottom, -(Chrome.barTab + Chrome.barShadow - Chrome.barSide))
                .allowsHitTesting(false)
            ZStack(alignment: .top) {
                Image(wide ? "BottomBarWide" : "BottomBar").resizable()
                    .allowsHitTesting(false)
                    .frame(width: wide ? Chrome.barWideW : Chrome.barW, height: Chrome.barTab + Chrome.barShadow)
                rankButton.padding(.top, Chrome.barShadow)
            }
            .frame(width: w, height: Chrome.barTab + Chrome.barShadow)
            .clipped()
            .overlay(alignment: .bottom) {
                // The coin corners open the Villa — the place the arcade's coins are spent.
                HStack(spacing: 5.5) {
                    silverButton(pad: .trailing)
                    Spacer(minLength: 0)
                    goldButton(pad: .leading)
                }
                .padding(.horizontal, 25.5)
                .frame(height: Chrome.coin)
                .padding(.bottom, 14)       // coin row centred in the side's lacquer, under its fillet
            }
        }
    }

    private var rankButton: some View {
        Button { openRecords() } label: {
            Image("Rank\(rankIndex)").resizable()
                .frame(width: Chrome.rank.width, height: Chrome.rank.height)
        }
        .buttonStyle(PlaqueButtonStyle())
        .accessibilityLabel("Rank: \(ludusRank()). Open the hall of records")
    }

    // The coins open the Villa — the place the arcade's coins are spent. `pad` = the side whose
    // 14-pt margin is part of the tap target.
    private func silverButton(pad: Edge.Set) -> some View {
        Button { openVilla() } label: {
            HStack(spacing: 5.5) {
                Image("CoinSilver").resizable().frame(width: Chrome.coin, height: Chrome.coin)
                coinText("\(denarii)")
            }
            .padding(.vertical, 10).padding(pad, 14).contentShape(Rectangle())
        }
        .buttonStyle(PlaqueButtonStyle())
        .accessibilityLabel("\(denarii) denarii. Open your villa")
    }

    private func goldButton(pad: Edge.Set) -> some View {
        Button { openVilla() } label: {
            HStack(spacing: 5.5) {
                coinText("\(LudusEconomy.aurei)")
                Image("CoinGold").resizable().frame(width: Chrome.coin, height: Chrome.coin)
            }
            .padding(.vertical, 10).padding(pad, 14).contentShape(Rectangle())
        }
        .buttonStyle(PlaqueButtonStyle())
        .accessibilityLabel("\(LudusEconomy.aurei) aurei. Open your villa")
    }

    private func openRecords() {
        guard !isTraveling else { return }
        Haptics.tap(); Sfx.play(.tick)
        showRecords = true
    }

    private func openVilla() {
        guard !isTraveling else { return }
        Haptics.tap(); Sfx.play(.coin)
        showVilla = true
    }

    private func coinText(_ v: String) -> some View {
        ZStack {
            Text(v).foregroundStyle(Color(.sRGB, red: 40 / 255, green: 6 / 255, blue: 4 / 255).opacity(0.6)).offset(y: 1)
            Text(v).foregroundStyle(Prov.coinInk)
        }
        .font(luCinzel(17)).tracking(0.4).monospacedDigit()
    }

    // The arrival card, laid out against the PHYSICAL screen bottom so its bottom rod rests on the tab.
    @ViewBuilder private func cardLayer(w: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            if let lm = cardLM {
                destinationCard(lm, width: min(Chrome.cardW, w - 58))
                    .opacity(1 - cardRise)
                    .offset(y: cardRise * 36)
                    // bottom rod centre = the tab's top edge (+0.5): container bottom sits a rod-half lower
                    .padding(.bottom, Chrome.barTab - 0.5 - DestinationCard.rodH / 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder private func destinationCard(_ lm: Landmark, width: CGFloat) -> some View {
        if let world = lm.world {
            DestinationCard(landmark: lm, world: world, progress: progress(world, index: landmarks.firstIndex { $0.id == lm.id } ?? 0),
                            width: width, open: cardOpen,
                            onPlay: { enter(world, at: lm) },
                            onClose: { dismissCard() })
        }
    }

    // MARK: Side panel — sideways iPads ("Atlas and Ledger")
    //
    // The map is a left column; this lacquer slab (SidePanel: the bar's lacquer and gilt moulding
    // turned down its map-facing edge) carries the chrome: the plaque at the top, the arrival card in
    // the middle — it slides in from the panel's outer edge, then unrolls — and the ledger (rank →
    // Tabularium, coins → Villa) at the bottom. Nothing covers the map, so the camera frames the
    // whole column and an open card stays while its landmark is selected.

    private func sidePanel(_ lay: HomeLayout) -> some View {
        let pw = lay.panelW
        let slotH = Chrome.cardH + Chrome.cardRod + DestinationCard.rodH   // the card fully unrolled
        return ZStack(alignment: .topLeading) {
            Image("SidePanel").resizable()
                .frame(width: Chrome.panel.width + Chrome.panelShadow, height: Chrome.panel.height)
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                plaque.padding(.top, lay.insets.top + 18)
                Spacer(minLength: 12)
                ZStack(alignment: .top) {
                    panelPrompt
                        .frame(height: slotH)
                        .opacity(cardLM == nil ? 1 : 0)
                        .animation(.easeOut(duration: 0.25), value: cardLM == nil)
                    if let lm = cardLM {
                        destinationCard(lm, width: min(Chrome.cardW, pw - 64))
                            .opacity(1 - cardRise)
                            .offset(x: cardRise * pw * 0.6)
                    }
                }
                .frame(height: slotH, alignment: .top)
                .padding(.vertical, 30)
                .frame(width: pw - 22)
                .background(cartouche)
                Spacer(minLength: 12)
                gildedRule(width: pw - 96)
                rankButton.padding(.top, 10)
                HStack(spacing: 0) {
                    silverButton(pad: .trailing)
                    Rectangle().fill(Color(hex: 0xc99a3a).opacity(0.7)).frame(width: 5, height: 5)
                        .rotationEffect(.degrees(45))
                    goldButton(pad: .leading)
                }
                .padding(.top, -12)
                .padding(.bottom, max(lay.insets.bottom, 12) + 6)
            }
            .frame(width: pw, height: lay.stage.height)
            .offset(x: Chrome.panelShadow)
        }
        .frame(width: pw + Chrome.panelShadow, height: lay.stage.height, alignment: .topLeading)
        .clipped()
    }

    /// The panel's middle while no card is up: where to go next, or where the traveler is headed.
    private var panelPrompt: some View {
        let headed = isTraveling ? selected : nil
        return VStack(spacing: 12) {
            Text(headed == nil ? "CHOOSE A PLACE" : "ON THE ROAD TO")
                .font(luCinzel(12, bold: true)).tracking(2.2)
                .foregroundStyle(Color(hex: 0xe6c15f))
            Group {
                if let lm = headed {
                    Text(lm.name.uppercased()).font(luCinzel(26)).tracking(0.8)
                } else {
                    Text("Tap a seal on the map\nto travel there").font(luGaramond(20))
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(Prov.coinInk)
            .shadow(color: Color(.sRGB, red: 40 / 255, green: 6 / 255, blue: 4 / 255).opacity(0.6), radius: 0, y: 1)
        }
        .accessibilityElement(children: .combine)
    }

    /// The recessed field the card docks in: a darker sunk panel with a double engraved gilt line
    /// (the plaque's moulding + fillet, in hairline) and a lozenge riveted top and bottom.
    private var cartouche: some View {
        let gilt = Color(hex: 0xc99a3a)
        return ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x3c0806).opacity(0.22))
            RoundedRectangle(cornerRadius: 10).strokeBorder(gilt.opacity(0.85), lineWidth: 1.2)
            RoundedRectangle(cornerRadius: 7).strokeBorder(gilt.opacity(0.45), lineWidth: 0.6).padding(4)
            VStack {
                lozenge.offset(y: -4)
                Spacer()
                lozenge.offset(y: 4)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 0, y: 1)   // the engraving's lower lip
        .allowsHitTesting(false)
    }

    private var lozenge: some View {
        Rectangle().fill(Color(hex: 0xe6c15f)).frame(width: 7, height: 7).rotationEffect(.degrees(45))
            .shadow(color: .black.opacity(0.35), radius: 0, y: 1)
    }

    /// A hairline gilt rule with a lozenge at its centre (the card's inked rule, in gold).
    private func gildedRule(width: CGFloat) -> some View {
        HStack(spacing: 14) {
            Rectangle().frame(height: 0.8)
            Rectangle().frame(height: 0.8)
        }
        .foregroundStyle(Color(hex: 0xc99a3a).opacity(0.75))
        .overlay(Rectangle().fill(Color(hex: 0xe6c15f)).frame(width: 5, height: 5).rotationEffect(.degrees(45)))
        .frame(width: width)
    }
}

// MARK: - A landmark seal: wax body + progress ring (+ selection halo), all baked

struct SealStack: View {
    let key: String
    let progress: SealProgress
    var halo: Bool = false

    var body: some View {
        ZStack {
            Image("SealHalo").resizable().opacity(halo ? 1 : 0)
            if let ring = progress.ringAsset { Image(ring).resizable() }
            Image("Seal" + key).resizable()
        }
    }
}

// MARK: - Scroll rods (F): a wooden roller whose finials + cord wraps stay put as it stretches

private struct ScrollRod: View {
    let asset: String
    let d: CGFloat          // rod diameter (pt); the image is (shaft + 2d) × 1.6d
    var body: some View {
        Image(asset)
            .resizable(capInsets: EdgeInsets(top: 0, leading: 2 * d, bottom: 0, trailing: 2 * d))
            .frame(height: 1.6 * d)
            .padding(.horizontal, -d)
    }
}

// MARK: - The name scroll that hangs under the selected seal

private struct NamePlate: View {
    let name: String
    let subject: String
    let wax: UInt
    var open: CGFloat        // 0 = rolled into its rod (hidden), 1 = hanging open

    var body: some View {
        let rodH = Chrome.plateRod * 1.6
        VStack(spacing: 2) {
            Text(name.uppercased()).font(luCinzel(11)).tracking(0.5).foregroundStyle(Prov.ink)
            Text(subject).font(luGaramond(11.5, semibold: true)).foregroundStyle(waxInk(wax, 25))
        }
        .fixedSize()
        .padding(.horizontal, 20)
        .padding(.top, 1)                       // optical: clear of the top rod's curl shade
        .frame(height: Chrome.plateH)
        .background(Image("PlateParchment")
            .resizable(capInsets: EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)))
        // Text rides the top rod; the bottom rod drops to unroll (the frame grows downward).
        .frame(height: Chrome.plateH * open, alignment: .top)
        .clipped()
        .overlay(alignment: .top) { ScrollRod(asset: "PlateRod", d: Chrome.plateRod).offset(y: -rodH / 2) }
        .overlay(alignment: .bottom) { ScrollRod(asset: "PlateRod", d: Chrome.plateRod).offset(y: rodH / 2) }
        .padding(.vertical, rodH / 2)
        .opacity(open > 0.01 ? 1 : 0)
    }
}

// MARK: - The arrival card: an F scroll docked on the bar's tab

private struct DestinationCard: View {
    let landmark: Landmark
    let world: LudusWorld
    let progress: SealProgress
    let width: CGFloat       // parchment width; the rods' finials reach ~13 pt further
    var open: CGFloat        // 0 = furled (rods together), 1 = unrolled
    let onPlay: () -> Void
    let onClose: () -> Void

    static let rodH = Chrome.cardRod * 1.6

    var body: some View {
        let vis = Chrome.cardH * open
        sheet
            .frame(width: width, height: Chrome.cardH, alignment: .top)
            // Content rides the TOP rod as it rolls up, so the title shows first and PLAY last.
            .frame(height: vis, alignment: .top)
            .clipped()
            .overlay(alignment: .bottom) {       // curl shade where the sheet meets the bottom rod
                LinearGradient(colors: [Color(hex: 0x3c230a).opacity(0), Color(hex: 0x3c230a).opacity(0.43)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: min(6, vis))
            }
            .padding(.vertical, Chrome.cardRod / 2)          // rod centres sit half a rod outside the sheet
            .background(
                Image("CardShadow")
                    .resizable(capInsets: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40))
                    .padding(-16).offset(y: 6)
            )
            .overlay(alignment: .top) { ScrollRod(asset: "CardRod", d: Chrome.cardRod).offset(y: -Self.rodH / 2) }
            .overlay(alignment: .bottom) { ScrollRod(asset: "CardRod", d: Chrome.cardRod).offset(y: Self.rodH / 2) }
            .padding(.vertical, Self.rodH / 2)
    }

    private var sheet: some View {
        let colX: CGFloat = 104
        let colW = width - colX - 40                          // clear of the close button
        let k = width / Chrome.cardW
        let n = progress.n, done = min(progress.done, progress.n)
        return ZStack(alignment: .topLeading) {
            Image("CardParchment").resizable()
            // the selected seal, larger, with its ring — the same object as on the map
            SealStack(key: landmark.key, progress: progress)
                .frame(width: Chrome.sealBox * Chrome.cardSeal, height: Chrome.sealBox * Chrome.cardSeal)
                .position(x: 52, y: 47)
            Text(world.subject.uppercased())
                .font(luCinzel(10, bold: true)).tracking(1.6).foregroundStyle(waxInk(landmark.wax, 35))
                .lineLimit(1)
                .frame(width: colW, alignment: .leading).position(x: colX + colW / 2, y: 24)
            ZStack {
                Text(landmark.name.uppercased()).foregroundStyle(Color(hex: 0xfff5dc).opacity(0.55)).offset(y: 0.7)
                Text(landmark.name.uppercased()).foregroundStyle(Prov.ink)
            }
            .font(luCinzel(22)).tracking(0.6).lineLimit(1).minimumScaleFactor(0.68)
            .frame(width: colW, alignment: .leading).position(x: colX + colW / 2, y: 46)
            Text(done == 0 ? "\(n) game\(n == 1 ? "" : "s") to win" : "\(done) of \(n) game\(n == 1 ? "" : "s") won")
                .font(luGaramond(14)).foregroundStyle(Prov.ink.opacity(0.62))
                .frame(width: colW, alignment: .leading).position(x: colX + colW / 2, y: 70)
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Prov.ink.opacity(0.55))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color(hex: 0x78501e).opacity(0.10))
                        .overlay(Circle().strokeBorder(Color(hex: 0xc99a3a).opacity(0.45), lineWidth: 0.8)))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .position(x: width - 22, y: 22)
            // inked rule with a crimson lozenge between the header and PLAY
            HStack(spacing: 16) {
                Rectangle().fill(Prov.rule.opacity(0.8)).frame(height: 0.7)
                Rectangle().fill(Prov.rule.opacity(0.8)).frame(height: 0.7)
            }
            .overlay(Rectangle().fill(Color(hex: 0x9e2b25)).frame(width: 4.8, height: 4.8).rotationEffect(.degrees(45)))
            .frame(width: width - 52).position(x: width / 2, y: 92)
            Button(action: onPlay) {
                Image("PlayPlaque").resizable()
                    .frame(width: Chrome.play.width * k, height: Chrome.play.height * k)
            }
            .buttonStyle(PlaqueButtonStyle())
            .accessibilityLabel("Play")
            .position(x: width / 2, y: 94 + Chrome.play.height * k / 2)
        }
        .frame(width: width, height: Chrome.cardH)
    }
}

/// A baked plaque button: dips and darkens a touch while pressed.
struct PlaqueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.08 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
