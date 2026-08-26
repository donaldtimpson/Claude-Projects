import Foundation
import SwiftData

// The one SwiftData container behind the on-device drill records (Leitner boxes for
// Learn mode + the ✦ aced marks). Both models share it for two reasons:
//
//  * Building the FIRST container is the expensive one — measured at 120–265 ms on a
//    Mac, and it was being paid inside a SwiftUI view body the moment the Drills tab
//    first rendered (DrillsView asks LessonProgress for the aced count while laying
//    out the category rows). A second container after it costs ~8 ms, so two stores
//    bought nothing but a second store file.
//  * `warm()` builds it off the main thread during launch, while the splash screen is
//    already up waiting on auth — so by the time anyone reaches Drills it's ready.
//
// Still decoupled from the offline write queue's container; this is only drill state.
enum DrillStore {
    static let container: ModelContainer = {
        do { return try ModelContainer(for: DrillItemMastery.self, LessonAced.self) }
        catch { fatalError("DrillStore SwiftData container: \(error)") }
    }()

    /// Build the container (and the drill catalog) off the main thread at launch so the
    /// first render of the Drills tab isn't the thing that pays for them. Safe to call
    /// more than once — the statics are `swift_once`-guarded, and a main-thread access
    /// that races this just waits for the work already in flight.
    static func warm() {
        Task.detached(priority: .utility) {
            _ = container
            _ = DrillCatalog.all
        }
    }
}
