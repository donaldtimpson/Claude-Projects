import SwiftUI
import UIKit

// A child swipes a card sideways to change it, and iOS reads a swipe from the left
// edge as "go back". The two gestures overlap, so a slightly-too-far-left swipe
// throws them out of the deck. Cards can be swiped either way, so there is no
// direction left to reserve for navigation — the edge gesture has to go, and the
// back button in the bar stays as the way out.
struct DisableBackSwipe: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { Holder() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {}

    private final class Holder: UIViewController {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // Hand it back on the way out, so the rest of the app behaves normally.
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}

extension View {
    /// Use on any screen where a horizontal drag means something to the child.
    func noBackSwipe() -> some View {
        background(DisableBackSwipe().frame(width: 0, height: 0))
    }
}
