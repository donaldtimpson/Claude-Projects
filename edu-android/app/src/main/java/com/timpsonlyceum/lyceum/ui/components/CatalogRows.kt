package com.timpsonlyceum.lyceum.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.timpsonlyceum.lyceum.model.CategoryItem
import com.timpsonlyceum.lyceum.model.CourseListItem
import com.timpsonlyceum.lyceum.model.VideoListItem
import com.timpsonlyceum.lyceum.net.AppConfig
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display
import com.timpsonlyceum.lyceum.ui.theme.serif

private val ThumbShape = RoundedCornerShape(8.dp)

@Composable
fun Thumb(url: String) {
    AsyncImage(
        model = url,
        contentDescription = null,
        contentScale = ContentScale.Crop,
        modifier = Modifier.size(width = 96.dp, height = 60.dp).clip(ThumbShape).background(Theme.parchmentDeep),
    )
}

/**
 * Compact "Coming Soon" thumbnail for a course with no lectures yet — crimson
 * gradient and a gold frame, so an empty course never shows YouTube's grey
 * empty-playlist image.
 */
@Composable
fun ComingSoonThumb() {
    Box(
        modifier = Modifier
            .size(width = 96.dp, height = 60.dp)
            .clip(ThumbShape)
            .background(
                Brush.linearGradient(listOf(Theme.crimson800, Theme.crimson900, Theme.crimson950))
            ),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier.matchParentSize().padding(4.dp)
                .border(1.dp, Theme.gold500.copy(alpha = 0.4f), RoundedCornerShape(6.dp))
        )
        Text(
            "COMING\nSOON",
            style = display(10).copy(
                color = Theme.gold300,
                letterSpacing = 2.sp,
                textAlign = TextAlign.Center,
            ),
        )
    }
}

@Composable
fun CourseRow(course: CourseListItem, highlight: String? = null, onClick: () -> Unit) {
    LyceumCard(onClick = onClick, modifier = Modifier.testTag("courseRow")) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (course.videoCount == 0) ComingSoonThumb() else Thumb(course.thumbnailUrl)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    searchHighlighted(course.title, highlight),
                    style = display(15).copy(color = Theme.ink, letterSpacing = 0.5.sp),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        if (course.videoCount == 0) "Coming soon" else "${course.videoCount} lectures",
                        style = serif(15).copy(color = Theme.inkSoft),
                    )
                    Spacer(Modifier.weight(1f))
                    if (course.isCurrent) LivePill()
                }
            }
        }
    }
}

/**
 * Category row — the same shape as [CourseRow] so the name stays crisp native
 * text, over the web's category artwork at /categories/<slug>.png.
 */
@Composable
fun CategoryRow(category: CategoryItem, highlight: String? = null, onClick: () -> Unit) {
    LyceumCard(onClick = onClick) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            AsyncImage(
                model = AppConfig.assetUrl("/categories/${category.slug}.png"),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.size(width = 96.dp, height = 60.dp).clip(ThumbShape)
                    .background(Theme.parchmentDeep),
            )
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    searchHighlighted(category.name, highlight),
                    style = display(16).copy(color = Theme.ink, letterSpacing = 0.5.sp),
                )
                category.courseCount?.let { count ->
                    Spacer(Modifier.height(4.dp))
                    Text(
                        "$count course" + if (count == 1) "" else "s",
                        style = serif(15).copy(color = Theme.inkSoft),
                    )
                }
            }
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = Theme.gold400,
            )
        }
    }
}

/**
 * Lecture row — mirrors [CourseRow], with the lecture's duration where the course
 * has its lecture count, and the lecture number on the right so a student can see
 * which one they are on without reading the title.
 */
@Composable
fun LectureRow(video: VideoListItem, highlight: String? = null, onClick: () -> Unit) {
    LyceumCard(onClick = onClick, modifier = Modifier.testTag("lectureRow")) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Thumb(video.thumbnailUrl)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    searchHighlighted(video.title, highlight),
                    style = display(15).copy(color = Theme.ink, letterSpacing = 0.5.sp),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (video.durationSeconds > 0) {
                        Text(formatDuration(video.durationSeconds), style = serif(15).copy(color = Theme.inkSoft))
                    }
                    Spacer(Modifier.weight(1f))
                    Text("${video.position + 1}", style = display(15).copy(color = Theme.gold400))
                }
            }
        }
    }
}
