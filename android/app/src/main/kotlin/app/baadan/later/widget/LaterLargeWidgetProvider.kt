package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.baadan.later.R

/** Large widget: a small dashboard of every shelf, the suggestion and the actions. */
class LaterLargeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = update(context, manager, ids)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        WidgetActions.handleRefresh(context, intent)
    }

    companion object {
        private data class Cell(val key: String, val n: Int, val l: Int)

        private val CELLS = listOf(
            Cell("today", R.id.c1_n, R.id.c1_l),
            Cell("inbox", R.id.c2_n, R.id.c2_l),
            Cell("learn", R.id.c3_n, R.id.c3_l),
            Cell("podcasts", R.id.c4_n, R.id.c4_l),
            Cell("games", R.id.c5_n, R.id.c5_l),
            Cell("wishlist", R.id.c6_n, R.id.c6_l),
            Cell("ideas", R.id.c7_n, R.id.c7_l),
            Cell("read", R.id.c8_n, R.id.c8_l),
        )

        fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val data = WidgetStore.load(context)
            for (id in ids) {
                val v = RemoteViews(context.packageName, R.layout.widget_large)
                v.setTextViewText(R.id.widget_title, data?.str("app", "") ?: context.getString(R.string.widget_loading))
                v.setTextViewText(R.id.widget_tagline, data?.str("tagline", "") ?: "")
                if (data != null) {
                    for (c in CELLS) {
                        v.setTextViewText(c.n, data.counter(c.key))
                        v.setTextViewText(c.l, data.str(c.key))
                    }
                    v.setTextViewText(R.id.widget_suggestion, data.smartText?.takeIf { it.isNotBlank() } ?: data.str("nothing"))
                    v.setContentDescription(R.id.widget_add, data.str("add"))
                    v.setContentDescription(R.id.widget_pick, data.str("pick"))
                    v.setContentDescription(R.id.widget_inbox, data.str("inbox"))
                    v.setContentDescription(R.id.widget_refresh, data.str("refresh"))
                }
                v.setOnClickPendingIntent(R.id.widget_add, WidgetActions.open(context, "capture", id * 10 + 1))
                v.setOnClickPendingIntent(R.id.widget_pick, WidgetActions.open(context, "pick", id * 10 + 2))
                v.setOnClickPendingIntent(R.id.widget_inbox, WidgetActions.open(context, "inbox", id * 10 + 3))
                v.setOnClickPendingIntent(R.id.widget_refresh, WidgetActions.refresh(context, LaterLargeWidgetProvider::class.java, id * 10 + 4))
                v.setOnClickPendingIntent(R.id.widget_suggestion, WidgetActions.openItem(context, data?.smartId, id * 10 + 5))
                v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 6))
                manager.updateAppWidget(id, v)
            }
        }
    }
}
