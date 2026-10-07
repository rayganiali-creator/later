package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.baadan.later.R

/** Medium widget: inbox and today, one suggestion, four actions. */
class LaterMediumWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = update(context, manager, ids)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        WidgetActions.handleRefresh(context, intent)
    }

    companion object {
        fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val data = WidgetStore.load(context)
            for (id in ids) {
                val v = RemoteViews(context.packageName, R.layout.widget_medium)
                v.setTextViewText(R.id.widget_title, data?.str("app", "") ?: context.getString(R.string.widget_loading))
                v.setTextViewText(R.id.widget_tagline, data?.str("tagline", "") ?: "")
                if (data != null) {
                    v.setTextViewText(R.id.widget_inbox_n, data.counter("inbox"))
                    v.setTextViewText(R.id.widget_inbox_l, data.str("inbox"))
                    v.setTextViewText(R.id.widget_today_n, data.counter("today"))
                    v.setTextViewText(R.id.widget_today_l, data.str("today"))
                    v.setTextViewText(R.id.widget_suggestion, data.smartText?.takeIf { it.isNotBlank() } ?: data.str("nothing"))
                    v.setContentDescription(R.id.widget_add, data.str("add"))
                    v.setContentDescription(R.id.widget_pick, data.str("pick"))
                    v.setContentDescription(R.id.widget_inbox, data.str("inbox"))
                    v.setContentDescription(R.id.widget_refresh, data.str("refresh"))
                }
                v.setOnClickPendingIntent(R.id.widget_add, WidgetActions.open(context, "capture", id * 10 + 1))
                v.setOnClickPendingIntent(R.id.widget_pick, WidgetActions.open(context, "pick", id * 10 + 2))
                v.setOnClickPendingIntent(R.id.widget_inbox, WidgetActions.open(context, "inbox", id * 10 + 3))
                v.setOnClickPendingIntent(R.id.widget_refresh, WidgetActions.refresh(context, LaterMediumWidgetProvider::class.java, id * 10 + 4))
                v.setOnClickPendingIntent(R.id.widget_suggestion, WidgetActions.openItem(context, data?.smartId, id * 10 + 5))
                v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 6))
                manager.updateAppWidget(id, v)
            }
        }
    }
}
