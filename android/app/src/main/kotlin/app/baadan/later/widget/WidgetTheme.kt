package app.baadan.later.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color

/** The widget's colours: one accent chosen in the app, light or night neutrals. */
class WidgetTheme(val accent: Int, val edge: Int, private val softLight: Int, val night: Boolean) {
    /** Soft tint used behind rows and the counter. */
    val soft: Int get() = if (night) blend(accent, NIGHT_BG, 0.20f) else softLight
    val accentText: Int get() = if (night) accent else edge
    val lateBg: Int get() = if (night) blend(RED, NIGHT_BG, 0.20f) else 0xFFFFE6E6.toInt()
    val lateText: Int get() = if (night) 0xFFFF9A9A.toInt() else 0xFFB53434.toInt()
    val red: Int get() = RED

    companion object {
        private const val RED = 0xFFEA5455.toInt()
        private val NIGHT_BG = 0xFF202A31.toInt()

        // name -> accent, accent edge (the "thick" bottom border), light soft tint
        private val TABLE = mapOf(
            "green" to Triple(0xFF58B947, 0xFF3F9A31, 0xFFE3F6DE),
            "blue" to Triple(0xFF1CB0F6, 0xFF1587C2, 0xFFDDF3FF),
            "purple" to Triple(0xFFA56CF0, 0xFF7F47C4, 0xFFEFE4FF),
            "orange" to Triple(0xFFFF9600, 0xFFCC7A00, 0xFFFFEBCF),
            "pink" to Triple(0xFFF2619A, 0xFFC94479, 0xFFFFE1ED),
            "ink" to Triple(0xFF4B5F6B, 0xFF33444E, 0xFFE3E9EC),
        )

        fun of(context: Context, name: String): WidgetTheme {
            val t = TABLE[name] ?: TABLE.getValue("green")
            val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            return WidgetTheme(t.first.toInt(), t.second.toInt(), t.third.toInt(), night)
        }

        private fun blend(fg: Int, bg: Int, a: Float): Int {
            val r = (Color.red(fg) * a + Color.red(bg) * (1 - a)).toInt()
            val g = (Color.green(fg) * a + Color.green(bg) * (1 - a)).toInt()
            val b = (Color.blue(fg) * a + Color.blue(bg) * (1 - a)).toInt()
            return Color.rgb(r, g, b)
        }
    }
}
