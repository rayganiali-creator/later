package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.baadan.later.R

/** Small widget: one suggestion, [+ quick add] and [pick]. */
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
                if (data == null) {
                    v.setTextViewText(R.id.widget_suggestion, "")
                } else {
                    val text = data.smartText?.takeIf { it.isNotBlank() }
                        ?: if (data.count == 0) data.str("empty") else data.str("waiting", "{n}").replace("{n}", data.num(data.count))
                    v.setTextViewText(R.id.widget_suggestion, text)
                    v.setTextViewText(R.id.widget_add, "＋")
                    v.setTextViewText(R.id.widget_pick, "🎯")
                    v.setContentDescription(R.id.widget_add, data.str("add"))
                    v.setContentDescription(R.id.widget_pick, data.str("pick"))
                }
                v.setOnClickPendingIntent(R.id.widget_add, WidgetActions.open(context, "capture", id * 10 + 1))
                v.setOnClickPendingIntent(R.id.widget_pick, WidgetActions.open(context, "pick", id * 10 + 2))
                v.setOnClickPendingIntent(R.id.widget_suggestion, WidgetActions.openItem(context, data?.smartId, id * 10 + 3))
                v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 4))
                manager.updateAppWidget(id, v)
            }
        }

        /** Kept for the list widget. */
        fun pending(context: Context, quick: String, requestCode: Int) = WidgetActions.open(context, quick, requestCode)
    }
}
