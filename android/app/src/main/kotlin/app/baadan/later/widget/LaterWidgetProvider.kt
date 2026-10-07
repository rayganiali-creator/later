package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.baadan.later.R

/** Small widget (2x2): today's count and first items, with a quick add button. */
class LaterWidgetProvider : AppWidgetProvider() {

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
                val v = RemoteViews(context.packageName, R.layout.widget_small)
                v.setTextViewText(R.id.widget_title, data?.str("app", "") ?: context.getString(R.string.widget_loading))
                if (data != null) {
                    v.setTextViewText(R.id.widget_count, data.counter("today"))
                    v.setContentDescription(R.id.widget_add, data.str("add"))
                }
                WidgetRows.bind(context, v, data, 2, id * 10 + 10, WidgetHeader.emptyText(data))
                v.setOnClickPendingIntent(R.id.widget_add, WidgetActions.open(context, "capture", id * 10 + 1))
                v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 4))
                manager.updateAppWidget(id, v)
            }
        }

        /** Kept for the list widget. */
        fun pending(context: Context, quick: String, requestCode: Int) = WidgetActions.open(context, quick, requestCode)
    }
}
