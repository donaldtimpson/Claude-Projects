import SwiftUI

// Pick the public handle — the mobile twin of the web dashboard's HandleForm.
// Validation lives on the server (PUT /me/handle reuses the same validateHandle the
// web server action calls), so the rules can't drift between the two; this screen
// only mirrors the length cap locally and shows whatever the server says.
struct HandleEditorSheet: View {
    let current: String?
    let onSaved: (AuthUser) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var handle = ""
    @State private var error: String?
    @State private var busy = false

    // Matches HANDLE_MIN / HANDLE_MAX in lib/gamification/handle.ts.
    private static let maxLength = 20
    private var trimmed: String { handle.trimmingCharacters(in: .whitespaces) }
    private var canSubmit: Bool { trimmed.count >= 3 && trimmed != current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("This is the only name shown publicly in the Hall of Scholars — never your real name or email.")
                        .font(.serif(15)).foregroundStyle(Theme.inkSoft)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Handle").font(.caption).foregroundStyle(Theme.inkSoft)
                        TextField("Scholar", text: $handle)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Theme.card)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onChange(of: handle) { _, new in
                                if new.count > Self.maxLength { handle = String(new.prefix(Self.maxLength)) }
                                error = nil
                            }
                        Text("3–\(Self.maxLength) characters. Letters, numbers, hyphens, and underscores.")
                            .font(.caption).foregroundStyle(Theme.inkSoft)
                    }

                    if let error {
                        Text(error).font(.callout).foregroundStyle(Theme.danger)
                    }

                    PrimaryButton(title: "Save handle", enabled: canSubmit, loading: busy) {
                        Task { await submit() }
                    }
                }
                .padding()
            }
            .background(Theme.parchment)
            .navigationTitle("Your Handle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Theme.gold300)
                }
            }
        }
        .onAppear { handle = current ?? "" }
    }

    private struct HandlePayload: Encodable { let handle: String }

    private func submit() async {
        busy = true
        error = nil
        do {
            let res: HandleResponse = try await APIClient.shared.put("/me/handle", body: HandlePayload(handle: trimmed))
            onSaved(res.user)
            dismiss()
        } catch let e as APIError {
            // The server's message is the useful one ("already taken", "reserved").
            self.error = e.message
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }
}
