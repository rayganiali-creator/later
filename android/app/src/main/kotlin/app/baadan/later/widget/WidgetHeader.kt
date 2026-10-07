package app.baadan.later.widget

import android.content.Context
import android.widget.RemoteViews
import app.baadan.later.R

/** Title, today-count pill and the small round buttons, shared by every size. */
object WidgetHeader {
    fun emptyText(data: WidgetData?): String = when {
        data == null -> ""
        data.isStaleDay() -> data.str("tagline")
        else -> data.str("todayEmpty", data.str("tagline"))
    }

    fun bind(context: Context, v: RemoteViews, data: WidgetData?, id: Int) {
        v.setTextViewText(R.id.widget_title, data?.str("app", "") ?: context.getString(R.string.widget_loading))
        if (data != null) {
            v.setTextViewText(R.id.widget_count, data.str("today") + " · " + data.counter("today"))
            v.setContentDescription(R.id.widget_add, data.str("add"))
            v.setContentDescription(R.id.widget_pick, data.str("pick"))
            v.setContentDescription(R.id.widget_inbox, data.str("inbox"))
        }
        v.setOnClickPendingIntent(R.id.widget_add, WidgetActions.open(context, "capture", id * 10 + 1))
        v.setOnClickPendingIntent(R.id.widget_pick, WidgetActions.open(context, "pick", id * 10 + 2))
        v.setOnClickPendingIntent(R.id.widget_inbox, WidgetActions.open(context, "inbox", id * 10 + 3))
    }
}
