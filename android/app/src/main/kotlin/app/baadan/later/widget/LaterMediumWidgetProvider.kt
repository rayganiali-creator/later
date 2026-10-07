package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.baadan.later.R

/** Main widget (4x2, compact): what is set for today, plus add / roulette / inbox. */
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
                WidgetHeader.bind(context, v, data, id)
                WidgetRows.bind(context, v, data, 3, id * 10 + 10, WidgetHeader.emptyText(data))
                v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 6))
                manager.updateAppWidget(id, v)
            }
        }
    }
}
