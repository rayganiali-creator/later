package app.baadan.later.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import app.baadan.later.R

/** Advanced (Pro) widget: the next few items. Shows a hint when Pro is off. */
class LaterListWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        update(context, manager, ids)
    }

    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        WidgetActions.handleRefresh(context, intent)
    }

    companion object {
        private val ITEM_IDS = intArrayOf(R.id.widget_item1, R.id.widget_item2, R.id.widget_item3, R.id.widget_item4)

        fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val data = WidgetStore.load(context)
            for (id in ids) {
                val v = RemoteViews(context.packageName, R.layout.widget_list)
                v.setTextViewText(R.id.widget_title, data?.str("app", "") ?: context.getString(R.string.widget_loading))
                if (data == null) {
                    v.setTextViewText(R.id.widget_count, "")
                    ITEM_IDS.forEach { v.setTextViewText(it, "") }
                } else {
                    val countText = if (data.count == 0) data.str("empty")
                    else data.str("waiting", "{n}").replace("{n}", data.num(data.count))
                    v.setTextViewText(R.id.widget_count, countText)
                    if (!data.pro) {
                        ITEM_IDS.forEachIndexed { i, rid -> v.setTextViewText(rid, if (i == 0) data.str("proOnly") else "") }
                    } else {
                        ITEM_IDS.forEachIndexed { i, rid ->
                            v.setTextViewText(rid, data.items.getOrNull(i)?.let { "• $it" } ?: "")
                        }
                    }
                    v.setTextViewText(R.id.widget_add, data.str("add"))
                    v.setTextViewText(R.id.widget_pick, data.str("pick"))
                }
                v.setOnClickPendingIntent(R.id.widget_add, WidgetActions.open(context, "capture", id * 10 + 4))
                v.setOnClickPendingIntent(R.id.widget_pick, WidgetActions.open(context, "pick", id * 10 + 5))
                v.setOnClickPendingIntent(R.id.widget_root, WidgetActions.open(context, "open", id * 10 + 6))
                manager.updateAppWidget(id, v)
            }
        }
    }
}
