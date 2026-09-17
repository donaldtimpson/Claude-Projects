import SwiftUI

// Relative timestamp ("2h ago") from the API's ISO-8601 createdAt.
func relativeTime(_ iso: String) -> String {
    let withFractional = ISO8601DateFormatter()
    withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let plain = ISO8601DateFormatter()
    guard let date = withFractional.date(from: iso) ?? plain.date(from: iso) else { return "" }
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    return f.localizedString(for: date, relativeTo: Date())
}

// Total non-deleted comments across both levels — used for the "Discussion (N)" label.
func liveCommentCount(_ comments: [CommentItem]) -> Int {
    comments.reduce(0) { acc, c in
        acc + (c.deleted ? 0 : 1) + c.replies.filter { !$0.deleted }.count
    }
}

// The Discussion segment body: a compose affordance (or sign-in nudge) + the thread.
struct DiscussionSection: View {
    let comments: [CommentItem]
    let isSignedIn: Bool
    let currentUserId: String?
    let onAdd: () -> Void
    let onReply: (CommentItem) -> Void
    let onDelete: (CommentItem) -> Void
    let onReport: (CommentItem) -> Void
    let onBlock: (CommentItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isSignedIn {
                SecondaryButton(title: "Add a comment", action: onAdd)
            } else {
                Text("Sign in to join the discussion.")
                    .font(.serif(15)).foregroundStyle(Theme.inkSoft)
            }

            if comments.isEmpty {
                Text("No comments yet.")
                    .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(comments) { comment in
                    CommentThread(
                        comment: comment,
                        isSignedIn: isSignedIn,
                        currentUserId: currentUserId,
                        onReply: onReply,
                        onDelete: onDelete,
                        onReport: onReport,
                        onBlock: onBlock
                    )
                }
            }
        }
    }
}

// A top-level comment with its (single-level) replies indented beneath it.
private struct CommentThread: View {
    let comment: CommentItem
    let isSignedIn: Bool
    let currentUserId: String?
    let onReply: (CommentItem) -> Void
    let onDelete: (CommentItem) -> Void
    let onReport: (CommentItem) -> Void
    let onBlock: (CommentItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CommentBody(
                comment: comment,
                isSignedIn: isSignedIn,
                currentUserId: currentUserId,
                canReply: isSignedIn,
                onReply: { onReply(comment) },
                onDelete: { onDelete(comment) },
                onReport: { onReport(comment) },
                onBlock: { onBlock(comment) }
            )
            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(comment.replies) { reply in
                        CommentBody(
                            comment: reply,
                            isSignedIn: isSignedIn,
                            currentUserId: currentUserId,
                            canReply: false,
                            onReply: {},
                            onDelete: { onDelete(reply) },
                            onReport: { onReport(reply) },
                            onBlock: { onBlock(reply) }
                        )
                    }
                }
                .padding(.leading, 14)
                .overlay(Rectangle().fill(Theme.line).frame(width: 1), alignment: .leading)
            }
        }
        .lyceumCard()
    }
}

private struct CommentBody: View {
    let comment: CommentItem
    let isSignedIn: Bool
    let currentUserId: String?
    let canReply: Bool
    let onReply: () -> Void
    let onDelete: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void

    private var isOwn: Bool {
        !comment.deleted && currentUserId != nil && comment.user.id == currentUserId
    }

    // Report + Block are offered on other people's live comments once signed in —
    // the App Store Guideline 1.2 affordances. Never on your own comment or a
    // deleted placeholder.
    private var canModerate: Bool {
        !comment.deleted && isSignedIn && currentUserId != nil && comment.user.id != currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(comment.deleted ? "deleted" : comment.user.name)
                    .font(.display(13)).kerning(0.3)
                    .foregroundStyle(comment.deleted ? Theme.inkSoft : Theme.gold300)
                Text(relativeTime(comment.createdAt))
                    .font(.caption).foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 0)
            }
            Text(comment.body)
                .font(.serif(16))
                .foregroundStyle(comment.deleted ? Theme.inkSoft : Theme.ink)
                .italic(comment.deleted)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !comment.deleted && (canReply || isOwn || canModerate) {
                HStack(spacing: 18) {
                    if canReply {
                        Button("Reply", action: onReply)
                            .font(.caption).foregroundStyle(Theme.gold400)
                    }
                    if isOwn {
                        Button("Delete", role: .destructive, action: onDelete)
                            .font(.caption)
                    }
                    if canModerate {
                        // A small overflow menu keeps Report/Block discoverable
                        // without cluttering the row.
                        Menu {
                            Button("Report comment", systemImage: "flag", role: .destructive, action: onReport)
                            Button("Block \(comment.user.name)", systemImage: "hand.raised", role: .destructive, action: onBlock)
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.caption).foregroundStyle(Theme.inkSoft)
                                .accessibilityLabel("More actions")
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
        }
    }
}

// Focused compose sheet for a new comment or a reply — keeps the keyboard out of
// the lecture's scroll view.
struct CommentComposeSheet: View {
    let replyingTo: CommentItem?
    /// Returns true on success (sheet dismisses); false shows an inline error.
    let onSubmit: (String) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var submitting = false
    @State private var errorText: String?
    @FocusState private var focused: Bool

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if let replyingTo {
                    Text("Replying to \(replyingTo.user.name)")
                        .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                }
                TextEditor(text: $text)
                    .focused($focused)
                    .font(.serif(17))
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Theme.parchmentDeep, in: RoundedRectangle(cornerRadius: 10))
                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .background(Theme.parchment)
            .navigationTitle(replyingTo == nil ? "New comment" : "Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submit() }
                        .disabled(trimmed.isEmpty || submitting)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func submit() {
        submitting = true
        errorText = nil
        Task {
            let ok = await onSubmit(trimmed)
            submitting = false
            if ok { dismiss() } else { errorText = "Couldn't post your comment. Try again." }
        }
    }
}
