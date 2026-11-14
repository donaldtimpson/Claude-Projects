import SwiftUI

// Tints every case-insensitive occurrence of `query` within `text` (for search
// match highlighting). Non-matching text keeps the view's default color.
func searchHighlighted(_ text: String, _ query: String, color: Color = Theme.accentText) -> AttributedString {
    let q = query.trimmingCharacters(in: .whitespaces)
    guard !q.isEmpty else { return AttributedString(text) }
    var result = AttributedString()
    var idx = text.startIndex
    while let range = text.range(of: q, options: .caseInsensitive, range: idx..<text.endIndex) {
        result += AttributedString(String(text[idx..<range.lowerBound]))
        var matched = AttributedString(String(text[range]))
        matched.foregroundColor = color
        result += matched
        idx = range.upperBound
    }
    result += AttributedString(String(text[idx...]))
    return result
}

/// Older name for the section heading; same component as `SectionTitle`.
struct SectionHeader: View {
    let title: String
    var body: some View { SectionTitle(title) }
}

struct Thumb: View {
    let url: String
    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle().fill(Theme.tint)
        }
        .frame(width: 96, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Compact "Coming Soon" thumbnail for an empty course (0 lectures) — the row-sized
// counterpart to the web's CourseThumb placeholder. Crimson gradient + gold frame
// so an empty course never shows YouTube's gray empty-playlist image.
struct ComingSoonThumb: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.brandCrimson800, Theme.brandCrimson900, Theme.brandCrimson950],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Text("COMING\nSOON")
                .font(.display(10))
                .kerning(2)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
                .foregroundStyle(Theme.brandGold)
        }
        .frame(width: 96, height: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .inset(by: 4)
                .stroke(Theme.brandGold.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Category row: same shape as CourseRow (artwork left, name + count right).
struct CategoryRow: View {
    let category: CategoryItem
    var highlight: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: AppConfig.assetURL("/categories/\(category.slug).png")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Theme.tint)
            }
            .frame(width: 96, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                nameText.font(.serif(18, .semibold)).foregroundStyle(Theme.ink)
                if let count = category.courseCount {
                    Text("\(count) course\(count == 1 ? "" : "s")")
                        .font(.ui(14)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.ui(14, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .lyceumCard(padding: 12)
    }

    private var nameText: Text {
        if let highlight, !highlight.isEmpty {
            return Text(searchHighlighted(category.name, highlight))
        }
        return Text(category.name)
    }
}

// "2:05:16" (or "5:42" under an hour).
func formatDuration(_ seconds: Int) -> String {
    let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}

// Lecture row: thumbnail, title, and a metadata line with the lecture's label
// ("Lecture 3", read from its title by the server), duration, comments, and a
// green ✓ once watched.
struct LectureRow: View {
    let video: VideoListItem
    var watched: Bool = false
    var highlight: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            Thumb(url: video.thumbnailUrl)
            VStack(alignment: .leading, spacing: 5) {
                titleText.font(.serif(17, .semibold)).foregroundStyle(Theme.ink).lineLimit(2)
                HStack(spacing: 6) {
                    Text(meta).font(.ui(13)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                    Spacer(minLength: 4)
                    if watched {
                        Label("Watched", systemImage: "checkmark")
                            .labelStyle(.iconOnly)
                            .font(.ui(13, .bold))
                            .foregroundStyle(Theme.success)
                            .accessibilityLabel("Watched")
                    }
                }
            }
        }
        .lyceumCard(padding: 12)
        .accessibilityIdentifier("lectureRow")
    }

    private var meta: String {
        var bits: [String] = []
        if let label = video.label { bits.append(label) }
        if video.durationSeconds > 0 { bits.append(formatDuration(video.durationSeconds)) }
        if let c = video.commentCount, c > 0 { bits.append("\(c) comment\(c == 1 ? "" : "s")") }
        return bits.joined(separator: " · ")
    }

    private var titleText: Text {
        if let highlight, !highlight.isEmpty {
            return Text(searchHighlighted(video.title, highlight))
        }
        return Text(video.title)
    }
}

struct CourseRow: View {
    let course: CourseListItem
    var highlight: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            if course.videoCount == 0 {
                ComingSoonThumb()
            } else {
                Thumb(url: course.thumbnailUrl)
            }
            VStack(alignment: .leading, spacing: 5) {
                titleText.font(.serif(17, .semibold)).foregroundStyle(Theme.ink).lineLimit(2)
                HStack(spacing: 8) {
                    Text(course.videoCount == 0 ? "Coming soon" : "\(course.videoCount) lectures")
                        .font(.ui(13)).foregroundStyle(Theme.inkSoft)
                    Spacer(minLength: 8)
                    if course.isCurrent { Pill("Live", tone: .accent) }
                }
            }
        }
        .lyceumCard(padding: 12)
        // Stable handle for the screenshot UI test.
        .accessibilityIdentifier("courseRow")
    }

    private var titleText: Text {
        if let highlight, !highlight.isEmpty {
            return Text(searchHighlighted(course.title, highlight))
        }
        return Text(course.title)
    }
}
