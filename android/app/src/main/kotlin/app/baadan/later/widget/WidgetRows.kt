package app.baadan.later.widget

import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews
import app.baadan.later.R

/** Draws the "today" rows shared by the small, medium and large widgets. */
object WidgetRows {
    private val ROWS = listOf(
        Triple(R.id.row1, R.id.row1_dot, R.id.row1_t),
        Triple(R.id.row2, R.id.row2_dot, R.id.row2_t),
        Triple(R.id.row3, R.id.row3_dot, R.id.row3_t),
        Triple(R.id.row4, R.id.row4_dot, R.id.row4_t),
    )
    private const val OVERDUE = 0xFFE5484D.toInt()

    /**
     * Fills up to [max] rows with today's items (tap = open that item). When
     * there are none, shows [emptyText] instead. Returns nothing; rows beyond
     * [max] stay hidden. The last row turns into "+N more" if items are left.
     */
    fun bind(context: Context, v: RemoteViews, data: WidgetData?, max: Int, firstCode: Int, emptyText: String, idRows: Int = max) {
        val rows = data?.todayRows() ?: emptyList()
        val shown = minOf(max, ROWS.size, idRows)
        val extra = rows.size - shown
        for ((i, r) in ROWS.withIndex()) {
            val (row, dot, text) = r
            if (i >= shown || (rows.isEmpty())) {
                v.setViewVisibility(row, android.view.View.GONE)
                continue
            }
            val last = i == shown - 1 && extra > 0
            if (last) {
                v.setViewVisibility(row, android.view.View.VISIBLE)
                v.setInt(dot, "setColorFilter", Color.TRANSPARENT)
                v.setTextViewText(text, data!!.str("more", "+{n}").replace("{n}", data.num(extra + 1)))
                v.setOnClickPendingIntent(row, WidgetActions.open(context, "open", firstCode + i))
                continue
            }
            val it = rows[i]
            v.setViewVisibility(row, android.view.View.VISIBLE)
            v.setInt(dot, "setColorFilter", if (it.overdue) OVERDUE else it.color)
            v.setTextViewText(text, it.title)
            v.setTextColor(text, if (it.overdue) OVERDUE else textColor(context))
            v.setOnClickPendingIntent(row, WidgetActions.openItem(context, it.id, firstCode + i))
        }
        if (rows.isEmpty()) {
            v.setViewVisibility(R.id.widget_msg, android.view.View.VISIBLE)
            v.setTextViewText(R.id.widget_msg, emptyText)
        } else {
            v.setViewVisibility(R.id.widget_msg, android.view.View.GONE)
        }
    }

    private fun textColor(context: Context): Int = context.getColor(R.color.widget_text)
}
