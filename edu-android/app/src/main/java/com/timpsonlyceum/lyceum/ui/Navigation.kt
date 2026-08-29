package com.timpsonlyceum.lyceum.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Hub
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.timpsonlyceum.lyceum.auth.AuthViewModel
import com.timpsonlyceum.lyceum.ui.components.LoadingScreen
import com.timpsonlyceum.lyceum.ui.screens.*
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.display

/**
 * Route names. Kept as plain strings rather than a sealed type because several
 * carry ids and the argument plumbing reads better inline.
 */
object Routes {
    const val COURSES = "courses"
    const val REVIEW = "review"
    const val DRILLS = "drills"
    const val PROGRESS = "progress"

    const val CATEGORY = "category/{slug}/{name}"
    fun category(slug: String, name: String) = "category/$slug/${name.encodeArg()}"

    const val COURSE = "course/{courseId}"
    fun course(id: String) = "course/$id"

    const val LECTURE = "lecture/{courseId}/{videoId}"
    fun lecture(courseId: String, videoId: String) = "lecture/$courseId/$videoId"

    const val COURSE_TEST = "coursetest/{courseId}/{title}"
    fun courseTest(courseId: String, title: String) = "coursetest/$courseId/${title.encodeArg()}"

    const val PROBLEM_SET = "problemset/{courseId}/{problemSetId}"
    fun problemSet(courseId: String, id: String) = "problemset/$courseId/$id"

    const val MAP = "map"
    const val SCHOLARS = "scholars"
    const val SIGN_IN = "signin"
}

private fun String.encodeArg(): String =
    java.net.URLEncoder.encode(this, "UTF-8").replace("+", "%20")

private data class Tab(val route: String, val label: String, val icon: ImageVector)

private val Tabs = listOf(
    // "Courses", matching the web nav — it was "Learn" in the tab bar and
    // "Courses" on the web for one identical catalog.
    Tab(Routes.COURSES, "Courses", Icons.AutoMirrored.Filled.MenuBook),
    Tab(Routes.REVIEW, "Review", Icons.Filled.Layers),
    Tab(Routes.DRILLS, "Drills", Icons.Filled.FitnessCenter),
    // "Progress", not "Profile": the same screen the web calls My Progress.
    Tab(Routes.PROGRESS, "Progress", Icons.Filled.ShowChart),
)

@Composable
fun LyceumApp() {
    val auth: AuthViewModel = viewModel()
    val loading by auth.loading.collectAsState()
    val nav = rememberNavController()

    if (loading) {
        SplashScreen()
        return
    }
    Scaffold(
        containerColor = Theme.parchment,
        bottomBar = { LyceumBottomBar(nav) },
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = Routes.COURSES,
            modifier = Modifier.padding(padding),
        ) {
            composable(Routes.COURSES) {
                CoursesTab(nav)
            }
            composable(Routes.REVIEW) {
                ReviewScreen(auth) { nav.navigate(Routes.SIGN_IN) }
            }
            composable(Routes.DRILLS) {
                DrillsScreen()
            }
            composable(Routes.PROGRESS) {
                ProgressScreen(auth, nav)
            }
            composable(Routes.SIGN_IN) {
                SignInScreen(auth, onDone = { nav.popBackStack() })
            }
            composable(Routes.MAP) {
                CourseMapScreen { id -> nav.navigate(Routes.course(id)) }
            }
            composable(Routes.SCHOLARS) {
                ScholarsScreen(auth) { nav.navigate(Routes.SIGN_IN) }
            }
            composable(Routes.CATEGORY) { entry ->
                CategoryScreen(
                    slug = entry.arguments?.getString("slug").orEmpty(),
                    name = decodeArg(entry.arguments?.getString("name")),
                    onOpenCourse = { nav.navigate(Routes.course(it)) },
                )
            }
            composable(Routes.COURSE) { entry ->
                CourseScreen(
                    courseId = entry.arguments?.getString("courseId").orEmpty(),
                    nav = nav,
                )
            }
            composable(Routes.LECTURE) { entry ->
                LectureScreen(
                    courseId = entry.arguments?.getString("courseId").orEmpty(),
                    videoId = entry.arguments?.getString("videoId").orEmpty(),
                    auth = auth,
                    nav = nav,
                )
            }
            composable(Routes.COURSE_TEST) { entry ->
                CourseTestScreen(
                    courseId = entry.arguments?.getString("courseId").orEmpty(),
                    title = decodeArg(entry.arguments?.getString("title")),
                    auth = auth,
                    onSignIn = { nav.navigate(Routes.SIGN_IN) },
                )
            }
            composable(Routes.PROBLEM_SET) { entry ->
                ProblemSetScreen(
                    courseId = entry.arguments?.getString("courseId").orEmpty(),
                    problemSetId = entry.arguments?.getString("problemSetId").orEmpty(),
                )
            }
        }
    }
}

private fun decodeArg(raw: String?): String =
    raw?.let { java.net.URLDecoder.decode(it, "UTF-8") }.orEmpty()

@Composable
private fun CoursesTab(nav: NavHostController) {
    CatalogScreen(
        onOpenCourse = { nav.navigate(Routes.course(it)) },
        onOpenCategory = { nav.navigate(Routes.category(it.slug, it.name)) },
        onOpenLecture = { c, v -> nav.navigate(Routes.lecture(c, v)) },
    )
}

@Composable
private fun LyceumBottomBar(nav: NavHostController) {
    val entry by nav.currentBackStackEntryAsState()
    val current = entry?.destination?.route
    NavigationBar(containerColor = Theme.card, contentColor = Theme.ink) {
        Tabs.forEach { tab ->
            NavigationBarItem(
                selected = current == tab.route,
                onClick = {
                    nav.navigate(tab.route) {
                        popUpTo(Routes.COURSES) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                },
                icon = { Icon(tab.icon, contentDescription = tab.label) },
                label = { Text(tab.label, style = display(12).copy(color = Theme.ink)) },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = Theme.gold300,
                    selectedTextColor = Theme.gold300,
                    unselectedIconColor = Theme.inkSoft,
                    unselectedTextColor = Theme.inkSoft,
                    indicatorColor = Theme.parchmentDeep,
                ),
            )
        }
    }
}
