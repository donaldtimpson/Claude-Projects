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
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Theme.card)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Light is easier to read in a bright room or on a projector. System follows your device.")
            }

            Section("About") {
                Link(destination: AppConfig.assetURL("/privacy")!) { row("Privacy Policy", "hand.raised") }
                Link(destination: AppConfig.assetURL("/support")!) { row("Support", "questionmark.circle") }
                Link(destination: AppConfig.assetURL("/")!) { row("The Timpson Lyceum website", "globe") }
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
                Text(versionString).font(.ui(13)).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .font(.ui(16))
        .scrollContentBackground(.hidden)
        .background(Theme.page)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDelete) { DeleteAccountSheet() }
        // Signing out or deleting the account here returns to the Progress tab's
        // root, which is the sign-in form when signed out.
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if !signedIn { router.progress = NavigationPath() }
        }
    }

    private func row(_ title: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundStyle(Theme.ink)
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
