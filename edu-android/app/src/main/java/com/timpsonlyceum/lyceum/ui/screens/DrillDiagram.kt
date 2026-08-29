package com.timpsonlyceum.lyceum.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.timpsonlyceum.lyceum.drills.DrillDiagram
import com.timpsonlyceum.lyceum.ui.theme.Theme
import com.timpsonlyceum.lyceum.ui.theme.serif
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/** The figure that goes with a drill prompt, when it has one. */
@Composable
fun DrillDiagramView(diagram: DrillDiagram) {
    when (diagram) {
        is DrillDiagram.Matrix -> BracketedGrid(diagram.rows, bars = true)
        is DrillDiagram.MatrixVector -> Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            BracketedGrid(diagram.matrix, bars = false, fill = false)
            Spacer(Modifier.width(10.dp))
            BracketedGrid(diagram.vector.map { listOf(it) }, bars = false, fill = false)
        }
        is DrillDiagram.UnitCircle -> UnitCirclePlot(diagram.angleDeg, diagram.fn)
        is DrillDiagram.Vector -> VectorPlot(diagram.angleDeg, diagram.component)
        is DrillDiagram.GeoMap -> Text(
            "Map not available",
            style = serif(14).copy(color = Theme.inkSoft),
        )
    }
}

/**
 * A matrix, drawn with determinant bars or square brackets.
 *
 * The minus signs are replaced here rather than at the generator, because the
 * grid is the only place these integers are shown raw.
 */
@Composable
private fun BracketedGrid(rows: List<List<Int>>, bars: Boolean, fill: Boolean = true) {
    val edge = if (bars) "│" else "["
    val edgeR = if (bars) "│" else "]"
    Row(
        modifier = if (fill) Modifier.fillMaxWidth() else Modifier,
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(edge, fontSize = (28 * rows.size).sp, color = Theme.gold400)
        Spacer(Modifier.width(6.dp))
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            rows.forEach { row ->
                Row {
                    row.forEach { v ->
                        Text(
                            v.toString().replace("-", "−"),
                            style = serif(20).copy(color = Theme.ink, textAlign = TextAlign.Center),
                            modifier = Modifier.widthIn(min = 44.dp).padding(vertical = 2.dp),
                        )
                    }
                }
            }
        }
        Spacer(Modifier.width(6.dp))
        Text(edgeR, fontSize = (28 * rows.size).sp, color = Theme.gold400)
    }
}

/** The unit circle with the asked-about angle drawn on it. */
@Composable
private fun UnitCirclePlot(angleDeg: Double, fn: String) {
    Canvas(Modifier.fillMaxWidth().height(180.dp)) {
        val cx = size.width / 2
        val cy = size.height / 2
        val r = minOf(cx, cy) * 0.78f

        drawCircle(Theme.line, radius = r, center = Offset(cx, cy), style = Stroke(width = 2f))
        drawLine(Theme.line, Offset(cx - r, cy), Offset(cx + r, cy), strokeWidth = 1.5f)
        drawLine(Theme.line, Offset(cx, cy - r), Offset(cx, cy + r), strokeWidth = 1.5f)

        // Screen y grows downward, so the angle is negated to read anticlockwise.
        val rad = angleDeg * PI / 180.0
        val px = cx + r * cos(rad).toFloat()
        val py = cy - r * sin(rad).toFloat()

        drawLine(Theme.gold300, Offset(cx, cy), Offset(px, py), strokeWidth = 4f)
        drawCircle(Theme.gold300, radius = 7f, center = Offset(px, py))

        // The dashed drop shows which projection the question is asking for.
        val dash = PathEffect.dashPathEffect(floatArrayOf(8f, 8f))
        if (fn == "cos") {
            drawLine(Theme.inkSoft, Offset(px, py), Offset(px, cy), strokeWidth = 2f, pathEffect = dash)
            drawLine(Theme.success, Offset(cx, cy), Offset(px, cy), strokeWidth = 4f)
        } else if (fn == "sin") {
            drawLine(Theme.inkSoft, Offset(px, py), Offset(cx, py), strokeWidth = 2f, pathEffect = dash)
            drawLine(Theme.success, Offset(cx, cy), Offset(cx, py), strokeWidth = 4f)
        }
    }
}

/** A vector at an angle, with the requested component picked out. */
@Composable
private fun VectorPlot(angleDeg: Double, component: String) {
    Canvas(Modifier.fillMaxWidth().height(180.dp)) {
        val cx = size.width / 2
        val cy = size.height / 2
        val r = minOf(cx, cy) * 0.78f

        drawLine(Theme.line, Offset(cx - r, cy), Offset(cx + r, cy), strokeWidth = 1.5f)
        drawLine(Theme.line, Offset(cx, cy - r), Offset(cx, cy + r), strokeWidth = 1.5f)

        val rad = angleDeg * PI / 180.0
        val px = cx + r * cos(rad).toFloat()
        val py = cy - r * sin(rad).toFloat()

        drawLine(Theme.gold300, Offset(cx, cy), Offset(px, py), strokeWidth = 4f)
        drawCircle(Theme.gold300, radius = 7f, center = Offset(px, py))

        val dash = PathEffect.dashPathEffect(floatArrayOf(8f, 8f))
        if (component == "x") {
            drawLine(Theme.inkSoft, Offset(px, py), Offset(px, cy), strokeWidth = 2f, pathEffect = dash)
            drawLine(Theme.success, Offset(cx, cy), Offset(px, cy), strokeWidth = 5f)
        } else {
            drawLine(Theme.inkSoft, Offset(px, py), Offset(cx, py), strokeWidth = 2f, pathEffect = dash)
            drawLine(Theme.success, Offset(cx, cy), Offset(cx, py), strokeWidth = 5f)
        }
    }
}
