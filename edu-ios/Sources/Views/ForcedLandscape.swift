import SwiftUI

// Draws its content in landscape within a portrait-locked app — no device-orientation
// plumbing (the app stays portrait everywhere else). The content is laid out in a
// landscape-shaped frame (the screen's long edge becomes the width) and rotated 90° to
// fill the portrait screen. Used by the tap-to-locate drills, whose maps are far wider
// than tall.
//
// Hit-testing stays correct: a gesture attached inside `content` reports its location in
// the content's own (rotated) coordinate space, and the map measures its size in that
// same space — so the reverse transform in GeoMapDiagram lines up.
struct ForcedLandscape<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            content
                .frame(width: geo.size.height, height: geo.size.width)
                .rotationEffect(.degrees(90))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
