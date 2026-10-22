package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import app.baadan.later.R

/**
 * Draws the one adaptive widget: whatever size the user drags it to, the
 * layout that fits is chosen (strip, tiny, small, medium, large) and filled
 * with today's items in the colour picked in the app.
 */
object WidgetRender {
    private enum class Kind(val layout: Int, val rows: Int) {
        TINY(R.layout.widget_tiny, 0),
        STRIP(R.layout.widget_strip, 0),
        SMALL(R.layout.widget_small, 1),
        MEDIUM(R.layout.widget_medium, 3),
        LARGE(R.layout.widget_large, 4),
    }

    private val ROW_IDS = listOf(
        intArrayOf(R.id.row1, R.id.row1_bg, R.id.row1_dot, R.id.row1_t, R.id.row1_w),
        intArrayOf(R.id.row2, R.id.row2_bg, R.id.row2_dot, R.id.row2_t, R.id.row2_w),
        intArrayOf(R.id.row3, R.id.row3_bg, R.id.row3_dot, R.id.row3_t, R.id.row3_w),
        intArrayOf(R.id.row4, R.id.row4_bg, R.id.row4_dot, R.id.row4_t, R.id.row4_w),
    )

    private val CHIPS = listOf("inbox" to "📥", "learn" to "📚", "podcasts" to "🎧", "games" to "🎮", "wishlist" to "🛍", "ideas" to "💡")

    /** Which layout fits a widget of this size (dp). */
    private fun kindFor(w: Int, h: Int): Kind = when {
        h < 95 -> if (w >= 200) Kind.STRIP else Kind.TINY
        w < 200 -> Kind.SMALL
        h < 190 -> Kind.MEDIUM
        else -> Kind.LARGE
    }

    fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val data = WidgetStore.load(context)
        for (id in ids) {
            manager.updateAppWidget(id, render(context, id, manager.getAppWidgetOptions(id), data))
        }
    }

    fun render(context: Context, id: Int, options: Bundle, data: WidgetData?): RemoteViews {
        val w = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val h = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
        val kind = kindFor(w, h)
        val v = RemoteViews(context.packageName, kind.layout)
        val theme = WidgetTheme.of(context, data?.color ?: "green")
        val rows = data?.todayRows() ?: emptyList()
        val todayN = data?.counter("today") ?: ""

        // Accent parts
        for (mark in intArrayOf(R.id.mark_face, R.id.fab_face)) v.setInt(mark, "setColorFilter", theme.accent)
        for (edge in intArrayOf(R.id.mark_edge, R.id.fab_edge)) v.setInt(edge, "setColorFilter", theme.edge)
        v.setInt(R.id.count_bg, "setColorFilter", theme.soft)
        v.setTextColor(R.id.widget_count, theme.accentText)
        v.setTextColor(R.id.big, theme.accent)
        v.setInt(R.id.sug_bg, "setColorFilter", theme.accent)

        v.setTextViewText(R.id.widget_title, if (kind == Kind.SMALL) (data?.str("today") ?: "") else (data?.str("app") ?: context.getString(R.string.widget_loading)))
        v.setTextViewText(R.id.widget_count, if (data == null) "" else data.str("today") + " · " + todayN)
        v.setTextViewText(R.id.big, todayN)

        // Strip: first item (or the empty line) + a short sub line
        val first = rows.firstOrNull()
        v.setTextViewText(R.id.strip_t, first?.title ?: WidgetText.empty(data))
        v.setTextViewText(R.id.strip_sub, when {
            data == null -> ""
            first == null -> data.str("tagline")
            rows.size > 1 -> data.str("more", "+{n}").replace("{n}", data.num(rows.size - 1))
            else -> first.whenText
        })

        // Today rows
        for (i in 0 until 4) {
            val ids = ROW_IDS[i]
            if (i >= kind.rows) {
                v.setViewVisibility(ids[0], View.GONE)
                continue
            }
            val r = rows.getOrNull(i)
            if (r == null) {
                v.setViewVisibility(ids[0], View.GONE)
                continue
            }
            val extra = rows.size - kind.rows
            val isMore = i == kind.rows - 1 && extra > 0
            v.setViewVisibility(ids[0], View.VISIBLE)
            if (isMore) {
                v.setInt(ids[1], "setColorFilter", theme.soft)
                v.setInt(ids[2], "setColorFilter", android.graphics.Color.TRANSPARENT)
                v.setTextViewText(ids[3], data!!.str("more", "+{n}").replace("{n}", data.num(extra + 1)))
                v.setTextColor(ids[3], theme.accentText)
                v.setTextViewText(ids[4], "")
                v.setOnClickPendingIntent(ids[0], WidgetActions.open(context, "open", id * 10 + 10 + i))
            } else {
                v.setInt(ids[1], "setColorFilter", if (r.overdue) theme.lateBg else theme.soft)
                v.setInt(ids[2], "setColorFilter", if (r.overdue) theme.red else r.color)
                v.setTextViewText(ids[3], r.title)
                v.setTextColor(ids[3], if (r.overdue) theme.lateText else context.getColor(R.color.widget_text))
                v.setTextViewText(ids[4], r.whenText)
                v.setTextColor(ids[4], if (r.overdue) theme.lateText else context.getColor(R.color.widget_text_secondary))
                v.setOnClickPendingIntent(ids[0], WidgetActions.openItem(context, r.id, id * 10 + 10 + i))
            }
        }
        if (kind.rows > 0 || kind == Kind.SMALL) {
            if (rows.isEmpty()) {
                v.setViewVisibility(R.id.widget_msg, View.VISIBLE)
                v.setTextViewText(R.id.widget_msg, WidgetText.empty(data))
            } else {
                v.setViewVisibility(R.id.widget_msg, View.GONE)
            }
        }

        // Large: shelf counters + suggestion
        if (data != null) {
            val chips = CHIPS.filter { (data.counts[it.first] ?: 0) > 0 }
                .joinToString("   ") { "${it.second} ${data.counter(it.first)}" }
            v.setTextViewText(R.id.chips, chips)
            val sug = data.smartText?.takeIf { it.isNotBlank() }?.replace("\n", " ")
            v.setTextViewText(R.id.widget_suggestion, sug ?: data.str("nothing"))
            v.setViewVisibility(R.id.sug_box, if (sug == null) View.GONE else View.VISIBLE)
            v.setOnClickPendingIntent(R.id.sug_box, WidgetActions.openItem(context, data.smartId, id * 10 + 8))
            v.setContentDescription(R.id.widget_add, data.str("add"))
        }

        v.setOnClickPendingIntent(R.id.widget_add, WidgetActions.open(context, "capture", id * 10 + 1))
        v.setOnClickPendingIntent(R.id.strip_text, WidgetActions.openItem(context, first?.id, id * 10 + 2))
        v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 6))
        return v
    }
}

/** Builds and inflates every layout/colour combination; returns "ok" or the first error. */
object WidgetSelfTest {
    fun run(context: Context): String {
        val rows = listOf(
            TodayRow("1", "زنگ به مامان", 0xFF2E9E8F.toInt(), false, "۱۸:۰۰"),
            TodayRow("2", "قرص‌های ویتامین", 0xFF5B4FD6.toInt(), false, "۲۰:۳۰"),
            TodayRow("3", "پرداخت قبض", 0xFFD64F6E.toInt(), true, "دیروز"),
            TodayRow("4", "فیلم", 0xFFD64F6E.toInt(), false, ""),
            TodayRow("5", "کتاب", 0xFF2F7BC9.toInt(), false, ""),
        )
        val strings = mapOf("app" to "بعداً", "today" to "امروز", "more" to "+{n}", "todayEmpty" to "امروز چیزی نداری", "tagline" to "x", "fa" to "1")
        val withRows = WidgetData(5, false, null, null, emptyList(), mapOf("inbox" to 2, "games" to 1), "پیشنهاد", "1", "green", rows, strings)
        val empty = withRows.copy(today = emptyList(), smartText = null)
        val sizes = listOf(110 to 40, 150 to 70, 250 to 60, 150 to 150, 250 to 110, 250 to 230, 300 to 400)
        try {
            for (color in listOf("green", "blue", "purple", "orange", "pink", "ink")) {
                for ((w, h) in sizes) {
                    for (d in listOf(withRows.copy(color = color), empty.copy(color = color), null)) {
                        val b = Bundle()
                        b.putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, w)
                        b.putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, h)
                        WidgetRender.render(context, 7, b, d).apply(context, android.widget.FrameLayout(context))
                    }
                }
            }
        } catch (e: Exception) {
            return "error: $e"
        }
        return "ok"
    }
}

object WidgetText {
    fun empty(data: WidgetData?): String = when {
        data == null -> ""
        data.isStaleDay() -> data.str("tagline")
        else -> "🌿 " + data.str("todayEmpty", data.str("tagline"))
    }
}
