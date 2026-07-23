import SwiftUI
import UIKit

// The app is portrait everywhere EXCEPT the tap-to-locate map, which allows real landscape
// rotation (either direction) so you can hold the phone whichever way you like. A view opts
// in with `.landscapeWhilePresented()`; leaving it returns the app to portrait.
//
// This replaces the old ForcedLandscape rotationEffect hack (which faked one fixed landscape
// and couldn't follow the device). We gate the allowed orientations through an app delegate
// and ask the window scene to rotate on appear/disappear.
enum OrientationGate {
    static var mask: UIInterfaceOrientationMask = .portrait
}

final class OrientationAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationGate.mask
    }
}

@MainActor
private func setOrientation(_ mask: UIInterfaceOrientationMask) {
    OrientationGate.mask = mask
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
    guard let scene else { return }
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
}

extension View {
    // Allow + prefer landscape (both directions) while on screen; restore portrait on exit.
    func landscapeWhilePresented() -> some View {
        onAppear { setOrientation(.landscape) }
            .onDisappear { setOrientation(.portrait) }
    }
}
