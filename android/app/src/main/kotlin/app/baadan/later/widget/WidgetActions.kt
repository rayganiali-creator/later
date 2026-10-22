package app.baadan.later.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import app.baadan.later.MainActivity

/** Intents shared by every widget size. All of them stay inside this app. */
object WidgetActions {
    const val ACTION_REFRESH = "app.baadan.later.WIDGET_REFRESH"

    fun open(context: Context, quick: String, requestCode: Int): PendingIntent =
        PendingIntent.getActivity(
            context,
            requestCode,
            MainActivity.quickIntent(context, quick),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** Tapping the suggestion opens that very item. */
    fun openItem(context: Context, itemId: String?, requestCode: Int): PendingIntent =
        if (itemId.isNullOrBlank()) open(context, "open", requestCode) else open(context, "item:$itemId", requestCode)

    fun refresh(context: Context, provider: Class<out AppWidgetProvider>, requestCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, provider).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** Refresh button: ask a running app for fresh data, then redraw from the saved snapshot. */
    fun handleRefresh(context: Context, intent: Intent) {
        if (intent.action != ACTION_REFRESH) return
        MainActivity.requestWidgetRefresh()
        WidgetStore.refreshAll(context)
    }

    fun idsOf(context: Context, cls: Class<out AppWidgetProvider>): IntArray =
        AppWidgetManager.getInstance(context).getAppWidgetIds(android.content.ComponentName(context, cls))
}
