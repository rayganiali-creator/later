package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.baadan.later.R

/** Large widget (4x3): more of today's items, shelf counters and the suggestion. */
class LaterLargeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = update(context, manager, ids)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        WidgetActions.handleRefresh(context, intent)
    }

    companion object {
        private val CHIPS = listOf(
            "inbox" to "📥",
            "learn" to "📚",
            "podcasts" to "🎧",
            "games" to "🎮",
            "wishlist" to "🛍",
            "ideas" to "💡",
        )

        fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val data = WidgetStore.load(context)
            for (id in ids) {
                val v = RemoteViews(context.packageName, R.layout.widget_large)
                WidgetHeader.bind(context, v, data, id)
                WidgetRows.bind(context, v, data, 4, id * 10 + 10, WidgetHeader.emptyText(data))
                if (data != null) {
                    val chips = CHIPS.filter { (data.counts[it.first] ?: 0) > 0 }
                        .joinToString("   ") { "${it.second} ${data.counter(it.first)}" }
                    v.setTextViewText(R.id.widget_chips, chips)
                    v.setTextViewText(R.id.widget_suggestion, data.smartText?.takeIf { it.isNotBlank() }?.replace("\n", " ") ?: data.str("nothing"))
                    v.setContentDescription(R.id.widget_refresh, data.str("refresh"))
                }
                v.setOnClickPendingIntent(R.id.widget_refresh, WidgetActions.refresh(context, LaterLargeWidgetProvider::class.java, id * 10 + 4))
                v.setOnClickPendingIntent(R.id.widget_suggestion, WidgetActions.openItem(context, data?.smartId, id * 10 + 5))
                v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 6))
                manager.updateAppWidget(id, v)
            }
        }
    }
}
