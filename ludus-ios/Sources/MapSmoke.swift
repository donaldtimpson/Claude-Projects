import SwiftUI
import UIKit

// MARK: - Volcano smoke — the painted plume, billowing, at ~zero CPU
//
// The motion is the art's OWN smoke: offline, the plume's painted texture is streamed upward along
// a flow field inside its fixed silhouette (a seamless 6 s cinemagraph loop, 90 frames), and packed
// into `SmokeSheet` — each cell is the flowed plume with an alpha envelope, so composited over the
// static map it reproduces the render exactly. Here Core Animation plays the sheet as a flipbook by
// stepping `contentsRect`: the render server drives it, so the app does no per-frame work (the old
// full-map Metal shader in a TimelineView is what cost ~75% CPU). Rebuild the sheet and these
// constants with tools/smoke_flow.py if the art changes.

private enum SmokeSheet {
    static let frames = 90, cols = 10
    static let cellW: CGFloat = 134, cellH: CGFloat = 105, gutter: CGFloat = 2
    static let frameW: CGFloat = 130, frameH: CGFloat = 101
    static let mapX: CGFloat = 466, mapY: CGFloat = 612     // frame's top-left in ProvinceMap px
    static let loop: CFTimeInterval = 6
    static var rows: Int { (frames + cols - 1) / cols }
}

/// Positioned in the map's coordinate space: `w` is the rendered map width (map px × w / 724).
struct VolcanoSmoke: View {
    let w: CGFloat
    var body: some View {
        let k = w / 724
        SmokeFlipbook()
            .frame(width: SmokeSheet.frameW * k, height: SmokeSheet.frameH * k)
            .position(x: (SmokeSheet.mapX + SmokeSheet.frameW / 2) * k,
                      y: (SmokeSheet.mapY + SmokeSheet.frameH / 2) * k)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct SmokeFlipbook: UIViewRepresentable {
    func makeUIView(context: Context) -> FlipbookView { FlipbookView() }
    func updateUIView(_ view: FlipbookView, context: Context) {}
}

private final class FlipbookView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.contents = UIImage(named: "SmokeSheet")?.cgImage
        layer.contentsGravity = .resize
        layer.contentsRect = Self.rect(0)
    }
    required init?(coder: NSCoder) { fatalError() }

    /// Unit-space rect of cell `i` inside the sheet, excluding its transparent gutter.
    private static func rect(_ i: Int) -> CGRect {
        let sw = SmokeSheet.cellW * CGFloat(SmokeSheet.cols), sh = SmokeSheet.cellH * CGFloat(SmokeSheet.rows)
        let r = i / SmokeSheet.cols, c = i % SmokeSheet.cols
        return CGRect(x: (CGFloat(c) * SmokeSheet.cellW + SmokeSheet.gutter) / sw,
                      y: (CGFloat(r) * SmokeSheet.cellH + SmokeSheet.gutter) / sh,
                      width: SmokeSheet.frameW / sw, height: SmokeSheet.frameH / sh)
    }

    // Run only while on screen (UIKit detaches the home view while a game is pushed); with Reduce
    // Motion on, hide the overlay so the painting stays still.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        layer.removeAnimation(forKey: "smoke")
        isHidden = UIAccessibility.isReduceMotionEnabled
        guard window != nil, !isHidden else { return }
        let a = CAKeyframeAnimation(keyPath: "contentsRect")
        a.values = (0..<SmokeSheet.frames).map { NSValue(cgRect: Self.rect($0)) }
        a.calculationMode = .discrete
        a.duration = SmokeSheet.loop
        a.repeatCount = .infinity
        a.isRemovedOnCompletion = false
        layer.add(a, forKey: "smoke")
    }
}
