import SwiftUI

/// "Who's playing?" — one wax seal per child. (Placeholder; the full picker replaces this.)
struct ProfilePickerView: View {
    @ObservedObject private var profiles = LudusProfiles.shared
    var body: some View {
        VStack(spacing: 16) {
            ForEach(profiles.all) { p in
                Button(p.name) { profiles.select(p.id) }
            }
        }
    }
}
