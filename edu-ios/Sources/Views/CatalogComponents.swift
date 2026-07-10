import SwiftUI

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
                Text(category.name).font(.display(16)).kerning(0.5).foregroundStyle(Theme.ink)
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
}

struct CourseRow: View {
    let course: CourseListItem
    var body: some View {
        HStack(spacing: 12) {
            Thumb(url: course.thumbnailUrl)
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title).font(.display(15)).kerning(0.5).foregroundStyle(Theme.ink).lineLimit(2)
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
}
