import SwiftUI

// Tints every case-insensitive occurrence of `query` within `text` (for search
// match highlighting). Non-matching text keeps the view's default color.
func searchHighlighted(_ text: String, _ query: String, color: Color = Theme.gold300) -> AttributedString {
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

// Cinzel, uppercase, wide tracking, gold with a hairline rule — mirrors the web's
// section headings (font-display tracking-[0.25em] text-gold-400 border-crimson-700).
struct SectionHeader: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.display(15))
                .kerning(3)
                .foregroundStyle(Theme.gold400)
            Rectangle().fill(Theme.line).frame(height: 1)
        }
        .padding(.top, 8)
    }
}

struct Thumb: View {
    let url: String
    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle().fill(Theme.parchmentDeep)
        }
        .frame(width: 96, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Category row — same shape as CourseRow (thumbnail left, name + count right) so
// the category name is crisp native text. Thumbnail uses our web category
// artwork (/categories/<slug>.png).
struct CategoryRow: View {
    let category: CategoryItem
    var highlight: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: AppConfig.assetURL("/categories/\(category.slug).png")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Theme.parchmentDeep)
            }
            .frame(width: 96, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                nameText.font(.display(16)).kerning(0.5).foregroundStyle(Theme.ink)
                if let count = category.courseCount {
                    Text("\(count) course\(count == 1 ? "" : "s")")
                        .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Theme.gold400)
        }
        .lyceumCard()
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

// Lecture row — mirrors CourseRow (thumbnail + title + metadata), with the
// lecture's duration in place of the course's lecture count.
struct LectureRow: View {
    let video: VideoListItem
    var highlight: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            Thumb(url: video.thumbnailUrl)
            VStack(alignment: .leading, spacing: 4) {
                titleText.font(.display(15)).kerning(0.5).foregroundStyle(Theme.ink).lineLimit(2)
                if video.durationSeconds > 0 {
                    Text(formatDuration(video.durationSeconds))
                        .font(.serif(15)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer(minLength: 0)
        }
        .lyceumCard()
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
            Thumb(url: course.thumbnailUrl)
            VStack(alignment: .leading, spacing: 4) {
                titleText.font(.display(15)).kerning(0.5).foregroundStyle(Theme.ink).lineLimit(2)
                HStack(spacing: 8) {
                    Text("\(course.videoCount) lectures").font(.serif(15)).foregroundStyle(Theme.inkSoft)
                    Spacer(minLength: 8)
                    if course.isCurrent {
                        Text("Live")
                            .font(.display(10)).kerning(1).foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Theme.gold500).clipShape(Capsule())
                    }
                }
            }
        }
        .lyceumCard()
    }

    private var titleText: Text {
        if let highlight, !highlight.isEmpty {
            return Text(searchHighlighted(course.title, highlight))
        }
        return Text(course.title)
    }
}
