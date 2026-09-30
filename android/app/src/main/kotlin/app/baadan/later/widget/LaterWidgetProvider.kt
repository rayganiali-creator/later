package app.baadan.later.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import app.baadan.later.MainActivity
import app.baadan.later.R

/** Small widget: waiting count, one suggestion, [+ add] and [pick] buttons. */
class LaterWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        update(context, manager, ids)
    }

    companion object {
        fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val data = WidgetStore.load(context)
            for (id in ids) {
                val v = RemoteViews(context.packageName, R.layout.widget_small)
                v.setTextViewText(R.id.widget_title, data?.str("app", "") ?: context.getString(R.string.widget_loading))
                if (data == null) {
                    v.setTextViewText(R.id.widget_count, "")
                    v.setTextViewText(R.id.widget_suggestion, "")
                } else {
                    val text = if (data.count == 0) data.str("empty")
                    else data.str("waiting", "{n}").replace("{n}", data.count.toString())
                    v.setTextViewText(R.id.widget_count, text)
                    val sug = data.suggestion
                    v.setTextViewText(
                        R.id.widget_suggestion,
                        if (sug.isNullOrBlank()) "" else "${data.str("suggestion")}: $sug",
                    )
                    v.setTextViewText(R.id.widget_add, data.str("add"))
                    v.setTextViewText(R.id.widget_pick, data.str("pick"))
                }
                v.setOnClickPendingIntent(R.id.widget_add, pending(context, "add", id * 10 + 1))
                v.setOnClickPendingIntent(R.id.widget_pick, pending(context, "pick", id * 10 + 2))
                v.setOnClickPendingIntent(R.id.widget_root, pending(context, "open", id * 10 + 3))
                manager.updateAppWidget(id, v)
            }
        }

        fun pending(context: Context, quick: String, requestCode: Int): PendingIntent =
            PendingIntent.getActivity(
                context,
                requestCode,
                MainActivity.quickIntent(context, quick),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
    }
}
