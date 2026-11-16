import SwiftUI

// Settings: appearance, the policy pages, and account controls. Reachable signed
// in or out (Privacy and Support must be findable without an account).
struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var router: Router
    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .system
    @State private var showDelete = false

    var body: some View {
        Form {
            Section {
                // Like Display & Brightness: a small page in each look, tap to choose.
                HStack(spacing: 0) {
                    ForEach(Appearance.allCases) { option in
                        Button {
                            withAnimation(.snappy) { appearance = option }
                        } label: {
                            VStack(spacing: 8) {
                                AppearanceSwatch(option: option)
                                Text(option.label).font(.ui(14, .medium)).foregroundStyle(Theme.ink)
                                Image(systemName: appearance == option ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(appearance == option ? Theme.accent : Theme.inkSoft.opacity(0.5))
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.label)
                        .accessibilityAddTraits(appearance == option ? .isSelected : [])
                    }
                }
                .padding(.vertical, 8)
                .sensoryFeedback(.selection, trigger: appearance)
                .listRowBackground(Theme.card)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Light is easier to read in a bright room or on a projector. System follows your device.")
            }

            Section("About") {
                Link(destination: AppConfig.assetURL("/privacy")!) { row("Privacy Policy", "hand.raised.fill") }
                Link(destination: AppConfig.assetURL("/support")!) { row("Support", "questionmark") }
                Link(destination: AppConfig.assetURL("/")!) { row("The Timpson Lyceum website", "building.columns.fill") }
            }
            .listRowBackground(Theme.card)

            if auth.isSignedIn {
                Section("Account") {
                    if let email = auth.user?.email {
                        LabeledContent("Signed in as", value: email)
                    }
                    Button("Sign out") { Task { await auth.logout() } }
                        .foregroundStyle(Theme.ink)
                    // Account deletion must be reachable in the app (Guideline 5.1.1(v)).
                    Button("Delete account", role: .destructive) { showDelete = true }
                        .foregroundStyle(Theme.danger)
                }
                .listRowBackground(Theme.card)
            }

            Section {
                // The colophon.
                VStack(spacing: 8) {
                    GiltDiamond(size: 6)
                    Text("The Timpson Lyceum").font(.display(13)).kerning(1.4).foregroundStyle(Theme.inkSoft)
                    Text(versionString).font(.ui(12)).foregroundStyle(Theme.inkSoft.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
            }
        }
        .font(.ui(16))
        .scrollContentBackground(.hidden)
        .background(Theme.page)
        .leatherBar("Settings")
        .sheet(isPresented: $showDelete) { DeleteAccountSheet() }
        // Signing out or deleting the account here returns to the Progress tab's
        // root, which is the sign-in form when signed out.
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if !signedIn { router.progress = NavigationPath() }
        }
    }

    private func row(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            // Settings-style icon tiles, in leather and gold.
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.gilt)
                .frame(width: 29, height: 29)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Theme.leather))
            Text(title).foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: "arrow.up.right").font(.ui(13, .semibold)).foregroundStyle(Theme.inkSoft)
        }
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(v) (\(b))"
    }
}

/// A thumbnail of the app in one appearance: a leather masthead over a page with
/// two cards. System is split down the middle, light and dark.
private struct AppearanceSwatch: View {
    let option: Appearance
    var body: some View {
        ZStack {
            switch option {
            case .light: page(dark: false)
            case .dark: page(dark: true)
            case .system:
                page(dark: false)
                page(dark: true).mask(HStack(spacing: 0) { Color.clear; Color.black })
            }
        }
        .frame(width: 64, height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.strongLine.opacity(0.6), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }

    private func page(dark: Bool) -> some View {
        VStack(spacing: 5) {
            LinearGradient(colors: dark ? [Color(hex: 0x431212), Color(hex: 0x220808)] : [Color(hex: 0x8e2424), Color(hex: 0x5c1212)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 34)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.giltBar).frame(height: 1) }
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Capsule().fill(Color(hex: 0xe8c96e)).frame(width: 18, height: 2.5)
                        Capsule().fill(Color(hex: 0xf7eedb)).frame(width: 30, height: 4)
                    }
                    .padding(.leading, 7).padding(.top, 8)
                }
            ForEach(0..<2) { _ in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(dark ? Color(hex: 0x1a0909) : Color(hex: 0xfffdf9))
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Capsule().fill(dark ? Color(hex: 0xf5ecd8) : Color(hex: 0x1d1814)).frame(width: 30, height: 3)
                            Capsule().fill(Theme.giltBar).frame(width: 22, height: 2.5)
                        }
                        .padding(5)
                    }
                    .frame(height: 22)
                    .padding(.horizontal, 6)
            }
            Spacer(minLength: 0)
        }
        .background(dark ? Color(hex: 0x0f0404) : Color(hex: 0xf6f2ec))
    }
}
